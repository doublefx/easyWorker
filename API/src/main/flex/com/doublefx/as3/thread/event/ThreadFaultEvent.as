/*
 * Copyright (c) Frédéric Thomas 2014.
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
 * User: Frederic THOMAS Date: 14/06/2014 Time: 15:13
 */
package com.doublefx.as3.thread.event {
import flash.events.Event;

[RemoteClass(alias="com.doublefx.as3.thread.event.ThreadFaultEvent")]
public class ThreadFaultEvent extends Event {
    public static const FAULT:String = "fault";

    private var _fault:Error;

    public function ThreadFaultEvent(fault:Error = null, bubbles:Boolean = false, cancelable:Boolean = false) {
        super(FAULT, bubbles, cancelable);
        _fault = fault;
    }

    public function get fault():Error {
        return _fault;
    }

    public override function clone():Event {
        var evt:ThreadFaultEvent = new ThreadFaultEvent(fault, this.bubbles, this.cancelable);
        return evt;
    }

    public function set fault(value:Error):void {
        _fault = value;
    }
}
}
