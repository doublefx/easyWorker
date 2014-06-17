/*
 * Copyright (c) Frédéric Thomas 2014.
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
import com.doublefx.as3.thread.event.ThreadFaultEvent;
import com.doublefx.as3.thread.event.ThreadProgressEvent;
import com.doublefx.as3.thread.event.ThreadResultEvent;

import flash.events.Event;
import flash.net.registerClassAlias;
import flash.system.MessageChannel;
import flash.system.Worker;
import flash.utils.getDefinitionByName;

import mx.core.DebuggableWorker;

[Exclude]
/**
 * Basically a decorator for a Runnable implementation
 * allowing it to extend something else than Sprite if needed.
 *
 * The Thread instance will pass an instance of the Runnable,
 * Its run method will be called from here passing it the optional arguments.
 *
 * This instance will be pass to the Runnable public var dispatcher:CrossThreadDispatcher
 * in order to delegate the sending of the events to the caller Thread.
 * Note: The event is not sent as it is, it is recreated from its data in the caller Thread.
 */
public class ThreadRunner extends DebuggableWorker implements CrossThreadDispatcher {

    private static const DISPATCHER_PROPERTY:String = "dispatcher";
    public static const RUN_METHOD:String = "run";
    public static const REGISTER_ALIASES_METHOD:String = "registerClassAliases";

    private var _runnable:Runnable;
    private var _incomingChannel:MessageChannel;
    private var _outgoingChannel:MessageChannel;

    public function ThreadRunner():void {
        init();
    }

    private function init():void {

        registerClassAlias("com.doublefx.as3.thread.util.ClassAlias", ClassAlias);

        if (!Worker.current.isPrimordial) {
            _incomingChannel = Worker.current.getSharedProperty(getQualifiedClassName(this) + "incoming") as MessageChannel;
            _outgoingChannel = Worker.current.getSharedProperty(getQualifiedClassName(this) + "outgoing") as MessageChannel;

            _incomingChannel.addEventListener(Event.CHANNEL_MESSAGE, onMessage);
        }
    }

    protected function onMessage(e:Event):void {
        const args:Array = _incomingChannel.receive();

        const runnableClassName:* = args.shift();
        if (!_runnable) {
            const alias:Class = getDefinitionByName(runnableClassName) as Class;
            _runnable = new alias();
            if (!(_runnable is Runnable))
                throw new TypeError(_runnable + " must implement Runnable");
        }

        const funcName:* = args.shift();

        if (funcName == RUN_METHOD || funcName == REGISTER_ALIASES_METHOD) {
            const func:Function = this[funcName];
            func.apply(null, args);
        }
    }

    protected function run(args:Array):void {

        if (_runnable) {
            const hasDispatcherProperty:Boolean = DISPATCHER_PROPERTY in _runnable;
            if (hasDispatcherProperty && _runnable[DISPATCHER_PROPERTY] == null) {
                _runnable[DISPATCHER_PROPERTY] = this;
            }
            _runnable.run(args);
        } else
            throw new TypeError(_runnable + " must implement Runnable");
    }

    /**
     * @private
     *
     *  All the classes you want to pass back and forth to the worker need to be registered for AMF serialization / de-serialization.
     *  Consider to pass the Class to the Thread's constructor if they can't be automatically detected.
     *
     *  @see flash.net.registerClassAlias
     *
     * @param aliases A vector of ClassAliases.
     */
    public function registerClassAliases(aliases:Vector.<ClassAlias>):void {

        for each (var classAlias:ClassAlias in aliases) {
            try {
                if (!classAlias.classObject)
                    classAlias.classObject = getDefinitionByName(classAlias.alias) as Class;

                registerClassAlias(classAlias.alias, classAlias.classObject);
                //trace("ThreadRunner for " + getQualifiedClassName(_runnable) + ", is registering " + classAlias.alias + " to " + getQualifiedClassName(classAlias.classObject));
            } catch (e:Error) {
                //trace(e);
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
        _outgoingChannel.send(new ThreadFaultEvent(error));
    }

    public function dispatchResult(result:*):void {
        _outgoingChannel.send(new ThreadResultEvent(result));
    }
}
}
