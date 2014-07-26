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
 * User: Frederic THOMAS Date: 15/06/2014 Time: 14:00
 */
package com.doublefx.as3.thread.api {

import flash.events.Event;
import flash.events.IEventDispatcher;

/**
 * Use it to dispatch progress, error, result and ready for pause, resume and terminate from runnable.
 * This dispatcher is automatically injected into the Runnable if the Runnable contains this declaration:
 *
 * <code>public var dispatcher:CrossThreadDispatcher;</code>
 */
public interface CrossThreadDispatcher extends IWorker, IEventDispatcher{
    function dispatchProgress(current:uint, total:uint):void;
    function dispatchError(error:Error):void;
    function dispatchResult(result:*):void;
    function dispatchArbitraryEvent(event:Event):void;
    function get currentThreadName():String;
    function get currentThreadId():String
}
}
