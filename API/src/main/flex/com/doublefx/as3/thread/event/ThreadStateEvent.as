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
 * User: Frederic THOMAS Date: 18/06/2014 Time: 10:26
 */
package com.doublefx.as3.thread.event {
import flash.events.Event;

public class ThreadStateEvent extends Event {

    public static const THREAD_STATE:String = "threadState";

    private var _state:String;

    public function ThreadStateEvent(state:String = null, bubbles:Boolean = false, cancelable:Boolean = true) {
        super(THREAD_STATE, bubbles, cancelable);
        _state = state;
    }

    public function get state():String {
        return _state;
    }

    public function set state(value:String):void {
        _state = value;
    }


    override public function clone():Event {
        var evt:ThreadStateEvent = new ThreadStateEvent(state, this.bubbles, this.cancelable);
        return evt;
    }
}
}
