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

package {
import com.doublefx.as3.thread.api.CrossThreadDispatcher;
import com.doublefx.as3.thread.api.Runnable;

import flash.events.Event;
import flash.events.ProgressEvent;
import flash.utils.ByteArray;

import fr.kikko.lab.ShineMP3Encoder;

public class BackWorker implements Runnable {
    private var mp3Encoder:ShineMP3Encoder;

    public var dispatcher:CrossThreadDispatcher;


    public function run(args:Array):void {
        const fileToEncode:ByteArray = args[0] as ByteArray;
        encode(fileToEncode);
    }

    protected function encode(fileToEncode:ByteArray):void {
        if (mp3Encoder == null) {
            mp3Encoder = new ShineMP3Encoder(fileToEncode);
            mp3Encoder.addEventListener(Event.COMPLETE, encodeComplete);
            mp3Encoder.addEventListener(ProgressEvent.PROGRESS, onProgress);
            mp3Encoder.start();
        }
    }

    protected function onProgress(event:ProgressEvent):void {
        dispatcher.dispatchProgress(event.bytesLoaded, event.bytesTotal);
    }

    protected function encodeComplete(event:Event):void {
        dispatcher.dispatchResult(mp3Encoder.mp3Data);
    }
}
}