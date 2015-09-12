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
 * User: Frederic THOMAS Date: 16/06/2014 Time: 09:53
 */
package com.doublefx.as3.thread {
import com.doublefx.as3.thread.event.ThreadFaultEvent;
import com.doublefx.as3.thread.event.ThreadResultEvent;
import com.doublefx.as3.thread.namespace.thread_diagnostic;

import org.flexunit.asserts.assertEquals;
import org.flexunit.async.Async;
import org.hamcrest.assertThat;

import workers.*;

use namespace thread_diagnostic;

public class ThreadWithEmbedsTest extends SimpleThreadTestWithNoArgs {

    [Before]
    override public function setUp():void {
        _thread = new Thread(WorkerWithEmbeds, "workerWithEmbeds", false, null, loaderInfo);
    }

    [Test(description="Verify the name of the Thread")]
    override public function testName():void {
        assertEquals("Should be equal to 'workerWithEmbeds'", _thread.name, "workerWithEmbeds");
    }

    [Test(description="Verify dependencies")]
    override public function testDependenciesExistence():void {
        super.testDependenciesExistence();
    }

    [Test(description="Verify dependencies content")]
    override public function testDependenciesContent():void {
        const dependencies:Vector.<String> = Vector.<String>(
                "mx.core.DebuggableWorker,com.doublefx.as3.thread.api.CrossThreadDispatcher,com.doublefx.as3.thread.api.IWorker,workers.WorkerWithEmbeds,workers.WorkerWithEmbeds_HELLO_WORLD,mx.core.ByteArrayAsset,mx.core.IFlexAsset,com.doublefx.as3.thread.api.Runnable,com.doublefx.as3.thread.api.IProperty,com.doublefx.as3.thread.api.SharableData,com.doublefx.as3.thread.api.IDataProducer,com.doublefx.as3.thread.util.AsynchronousDataManager,com.doublefx.as3.thread.util.Closure,com.doublefx.as3.thread.util.DecodedMessage,com.doublefx.as3.thread.event.ThreadFaultEvent,com.doublefx.as3.thread.event.ThreadResultEvent,com.doublefx.as3.thread.event.ThreadProgressEvent,com.doublefx.as3.thread.event.ThreadActionRequestEvent,com.doublefx.as3.thread.event.ThreadActionResponseEvent,com.doublefx.as3.thread.error.NotImplementedRunnableError,com.doublefx.as3.thread.error.IllegalStateError,com.doublefx.as3.thread.error.UnsupportedOperationError,com.doublefx.as3.thread.util.ClassAlias".split(",")
        );

        assertThat(Thread(_thread).collectedDependencies, arrayExact(dependencies));
    }

    [Test(description="Verify the Runnable class name")]
    override public function testRunnableClassName():void {
        assertEquals(Thread(_thread).runnableClassName, "workers.WorkerWithEmbeds");
    }

    [Test(async, description="Verify the Runnable 'run' method can be call and return 'Hello World !!'")]
    override public function testStartThreadWithValidValues():void {
        _thread.addEventListener(ThreadResultEvent.RESULT, Async.asyncHandler(this, thread_resultHandler, 2000, null, thread_faultHandler), false, 0, true);
        _thread.addEventListener(ThreadFaultEvent.FAULT, thread_faultHandler);
        _thread.start();
    }


    override protected function thread_resultHandler(event:ThreadResultEvent, passThroughData:Object = null):void {
        testStateRunning();
        assertEquals(HelloWorldFactory.helloWorld, event.result);
    }
}
}
