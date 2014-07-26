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
 * User: Frederic THOMAS Date: 26/07/2014 Time: 13:57
 */
package workers {
import com.doublefx.as3.thread.api.CrossThreadDispatcher;
import com.doublefx.as3.thread.api.Runnable;

import mx.core.ByteArrayAsset;

public class WorkerWithEmbeds implements Runnable{

    [Embed(source="./assets/helloWorld.txt", mimeType="application/octet-stream")]
    protected static const HELLO_WORLD:Class;

    /**
     * Mandatory declaration if you want your Worker be able to communicate.
     * This CrossThreadDispatcher is injected at runtime.
     */
    public var dispatcher:CrossThreadDispatcher;

    public function run(args:Array):void {

        try {
            const helloWorldAsset:ByteArrayAsset = new HELLO_WORLD() as ByteArrayAsset;
            dispatcher.dispatchResult(helloWorldAsset.toString());
        } catch (err:Error) {
            dispatcher.dispatchError(err);
        }
    }
}
}
