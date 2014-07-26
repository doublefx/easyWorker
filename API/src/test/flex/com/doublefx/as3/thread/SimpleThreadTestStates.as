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
 * User: Frederic THOMAS Date: 18/06/2014 Time: 23:50
 */
package com.doublefx.as3.thread {
import com.doublefx.as3.thread.event.ThreadFaultEvent;
import com.doublefx.as3.thread.event.ThreadResultEvent;
import com.doublefx.as3.thread.event.ThreadStateEvent;

import flash.events.IEventDispatcher;

import org.flexunit.asserts.assertFalse;
import org.flexunit.asserts.assertTrue;
import org.flexunit.async.Async;
import org.fluint.sequence.SequenceCaller;
import org.fluint.sequence.SequenceRunner;
import org.fluint.sequence.SequenceWaiter;

public class SimpleThreadTestStates extends SimpleThreadTestWithNoArgs {
    public function SimpleThreadTestStates() {
        super();
    }

    /**
     * It will start the Thread in Pause.
     */
    [Test(async, expects="Error", description="Verify the pause can be called before start")]
    public function testPauseBeforeStart():void {
        testStateNew();

        _thread.pause();
        assertFalse(_thread.isPausing);

        _thread.addEventListener(ThreadResultEvent.RESULT, Async.asyncHandler(this, thread_resultHandler, 2000, null, thread_faultHandler), false, 0, true);
        _thread.addEventListener(ThreadFaultEvent.FAULT, thread_faultHandler);
        _thread.start();
    }

    [Test(async, description="Verify the Thread State sequence New->Running")]
    public function testNewToRunning():void {
        testStateNew();

        const runner:SequenceRunner = new SequenceRunner(this);

        runner.addStep(new SequenceCaller(_thread, _thread.start));
        runner.addStep(new SequenceWaiter(_thread, ThreadStateEvent.THREAD_STATE, 500));
        runner.addAssertHandler(thread_stateRunning, null);

        runner.run();
    }

    [Test(async, description="Verify the Thread State sequence New->Running->Terminated")]
    public function testNewToRunningToTerminate():void {
        testStateNew();

        const runner:SequenceRunner = new SequenceRunner(this);

        runner.addStep(new SequenceCaller(_thread, _thread.start));
        runner.addStep(new SequenceWaiter(_thread, ThreadStateEvent.THREAD_STATE, 500));
        runner.addStep(new SequenceCaller(_thread, _thread.terminate));
        runner.addStep(new SequenceWaiter(_thread, ThreadStateEvent.THREAD_STATE, 500));
        runner.addAssertHandler(thread_stateTerminate, null);

        runner.run();
    }

    [Test(async, description="Verify the Thread State sequence New->Running->Terminated->Terminated")]
    public function testNewToRunningToTerminateToTerminate():void {
        testStateNew();

        const runner:SequenceRunner = new SequenceRunner(this);

        runner.addStep(new SequenceCaller(_thread, _thread.start));
        runner.addStep(new SequenceWaiter(_thread, ThreadStateEvent.THREAD_STATE, 500));
        runner.addStep(new SequenceCaller(_thread, _thread.terminate));
        runner.addStep(new SequenceWaiter(_thread, ThreadStateEvent.THREAD_STATE, 500));
        runner.addStep(new SequenceCaller(_thread, _thread.terminate));
        runner.addAssertHandler(thread_stateTerminate, null);

        runner.run();
    }

    [Test(async, expects="Error", description="Verify the Thread don't dispatch ThreadStateEvent.THREAD_STATE event on sequence New->Running->Terminated->Terminated")]
    public function testNewToRunningToTerminateToTerminateStateEvent():void {
        testStateNew();

        const runner:SequenceRunner = new SequenceRunner(this);

        runner.addStep(new SequenceCaller(_thread, _thread.start));
        runner.addStep(new SequenceWaiter(_thread, ThreadStateEvent.THREAD_STATE, 500));
        runner.addStep(new SequenceCaller(_thread, _thread.terminate));
        runner.addStep(new SequenceWaiter(_thread, ThreadStateEvent.THREAD_STATE, 500));
        runner.addStep(new SequenceCaller(_thread, _thread.terminate));
        runner.addStep(new SequenceWaiter(_thread, ThreadStateEvent.THREAD_STATE, 500));
        runner.addAssertHandler(thread_stateTerminate, null);

        runner.run();
    }

    [Test(async, description="Verify the Thread State sequence New->Running->Pause")]
    public function testNewToRunningToPause():void {
        testStateNew();

        const runner:SequenceRunner = new SequenceRunner(this);

        runner.addStep(new SequenceCaller(_thread, _thread.start));
        runner.addStep(new SequenceWaiter(_thread, ThreadStateEvent.THREAD_STATE, 500));
        runner.addStep(new SequenceCaller(_thread, _thread.pause));
        runner.addStep(new SequenceWaiter(_thread, ThreadStateEvent.THREAD_STATE, 500));
        runner.addAssertHandler(thread_statePause, null);

        runner.run();
    }

    [Test(async, description="Verify the Thread State sequence New->Running->Pause->Pause")]
    public function testNewToRunningToPauseToPause():void {
        testStateNew();

        const runner:SequenceRunner = new SequenceRunner(this);

        runner.addStep(new SequenceCaller(_thread, _thread.start));
        runner.addStep(new SequenceWaiter(_thread, ThreadStateEvent.THREAD_STATE, 500));
        runner.addStep(new SequenceCaller(_thread, _thread.pause));
        runner.addStep(new SequenceWaiter(_thread, ThreadStateEvent.THREAD_STATE, 500));
        runner.addStep(new SequenceCaller(_thread, _thread.pause));
        runner.addAssertHandler(thread_statePause, null);

        runner.run();
    }

    [Test(async, expects="Error", description="Verify the Thread don't dispatch ThreadStateEvent.THREAD_STATE event on sequence New->Running->Pause->Pause")]
    public function testNewToRunningToPauseToPauseStateEvent():void {
        testStateNew();

        const runner:SequenceRunner = new SequenceRunner(this);

        runner.addStep(new SequenceCaller(_thread, _thread.start));
        runner.addStep(new SequenceWaiter(_thread, ThreadStateEvent.THREAD_STATE, 500));
        runner.addStep(new SequenceCaller(_thread, _thread.pause));
        runner.addStep(new SequenceWaiter(_thread, ThreadStateEvent.THREAD_STATE, 500));
        runner.addStep(new SequenceCaller(_thread, _thread.pause));
        runner.addStep(new SequenceWaiter(_thread, ThreadStateEvent.THREAD_STATE, 500));
        runner.addAssertHandler(thread_statePause, null);

        runner.run();
    }

    [Test(async, description="Verify the Thread State sequence New->Running->Pause->Resume")]
    public function testNewToRunningToPauseToResume():void {
        testStateNew();

        const runner:SequenceRunner = new SequenceRunner(this);

        runner.addStep(new SequenceCaller(_thread, _thread.start));
        runner.addStep(new SequenceWaiter(_thread, ThreadStateEvent.THREAD_STATE, 500));
        runner.addStep(new SequenceCaller(_thread, _thread.pause));
        runner.addStep(new SequenceWaiter(_thread, ThreadStateEvent.THREAD_STATE, 500));
        runner.addStep(new SequenceCaller(_thread, _thread.resume));
        runner.addStep(new SequenceWaiter(_thread, ThreadStateEvent.THREAD_STATE, 500));
        runner.addAssertHandler(thread_stateResume, null);

        runner.run();
    }

    [Test(async, description="Verify the Thread State sequence New->Running->Pause->Resume->Resume")]
    public function testNewToRunningToPauseToResumeToResume():void {
        testStateNew();

        const runner:SequenceRunner = new SequenceRunner(this);

        runner.addStep(new SequenceCaller(_thread, _thread.start));
        runner.addStep(new SequenceWaiter(_thread, ThreadStateEvent.THREAD_STATE, 500));
        runner.addStep(new SequenceCaller(_thread, _thread.pause));
        runner.addStep(new SequenceWaiter(_thread, ThreadStateEvent.THREAD_STATE, 500));
        runner.addStep(new SequenceCaller(_thread, _thread.resume));
        runner.addStep(new SequenceWaiter(_thread, ThreadStateEvent.THREAD_STATE, 500));
        runner.addStep(new SequenceCaller(_thread, _thread.resume));
        runner.addAssertHandler(thread_stateResume, null);

        runner.run();
    }

    [Test(async, expects="Error", description="Verify the Thread don't dispatch ThreadStateEvent.THREAD_STATE event on sequence New->Running->Pause->Resume->Resume")]
    public function testNewToRunningToPauseToResumeToResumeStateEvent():void {
        testStateNew();

        const runner:SequenceRunner = new SequenceRunner(this);

        runner.addStep(new SequenceCaller(_thread, _thread.start));
        runner.addStep(new SequenceWaiter(_thread, ThreadStateEvent.THREAD_STATE, 500));
        runner.addStep(new SequenceCaller(_thread, _thread.pause));
        runner.addStep(new SequenceWaiter(_thread, ThreadStateEvent.THREAD_STATE, 500));
        runner.addStep(new SequenceCaller(_thread, _thread.resume));
        runner.addStep(new SequenceWaiter(_thread, ThreadStateEvent.THREAD_STATE, 500));
        runner.addStep(new SequenceCaller(_thread, _thread.resume));
        runner.addStep(new SequenceWaiter(_thread, ThreadStateEvent.THREAD_STATE, 500));
        runner.addAssertHandler(thread_stateResume, null);

        runner.run();
    }

    [Test(async, description="Verify the Thread State sequence New->Running->Pause->Resume->Terminate")]
    public function testNewToRunningToPauseToResumeToTerminate():void {
        testStateNew();

        const runner:SequenceRunner = new SequenceRunner(this);

        runner.addStep(new SequenceCaller(_thread, _thread.start));
        runner.addStep(new SequenceWaiter(_thread, ThreadStateEvent.THREAD_STATE, 500));
        runner.addStep(new SequenceCaller(_thread, _thread.pause));
        runner.addStep(new SequenceWaiter(_thread, ThreadStateEvent.THREAD_STATE, 500));
        runner.addStep(new SequenceCaller(_thread, _thread.resume));
        runner.addStep(new SequenceWaiter(_thread, ThreadStateEvent.THREAD_STATE, 500));
        runner.addStep(new SequenceCaller(_thread, _thread.terminate));
        runner.addStep(new SequenceWaiter(_thread, ThreadStateEvent.THREAD_STATE, 500));
        runner.addAssertHandler(thread_stateTerminate, null);

        runner.run();
    }

    private function createStateSequenceRunner(target:IEventDispatcher, method:Function, assertHandler:Function, timeout:int = 500, args:Array = null, argsFunction:Function = null):SequenceRunner {
        const runner:SequenceRunner = new SequenceRunner(this);

        runner.addStep(new SequenceCaller(target, method, args, argsFunction));
        runner.addStep(new SequenceWaiter(target, ThreadStateEvent.THREAD_STATE, timeout));
        runner.addAssertHandler(assertHandler, null);

        return runner;
    }

    private function thread_stateRunning(e:ThreadStateEvent, passThroughData:Object = null):void {
        testStateRunning();
    }

    private function thread_statePause(e:ThreadStateEvent, passThroughData:Object = null):void {
        testStatePaused();
    }

    private function thread_statePausing(e:ThreadStateEvent, passThroughData:Object = null):void {
        assertTrue(_thread.isPausing);
    }

    private function thread_stateResume(e:ThreadStateEvent, passThroughData:Object = null):void {
        testStateResumed();
    }

    private function thread_stateResuming(e:ThreadStateEvent, passThroughData:Object = null):void {
        assertTrue(_thread.isResuming);
    }

    private function thread_stateTerminate(e:ThreadStateEvent, passThroughData:Object = null):void {
        testStateTerminated();
    }

    private function thread_stateTerminating(e:ThreadStateEvent, passThroughData:Object = null):void {
        assertTrue(_thread.isTerminating);
    }

}
}
