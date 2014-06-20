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
 * User: Frederic THOMAS Date: 18/06/2014 Time: 16:41
 */
package com.doublefx.as3.thread {
import com.doublefx.as3.thread.event.ThreadFaultEvent;
import com.doublefx.as3.thread.event.ThreadResultEvent;
import com.doublefx.as3.thread.namespace.thread_diagnostic;

import org.flexunit.asserts.assertEquals;
import org.flexunit.async.Async;
import org.hamcrest.assertThat;

import workers.SimpleWorkerWithTwoArg;

use namespace thread_diagnostic;

public class SimpleThreadTestWithTwoArgs extends SimpleThreadTestWithOneArgs {
    public function SimpleThreadTestWithTwoArgs() {
        super();
    }

    [Before]
    override public function setUp():void {
        _thread = new Thread(SimpleWorkerWithTwoArg, "simpleRunnable", null, loaderInfo, currentDomain);
    }

    [Test(description="Verify dependencies content")]
    override public function testDependenciesContent():void {
        const dependencies:Array = ["mx.core.DebuggableWorker",
            "com.doublefx.as3.thread.api.CrossThreadDispatcher",
            "com.doublefx.as3.thread.util.ClassAlias",
            "com.doublefx.as3.thread.util.DecodedMessage",
            "com.doublefx.as3.thread.event.ThreadFaultEvent",
            "com.doublefx.as3.thread.event.ThreadResultEvent",
            "com.doublefx.as3.thread.event.ThreadProgressEvent",
            "com.doublefx.as3.thread.event.ThreadActionRequestEvent",
            "com.doublefx.as3.thread.event.ThreadActionResponseEvent",
            "com.doublefx.as3.thread.error.NotImplementedRunnableError",
            "workers.SimpleWorkerWithTwoArg",
            "com.doublefx.as3.thread.api.Runnable"];

        assertThat(Thread(_thread).dependencies.toArray(), arrayExact(dependencies));
    }

    [Test(description="Verify the Runnable class name")]
    override public function testRunnableClassName():void {
        assertEquals(Thread(_thread).runnableClassName, "workers.SimpleWorkerWithTwoArg");
    }

    [Test(async, description="Verify the Runnable 'run' method can be call with valide primitive values")]
    override public function testStartThreadWithValidValues():void {
        _thread.addEventListener(ThreadResultEvent.RESULT, Async.asyncHandler(this, thread_resultHandler, 2000, null, thread_faultHandler), false, 0, true);
        _thread.addEventListener(ThreadFaultEvent.FAULT, thread_faultHandler);
        _thread.start(1, 2);
    }

    [Test(async, description="Verify the Runnable 'run' method can be call with invalide primitive values")]
    override public function testStartThreadWithNotValidValues():void {
        _thread.addEventListener(ThreadResultEvent.RESULT, Async.asyncHandler(this, thread_resultHandlerNaN, 2000, null, thread_faultHandler), false, 0, true);
        _thread.addEventListener(ThreadFaultEvent.FAULT, thread_faultHandler);
        _thread.start("A", 2);
    }
}
}
