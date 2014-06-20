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

[RemoteClass(alias="com.doublefx.as3.thread.event.ThreadActionRequestEvent")]
public class ThreadActionRequestEvent extends Event {

    /**
     * The Thread has requested a Pause.
     * Won't be catch if pause() has been called before Start()
     */
    public static const PAUSE_REQUESTED:String = "pauseRequested";

    /**
     * The Thread has requested a Resume.
     * Won't be catch if resume() has been called before Start()
     */
    public static const RESUME_REQUESTED:String = "resumeRequested";

    /**
     * The Thread has requested a Terminate.
     * Won't be catch if terminate() has been called before Start()
     */
    public static const TERMINATE_REQUESTED:String = "terminateRequested";

    public function ThreadActionRequestEvent(type:String = null) {
        super(type);
    }
}
}
