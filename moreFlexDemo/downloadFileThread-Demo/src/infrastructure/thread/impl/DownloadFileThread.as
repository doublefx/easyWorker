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
 * User: Frederic THOMAS Date: 06/07/2014 Time: 19:23
 */
package infrastructure.thread.impl {
import com.doublefx.as3.thread.Thread;
import com.doublefx.as3.thread.ThreadState;
import com.doublefx.as3.thread.event.ThreadFaultEvent;
import com.doublefx.as3.thread.event.ThreadProgressEvent;
import com.doublefx.as3.thread.event.ThreadResultEvent;
import com.doublefx.as3.thread.event.ThreadStateEvent;

import domain.vo.DownloadFileDescriptor;

import infrastructure.thread.api.downloadFileWorker.IDownloader;
import infrastructure.thread.event.ResumableStatusEvent;

import mx.events.PropertyChangeEvent;

public class DownloadFileThread extends Thread implements IDownloader {
    public static var dbPath:String;

    private static const extraDependencies:Vector.<String> = Vector.<String>(
            ["domain.vo::DownloadFileDescriptor",
                "infrastructure.thread.impl.util.db::Registry",
                "infrastructure.thread.event::ResumableStatusEvent"]);

    private var _downloadFileDescriptor:DownloadFileDescriptor;
    private var _onProgress:Function;
    private var _onError:Function;
    private var _onCompleted:Function;

    private var _useCache:Boolean = true;
    private var _isResumable:Boolean;

    public function DownloadFileThread(name:String, downloadFileDescriptor:DownloadFileDescriptor, onProgress:Function = null, onError:Function = null, onCompleted:Function = null) {
        super(DownloadFileRunnable, name, true, extraDependencies);

        _downloadFileDescriptor = downloadFileDescriptor;
        _onProgress = onProgress;
        _onError = onError;
        _onCompleted = onCompleted;

        setSharedProperty("dbPath", dbPath);

        // Set up listeners
        addEventListener(ThreadStateEvent.THREAD_STATE, threadStateHandler);
    }

    private function threadStateHandler(event:ThreadStateEvent):void {
        switch (state) {
            case ThreadState.RUNNING:
            {
                addEventListeners();
                break;
            }

            case ThreadState.TERMINATED:
            {
                removeEventListeners();
                break;
            }
        }
    }

    override public function start(...args):void {
        super.start(_downloadFileDescriptor);
    }

    [Bindable]
    public function get useCache():Boolean {
        return _useCache;
    }

    public function set useCache(v:Boolean):void {
        if (isNew) {
            setSharedProperty("useCache", v);
            _useCache = v;
        }
    }

    public function get isResumable():Boolean {
        return _isResumable;
    }

    public function get fileDescriptor():DownloadFileDescriptor {
        return _downloadFileDescriptor;
    }

    private function addEventListeners():void {

        addEventListener(ResumableStatusEvent.RESUMABLE_STATUS, resumableStatusHandler);

        addEventListener(ThreadProgressEvent.PROGRESS, progressHandler);
        if (_onProgress != null) {
            addEventListener(ThreadProgressEvent.PROGRESS, _onProgress);
        }

        if (_onError != null)
            addEventListener(ThreadFaultEvent.FAULT, _onError);

        if (_onCompleted != null)
            addEventListener(ThreadResultEvent.RESULT, _onCompleted);
    }

    private function removeEventListeners():void {

        removeEventListener(ThreadStateEvent.THREAD_STATE, threadStateHandler);
        removeEventListener(ResumableStatusEvent.RESUMABLE_STATUS, resumableStatusHandler);

        removeEventListener(ThreadProgressEvent.PROGRESS, progressHandler);
        if (_onProgress != null) {
            removeEventListener(ThreadProgressEvent.PROGRESS, _onProgress);
        }

        if (_onError != null)
            removeEventListener(ThreadFaultEvent.FAULT, _onError);

        if (_onCompleted != null)
            removeEventListener(ThreadResultEvent.RESULT, _onCompleted);
    }

    private function progressHandler(event:ThreadProgressEvent):void {
        fileDescriptor.bytesTotal = event.total;
        fileDescriptor.bytesLoaded = event.current;
    }

    private function resumableStatusHandler(event:ResumableStatusEvent):void {
        const oldValue:Boolean = _isResumable;
        _isResumable = event.isResumable;

        const propertyChangeEvent:PropertyChangeEvent = PropertyChangeEvent.createUpdateEvent(this, "isResumable", oldValue, _isResumable);
        dispatchEvent(propertyChangeEvent);
    }
}
}
