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
 * User: Frederic THOMAS Date: 20/06/2014 Time: 15:07
 */
package com.doublefx.as3.thread.util {
[ExcludeClass]
public class Closure {

    public static function create(context:Object, func:Function, ...pms):Function {

        var f:Function = function ():* {
            var target:* = arguments.callee.target;
            var func:* = arguments.callee.func;
            var params:* = arguments.callee.params;

            var len:Number = arguments.length;
            var args:Array = new Array(len);
            for (var i:Number = 0; i < len; i++)
                args[i] = arguments[i];

            args["push"].apply(args, params);
            return func.apply(target, args);
        };

        var _f:Object = f;
        _f.target = context;
        _f.func = func;
        _f.params = pms;
        return f;
    }
}
}
