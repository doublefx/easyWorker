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
 * User: Frederic THOMAS Date: 23/06/2014 Time: 14:27
 */
package {
import com.doublefx.as3.thread.Thread;
import com.doublefx.as3.thread.api.IThread;
import com.doublefx.as3.thread.event.ThreadFaultEvent;
import com.doublefx.as3.thread.event.ThreadProgressEvent;
import com.doublefx.as3.thread.event.ThreadResultEvent;
import com.doublefx.as3.thread.event.ThreadStateEvent;

import feathers.controls.Button;
import feathers.controls.Check;
import feathers.controls.Label;

import starling.display.Sprite;
import starling.events.Event;

import workers.ComplexWorker;
import workers.vo.TermsVo;

public class Main extends Sprite {

    public static var themeClass:Class;

    private var _result:Label;

    private var _isNewCheck:Check;
    private var _isRunningCheck:Check;
    private var _isPausedCheck:Check;
    private var _isResumedCheck:Check;
    private var _isTerminatedCheck:Check;
    private var _startBtn:Button;

    private var _thread:IThread;

    public function Main():void {
        initialize();
    }

    private function initialize():void {
        if (stage) createChildren();
        else addEventListener(Event.ADDED_TO_STAGE, createChildren);

        addEventListener("childrenCreated", childrenCreated);
    }

    private function createChildren(event:Event = null):void {
        removeEventListener(Event.ADDED_TO_STAGE, createChildren);

        if (themeClass)
            new themeClass();

        _result = new Label();
        _result.text = "Result: ";
        addChild(_result);
        _result.validate();

        _isNewCheck = new Check();
        _isNewCheck.label = "NEW";
        _isNewCheck.y = _result.y + _result.height + 2;
        _isNewCheck.height = _result.height;
        _isNewCheck.isSelected = true;
        _isNewCheck.isEnabled = false;
        addChild(_isNewCheck);
        _isNewCheck.validate();

        _isRunningCheck = new Check();
        _isRunningCheck.label = "RUNNING";
        _isRunningCheck.y = _result.y + _result.height + 2;
        _isRunningCheck.x = _isNewCheck.x + _isNewCheck.width + 2;
        _isRunningCheck.isEnabled = false;
        addChild(_isRunningCheck);
        _isRunningCheck.validate();

        _isPausedCheck = new Check();
        _isPausedCheck.label = "PAUSED";
        _isPausedCheck.y = _isRunningCheck.y;
        _isPausedCheck.x = _isRunningCheck.x + _isRunningCheck.width + 2;
        _isPausedCheck.isEnabled = false;
        addChild(_isPausedCheck);
        _isPausedCheck.validate();

        _isResumedCheck = new Check();
        _isResumedCheck.label = "RESUMED";
        _isResumedCheck.y = _isRunningCheck.y;
        _isResumedCheck.x = _isPausedCheck.x + _isPausedCheck.width + 2;
        _isResumedCheck.isEnabled = false;
        addChild(_isResumedCheck);
        _isResumedCheck.validate();

        _isTerminatedCheck = new Check();
        _isTerminatedCheck.label = "TERMINATED";
        _isTerminatedCheck.y = _isRunningCheck.y;
        _isTerminatedCheck.x = _isResumedCheck.x + _isResumedCheck.width + 2;
        _isTerminatedCheck.isEnabled = false;
        addChild(_isTerminatedCheck);
        _isTerminatedCheck.validate();

        _startBtn = new Button();
        _startBtn.label = "Start";
        _startBtn.y = _isResumedCheck.y + _isRunningCheck.height + 2;
        _startBtn.addEventListener(Event.TRIGGERED, startBtn_triggeredHandler);
        addChild(_startBtn);

        dispatchEvent(new Event("childrenCreated"));
    }

    private function childrenCreated(event:Event):void {
        try {
            _thread = new Thread(ComplexWorker, "complexRunnable");

            _thread.addEventListener(ThreadStateEvent.THREAD_STATE, onThreadState);
            _thread.addEventListener(ThreadProgressEvent.PROGRESS, thread_progressHandler);
            _thread.addEventListener(ThreadResultEvent.RESULT, thread_resultHandler);
            _thread.addEventListener(ThreadFaultEvent.FAULT, thread_faultHandler);

            //Start a Thread in Pause, click on Start to resume it.
            _thread.pause();
            _thread.start(new TermsVo(1, 2));
        } catch (e:Error) {
            _result.text += e.message;
            _startBtn.isEnabled = false;
        }
    }


    private function onThreadState(event:ThreadStateEvent):void {
        _isNewCheck.isSelected = _thread.isNew;
        _isRunningCheck.isSelected = _thread.isRunning;
        _isPausedCheck.isSelected = _thread.isPaused;
        _isResumedCheck.isSelected = !_thread.isPaused && !_thread.isTerminated;
        _isTerminatedCheck.isSelected = _thread.isTerminated;
    }

    private function thread_resultHandler(event:ThreadResultEvent):void {
        _result.text += event.result;
        _thread.terminate();
    }

    private function thread_faultHandler(event:ThreadFaultEvent):void {
        _result.text += event.fault.message;
        _thread.terminate();
    }

    private function thread_progressHandler(event:ThreadProgressEvent):void {
    }

    private function startBtn_triggeredHandler(event:Event):void {
        _thread.resume();
    }
}
}
