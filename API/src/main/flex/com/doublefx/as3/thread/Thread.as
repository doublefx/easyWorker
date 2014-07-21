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
import com.doublefx.as3.thread.event.ThreadActionResponseEvent;
import com.doublefx.as3.thread.event.ThreadFaultEvent;
import com.doublefx.as3.thread.event.ThreadProgressEvent;
import com.doublefx.as3.thread.event.ThreadResultEvent;
import com.doublefx.as3.thread.event.ThreadStateEvent;
import com.doublefx.as3.thread.namespace.thread_diagnostic;
import com.doublefx.as3.thread.util.ClassAlias;
import com.doublefx.as3.thread.util.ThreadDependencyHelper;
import com.doublefx.as3.thread.util.ThreadRunner;
import com.doublefx.as3.thread.util.WorkerFactory;

import flash.display.LoaderInfo;
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.net.SharedObject;
import flash.net.registerClassAlias;
import flash.system.ApplicationDomain;
import flash.system.Capabilities;
import flash.system.MessageChannel;
import flash.system.MessageChannelState;
import flash.system.System;
import flash.system.Worker;
import flash.system.WorkerDomain;
import flash.system.WorkerState;
import flash.utils.Dictionary;
import flash.utils.getDefinitionByName;
import flash.utils.getQualifiedClassName;
import flash.utils.setTimeout;

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
public class Thread extends EventDispatcher implements IThread {

    /**
     * The Default LoaderInfo used by all new created Thread when none is provided to its constructor.
     *
     * For Flex / AIR, the default is FlexGlobals.topLevelApplication.loaderInfo
     * For Flash, there is no default, you need to provide the one containing this easyWorker library and your runnables,
     * could be stage.loaderInfo for example if everything is compiled in the same application.
     */
    public static var DEFAULT_LOADER_INFO:LoaderInfo;

    /**
     * Minimum elapse time between each chained method.
     * At time, FP/AIR is not able to compute all chained messages, giving a minimum elapse time between each chained method might help in this cases.
     */
    public static var commandInterval:uint = 0;

    private static var __internalDependencies:Vector.<String>;
    private static var __internalAliasesToRegister:Vector.<ClassAlias>;
    private static var __count:uint;

    private var _worker:Worker;
    private var _id:uint;
    private var _name:String;
    private var _runnableClassName:String;

    private var _incomingChannel:MessageChannel;
    private var _outgoingChannel:MessageChannel;

    private var _sharedProperties:Dictionary;

    private var _callLater:Array;

    private var _collectedDependencies:Vector.<String>;
    private var _collectedAliasesToRegister:Vector.<ClassAlias>;
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
        __internalDependencies = Vector.<String>([
            "com.doublefx.as3.thread.api.Runnable",
            "com.doublefx.as3.thread.util.Closure",
            "com.doublefx.as3.thread.util.DecodedMessage",
            "com.doublefx.as3.thread.event.ThreadFaultEvent",
            "com.doublefx.as3.thread.event.ThreadResultEvent",
            "com.doublefx.as3.thread.event.ThreadProgressEvent",
            "com.doublefx.as3.thread.event.ThreadActionRequestEvent",
            "com.doublefx.as3.thread.event.ThreadActionResponseEvent",
            "com.doublefx.as3.thread.error.NotImplementedRunnableError",
            "com.doublefx.as3.thread.util.ClassAlias"]);
    }

    {
        __internalAliasesToRegister = new Vector.<ClassAlias>();

        __internalAliasesToRegister[__internalAliasesToRegister.length] = new ClassAlias("Class");
        __internalAliasesToRegister[__internalAliasesToRegister.length] = new ClassAlias("RegExp");
        __internalAliasesToRegister[__internalAliasesToRegister.length] = new ClassAlias("Error");
        __internalAliasesToRegister[__internalAliasesToRegister.length] = new ClassAlias("ArgumentError");
        __internalAliasesToRegister[__internalAliasesToRegister.length] = new ClassAlias("DefinitionError");
        __internalAliasesToRegister[__internalAliasesToRegister.length] = new ClassAlias("EvalError");
        __internalAliasesToRegister[__internalAliasesToRegister.length] = new ClassAlias("RangeError");
        __internalAliasesToRegister[__internalAliasesToRegister.length] = new ClassAlias("ReferenceError");
        __internalAliasesToRegister[__internalAliasesToRegister.length] = new ClassAlias("SecurityError");
        __internalAliasesToRegister[__internalAliasesToRegister.length] = new ClassAlias("SyntaxError");
        __internalAliasesToRegister[__internalAliasesToRegister.length] = new ClassAlias("TypeError");
        __internalAliasesToRegister[__internalAliasesToRegister.length] = new ClassAlias("URIError");
        __internalAliasesToRegister[__internalAliasesToRegister.length] = new ClassAlias("VerifyError");
        __internalAliasesToRegister[__internalAliasesToRegister.length] = new ClassAlias("UninitializedError");
        __internalAliasesToRegister[__internalAliasesToRegister.length] = new ClassAlias("flash.errors.IOError");
        __internalAliasesToRegister[__internalAliasesToRegister.length] = new ClassAlias("flash.errors.EOFError");
        __internalAliasesToRegister[__internalAliasesToRegister.length] = new ClassAlias("flash.errors.MemoryError");
        __internalAliasesToRegister[__internalAliasesToRegister.length] = new ClassAlias("flash.errors.IllegalOperationError");
    }

    /**
     * Constructor.
     *
     * @param runnable A class that implements Runnable.
     * @param name The name of the Thread.
     * @param giveAppPrivileges (default = false) — indicates whether the worker should be given application sandbox privileges in AIR. This parameter is ignored in Flash Player
     * @param extraDependencies Qualified or fully qualified name of the extra dependencies that can't be automatically discovered.
     * Will automatically add all reflected dependencies.
     * Accepts wildcard at the end of the qualified name eg. <code>const aliases:Vector.<String> = Vector.<String>(["fr.kikko.lab.ShineMP3Encoder", "cmodule.shine.*"]);</code>
     * To define alias, do it using the RemoteClass tag, otherwise it will generate a TypeError: Error #1034
     * @param loaderInfo The loader info where the code of this lib and the Runnable stands, FlexGlobals.topLevelApplication.loaderInfo if none is provided.
     * @param workerDomain The Worker domain in which the Worker will be created, WorkerDomain.current if none is provided.
     */
    public function Thread(runnable:Class = null, name:String = null, giveAppPrivileges:Boolean = false, extraDependencies:Vector.<String> = null, loaderInfo:LoaderInfo = null, workerDomain:WorkerDomain = null):void {
        if (WorkerDomain.isSupported) {
            _id = ++__count;
            _name = name;

            if (runnable) {

                _sharedProperties = new Dictionary();
                registerClassAlias("com.doublefx.as3.thread.util.ClassAlias", ClassAlias);
                registerClassAlias("flash.net.SharedObject", SharedObject);

                loaderInfo ||= DEFAULT_LOADER_INFO;
                _runnableClassName = ClassUtils.getFullyQualifiedName(runnable, true);

                if (loaderInfo) {

                    if (extraDependencies)
                        extraDependencies = extractClassesFromPackages(loaderInfo.applicationDomain, extraDependencies);

                    reflect(loaderInfo.applicationDomain, extraDependencies);

                    _worker = WorkerFactory.getWorkerFromClass(loaderInfo, ThreadRunner, _collectedDependencies, Capabilities.isDebugger, giveAppPrivileges, workerDomain);
                    _worker.addEventListener(Event.WORKER_STATE, onWorkerState);
                    _worker.setSharedProperty("com.doublefx.as3.thread.name", _name);
                    _worker.setSharedProperty("com.doublefx.as3.thread.id", _id);

                    _incomingChannel = _worker.createMessageChannel(Worker.current);
                    _outgoingChannel = Worker.current.createMessageChannel(_worker);

                    _incomingChannel.addEventListener(Event.CHANNEL_MESSAGE, onMessage);

                    _worker.setSharedProperty(getQualifiedClassName(ThreadRunner) + "incoming", _outgoingChannel);
                    _worker.setSharedProperty(getQualifiedClassName(ThreadRunner) + "outgoing", _incomingChannel);

                    registerClassAliases(__internalAliasesToRegister);
                    registerClassAliases(_collectedAliasesToRegister);
                }
            }
        } else {
            throw new Error("Concurrent workers not supported by this platform");
        }
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
            if (StringUtils.isEmpty(classAlias.alias))
                classAlias.alias = ClassUtils.convertFullyQualifiedName(classAlias.fullyQualifiedName);

            aliasesToRegister[aliasesToRegister.length] = [classAlias.fullyQualifiedName, classAlias.alias];

            var cls:Class = getDefinitionByName(classAlias.fullyQualifiedName) as Class;
            registerClassAlias(classAlias.alias, cls);
        }

        if (_worker && _worker.state == WorkerState.RUNNING)
            command(_runnableClassName, ThreadRunner.REGISTER_ALIASES_METHOD, aliasesToRegister);
        else
            callLater(function ():void {
                const v:uint = commandInterval;
                commandInterval = 0;
                command(_runnableClassName, ThreadRunner.REGISTER_ALIASES_METHOD, aliasesToRegister);
                commandInterval = v;
                _workerReady = true;
            });
    }

    private static function extractClassesFromPackages(applicationDomain:ApplicationDomain, extraDependencies:Vector.<String>):Vector.<String> {
        const more:Array = [];
        for (var i:uint = 0; i < extraDependencies.length; i++) {
            const alias:String = extraDependencies[i];
            if (StringUtils.endsWith(alias, ".*")) {
                extraDependencies.splice(i--, 1);
                const packageBase:String = alias.substr(0, alias.indexOf(".*")) + "::";
                const packageBaseEx:String = alias.substr(0, alias.indexOf(".*")) + ".";
                const definitionNames:Vector.<String> = applicationDomain.getQualifiedDefinitionNames();
                for each (var definitionName:String in definitionNames) {
                    if (StringUtils.startsWith(definitionName, packageBase) || StringUtils.startsWith(definitionName, packageBaseEx)) {
                        more[more.length] = definitionName;
                    }
                }
            }
        }

        if (more.length > 0)
            for each (var definition:String in more) {
                extraDependencies[extraDependencies.length] = definition;
            }

        return extraDependencies;
    }

    private function reflect(domain:ApplicationDomain, extraDependencies:Vector.<String>):void {
        var className:String;

        const threadRunnerClassName:String = ClassUtils.getFullyQualifiedName(ThreadRunner, true);
        const threadRunnerType:Type = Type.forName(threadRunnerClassName, domain);
        _collectedDependencies = ThreadDependencyHelper.collectDependencies(threadRunnerType);

        const runnableType:Type = Type.forName(_runnableClassName, domain);
        const runnableDependencies:Vector.<String> = ThreadDependencyHelper.collectDependencies(runnableType);

        if (runnableDependencies.length > 0)
            for each (className in runnableDependencies) {
                className = ClassUtils.convertFullyQualifiedName(className);
                if (className.indexOf("com.doublefx.as3.thread.") != 0) {
                    ThreadDependencyHelper.addUniquely(className, _collectedDependencies);
                }
            }

        if (_collectedDependencies.length > 0)
            _collectedDependencies.shift();

        if (__internalDependencies && __internalDependencies.length > 0)
            for each (className in __internalDependencies) {
                ThreadDependencyHelper.addUniquely(className, _collectedDependencies);
            }

        if (extraDependencies && extraDependencies.length > 0)
            for each (className in extraDependencies) {
                if (className) {
                    try {
                        const classType:Type = Type.forName(className, domain);
                        const collectExtraDependencies:Vector.<String> = ThreadDependencyHelper.collectDependencies(classType);
                        for each (var dependencyName:String in collectExtraDependencies) {
                            dependencyName = ClassUtils.convertFullyQualifiedName(dependencyName);
                            if (dependencyName.indexOf("com.doublefx.as3.thread.") != 0) {
                                ThreadDependencyHelper.addUniquely(dependencyName, _collectedDependencies);
                            }
                        }
                    } catch (e:Error) {
                        var qualifiedName:String = ClassUtils.convertFullyQualifiedName(className);
                        ThreadDependencyHelper.addUniquely(qualifiedName, _collectedDependencies);
                    }
                }
            }

        if (!_collectedAliasesToRegister)
            _collectedAliasesToRegister = new Vector.<ClassAlias>();

        for each (className in _collectedDependencies) {
            try {
                const dependency:Type = Type.forName(className, domain);
                if (dependency) {
                    const classAlias:ClassAlias = ThreadDependencyHelper.collectAliases(dependency);
                    if (classAlias)
                        _collectedAliasesToRegister[_collectedAliasesToRegister.length] = classAlias;
                }
            } catch (e:Error) {
            }
        }
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
                setTimeout(function ():void {
                    _outgoingChannel.send(args)
                }, commandInterval);
        }
    }

    public function setSharedProperty(key:String, value:*):void {
        if (!_worker)
            _sharedProperties[key] = value;
        else if (_worker.state != WorkerState.TERMINATED)
            _worker.setSharedProperty(key, value);
    }

    public function getSharedProperty(key:String):* {
        var sharedProperty:* = null;

        if (!_worker)
            sharedProperty = _sharedProperties[key];
        else if (_worker.state != WorkerState.TERMINATED)
            sharedProperty = _worker.getSharedProperty(key);

        return sharedProperty;
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

    thread_diagnostic function get collectedDependencies():Vector.<String> {
        return _collectedDependencies;
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
                for (var key:String in _sharedProperties) {
                    _worker.setSharedProperty(key, _sharedProperties[key]);
                }
                _sharedProperties = null;
                _isNew = false;
                _isRunning = true;
                _isStarting = false;
                _currentState = ThreadState.RUNNING;
                break;
            case WorkerState.TERMINATED:
                trace("Thread onWorkerState: TERMINATED");
                _isRunning = _isPaused = false;
                _isTerminating = false;
                _isTerminated = true;
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
                    _isRunning = false;
                    _isPaused = true;
                    _isPausing = false;
                    _currentState = ThreadState.PAUSED;
                    event = new ThreadStateEvent(ThreadState.PAUSED);
                    break;
                case ThreadActionResponseEvent.RESUMED:
                    _isRunning = true;
                    _isPaused = false;
                    _isResuming = false;
                    _currentState = ThreadState.RESUMED;
                    event = new ThreadStateEvent(ThreadState.RESUMED);
                    break;
                case ThreadActionResponseEvent.TERMINATED:
                    _isRunning = false;
                    _isPaused = false;
                    _isTerminated = true;
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
        _sharedProperties = null;
        System.gc(); //Collect
        System.gc(); //Garbage
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
}
}
