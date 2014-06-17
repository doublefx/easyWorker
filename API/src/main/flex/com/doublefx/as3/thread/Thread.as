/**
 * User: Frederic THOMAS Date: 13/06/2014 Time: 17:18
 */
package com.doublefx.as3.thread {
import com.doublefx.as3.thread.api.IThread;
import com.doublefx.as3.thread.event.ThreadFaultEvent;
import com.doublefx.as3.thread.event.ThreadProgressEvent;
import com.doublefx.as3.thread.event.ThreadResultEvent;
import com.doublefx.as3.thread.namespace.thread_diagnostic;
import com.doublefx.as3.thread.util.ClassAlias;
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
import flash.system.Worker;
import flash.system.WorkerDomain;
import flash.system.WorkerState;
import flash.utils.getDefinitionByName;
import flash.utils.getQualifiedClassName;
import flash.utils.setTimeout;

import mx.collections.ArrayList;
import mx.core.FlexGlobals;

import org.as3commons.bytecode.reflect.ByteCodeType;
import org.as3commons.lang.ClassUtils;
import org.as3commons.lang.StringUtils;

[Event(name="progress", type="com.doublefx.as3.thread.event.ThreadProgressEvent")]
[Event(name="result", type="com.doublefx.as3.thread.event.ThreadResultEvent")]
[Event(name="fault", type="com.doublefx.as3.thread.event.ThreadFaultEvent")]

/**
 * Create and Manage a Worker for a given Runnable.
 */
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


    /**
     * Constructor.
     *
     * @param runnable A class that implements Runnable.
     * @param name The name of the Thread.
     * @param extraDependencies Some extra dependencies (class names) that can't be automatically discovered.
     * @param loaderInfo The loader info where the code of the Runnable stands.
     * @param domain The application domain on witch the Runnable is registered.
     */
    public function Thread(runnable:Class = null, name:String = null, extraDependencies:Vector.<ClassAlias> = null, loaderInfo:LoaderInfo = null, domain:ApplicationDomain = null):void {
        if (WorkerDomain.isSupported) {
            _id = ++__count;
            _name = name;

            registerClassAlias("com.doublefx.as3.thread.util.ClassAlias", ClassAlias);

            var classAlias:ClassAlias;

            if (runnable) {
                loaderInfo ||= FlexGlobals.topLevelApplication.loaderInfo;
                domain ||= ApplicationDomain.currentDomain;
                _runnableClassName = ClassUtils.getFullyQualifiedName(runnable);

                if (loaderInfo && domain) {
                    ByteCodeType.fromLoader(loaderInfo, domain);

                    const workerDecoratorClassName:String = getQualifiedClassName(ThreadRunner);
                    const byteCodeTypeWorkerDecorator:ByteCodeType = ByteCodeType.forName(workerDecoratorClassName, domain);
                    _dependencies = ThreadDependencyHelper.collectDependencies(byteCodeTypeWorkerDecorator);

                    const byteCodeTypeRunnable:ByteCodeType = ByteCodeType.forName(_runnableClassName, domain);
                    const runnableDependencies:ArrayList = ThreadDependencyHelper.collectDependencies(byteCodeTypeRunnable);

                    fillInternalDependencies();
                    fillInternalAliasesToRegister();

                    if (_dependencies.length > 0)
                        _dependencies.removeItemAt(0);

                    if (__internalDependencies && __internalDependencies.length > 0)
                        for each (classAlias in __internalDependencies) {
                            ThreadDependencyHelper.addUniquely(classAlias.alias, _dependencies);
                        }

                    if (runnableDependencies.length > 0)
                        for each (var className:String in runnableDependencies.toArray()) {
                            ThreadDependencyHelper.addUniquely(className, _dependencies);
                            if (className != ClassUtils.convertFullyQualifiedName(_runnableClassName) && className.indexOf("com.doublefx.as3.thread.") != 0) {
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

    ////////////////////////////
    // IThread Implementation //
    ////////////////////////////

    public function command(runnableClassName:String, runnableMethod:String, ...args):void {
        args.unshift(runnableMethod);
        args.unshift(runnableClassName);
        _outgoingChannel.send(args);
    }

    public function start(...args):void {
        if (_worker) {
            callLater(function ():void {
                command(_runnableClassName, ThreadRunner.RUN_METHOD, args);
            });
            _worker.start();
        }
    }

    public function terminate():void {
        // Not correctly implemented yet
        _worker.terminate();
    }

    public function pause(milli:Number = 0):void {
        notImplementedYet()
    }

    public function resume():void {
        notImplementedYet();
    }

    public function get id():uint {
        return _id;
    }

    public function get name():String {
        return _name;
    }

    public function get state():String {
        return _worker ? _worker.state : null;
    }

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
        const event:Event = new Event(e.type, e.bubbles, e.cancelable);
        dispatchEvent(event);

        // Call the delayed Runnable's method calls if the worker state is running and default not prevented.
        if (_worker.state == WorkerState.RUNNING && !event.isDefaultPrevented()) {
            while (_callLater.length > 0) {
                const fct:Function = _callLater.shift() as Function;
                setTimeout(fct, 200);
            }
        }
    }

    private function onMessage(e:Event):void {
        const event:Event = _incomingChannel.receive();
        dispatchEvent(event);
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

        for each (var classAlias:ClassAlias in aliases) {
            if (StringUtils.isEmpty(classAlias.alias) && classAlias.classObject)
                classAlias.alias = ClassUtils.getFullyQualifiedName(classAlias.classObject, true);
            else if (!classAlias.classObject && !StringUtils.isEmpty(classAlias.alias))
                classAlias.classObject = getDefinitionByName(classAlias.alias) as Class;

            registerClassAlias(classAlias.alias, classAlias.classObject);
        }

        var args:Array = [_runnableClassName, ThreadRunner.REGISTER_ALIASES_METHOD, aliases];

        if (_worker.state == WorkerState.RUNNING)
            _outgoingChannel.send(args);
        else
            callLater(function ():void {
                _outgoingChannel.send(args)
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

    private static function fillInternalDependencies():void {
        if (!__internalDependencies) {
            __internalDependencies = new Vector.<ClassAlias>();

            __internalDependencies[__internalDependencies.length] = new ClassAlias("com.doublefx.as3.thread.util.ClassAlias", ClassAlias);
            __internalDependencies[__internalDependencies.length] = new ClassAlias("com.doublefx.as3.thread.event.ThreadFaultEvent", ThreadFaultEvent);
            __internalDependencies[__internalDependencies.length] = new ClassAlias("com.doublefx.as3.thread.event.ThreadResultEvent", ThreadResultEvent);
            __internalDependencies[__internalDependencies.length] = new ClassAlias("com.doublefx.as3.thread.event.ThreadProgressEvent", ThreadProgressEvent);
        }
    }

    private static function fillInternalAliasesToRegister():void {
        if (!__internalAliasesToRegister) {
            __internalAliasesToRegister = new Vector.<ClassAlias>();

            __internalAliasesToRegister[__internalAliasesToRegister.length] = new ClassAlias("Class", Class);
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
        }
    }

    private static function notImplementedYet():void {
        throw new Error("Not implemented yet !!");
    }
}
}
