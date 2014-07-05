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
 * User: Frederic THOMAS Date: 03/07/2014 Time: 00:11
 */
package com.doublefx.as3.thread.api {
public interface IWorker {

    /**
     * Provides a named value that is available to code running in this Thread.
     * @see flash.system.Worker.setSharedProperty
     *
     * @param key The name under which the shared property is stored.
     * @param value The value of the shared property.
     */
    function setSharedProperty(key:String, value:*):void;

    /**
     * Retrieves a value stored in this Thread with a named key.
     * @see flash.system.Worker.getSharedProperty
     *
     * @param key The name of the shared property to retrieve.
     * @return The shared property value stored with the specified key, or null if no value is stored for the specified key.
     */
    function getSharedProperty(key:String):*;
}
}
