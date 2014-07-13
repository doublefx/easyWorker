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
 * User: Frederic THOMAS Date: 06/07/2014 Time: 19:13
 */
package infrastructure.thread.event {
import flash.events.Event;

[RemoteClass(alias="infrastructure.thread.event.ResumableStatusEvent")]
public class ResumableStatusEvent extends Event{

    public static const RESUMABLE_STATUS:String = "resumableStatus";
    public var isResumable:Boolean;

    public function ResumableStatusEvent(isResumable:Boolean = false) {
        super(RESUMABLE_STATUS);
        this.isResumable = isResumable;
    }
}
}
