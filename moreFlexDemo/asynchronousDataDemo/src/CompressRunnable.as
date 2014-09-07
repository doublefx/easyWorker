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
import com.doublefx.as3.thread.util.AsynchronousDataManager;

import flash.utils.ByteArray;

public class CompressRunnable implements Runnable {

    public var dispatcher:CrossThreadDispatcher;

    public function run(args:Array):void {
        const asynchronousDataManager:AsynchronousDataManager = new AsynchronousDataManager(dispatcher, "whenDataReady");

        // Endless loop to compress data as long as it has been sent.
        // In real life, you may want a way to stop it cleanly, to do so, you can add an
        // event listener to the dispatcher on ThreadActionRequestEvent.TERMINATE_REQUESTED;
        while (true)
            compress(asynchronousDataManager.receive("bytes") as ByteArray);
    }

    private function compress(byte:ByteArray):void {

        // Compress the bytes
        byte.compress();

        // Notify the main thread that the bytes have been compressed
        dispatcher.dispatchResult(true);
    }
}
}
