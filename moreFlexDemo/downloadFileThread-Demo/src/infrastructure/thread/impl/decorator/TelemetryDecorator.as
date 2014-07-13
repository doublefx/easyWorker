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
 * User: Frédéric THOMAS Date: 16/09/13 Time: 20:23
 */
package infrastructure.thread.impl.decorator {
import com.doublefx.as3.thread.event.ThreadProgressEvent;
import com.doublefx.as3.thread.event.ThreadResultEvent;

import domain.vo.DownloadFileDescriptor;

import flash.events.Event;

import infrastructure.thread.api.downloadFileWorker.IDownloadFileWorkerTelemetry;
import infrastructure.thread.api.downloadFileWorker.IDownloader;

[Bindable]
public class TelemetryDecorator implements IDownloader, IDownloadFileWorkerTelemetry {
    private var _decorated:IDownloader;

    private var _startTime:Date;
    private var _endTime:Date;
    private var _totalTime:Number = 0;
    private var _totalEffectiveTime:Number = 0;
    private var _estimatedRemainingTime:Number = 0;
    private var _numberOfBytesPerSecondAverage:Number = 0;
    private var _midStartTime:Date;
    private var _midMilliseconds:Number = 0;
    //private var _alreadyFlushedBytes:Number = 0;

    public function TelemetryDecorator(decorated:IDownloader) {
        _decorated = decorated;

        if (_decorated == null)
            throw new ArgumentError("The decorated IDownloadFileThread must not be null");
    }

    public function get startTime():Date {
        return _startTime;
    }

    public function set startTime(v:Date):void {
        _startTime = v;
    }

    public function get endTime():Date {
        return _endTime;
    }

    public function set endTime(v:Date):void {
        _endTime = v;
    }

    public function get totalTime():Number {
        return _totalTime;
    }

    public function set totalTime(v:Number):void {
        _totalTime = v;
    }

    public function get totalEffectiveTime():Number {
        return _totalEffectiveTime;
    }

    public function set totalEffectiveTime(v:Number):void {
        _totalEffectiveTime = v;
    }

    public function get estimatedRemainingTime():Number {
        return _estimatedRemainingTime;
    }

    public function set estimatedRemainingTime(v:Number):void {
        _estimatedRemainingTime = v;
    }

    public function get numberOfBytesPerSecondAverage():Number {
        return _numberOfBytesPerSecondAverage;
    }

    public function set numberOfBytesPerSecondAverage(v:Number):void {
        _numberOfBytesPerSecondAverage = v;
    }

    public function start(...args):void {
        startTime = new Date();
        addEventHandlers();

        /*var fd:DownloadFileDescriptor = new DownloadFileDescriptor(fileDescriptor.fileUrl, fileDescriptor.fileTargetPath);
         Registry.load(fd);
         _alreadyFlushedBytes = fd.bytesLoaded;*/


        _decorated.start();
    }

    public function terminate():void {
        endTime = new Date();
        removeEventHandlers();

        _decorated.terminate();
    }

    public function pause(milli:Number = 0):void {
        _midStartTime = new Date();
        removeEventHandlers();

        _decorated.pause(milli);
    }

    public function resume():void {
        _midMilliseconds += new Date().getTime() - _midStartTime.getTime();
        addEventHandlers();

        _decorated.resume();
    }

    public function get useCache():Boolean {
        return _decorated.useCache;
    }

    public function set useCache(v:Boolean):void {
        _decorated.useCache = v;
    }

    public function get isRunning():Boolean {
        return _decorated.isRunning;
    }

    public function get isResumable():Boolean {
        return _decorated.isResumable;
    }

    public function get isPaused():Boolean {
        return _decorated.isPaused;
    }

    public function get id():uint {
        return _decorated.id;
    }

    public function get name():String {
        return _decorated.name;
    }

    public function get state():String {
        return _decorated.state;
    }

    public function get isNew():Boolean {
        return _decorated.isNew;
    }

    public function get isTerminated():Boolean {
        return _decorated.isTerminated;
    }

    public function get isStarting():Boolean {
        return _decorated.isStarting;
    }

    public function get isPausing():Boolean {
        return _decorated.isPausing;
    }

    public function get isResuming():Boolean {
        return _decorated.isResuming;
    }

    public function get isTerminating():Boolean {
        return _decorated.isTerminating;
    }

    public function setSharedProperty(key:String, value:*):void {
        _decorated.setSharedProperty(key, value);
    }

    public function getSharedProperty(key:String):* {
        return _decorated.getSharedProperty(key);
    }

    public function get fileDescriptor():DownloadFileDescriptor {
        return _decorated.fileDescriptor;
    }

    public function addEventListener(type:String, listener:Function, useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = false):void {
        _decorated.addEventListener(type, listener, useCapture, priority, useWeakReference);
    }

    public function removeEventListener(type:String, listener:Function, useCapture:Boolean = false):void {
        _decorated.removeEventListener(type, listener, useCapture);
    }

    public function dispatchEvent(event:Event):Boolean {
        return _decorated.dispatchEvent(event);
    }

    public function hasEventListener(type:String):Boolean {
        return _decorated.hasEventListener(type);
    }

    public function willTrigger(type:String):Boolean {
        return _decorated.willTrigger(type);
    }

    private function addEventHandlers():void {
        _decorated.addEventListener(ThreadProgressEvent.PROGRESS, decorated_progressHandler);
        _decorated.addEventListener(ThreadResultEvent.RESULT, decorated_completeHandler);
    }

    private function removeEventHandlers():void {
        _decorated.removeEventListener(ThreadProgressEvent.PROGRESS, decorated_progressHandler);
        _decorated.removeEventListener(ThreadResultEvent.RESULT, decorated_completeHandler);
    }

    private function decorated_progressHandler(event:ThreadProgressEvent):void {
        doTelemetry();
    }

    private function decorated_completeHandler(event:ThreadResultEvent):void {
        doTelemetry();
    }

    private function doTelemetry():void {
        var now:Date = _endTime ? _endTime : new Date();

        totalTime = now.getTime() - _startTime.getTime();
        totalEffectiveTime = _totalTime - _midMilliseconds;
        numberOfBytesPerSecondAverage = (fileDescriptor.bytesLoaded/* - _alreadyFlushedBytes*/) / _totalEffectiveTime * 1000;
        estimatedRemainingTime = (fileDescriptor.bytesTotal - fileDescriptor.bytesLoaded/* + _alreadyFlushedBytes*/) / _numberOfBytesPerSecondAverage * 1000;
    }
}
}