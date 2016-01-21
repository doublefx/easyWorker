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
 * User: Frederic THOMAS Date: 13/06/2014 Time: 17:26
 */
package com.doublefx.as3.thread.util {
import avmplus.getQualifiedClassName;

import com.doublefx.as3.thread.api.CrossThreadDispatcher;
import com.doublefx.as3.thread.api.Runnable;
import com.doublefx.as3.thread.error.NotImplementedRunnableError;
import com.doublefx.as3.thread.event.ThreadActionRequestEvent;
import com.doublefx.as3.thread.event.ThreadActionResponseEvent;
import com.doublefx.as3.thread.event.ThreadFaultEvent;
import com.doublefx.as3.thread.event.ThreadProgressEvent;
import com.doublefx.as3.thread.event.ThreadResultEvent;

import flash.events.Event;
import flash.net.SharedObject;
import flash.net.registerClassAlias;
import flash.system.MessageChannel;
import flash.system.Worker;
import flash.utils.getDefinitionByName;

import mx.core.DebuggableWorker;

/**
 * Basically a decorator for a Runnable implementation
 * allowing it to extend something else than Sprite if needed.
 *
 * The Thread instance will pass an instance of the Runnable,
 * Its run method will be called from here passing it the optional arguments.
 *
 * This instance will be pass to the Runnable public var dispatcher:CrossThreadDispatcher
 * in order to delegate the sending of the events to the caller Thread.
 */
[ExcludeClass]
public class ThreadRunner extends DebuggableWorker implements CrossThreadDispatcher {

    private static const DISPATCHER_PROPERTY:String = "dispatcher";
    public static const REGISTER_ALIASES_METHOD:String = "registerClassAliases";
    public static const RUN_METHOD:String = "run";
    public static const PAUSE_REQUESTED:String = "pauseRequested";
    public static const RESUME_REQUESTED:String = "resumeRequested";
    public static const TERMINATE_REQUESTED:String = "terminateRequested";

    private var _runnable:Runnable;
    private var _incomingChannel:MessageChannel;
    private var _outgoingChannel:MessageChannel;
    private var _paused:Boolean;
    private var _callLater:Array;

    public function ThreadRunner():void {
        init();
    }

    private function init():void {

        if (!Worker.current.isPrimordial) {
            registerClassAlias("com.doublefx.as3.thread.util.ClassAlias", ClassAlias);
            registerClassAlias("flash.net.SharedObject", SharedObject);

            _incomingChannel = Worker.current.getSharedProperty(getQualifiedClassName(this) + "incoming") as MessageChannel;
            _outgoingChannel = Worker.current.getSharedProperty(getQualifiedClassName(this) + "outgoing") as MessageChannel;

            _incomingChannel.addEventListener(Event.CHANNEL_MESSAGE, onMessage);
        }
    }

    public function setSharedProperty(key:String, value:*):void {
        Worker.current.setSharedProperty(key, value);
    }

    public function getSharedProperty(key:String):* {
        return Worker.current.getSharedProperty(key);
    }

    protected function onMessage(e:Event):void {
        if (_incomingChannel.messageAvailable) {
            const args:Array = getMessage();
            doMessage(new DecodedMessage(args));
        }
    }

    protected function getMessage(blockUntilReceived:Boolean = false):Array {
        return _incomingChannel.receive(blockUntilReceived);
    }

    private function doMessage(decodedMessage:DecodedMessage):void {
        if (!_runnable) {
            const cls:Class = getDefinitionByName(decodedMessage.runnableClassName) as Class;
            _runnable = new cls();
            if (!(_runnable is Runnable))
                throw new NotImplementedRunnableError(decodedMessage.runnableClassName);
        }

        const method:* = decodedMessage.functionName;

        if (method == RUN_METHOD) {

            this[method].apply(null, decodedMessage.args);

        } else if (method == PAUSE_REQUESTED ||
                method == RESUME_REQUESTED ||
                method == TERMINATE_REQUESTED) {

            this[method].call(null);

        } else if (method == REGISTER_ALIASES_METHOD) {
            this[method].call(null, decodedMessage.args);
        }
    }

    /**
     * @private
     *
     * Used to store and execute later the incoming call the function passed as argument as soon the Thread is running.
     *
     * @param fct The function passed as argument as soon the Thread is running.
     */
    private function callLater(fct:Function):void {
        if (!_callLater)
            _callLater = [];

        _callLater.push(fct);
    }

    protected function run(...args):void {
        invoke(_runnable.run, args);
    }

    private function invoke(func:Function, ...args):void {
        const hasDispatcherProperty:Boolean = DISPATCHER_PROPERTY in _runnable;
        if (hasDispatcherProperty && _runnable[DISPATCHER_PROPERTY] == null) {
            _runnable[DISPATCHER_PROPERTY] = this;
        }

        try {
            trace("ThreadRunner run");
            func.apply(null, args);
        } catch (e:Error) {
            dispatchError(e);
        }
    }

    protected function pauseRequested():void {
        if (this.hasEventListener(ThreadActionRequestEvent.PAUSE_REQUESTED)) {
            addEventListener(ThreadActionResponseEvent.PAUSED, pause);
            dispatchEvent(new ThreadActionRequestEvent(ThreadActionRequestEvent.PAUSE_REQUESTED));
        }
        else {
            pause();
        }
    }

    private function pause(e:ThreadActionResponseEvent = null):void {
        _paused = true;
        removeEventListener(ThreadActionResponseEvent.PAUSED, pause);
        dispatchActionResponse(new ThreadActionResponseEvent(ThreadActionResponseEvent.PAUSED));

        while (_paused) {
            var args:Array = getMessage(true);
            const message:DecodedMessage = new DecodedMessage(args);
            if (message.functionName == RESUME_REQUESTED || message.functionName == TERMINATE_REQUESTED) {
                doMessage(message);
                if (message.functionName == RESUME_REQUESTED)
                    if (_callLater)
                        while (_callLater.length > 0) {
                            const fct:Function = _callLater.shift() as Function;
                            fct();
                        }
            } else {
                callLater(Closure.create(this, doMessage, message));
            }
        }
    }

    protected function resumeRequested():void {
        if (this.hasEventListener(ThreadActionRequestEvent.RESUME_REQUESTED)) {
            addEventListener(ThreadActionResponseEvent.RESUMED, resume);
            dispatchEvent(new ThreadActionRequestEvent(ThreadActionRequestEvent.RESUME_REQUESTED));
        } else {
            resume();
        }
    }

    private function resume(e:ThreadActionResponseEvent = null):void {
        _paused = false;
        removeEventListener(ThreadActionResponseEvent.RESUMED, resume);
        dispatchActionResponse(new ThreadActionResponseEvent(ThreadActionResponseEvent.RESUMED));
    }

    protected function terminateRequested():void {
        trace("ThreadRunner terminateRequested");
        if (this.hasEventListener(ThreadActionRequestEvent.TERMINATE_REQUESTED)) {
            addEventListener(ThreadActionResponseEvent.TERMINATED, terminate);
            dispatchEvent(new ThreadActionRequestEvent(ThreadActionRequestEvent.TERMINATE_REQUESTED));
        } else {
            terminate();
        }
    }

    private function terminate(e:ThreadActionResponseEvent = null):void {
        trace("ThreadRunner terminate");
        _paused = false;
        removeEventListener(ThreadActionResponseEvent.TERMINATED, terminate);
        dispatchActionResponse(new ThreadActionResponseEvent(ThreadActionResponseEvent.TERMINATED));
        destroyRunnable();
    }

    private function destroyRunnable():void {
        trace("ThreadRunner destroyRunnable");

        _runnable[DISPATCHER_PROPERTY] = null;
        _runnable = null;

        _incomingChannel.removeEventListener(Event.CHANNEL_MESSAGE, onMessage);
        _incomingChannel.close();
        _incomingChannel = null;

        _outgoingChannel.close();
        _outgoingChannel = null;
    }

    private function dispatchActionResponse(e:ThreadActionResponseEvent):void {
        _outgoingChannel.send(e);
    }

    /**
     * @private
     *
     *  All the classes you want to pass back and forth to the worker need to be registered for AMF serialization / de-serialization.
     *  Consider to pass the Class to the Thread's constructor if they can't be automatically detected.
     *
     *  @see flash.net.registerClassAlias
     *
     * @param Array of String, the class qualified name.
     */
    protected function registerClassAliases(aliases:Array):void {
        var item:Array;

        for each (item in aliases) {
            var classAlias:ClassAlias = new ClassAlias(item[0], item[1]);
            try {
                var cls:Class = getDefinitionByName(classAlias.fullyQualifiedName) as Class;
                registerClassAlias(classAlias.alias, cls);
            } catch (e:Error) {
                trace("ThreadRunner registerClassAliases Error: " + e.message);
            }
        }
    }

    //////////////////////////////////////
    // CrossThreadDispatcher Interface //
    //////////////////////////////////////
    public function dispatchProgress(current:uint, total:uint):void {
        _outgoingChannel.send(new ThreadProgressEvent(current, total));
    }

    public function dispatchError(error:Error):void {
        trace("ThreadRunner dispatchError: " + error.message);
        _outgoingChannel.send(new ThreadFaultEvent(error));
    }

    public function dispatchResult(result:*):void {
        //trace("ThreadRunner dispatchResult: " + result);
        _outgoingChannel.send(new ThreadResultEvent(result));
    }

    public function dispatchArbitraryEvent(event:Event):void {
        _outgoingChannel.send(event);
    }

    public function get currentThreadName():String {
        return Worker.current.getSharedProperty("com.doublefx.as3.thread.name");
    }

    public function get currentThreadId():String {
        return Worker.current.getSharedProperty("com.doublefx.as3.thread.id");
    }
}
}
