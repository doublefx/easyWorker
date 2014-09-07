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
 * User: Frederic THOMAS Date: 07/09/2014 Time: 17:30
 */
package com.doublefx.as3.thread.util {
import com.doublefx.as3.thread.api.IDataProducer;
import com.doublefx.as3.thread.api.IWorker;
import com.doublefx.as3.thread.api.SharableData;
import com.doublefx.as3.thread.error.IllegalStateError;

import flash.concurrent.Condition;
import flash.concurrent.Mutex;

/**
 * Allow a Thread to send data to or received data from another Thread when a common condition is met.
 * If you use it from your main Thread (application), you won't want to lock it, the reason why the send() method
 * has lock set to false by default making the data passed asynchronously, set it to true for synchronous data transfer
 * locking in the same time the caller Thread.
 */
[RemoteClass(alias="com.doublefx.as3.thread.util.AsynchronousDataManager")]
public class AsynchronousDataManager {

    public function AsynchronousDataManager(worker:IWorker, conditionName:String) {
        _worker = worker;
        _conditionName = conditionName;
    }

    private var _worker:IWorker;
    private var _conditionName:String;

    public function send(dataProducer:IDataProducer, lock:Boolean = false):Boolean {

        if (!_worker)
            throw new IllegalStateError("Can't work without a IWorker");

        var _condition:Condition = getOrShareCondition();

        if (lock)
            _condition.mutex.lock();
        else
            lock = _condition.mutex.tryLock();

        if (lock) {
            const data:SharableData = dataProducer.produceData();
            _worker.setSharedProperty(data.key, data.value);

            _condition.notify();
            _condition.mutex.unlock();
        }

        return lock;
    }

    public function receive(name:String):Object {

        if (!_worker)
            throw new IllegalStateError("Can't work without a IWorker");

        var _condition:Condition = getOrShareCondition();

        _condition.mutex.lock();
        _condition.wait();

        return _worker.getSharedProperty(name);
    }

    private function getOrShareCondition():Condition {
        var condition:Condition;

        condition = _worker.getSharedProperty(_conditionName) as Condition;
        if (!condition) {
            condition = new Condition(new Mutex());
            _worker.setSharedProperty(_conditionName, condition);
        }

        return condition;
    }
}
}
