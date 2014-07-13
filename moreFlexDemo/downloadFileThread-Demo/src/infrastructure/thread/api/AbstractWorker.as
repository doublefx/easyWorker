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

package infrastructure.thread.api {
import flash.display.Sprite;
import flash.errors.IllegalOperationError;

public class AbstractWorker extends Sprite {

    protected var workerName:String;

    public function AbstractWorker(protectedConstructor:AbstractWorker) {
        super();

        if (protectedConstructor != this)
            throw new TypeError("Error #1007: Instantiation attempted on a non-constructor.", 1007);

        initialize();
    }

    protected function initialize():void {
        throw new IllegalOperationError("Must be overrided in sub-classes");
    }
}
}