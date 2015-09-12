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
 * User: Frederic THOMAS Date: 24/08/2014 Time: 14:51
 */
package {
import com.doublefx.as3.thread.api.CrossThreadDispatcher;
import com.doublefx.as3.thread.api.Runnable;

import flash.concurrent.Condition;
import flash.concurrent.Mutex;
import flash.utils.ByteArray;

public class CompressRunnable implements Runnable {

    public var dispatcher:CrossThreadDispatcher;

    private var _condition:Condition;
    private var _bytes:ByteArray;

    public function CompressRunnable() {
        _condition = new Condition(new Mutex());
    }

    public function run(args:Array):void {
        dispatcher.setSharedProperty("condition", _condition);

        // Endlessly loop compressing bytes that the main worker thread
        // gives us
        while (true)
        {
            // Pauses execution of the current thread until this mutex
            // is available and then takes ownership of the mutex.
            _condition.mutex.lock();

            // Wait for the bytes to be ready for compression. This releases
            // the condition's mutex and pauses this thread until the
            // main worker thread calls notify() on the condition.
            _condition.wait();

            // Get the bytes to compress
            _bytes = dispatcher.getSharedProperty("bytes");

            // Compress the bytes
            _bytes.compress();

            // Notify the main thread that the bytes have been compressed
            dispatcher.dispatchResult(true);
        }
    }
}
}
