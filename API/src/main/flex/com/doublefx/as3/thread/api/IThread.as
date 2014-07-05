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
 * User: Frederic THOMAS Date: 15/06/2014 Time: 16:35
 */
package com.doublefx.as3.thread.api {
import flash.events.IEventDispatcher;

/**
 * All we need to play with the Thread class.
 */
[Bindable]
public interface IThread extends IWorker, IEventDispatcher{

    /**
     * Start a Thread and call the Runnable's run method.
     *
     * @param args The arguments to pass to the Runnable's run method.
     */
    function start(...args):void;

    /**
     * Terminate Thread.
     */
    function terminate():void;

    /**
     * Pause a running Thread.
     * All command send to the Thread will be delayed until resume has been called.
     *
     * @param milli Optional number of milliseconds to pause.
     */
    function pause(milli:Number = 0):void;

    /**
     * Resume a paused Thread.
     */
    function resume():void;

    /**
     * The Thread's id, should be the same than the one seen via FDB.
     */
    function get id():uint;

    /**
     * The Thread's name.
     */
    function get name():String;

    /**
     * @see com.doublefx.as3.thread.ThreadState
     */
    function get state():String;

    /**
     * Return true if the Thread is new.
     */
    function get isNew():Boolean;

    /**
     * Return true if the Thread is running.
     */
    function get isRunning():Boolean;

    /**
     * Return true if the Thread is paused.
     */
    function get isPaused():Boolean;

    /**
     * Return true if the Thread is terminated.
     */
    function get isTerminated():Boolean;

    /**
     * Because the start, pause, resume and terminate function are asynchronous,
     * return true when the relative function is call but not yet completed,
     * return false when done (not Bindable).
     */
    function get isStarting():Boolean;


    /**
     * Because the start, pause, resume and terminate function are asynchronous,
     * return true when the relative function is call but not yet completed,
     * return false when done (not Bindable).
     */
    function get isPausing():Boolean;


    /**
     * Because the start, pause, resume and terminate function are asynchronous,
     * return true when the relative function is call but not yet completed,
     * return false when done (not Bindable).
     */
    function get isResuming():Boolean;


    /**
     * Because the start, pause, resume and terminate function are asynchronous,
     * return true when the relative function is call but not yet completed,
     * return false when done (not Bindable).
     */
    function get isTerminating():Boolean;
}
}
