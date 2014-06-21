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
 * User: Frederic THOMAS Date: 13/06/2014 Time: 17:18
 */
package com.doublefx.as3.thread {
import com.doublefx.as3.thread.api.IThread;
import com.doublefx.as3.thread.error.NotImplementedRunnableError;
import com.doublefx.as3.thread.event.ThreadActionRequestEvent;
import com.doublefx.as3.thread.event.ThreadActionResponseEvent;
import com.doublefx.as3.thread.event.ThreadFaultEvent;
import com.doublefx.as3.thread.event.ThreadProgressEvent;
import com.doublefx.as3.thread.event.ThreadResultEvent;
import com.doublefx.as3.thread.event.ThreadStateEvent;
import com.doublefx.as3.thread.namespace.thread_diagnostic;
import com.doublefx.as3.thread.util.ClassAlias;
import com.doublefx.as3.thread.util.Closure;
import com.doublefx.as3.thread.util.DecodedMessage;
import com.doublefx.as3.thread.util.ThreadDependencyHelper;
import com.doublefx.as3.thread.util.ThreadRunner;
import com.doublefx.as3.thread.util.WorkerFactory;

import flash.display.LoaderInfo;
import flash.errors.EOFError;
import flash.errors.IOError;
import flash.errors.IllegalOperationError;
import flash.errors.MemoryError;
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.net.registerClassAlias;
import flash.system.ApplicationDomain;
import flash.system.Capabilities;
import flash.system.MessageChannel;
import flash.system.MessageChannelState;
import flash.system.Worker;
import flash.system.WorkerDomain;
import flash.system.WorkerState;
import flash.utils.getDefinitionByName;
import flash.utils.getQualifiedClassName;
import flash.utils.setTimeout;

import mx.collections.ArrayList;
import mx.core.FlexGlobals;

import org.as3commons.lang.ClassUtils;
import org.as3commons.lang.StringUtils;
import org.as3commons.reflect.Type;

[Event(name="fault", type="com.doublefx.as3.thread.event.ThreadStateEvent")]
[Event(name="progress", type="com.doublefx.as3.thread.event.ThreadProgressEvent")]
[Event(name="result", type="com.doublefx.as3.thread.event.ThreadResultEvent")]
[Event(name="fault", type="com.doublefx.as3.thread.event.ThreadFaultEvent")]

/**
 * Create and Manage a Worker for a given Runnable.
 */
[Bindable]
public final class Thread extends EventDispatcher implements IThread {

    private static var __internalDependencies:Vector.<ClassAlias>;
    private static var __internalAliasesToRegister:Vector.<ClassAlias>;
    private static var __count:uint;

    private var _worker:Worker;
    private var _id:uint;
    private var _name:String;
    private var _runnableClassName:String;

    private var _incomingChannel:MessageChannel;
    private var _outgoingChannel:MessageChannel;

    private var _callLater:Array;

    private var _dependencies:ArrayList;
    private var _workerReady:Boolean;

    private var _isNew:Boolean = true;
    private var _isRunning:Boolean;
    private var _isPaused:Boolean;
    private var _isTerminated:Boolean;

    private var _isStarting:Boolean;
    private var _isPausing:Boolean;
    private var _isResuming:Boolean;
    private var _isTerminating:Boolean;

    private var _currentState:String = ThreadState.NEW;

    {
        __internalDependencies = new Vector.<ClassAlias>();

        __internalDependencies[__internalDependencies.length] = new ClassAlias("com.doublefx.as3.thread.util.Closure", Closure);
        __internalDependencies[__internalDependencies.length] = new ClassAlias("com.doublefx.as3.thread.util.DecodedMessage", DecodedMessage);
        __internalDependencies[__internalDependencies.length] = new ClassAlias("com.doublefx.as3.thread.event.ThreadFaultEvent", ThreadFaultEvent);
        __internalDependencies[__internalDependencies.length] = new ClassAlias("com.doublefx.as3.thread.event.ThreadResultEvent", ThreadResultEvent);
        __internalDependencies[__internalDependencies.length] = new ClassAlias("com.doublefx.as3.thread.event.ThreadProgressEvent", ThreadProgressEvent);
        __internalDependencies[__internalDependencies.length] = new ClassAlias("com.doublefx.as3.thread.event.ThreadActionRequestEvent", ThreadActionRequestEvent);
        __internalDependencies[__internalDependencies.length] = new ClassAlias("com.doublefx.as3.thread.event.ThreadActionResponseEvent", ThreadActionResponseEvent);
        __internalDependencies[__internalDependencies.length] = new ClassAlias("com.doublefx.as3.thread.error.NotImplementedRunnableError", NotImplementedRunnableError);
    }

    {
        __internalAliasesToRegister = new Vector.<ClassAlias>();

        __internalAliasesToRegister[__internalAliasesToRegister.length] = new ClassAlias("Class", Class);
        __internalAliasesToRegister[__internalAliasesToRegister.length] = new ClassAlias("RegExp", RegExp);
        __internalAliasesToRegister[__internalAliasesToRegister.length] = new ClassAlias("Error", Error);
        __internalAliasesToRegister[__internalAliasesToRegister.length] = new ClassAlias("ArgumentError", ArgumentError);
        __internalAliasesToRegister[__internalAliasesToRegister.length] = new ClassAlias("DefinitionError", DefinitionError);
        __internalAliasesToRegister[__internalAliasesToRegister.length] = new ClassAlias("EvalError", EvalError);
        __internalAliasesToRegister[__internalAliasesToRegister.length] = new ClassAlias("RangeError", RangeError);
        __internalAliasesToRegister[__internalAliasesToRegister.length] = new ClassAlias("ReferenceError", ReferenceError);
        __internalAliasesToRegister[__internalAliasesToRegister.length] = new ClassAlias("SecurityError", SecurityError);
        __internalAliasesToRegister[__internalAliasesToRegister.length] = new ClassAlias("SyntaxError", SyntaxError);
        __internalAliasesToRegister[__internalAliasesToRegister.length] = new ClassAlias("TypeError", TypeError);
        __internalAliasesToRegister[__internalAliasesToRegister.length] = new ClassAlias("URIError", URIError);
        __internalAliasesToRegister[__internalAliasesToRegister.length] = new ClassAlias("VerifyError", VerifyError);
        __internalAliasesToRegister[__internalAliasesToRegister.length] = new ClassAlias("UninitializedError", UninitializedError);
        __internalAliasesToRegister[__internalAliasesToRegister.length] = new ClassAlias("flash.errors.IOError", IOError);
        __internalAliasesToRegister[__internalAliasesToRegister.length] = new ClassAlias("flash.errors.EOFError", EOFError);
        __internalAliasesToRegister[__internalAliasesToRegister.length] = new ClassAlias("flash.errors.MemoryError", MemoryError);
        __internalAliasesToRegister[__internalAliasesToRegister.length] = new ClassAlias("flash.errors.IllegalOperationError", IllegalOperationError);

        __internalAliasesToRegister[__internalAliasesToRegister.length] = new ClassAlias("com.doublefx.as3.thread.event.ThreadFaultEvent", ThreadFaultEvent);
        __internalAliasesToRegister[__internalAliasesToRegister.length] = new ClassAlias("com.doublefx.as3.thread.event.ThreadResultEvent", ThreadResultEvent);
        __internalAliasesToRegister[__internalAliasesToRegister.length] = new ClassAlias("com.doublefx.as3.thread.event.ThreadProgressEvent", ThreadProgressEvent);
        __internalAliasesToRegister[__internalAliasesToRegister.length] = new ClassAlias("com.doublefx.as3.thread.event.ThreadActionResponseEvent", ThreadActionResponseEvent);
        __internalAliasesToRegister[__internalAliasesToRegister.length] = new ClassAlias("com.doublefx.as3.thread.error.NotImplementedRunnableError", NotImplementedRunnableError);
    }


    /**
     * Constructor.
     *
     * @param runnable A class that implements Runnable.
     * @param name The name of the Thread.
     * @param extraDependencies Some extra dependencies that can't be automatically discovered.
     * If you define a custom alias, do it using the RemoteClass tag, otherwise it will generate a TypeError: Error #1034
     * @param loaderInfo The loader info where the code of the Runnable stands.
     * @param domain The application domain on witch the Runnable is registered.
     */
    public function Thread(runnable:Class = null, name:String = null, extraDependencies:Vector.<ClassAlias> = null, loaderInfo:LoaderInfo = null, domain:ApplicationDomain = null):void {
        if (WorkerDomain.isSupported) {
            _id = ++__count;
            _name = name;

            if (runnable) {

                loaderInfo ||= FlexGlobals.topLevelApplication.loaderInfo;
                domain ||= loaderInfo.applicationDomain;
                _runnableClassName = ClassUtils.getFullyQualifiedName(runnable, true);

                if (loaderInfo && domain) {

                    extraDependencies = reflect(domain, extraDependencies);

                    _worker = WorkerFactory.getWorkerFromClass(loaderInfo.bytes, ThreadRunner, _dependencies.toArray(), Capabilities.isDebugger);
                    _worker.addEventListener(Event.WORKER_STATE, onWorkerState);

                    _incomingChannel = _worker.createMessageChannel(Worker.current);
                    _outgoingChannel = Worker.current.createMessageChannel(_worker);

                    _incomingChannel.addEventListener(Event.CHANNEL_MESSAGE, onMessage);

                    _worker.setSharedProperty(getQualifiedClassName(ThreadRunner) + "incoming", _outgoingChannel);
                    _worker.setSharedProperty(getQualifiedClassName(ThreadRunner) + "outgoing", _incomingChannel);

                    registerClassAliases(__internalAliasesToRegister);
                    registerClassAliases(extraDependencies);
                }
            }
        } else {
            throw new Error("Concurrent workers not supported by this platform");
        }
    }

    private function reflect(domain:ApplicationDomain, extraDependencies:Vector.<ClassAlias>):Vector.<ClassAlias> {
        var classAlias:ClassAlias;

        const threadRunnerClassName:String = ClassUtils.getFullyQualifiedName(ThreadRunner, true);
        const threadRunnerType:Type = Type.forName(threadRunnerClassName, domain);
        _dependencies = ThreadDependencyHelper.collectDependencies(threadRunnerType);

        const runnableType:Type = Type.forName(_runnableClassName, domain);
        const runnableDependencies:ArrayList = ThreadDependencyHelper.collectDependencies(runnableType);

        if (_dependencies.length > 0)
            _dependencies.removeItemAt(0);

        if (__internalDependencies && __internalDependencies.length > 0)
            for each (classAlias in __internalDependencies) {
                ThreadDependencyHelper.addUniquely(classAlias.alias, _dependencies);
            }

        if (runnableDependencies.length > 0)
            for each (var className:String in runnableDependencies.toArray()) {
                className = ClassUtils.convertFullyQualifiedName(className);
                ThreadDependencyHelper.addUniquely(className, _dependencies);
                if (className != _runnableClassName && className.indexOf("com.doublefx.as3.thread.") != 0) {
                    if (!extraDependencies)
                        extraDependencies = new Vector.<ClassAlias>();

                    extraDependencies[extraDependencies.length] = new ClassAlias(className, getDefinitionByName(className) as Class);
                }
            }

        if (extraDependencies && extraDependencies.length > 0)
            for each (classAlias in extraDependencies) {
                if (classAlias.classObject) {
                    const qualifiedName:String = ClassUtils.getFullyQualifiedName(classAlias.classObject, true);
                    ThreadDependencyHelper.addUniquely(qualifiedName, _dependencies);
                }
            }

        return extraDependencies;
    }

    ////////////////////////////
    // IThread Implementation //
    ////////////////////////////

    /**
     * Call a particular function on the Runnable.
     * Should disappear, it is preferable to use Interfaces and Proxies instead.
     *
     * @param runnableClassName The Runnable class name.
     * @param runnableMethod The method to call on the Runnable.
     * @param args The arguments to pass to the workerMethod.
     */
    private function command(runnableClassName:String, runnableMethod:String, ...args):void {
        if (_worker) {
            args.unshift(runnableMethod);
            args.unshift(runnableClassName);

            if (_outgoingChannel && _outgoingChannel.state == MessageChannelState.OPEN)
                _outgoingChannel.send(args);
        }
    }

    public function start(...args):void {
        if (!_isStarting && _worker && _isNew) {
            trace("Thread start");
            _isStarting = true;
            callLater(function ():void {
                command(_runnableClassName, ThreadRunner.RUN_METHOD, args);
            });
            _worker.start();
        }
    }

    public function pause(milli:Number = 0):void {
        if (!_workerReady) {
            callLater(function ():void {
                doPause(milli);
            });
        } else doPause(milli);
    }

    private function doPause(milli:Number):void {
        if (!_isPausing && _worker && _isRunning) {
            _isPausing = true;
            command(_runnableClassName, ThreadRunner.PAUSE_REQUESTED, null);
            if (milli)
                setTimeout(resume, milli);
        }
    }

    public function resume():void {
        if (!_workerReady) {
            callLater(doResume);
        } else doResume();
    }

    private function doResume():void {
        if (!_isResuming && _worker && _isPaused) {
            _isResuming = true;
            command(_runnableClassName, ThreadRunner.RESUME_REQUESTED, null);
        }
    }

    public function terminate():void {
        if (!_workerReady) {
            trace("Thread call later terminate");
            callLater(doTerminate);
        } else doTerminate();
    }

    private function doTerminate():void {
        trace("Thread terminate");
        if (!_isTerminating && _worker && !_isTerminated) {
            _isTerminating = true;
            command(_runnableClassName, ThreadRunner.TERMINATE_REQUESTED, null);
        }
    }

    public function get isStarting():Boolean {
        return _isStarting;
    }

    public function get isPausing():Boolean {
        return _isPausing;
    }

    public function get isResuming():Boolean {
        return _isResuming;
    }

    public function get isTerminating():Boolean {
        return _isTerminating;
    }

    public function get id():uint {
        return _id;
    }

    public function get name():String {
        return _name;
    }

    public function get state():String {
        return _currentState;
    }

    public function get isNew():Boolean {
        return _isNew;
    }

    public function get isRunning():Boolean {
        return _isRunning;
    }

    public function get isPaused():Boolean {
        return _isPaused;
    }

    public function get isTerminated():Boolean {
        return _isTerminated;
    }

    /////////////////////////////
    // Internal Implementation //
    /////////////////////////////
    thread_diagnostic function get worker():Worker {
        return _worker as Worker;
    }

    thread_diagnostic function get runnableClassName():String {
        return _runnableClassName;
    }

    thread_diagnostic function get dependencies():ArrayList {
        return _dependencies;
    }

    thread_diagnostic function get incomingChannel():MessageChannel {
        return _incomingChannel;
    }

    thread_diagnostic function get outgoingChannel():MessageChannel {
        return _outgoingChannel;
    }

    /////////////////////
    // Private methods //
    /////////////////////

    private function onWorkerState(e:Event):void {

        const worker:Worker = e.currentTarget as Worker;

        switch (worker.state) {
            case WorkerState.RUNNING:
                isNew = false;
                isRunning = true;
                _isStarting = false;
                _currentState = ThreadState.RUNNING;
                break;
            case WorkerState.TERMINATED:
                trace("Thread onWorkerState: TERMINATED");
                isRunning = isPaused = false;
                _isTerminating = false;
                isTerminated = true;
                destroyWorker();
                _currentState = ThreadState.TERMINATED;
                break;
            default:
                return;
        }

        const event:ThreadStateEvent = new ThreadStateEvent(_currentState);
        dispatchEvent(event);

        // Call the delayed Runnable's method calls if the worker state is running and default not prevented.
        if (_isRunning && !event.isDefaultPrevented()) {
            while (_callLater.length > 0) {
                const fct:Function = _callLater.shift() as Function;
                fct();
            }
        }
    }

    private function onMessage(e:Event):void {
        var event:Event = _incomingChannel.receive();

        if (event is ThreadActionResponseEvent) {
            const response:ThreadActionResponseEvent = event as ThreadActionResponseEvent;
            switch (response.type) {
                case ThreadActionResponseEvent.PAUSED:
                    isRunning = false;
                    isPaused = true;
                    _isPausing = false;
                    _currentState = ThreadState.PAUSED;
                    event = new ThreadStateEvent(ThreadState.PAUSED);
                    break;
                case ThreadActionResponseEvent.RESUMED:
                    isRunning = true;
                    isPaused = false;
                    _isResuming = false;
                    _currentState = ThreadState.RESUMED;
                    event = new ThreadStateEvent(ThreadState.RESUMED);
                    break;
                case ThreadActionResponseEvent.TERMINATED:
                    isRunning = false;
                    isPaused = false;
                    isTerminated = true;
                    terminateWorker();
                    break;
                default:
                    return;
            }
        }
        dispatchEvent(event);
    }

    private function terminateWorker():void {
        trace("Thread terminateWorker");
        _worker.terminate();
    }

    private function destroyWorker():void {
        trace("Thread destroyWorker");
        _worker.removeEventListener(Event.WORKER_STATE, onWorkerState);

        _incomingChannel.removeEventListener(Event.CHANNEL_MESSAGE, onMessage);
        _incomingChannel.close();
        _incomingChannel = null;

        _outgoingChannel.close();
        _outgoingChannel = null;
        _worker = null;
    }

    /**
     * @private
     *
     * Used to call the function passed as argument as soon the Thread is running.
     *
     * @param fct The function passed as argument as soon the Thread is running.
     */
    private function callLater(fct:Function):void {
        if (!_callLater)
            _callLater = [];

        _callLater[_callLater.length] = fct;
    }

    /**
     * @private
     *
     *  This method will register those aliases to the caller and callee Threads if not already registered.
     *
     *  @see flash.net.registerClassAlias
     *
     * @param aliases A vector of ClassAliases.
     */
    private function registerClassAliases(aliases:Vector.<ClassAlias>):void {

        const aliasesToRegister:Array = [];

        for each (var classAlias:ClassAlias in aliases) {
            if (StringUtils.isEmpty(classAlias.alias) && classAlias.classObject)
                classAlias.alias = ClassUtils.getFullyQualifiedName(classAlias.classObject, true);
            else if (!classAlias.classObject && !StringUtils.isEmpty(classAlias.alias))
                classAlias.classObject = getDefinitionByName(classAlias.alias) as Class;

            aliasesToRegister[aliasesToRegister.length] = classAlias.alias;

            registerClassAlias(classAlias.alias, classAlias.classObject);
        }

        var args:Array = [_runnableClassName, ThreadRunner.REGISTER_ALIASES_METHOD, aliasesToRegister];

        if (_worker && _worker.state == WorkerState.RUNNING)
            _outgoingChannel.send(args);
        else
            callLater(function ():void {
                if (_outgoingChannel && _outgoingChannel.state == MessageChannelState.OPEN) {
                    _outgoingChannel.send(args);
                    _workerReady = true;
                }
            });
    }

    ////////////////////////////////////////////////////////////////
    // Those 3 methods re-create the dispatched sub-Thread event, //
    // fill it up with de-serialized data and dispatch it.        //
    // Called from onMessage.                                     //
    ////////////////////////////////////////////////////////////////

    private function onProgress(current:uint, total:uint):void {
        const event:ThreadProgressEvent = new ThreadProgressEvent(current, total);
        dispatchEvent(event);
    }

    private function onResult(result:*):void {
        const event:ThreadResultEvent = new ThreadResultEvent(result);
        dispatchEvent(event);
    }

    private function onError(error:Error):void {
        const event:ThreadFaultEvent = new ThreadFaultEvent(error);
        dispatchEvent(event);
    }

    /**
     * Here for convenient binding, don't try to set it.
     */
    private function set isNew(value:Boolean):void {
        _isNew = value;
    }

    /**
     * Here for convenient binding, don't try to set it.
     */
    private function set isRunning(value:Boolean):void {
        _isRunning = value;
    }

    /**
     * Here for convenient binding, don't try to set it.
     */
    private function set isPaused(value:Boolean):void {
        _isPaused = value;
    }

    /**
     * Here for convenient binding, don't try to set it.
     */
    private function set isTerminated(value:Boolean):void {
        _isTerminated = value;
    }
}
}
