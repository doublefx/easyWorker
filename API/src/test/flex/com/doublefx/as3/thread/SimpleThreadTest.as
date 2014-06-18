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
 * User: Frederic THOMAS Date: 14/06/2014 Time: 20:47
 */
package com.doublefx.as3.thread {
import com.doublefx.as3.thread.event.ThreadFaultEvent;
import com.doublefx.as3.thread.event.ThreadResultEvent;
import com.doublefx.as3.thread.namespace.thread_diagnostic;
import workers.SimpleWorker;

import flash.system.MessageChannelState;
import flash.system.WorkerState;

import org.flexunit.assertThat;
import org.flexunit.asserts.assertEquals;
import org.flexunit.asserts.assertNotNull;
import org.flexunit.asserts.assertTrue;
import org.flexunit.asserts.fail;
import org.flexunit.async.Async;

use namespace thread_diagnostic;

public class SimpleThreadTest extends ThreadTestBase {

    [Before]
    override public function setUp():void {
        _thread = new Thread(SimpleWorker, "simpleRunnable", null, loaderInfo, currentDomain);
    }

    [Test(description="Verify the name of the Thread")]
    override public function testName():void {
        assertEquals("Should be equal to 'simpleRunnable'", _thread.name, "simpleRunnable");
    }

    [Test(description="Verify the state of the Thread before the start method has been called")]
    override public function testStateBeforeStart():void {
        assertEquals("Should be 'new'", _thread.state, WorkerState.NEW);
    }

    [Test(description="Verify dependencies")]
    override public function testDependenciesExistence():void {
        assertNotNull("Should not be null", Thread(_thread).dependencies);
    }

    [Test(description="Verify dependencies content")]
    public function testDependenciesContent():void {
        const dependencies:Array = ["mx.core.DebuggableWorker",
            "com.doublefx.as3.thread.api.CrossThreadDispatcher",
            "com.doublefx.as3.thread.util.ClassAlias",
            "com.doublefx.as3.thread.event.ThreadFaultEvent",
            "com.doublefx.as3.thread.event.ThreadResultEvent",
            "com.doublefx.as3.thread.event.ThreadProgressEvent",
            "workers.SimpleWorker",
            "com.doublefx.as3.thread.api.Runnable"];

        assertThat(Thread(_thread).dependencies.toArray(), arrayExact(dependencies));
    }

    [Test(description="Verify the Runnable class name")]
    override public function testRunnableClassName():void {
        assertEquals(Thread(_thread).runnableClassName, "workers.SimpleWorker");
    }

    [Test(description="Verify the Worker has been created")]
    override public function testWorkerExistence():void {
        assertNotNull("Should Not be null", Thread(_thread).worker);
    }

    [Test(description="Verify the incoming message channel has been created")]
    override public function testIncomingMessageChannelExistence():void {
        assertNotNull("Should Not be null", Thread(_thread).incomingChannel);
    }

    [Test(description="Verify the incoming message channel state")]
    public function testIncomingMessageChannelState():void {
        assertEquals("Should be opened", Thread(_thread).incomingChannel.state, MessageChannelState.OPEN);
    }

    [Test(description="Verify the outgoing message channel has been created")]
    override public function testOutgoingMessageChannelExistence():void {
        assertNotNull("Should Not be null", Thread(_thread).outgoingChannel);
    }

    [Test(description="Verify the outgoing message channel state")]
    public function testOutgoingMessageChannelState():void {
        assertEquals("Should be opened", Thread(_thread).outgoingChannel.state, MessageChannelState.OPEN);
    }

    [Test(async, description="Verify the Runnable 'run' method can be call with valide primitive values")]
    public function testStartThreadWithValidValues():void {
        _thread.addEventListener(ThreadResultEvent.RESULT, Async.asyncHandler(this, thread_resultHandler, 2000, null, thread_faultHandler), false, 0, true);
        _thread.addEventListener(ThreadFaultEvent.FAULT, thread_faultHandler);
        _thread.start(1, 2);
    }

    protected static function thread_resultHandler(event:ThreadResultEvent, passThroughData:Object = null):void {
        assertEquals(event.result, 3);
    }

    [Test(async, description="Verify the Runnable 'run' method can be call with invalide primitive values")]
    public function testStartThreadWithNotValidValues():void {
        _thread.addEventListener(ThreadResultEvent.RESULT, Async.asyncHandler(this, thread_resultHandlerNaN, 2000, null, thread_faultHandler), false, 0, true);
        _thread.addEventListener(ThreadFaultEvent.FAULT, thread_faultHandler);
        _thread.start("A", 2);
    }

    protected static function thread_resultHandlerNaN(event:ThreadResultEvent, passThroughData:Object = null):void {
        assertTrue(isNaN(event.result));
    }

    protected static function thread_faultHandler(event:ThreadFaultEvent, passThroughData:Object = null):void {
        fail(event.fault.message);
    }
}
}
