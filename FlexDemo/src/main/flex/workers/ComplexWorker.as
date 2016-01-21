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

package workers {
import com.doublefx.as3.thread.api.CrossThreadDispatcher;
import com.doublefx.as3.thread.api.Runnable;
import com.doublefx.as3.thread.event.ThreadActionRequestEvent;
import com.doublefx.as3.thread.event.ThreadActionResponseEvent;

import workers.vo.TermsVo;

// Don't need to extend Sprite anymore.
public class ComplexWorker implements Runnable {

    /**
     * Mandatory declaration if you want your Worker be able to communicate.
     * This CrossThreadDispatcher is injected at runtime.
     */
    private var _dispatcher:CrossThreadDispatcher;

    public function add(obj:TermsVo):Number {
        return obj.v1 + obj.v2;
    }

    // Implements Runnable interface
    public function run(args:Array):void {
        pkgLevelFunctionTest();
        topLevelFunctionTest();
        const values:TermsVo = args[0] as TermsVo;
        _dispatcher.dispatchResult(add(values));
    }

    public function get dispatcher():CrossThreadDispatcher {
        return _dispatcher;
    }

    public function set dispatcher(value:CrossThreadDispatcher):void {
        _dispatcher = value;

        if (_dispatcher) {
            _dispatcher.addEventListener(ThreadActionRequestEvent.PAUSE_REQUESTED, dispatcher_pauseRequestedHandler);
            _dispatcher.addEventListener(ThreadActionRequestEvent.RESUME_REQUESTED, dispatcher_resumeRequestedHandler);
            _dispatcher.addEventListener(ThreadActionRequestEvent.TERMINATE_REQUESTED, dispatcher_terminateRequestedHandler);
        }
    }

    // Won't be call if IThread.pause() has been called before start();
    private function dispatcher_pauseRequestedHandler(event:ThreadActionRequestEvent):void {
        trace("Pause requested, I do the eventual job to before Paused...");
        _dispatcher.dispatchEvent(new ThreadActionResponseEvent(ThreadActionResponseEvent.PAUSED));
    }

    // Won't be call if IThread.resume() has been called before start();
    private function dispatcher_resumeRequestedHandler(event:ThreadActionRequestEvent):void {
        trace("Resume requested, I do the eventual job to before Resumed...");
        _dispatcher.dispatchEvent(new ThreadActionResponseEvent(ThreadActionResponseEvent.RESUMED));
    }

    // Won't be call if IThread.terminate() has been called before start();
    private function dispatcher_terminateRequestedHandler(event:ThreadActionRequestEvent):void {
        trace("Terminate requested, I do the eventual job to before Terminated...");
        _dispatcher.dispatchEvent(new ThreadActionResponseEvent(ThreadActionResponseEvent.TERMINATED));
    }
}
}
