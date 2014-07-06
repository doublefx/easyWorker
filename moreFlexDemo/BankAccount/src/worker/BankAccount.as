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
 * User: Frederic THOMAS Date: 01/07/2014 Time: 12:46
 */
package worker {
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.utils.IDataInput;
import flash.utils.IDataOutput;
import flash.utils.IExternalizable;
import flash.utils.setTimeout;

[RemoteClass(alias="worker.BankAccount")]
public class BankAccount extends EventDispatcher implements IExternalizable{

    private var _balance:int = 200;

    public function BankAccount() {
    }

    public function get balance():int {
        return _balance;
    }

    public function withdraw(amount:int):void {
        // We simulate a remote call to do our withdraw method, this call will take between 100 and 500 ms.
        // Doing so, concurrent Threads are not guaranteed to be executed in order, so we can test our Threads
        // work as expected when sharing data using mutex.
        setTimeout(simulateRemoteWithdrawCall, Math.floor(Math.random() * (1 + 500 - 100)) + 100, amount);
    }

    private function simulateRemoteWithdrawCall(amount:int):void {
        if (amount <= balance) {
            _balance -= amount;
            trace("Account debited from " + amount + " euros");
        } else
            trace("Not enough money on the account");

        dispatchEvent(new Event("withdrawComplete"));
    }

    public function writeExternal(output:IDataOutput):void {
        output.writeInt(_balance);
    }

    public function readExternal(input:IDataInput):void {
        _balance = input.readInt();
    }
}
}
