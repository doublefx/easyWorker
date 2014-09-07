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
 * User: Frederic THOMAS Date: 07/09/2014 Time: 18:08
 */
package com.doublefx.as3.thread.api {

[RemoteClass(alias="com.doublefx.as3.thread.api.AsynchronousData")]
public class SharableData implements IProperty {

    private var _key:String;
    private var _value:Object;

    public function SharableData(key:String = null, value:Object = null) {
        _key = key;
        _value = value;
    }

    public function get key():String {
        return _key;
    }

    public function set key(v:String):void {
        _key = v;
    }

    public function get value():Object {
        return _value;
    }

    public function set value(v:Object):void {
        _value = v;
    }
}
}
