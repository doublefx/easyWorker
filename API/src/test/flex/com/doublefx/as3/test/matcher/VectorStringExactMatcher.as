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
 * User: Frederic THOMAS Date: 16/06/2014 Time: 04:17
 */
package com.doublefx.as3.test.matcher {
import org.hamcrest.BaseMatcher;
import org.hamcrest.Description;

public class VectorStringExactMatcher extends BaseMatcher {
    private var _items:Vector.<String>;

    public function VectorStringExactMatcher(items:Vector.<String>) {
        _items = items == null ? new Vector.<String>() : items;
    }

    /**
     * Matches if the specified Boolean condition evaluates to true
     */
    override public function matches(item:Object):Boolean {
        var a:Vector.<String> = item as Vector.<String>;
        if (a) {
            if (a.length != _items.length) {
                return false;
            }
            var match:Boolean = true;
            for (var i:int = 0; i < a.length; i++) {
                match = match && ( a[i] == _items[i] );
                if (!match)
                    break;
            }
            return match;
        } else {
            return false;
        }
    }

    /**
     * @inheritDoc
     */
    override public function describeTo(description:Description):void {
        description.appendText("an vector with exactly the same values. ")
                .appendValue(_items);
    }
}
}
