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
import com.doublefx.as3.thread.Thread;
import com.doublefx.as3.thread.Thread;
import com.doublefx.as3.thread.api.IThread;
import com.doublefx.as3.thread.namespace.thread_diagnostic;

import flash.display.LoaderInfo;
import flash.system.ApplicationDomain;

import flash.system.WorkerState;

import mx.core.FlexGlobals;

import org.flexunit.asserts.assertEquals;
import org.flexunit.asserts.assertNotNull;
import org.flexunit.asserts.assertNull;
import org.flexunit.asserts.assertTrue;
import org.hamcrest.Matcher;

use namespace thread_diagnostic;

public class ThreadTestBase {

    public static var loaderInfo:LoaderInfo;
    public static var currentDomain:ApplicationDomain;

    public function ThreadTestBase() {
        loaderInfo ||= FlexGlobals.topLevelApplication.loaderInfo;
        currentDomain ||= ApplicationDomain.currentDomain;
    }

    protected var _thread:IThread;

    [Before]
    public function setUp():void {
        _thread = new Thread();
    }


    [Test (description="The Thread should have been created")]
    public function testThreadHasBeenCreated():void {
        assertNotNull("Should not be null", _thread);
    }

    [Test (description="Verify the ID")]
    public function testId():void {
        assertTrue("Should be > 1", _thread.id > 0);
    }

    [Test (description="Verify the name of the Thread")]
    public function testName():void {
        assertNull("Should be null", _thread.name);
    }

    [Test (description="Verify the state of the Thread before the start method has been called")]
    public function testStateBeforeStart():void {
        assertNull("Should be null as no Runnable has been passed to the constructor", _thread.state);
    }

    [Test (description="Verify dependencies")]
    public function testDependenciesExistence():void {
        assertNull("Should be null" ,Thread(_thread).dependencies);
    }

    [Test (description="Verify the Runnable class name")]
    public function testRunnableClassName():void {
        assertNull("Should be null" ,Thread(_thread).runnableClassName);
    }

    [Test (description="Verify the Worker has been created")]
    public function testWorkerExistence():void {
        assertNull("Should be null" ,Thread(_thread).worker);
    }

    [Test (description="Verify the incoming message channel has been created")]
    public function testIncomingMessageChannelExistence():void {
        assertNull("Should be null" ,Thread(_thread).incomingChannel);
    }

    [Test (description="Verify the outgoing message channel has been created")]
    public function testOutgoingMessageChannelExistence():void {
        assertNull("Should be null" ,Thread(_thread).outgoingChannel);
    }

    /**
     * Shorthand hamcrest function style of the ArrayExactMatcher.
     */
    protected static function arrayExact(items:Array) : Matcher
    {
        return new ArrayExactMatcher(items);
    }

}
}
