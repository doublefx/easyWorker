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
import com.doublefx.as3.thread.util.ClassAlias;

import flash.events.IEventDispatcher;

/**
 * All we need to play with the Thread class.
 */
public interface IThread extends IEventDispatcher{

    /**
     * Call a particular function on the Runnable.
     * Should disappear, it is preferable to use Interfaces and Proxies instead.
     *
     * @param runnableClassName The Runnable class name.
     * @param runnableMethod The method to call on the Runnable.
     * @param args The arguments to pass to the workerMethod.
     */
    function command(runnableClassName:String, runnableMethod:String, ...args):void;

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
     * @see flash.system.WorkerState
     */
    function get state():String;
}
}
