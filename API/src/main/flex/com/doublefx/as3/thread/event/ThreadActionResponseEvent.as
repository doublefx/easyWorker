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

[RemoteClass(alias="com.doublefx.as3.thread.event.ThreadActionResponseEvent")]
public class ThreadActionResponseEvent extends Event {

    // Here to allow serialization.
    private static const NULL:String = "NULL";

    /**
     * Dispatch thru the CrossThreadDispatcher to indicate the runnable is ready for a Pause.
     */
    public static const PAUSED:String = "paused";

    /**
     * Dispatch thru the CrossThreadDispatcher to indicate the runnable is ready for a Resume.
     */
    public static const RESUMED:String = "resumed";

    /**
     * Dispatch thru the CrossThreadDispatcher to indicate the runnable is ready for a Terminate.
     */
    public static const TERMINATED:String = "terminated";

    private var _type:String;

    public function ThreadActionResponseEvent(type:String = NULL) {
        super(type);
    }

    override public function get type():String {
        return super.type == NULL ? _type : super.type;
    }

    public function set type(type:String):void {
        _type = type;
    }
}
}
