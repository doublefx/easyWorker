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
 * User: Frederic THOMAS Date: 01/07/2014 Time: 12:50
 */
package worker {
import com.doublefx.as3.thread.api.CrossThreadDispatcher;
import com.doublefx.as3.thread.api.Runnable;

import flash.concurrent.Mutex;
import flash.events.Event;
import flash.utils.ByteArray;

public class WithdrawMoney implements Runnable {

    private var _sharedAccount:ByteArray;
    private var _mutex:Mutex;

    /**
     * Public to make it automatically reflected, otherwise,
     * use the extraDependency argument of the Thread's constructor.
     */
    public var bankAccount:BankAccount;

    /**
     * Mandatory declaration if you want your Worker be able to communicate.
     * This CrossThreadDispatcher is injected at runtime.
     */
    public var dispatcher:CrossThreadDispatcher;

    public function run(args:Array):void {
        _mutex = dispatcher.getSharedProperty("mutex") as Mutex;

        // Pause the code here until the mutex is available.
        _mutex.lock();

        _sharedAccount = dispatcher.getSharedProperty("sharedAccount");
        bankAccount = _sharedAccount.readObject() as BankAccount;
        const amount:int = args[0];

        dispatcher.dispatchResult(dispatcher.currentThreadName + " is trying to withdraw " + amount);

        bankAccount.addEventListener("withdrawComplete", bankAccount_withdrawCompleteHandler);
        bankAccount.withdraw(amount);
    }

    private function bankAccount_withdrawCompleteHandler(event:Event):void {
        _sharedAccount.clear();
        _sharedAccount.writeObject(bankAccount);

        dispatcher.dispatchResult("There is " + bankAccount.balance + " euros on the account");

        // We're done with the computation, unlock the Mutex.
        _mutex.unlock();
    }
}
}
