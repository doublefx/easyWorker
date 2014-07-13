/*
 * Copyright (c) 2014 Frédéric Thomas
 *
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/**
 * User: Frederic THOMAS Date: 06/07/2014 Time: 17:53
 */
package infrastructure.thread.impl {
import com.doublefx.as3.thread.api.CrossThreadDispatcher;
import com.doublefx.as3.thread.api.Runnable;
import com.doublefx.as3.thread.event.ThreadActionRequestEvent;
import com.doublefx.as3.thread.event.ThreadActionResponseEvent;

import domain.vo.DownloadFileDescriptor;

import flash.desktop.NativeApplication;
import flash.events.ErrorEvent;
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.events.HTTPStatusEvent;
import flash.events.IOErrorEvent;
import flash.events.ProgressEvent;
import flash.events.SecurityErrorEvent;
import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;
import flash.net.URLRequest;
import flash.net.URLRequestHeader;
import flash.net.URLStream;
import flash.system.System;
import flash.system.Worker;
import flash.utils.ByteArray;
import flash.utils.clearInterval;
import flash.utils.setInterval;

import infrastructure.thread.event.ResumableStatusEvent;
import infrastructure.thread.impl.util.db.Registry;

/**
 * Download or copy a file represented by an URL in a FileDescriptor.
 *
 * The download can be started, paused (disk persistent when useCache=true), resumed and terminated.
 * If after a long pause, the file size has changed on the server, the download is aborted and started again.
 */
public class DownloadFileRunnable extends EventDispatcher implements Runnable {

    // Wait for 5 minutes before aborting a download attempt.
    // Some servers can be extremely slow at time.
    public static var idleTimeout:int = 300000;

    /**
     * HTTP status
     */
    private static const PARTIAL_CONTENT:int = 206;
    private static const OK:int = 200;

    /**
     * Mandatory declaration if you want your Worker be able to communicate.
     * This CrossThreadDispatcher is injected at runtime.
     */
    private var _dispatcher:CrossThreadDispatcher;

    /**
     * Do we want to display some debug info ?
     */
    protected var debugMode:Boolean = true;

    /**
     * The descriptor representing the file to download or copy.
     */
    protected var fileDescriptor:DownloadFileDescriptor;

    /**
     * Indicate if the use wants to cache the downloading file.
     * If true, the file will be resumed after a pause() or a pause() + terminate() + start()
     * If false, the file will be completely downloaded again
     */
    protected var useCache:Boolean = true;

    /**
     * The stream of the downloading file.
     */
    protected var urlStream:URLStream = null;

    /**
     * The URL Request use to download the file or its part.
     */
    protected var urlRequest:URLRequest = null;

    /**
     * The percentage loaded of the downloading file.
     * Used to send progress at ticks.
     */
    protected var lastPercentLoaded:Number = 0;

    /**
     * True if the server has resuming capabilities.
     */
    protected var hasResumingCapabilities:Boolean;

    /**
     * Stream to the downloading file written to the disk.
     * We flush it at ticks.
     */
    protected var fileStream:FileStream;

    /**
     * Used as buffer between the urlStream and the fileStream.
     */
    protected var buffer:ByteArray;

    /**
     * Indicate that the current download has been paused.
     */
    protected var paused:Boolean;

    /**
     * Interval for the tick (flush bytes to the disk and send progress).
     */
    protected var intervalId:uint;

    /**
     * Represent the bytes written to the disk before the start() has been called.
     */
    protected var flushedBytes:Number = 0;

    /**
     * The ID of this Runnable, applicationID + ThreadName + ThreadId
     */
    protected var runnableId:String;

    public function run(args:Array):void {
        var dbPath:String = Worker.current.getSharedProperty("dbPath");
        runnableId = NativeApplication.nativeApplication.applicationID + "[" + dispatcher.currentThreadName + "] [" + dispatcher.currentThreadId + "]";
        Registry.connect(dbPath, runnableId);

        fileDescriptor = args[0] as DownloadFileDescriptor;
        copyOrDownload();
    }


    protected function copyOrDownload():void {
        var fileTarget:File = new File(fileDescriptor.fileTargetPath);

        if (fileTarget.exists) {
            if (!useCache) {
                try {
                    fileTarget.deleteFile();
                    Registry.remove(fileDescriptor);
                }
                catch (e:Error) {
                    dispatcher.dispatchError(e);
                    return;
                }
            }
            else {
                Registry.load(fileDescriptor);
                flushedBytes = fileDescriptor.bytesLoaded;
                traceInfo("copyOrDownload -> Registry.load(fileDescriptor)", fileTarget ? "fileTarget.size: " + fileTarget.size : "fileTarget.size not available");

                dispatcher.dispatchProgress(fileDescriptor.bytesLoaded, fileDescriptor.bytesTotal);

                if (fileDescriptor.bytesTotal > 0 && fileDescriptor.bytesLoaded == fileDescriptor.bytesTotal) {
                    dispatcher.dispatchResult(fileDescriptor);
                    return;
                }
            }
        }
        doCopyOrDownload(fileTarget);

    }

    private function doCopyOrDownload(fileTarget:File):void {
        if (fileDescriptor.fileUrl.search("http") == 0 || fileDescriptor.fileUrl.search("file://") == 0) {
            download(fileDescriptor.fileUrl);
        }
        else {
            const source:File = new File(fileDescriptor.fileUrl);

            try {
                source.copyTo(fileTarget, true);
                fileDescriptor.bytesLoaded = fileDescriptor.bytesTotal = fileTarget.size;
                dispatcher.dispatchProgress(fileDescriptor.bytesLoaded, fileDescriptor.bytesTotal);
                dispatcher.dispatchResult(fileDescriptor);
            }
            catch (error:Error) {
                dispatcher.dispatchError(error);
            }
        }
    }

    protected function download(url:String):void {
        urlStream = new URLStream();
        urlRequest = new URLRequest(url + "?" + new Date().getTime());

        if (fileDescriptor.bytesLoaded > 0) {
            urlRequest.requestHeaders = [ new URLRequestHeader("Range", "bytes=" + fileDescriptor.bytesLoaded + "-")];
            traceInfo("download", "urlRequest.requestHeaders: " + "Range, bytes=" + fileDescriptor.bytesLoaded + "-");
        }

        urlRequest.idleTimeout = idleTimeout;

        buffer = new ByteArray();

        urlStream.addEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS, onDownloadResponseStatus);

        urlStream.addEventListener(ErrorEvent.ERROR, handleDownloadError, false, 0, true);
        urlStream.addEventListener(IOErrorEvent.IO_ERROR, handleDownloadError, false, 0, true);
        urlStream.addEventListener(SecurityErrorEvent.SECURITY_ERROR, handleDownloadError, false, 0, true);

        urlStream.addEventListener(ProgressEvent.PROGRESS, handleDownloadProgress, false, 0, true);
        urlStream.addEventListener(Event.COMPLETE, handleDownloadComplete, false, 0, true);

        urlStream.load(urlRequest);

        intervalId = setInterval(flushPartialDownloadToMemory, 500);
    }

    protected function onDownloadResponseStatus(event:HTTPStatusEvent):void {
        urlStream.removeEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS, onDownloadResponseStatus);
        var header:URLRequestHeader;

        if (event.status == OK || event.status == PARTIAL_CONTENT)
            for each (header in event.responseHeaders) {
                if (header.name == "Accept-Ranges" && header.value == "bytes") {
                    hasResumingCapabilities = true;
                }
                else if (header.name == "Content-Length") {
                    const contentLength:Number = parseInt(header.value);
                    traceInfo("onDownloadResponseStatus", "contentLength: " + contentLength);
                    if (fileDescriptor.bytesTotal > 0 && fileDescriptor.bytesTotal - fileDescriptor.bytesLoaded != contentLength) {
                        abort();
                        run([ fileDescriptor ]);
                        return;
                    }
                }
            }

        dispatcher.dispatchArbitraryEvent(new ResumableStatusEvent(hasResumingCapabilities));
    }

    protected function handleDownloadProgress(event:ProgressEvent):void {
        if (fileDescriptor.bytesTotal == 0) {
            fileDescriptor.bytesTotal = event.bytesTotal;
        }
        sendProgressAtTick();
    }

    protected function handleDownloadError(event:ErrorEvent):void {
        dispatcher.dispatchError(new Error(event.text, event.errorID));
    }

    protected function handleDownloadComplete(event:Event):void {
        flushMemoryToDisk();
        dispatcher.dispatchResult(fileDescriptor);
    }

    protected function abort():void {
        traceInfo("Before abort");

        clearInterval(intervalId);

        var isDownloadCompleted:Boolean = fileDescriptor.bytesLoaded == fileDescriptor.bytesTotal;

        if (isDownloadCompleted) {
            Registry.remove(fileDescriptor);
        }
        else if (hasResumingCapabilities && paused)
            flushMemoryToDisk();
        else
            deleteFile();

        freeUpMemory();

        Registry.close();
        System.gc();
        System.gc();

        traceInfo("After abort");
    }

    private function deleteFile():void {
        freeUpMemory();
        var fileTarget:File = new File(fileDescriptor.fileTargetPath);
        try {
            if (fileTarget.exists)
                fileTarget.deleteFile();
        }
        catch (e:Error) {
            // Don't dispatch an error at this stage as a we may just has the same one from the last try to delete it.
        }
        Registry.remove(fileDescriptor);
    }

    private function flushMemoryToDisk():void {
        //traceInfo("Before flushMemoryToDisk");
        flushLastBytesToMemory();
        sendProgressAtTick();
        writeFile();
        Registry.save(fileDescriptor);
        //traceInfo("After flushMemoryToDisk");
    }

    private function freeUpMemory():void {
        //traceInfo("Before flushMemoryToDisk");
        try {
            if (buffer) {
                buffer.clear();
                buffer = null;
            }

            if (urlStream) {
                urlStream.close();
                urlStream.removeEventListener(ErrorEvent.ERROR, handleDownloadError);
                urlStream.removeEventListener(IOErrorEvent.IO_ERROR, handleDownloadError);
                urlStream.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, handleDownloadError);
                urlStream.removeEventListener(ProgressEvent.PROGRESS, handleDownloadProgress);
                urlStream.removeEventListener(Event.COMPLETE, handleDownloadComplete);
                urlStream = null;
            }

            if (fileStream) {
                fileStream.removeEventListener(IOErrorEvent.IO_ERROR, handleDownloadError);
                fileStream.close();
                fileStream = null;
            }
        }
        catch (error:Error) {
            //trace("error: " + error.message);
        }
        finally {
            //traceInfo("After flushMemoryToDisk");
        }
    }

    protected function flushLastBytesToMemory():void {
        //traceInfo("Before flushLastBytesToMemory");
        clearInterval(intervalId);

        if (fileDescriptor.bytesLoaded != fileDescriptor.bytesTotal)
            flushPartialDownloadToMemory();

        //traceInfo("After flushLastBytesToMemory");
    }

    protected function sendProgressAtTick():void {
        var percentLoaded:Number = Number(Number(fileDescriptor.bytesLoaded * 100 / fileDescriptor.bytesTotal).toFixed(fileDescriptor.progressPrecision));


        // only send progress messages every
        // progressPrecision milestone with a
        // minimum of half second of delay
        // to avoid flooding the message channel.
        if (percentLoaded != lastPercentLoaded) {
            lastPercentLoaded = percentLoaded;
            //traceInfo("sendProgressAtTick");
            dispatcher.dispatchProgress(fileDescriptor.bytesLoaded, fileDescriptor.bytesTotal);
        }
    }

    protected function flushPartialDownloadToMemory():void {

        //traceInfo("Before flushPartialDownloadToMemory");
        try {
            const bytesAvailable:uint = urlStream.bytesAvailable;

            if (bytesAvailable) {
                urlStream.readBytes(buffer, fileDescriptor.bytesLoaded - flushedBytes, bytesAvailable);
                fileDescriptor.bytesLoaded += bytesAvailable;
            }
        }
        catch (error:Error) {
            //trace("error: " + error.message);
        }
        //traceInfo("After flushPartialDownloadToMemory");
    }

    protected function writeFile():void {
        if (buffer) {
            var fileTarget:File = new File(fileDescriptor.fileTargetPath);

            fileTarget.downloaded = true;
            fileTarget.preventBackup = true;

            fileStream = new FileStream();
            fileStream.addEventListener(IOErrorEvent.IO_ERROR, handleDownloadError, false, 0, true);
            fileStream.open(fileTarget, FileMode.APPEND);
            fileStream.writeBytes(buffer, 0, buffer.length);
            traceInfo("After writeFile", "fileTarget.size: " + fileTarget.size);
            fileStream.close();
        }
    }

    public function get dispatcher():CrossThreadDispatcher {
        return _dispatcher;
    }

    public function set dispatcher(value:CrossThreadDispatcher):void {
        if (_dispatcher) {
            _dispatcher.removeEventListener(ThreadActionRequestEvent.PAUSE_REQUESTED, dispatcher_pauseRequestedHandler);
            _dispatcher.removeEventListener(ThreadActionRequestEvent.RESUME_REQUESTED, dispatcher_resumeRequestedHandler);
            _dispatcher.removeEventListener(ThreadActionRequestEvent.TERMINATE_REQUESTED, dispatcher_terminateRequestedHandler);
        }

        _dispatcher = value;

        if (_dispatcher) {
            _dispatcher.addEventListener(ThreadActionRequestEvent.PAUSE_REQUESTED, dispatcher_pauseRequestedHandler);
            _dispatcher.addEventListener(ThreadActionRequestEvent.RESUME_REQUESTED, dispatcher_resumeRequestedHandler);
            _dispatcher.addEventListener(ThreadActionRequestEvent.TERMINATE_REQUESTED, dispatcher_terminateRequestedHandler);
        }
    }

    private function dispatcher_pauseRequestedHandler(event:ThreadActionRequestEvent):void {
        paused = true;

        trace("\n----------- Pausing --------------\n");

        abort();

        trace("\n----------- Paused --------------\n");

        _dispatcher.dispatchEvent(new ThreadActionResponseEvent(ThreadActionResponseEvent.PAUSED));
    }

    private function dispatcher_resumeRequestedHandler(event:ThreadActionRequestEvent):void {
        _dispatcher.dispatchEvent(new ThreadActionResponseEvent(ThreadActionResponseEvent.RESUMED));

        paused = false;

        trace("\n----------- Resumed --------------\n");

        run([ fileDescriptor ]);
    }

    private function dispatcher_terminateRequestedHandler(event:ThreadActionRequestEvent):void {
        trace("\n----------- Terminating --------------\n");
        abort();
        trace("\n----------- Terminated --------------\n");
        _dispatcher.dispatchEvent(new ThreadActionResponseEvent(ThreadActionResponseEvent.TERMINATED));
    }

    private function traceInfo(fctName:String, extraInfo:String = ""):void {
        if (debugMode) {
            const sep:String = "-------------------------------\n";
            const loaderInfo:String = urlStream && urlStream.connected ? urlStream.bytesAvailable.toString() : "0";
            const bufferInfo:String = buffer != null ? buffer.length.toString() : "null";

            var info:String = runnableId + "[" + fctName + "]" +
                    "\nfileDescriptor.bytesTotal: " + fileDescriptor.bytesTotal +
                    "\nfileDescriptor.bytesLoaded: " + fileDescriptor.bytesLoaded +
                    "\nfileDescriptor.bytesTotal - fileDescriptor.bytesLoaded: " + int(fileDescriptor.bytesTotal - fileDescriptor.bytesLoaded).toString() +
                    "\n_loader.bytesAvailable: " + loaderInfo +
                    "\n_buffer.length: " + bufferInfo +
                    "\n_flushedBytes: " + flushedBytes +
                    "\n_totalDownloadedBytes: " + fileDescriptor.bytesLoaded;

            trace(sep + info + "\n" + extraInfo + "\n" + sep);
        }
    }
}
}
