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
 * User: Frederic THOMAS Date: 16/06/2014 Time: 01:19
 */
package com.doublefx.as3.thread {
import com.doublefx.as3.test.matcher.ArrayExactMatcher;
import com.doublefx.as3.test.matcher.VectorStringExactMatcher;
import com.doublefx.as3.thread.api.IThread;
import com.doublefx.as3.thread.namespace.thread_diagnostic;

import flash.display.LoaderInfo;

import mx.core.FlexGlobals;

import org.flexunit.asserts.assertEquals;
import org.flexunit.asserts.assertFalse;
import org.flexunit.asserts.assertNotNull;
import org.flexunit.asserts.assertNull;
import org.flexunit.asserts.assertTrue;
import org.hamcrest.Matcher;

use namespace thread_diagnostic;

public class ThreadTestBase {

    public static var loaderInfo:LoaderInfo;

    public function ThreadTestBase() {
        loaderInfo ||= FlexGlobals.topLevelApplication.loaderInfo;
    }

    protected var _thread:IThread;

    [Before]
    public function setUp():void {
        _thread = new Thread();
    }


    [After]
    public function tearDown():void {
        _thread.terminate();
    }

    [Test(description="The Thread should have been created")]
    public function testThreadHasBeenCreated():void {
        assertNotNull("Should not be null", _thread);
    }

    [Test(description="Verify the ID")]
    public function testId():void {
        assertTrue("Should be > 1", _thread.id > 0);
    }

    [Test(description="Verify the name of the Thread")]
    public function testName():void {
        assertNull("Should be null", _thread.name);
    }

    [Test(description="Verify the state of the Thread before the start method has been called")]
    public function testStateBeforeStart():void {
        testStateNew();
    }

    [Test(description="Verify dependencies")]
    public function testDependenciesExistence():void {
        assertNull("Should be null", Thread(_thread).collectedDependencies);
    }

    [Test(description="Verify the Runnable class name")]
    public function testRunnableClassName():void {
        assertNull("Should be null", Thread(_thread).runnableClassName);
    }

    [Test(description="Verify the Worker has been created")]
    public function testWorkerExistence():void {
        assertNull("Should be null", Thread(_thread).worker);
    }

    [Test(description="Verify the incoming message channel has been created")]
    public function testIncomingMessageChannelExistence():void {
        assertNull("Should be null", Thread(_thread).incomingChannel);
    }

    [Test(description="Verify the outgoing message channel has been created")]
    public function testOutgoingMessageChannelExistence():void {
        assertNull("Should be null", Thread(_thread).outgoingChannel);
    }

    protected function testStateNew():void {
        assertEquals("Should be NEW", ThreadState.NEW, _thread.state);
        assertTrue("isNew() should return true", _thread.isNew);
        assertFalse("isRunning should return false", _thread.isRunning);
        assertFalse("isPaused should return false", _thread.isPaused);
        assertFalse("isTerminated should return false", _thread.isTerminated);
    }

    protected function testStateRunning():void {
        assertEquals("Should be RUNNING", ThreadState.RUNNING, _thread.state);
        assertFalse("isNew() should return false", _thread.isNew);
        assertTrue("isRunning should return true", _thread.isRunning);
        assertFalse("isPaused should return false", _thread.isPaused);
        assertFalse("isTerminated should return false", _thread.isTerminated);
    }

    protected function testStatePaused():void {
        assertEquals("Should be PAUSED", ThreadState.PAUSED, _thread.state);
        assertFalse("isNew() should return false", _thread.isNew);
        assertFalse("isRunning should return false", _thread.isRunning);
        assertTrue("isPaused should return true", _thread.isPaused);
        assertFalse("isTerminated should return false", _thread.isTerminated);
        assertFalse(_thread.isPausing);
    }

    protected function testStateResumed():void {
        assertEquals("Should be RESUMED", ThreadState.RESUMED, _thread.state);
        assertFalse("isNew() should return false", _thread.isNew);
        assertTrue("isRunning should return true", _thread.isRunning);
        assertFalse("isPaused should return false", _thread.isPaused);
        assertFalse("isTerminated should return false", _thread.isTerminated);
        assertFalse(_thread.isResuming);
    }

    protected function testStateTerminated():void {
        assertEquals("Should be TERMINATED", ThreadState.TERMINATED, _thread.state);
        assertFalse("isNew() should return false", _thread.isNew);
        assertFalse("isRunning should return false", _thread.isRunning);
        assertFalse("isPaused should return false", _thread.isPaused);
        assertTrue("isTerminated should return true", _thread.isTerminated);
        assertFalse(_thread.isTerminating);
    }

    /**
     * Shorthand hamcrest function style of the VectorStringExactMatcher.
     */
    protected static function arrayExact(items:Vector.<String>):Matcher {
        return new VectorStringExactMatcher(items);
    }

}
}
