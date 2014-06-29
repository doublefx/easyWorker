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
 * User: Frederic THOMAS Date: 28/06/2014 Time: 17:29
 */
package {
import com.doublefx.as3.thread.Thread;

import feathers.themes.AeonDesktopTheme;

import flash.display.LoaderInfo;
import flash.display.Sprite;
import flash.display.StageAlign;
import flash.display.StageScaleMode;
import flash.events.Event;
import flash.geom.Rectangle;

import starling.core.Starling;

[SWF(width="960", height="640", frameRate="60", backgroundColor="#4a4137")]
public class Desktop extends Sprite {

    public function Desktop() {
        if (this.stage) {
            this.stage.scaleMode = StageScaleMode.NO_SCALE;
            this.stage.align = StageAlign.TOP_LEFT;
        }
        this.mouseEnabled = this.mouseChildren = false;
        this.loaderInfo.addEventListener(Event.COMPLETE, loaderInfo_completeHandler);
    }

    private var _starling:Starling;

    private function loaderInfo_completeHandler(event:Event):void {
        /**
         * Set the default loader to be used as sources for your worker.
         * The default loader should contain the compiled code for easyWorker and your Runnables.
         */
        Thread.DEFAULT_LOADER_INFO = event.target as LoaderInfo;

        Starling.handleLostContext = true;
        Starling.multitouchEnabled = true;
        Main.themeClass = AeonDesktopTheme;
        this._starling = new Starling(Main, this.stage);
        this._starling.enableErrorChecking = false;
        this._starling.start();

        this.stage.addEventListener(Event.RESIZE, stage_resizeHandler, false, int.MAX_VALUE, true);
        this.stage.addEventListener(Event.DEACTIVATE, stage_deactivateHandler, false, 0, true);
    }

    private function stage_resizeHandler(event:Event):void {
        this._starling.stage.stageWidth = this.stage.stageWidth;
        this._starling.stage.stageHeight = this.stage.stageHeight;

        const viewPort:Rectangle = this._starling.viewPort;
        viewPort.width = this.stage.stageWidth;
        viewPort.height = this.stage.stageHeight;
        try {
            this._starling.viewPort = viewPort;
        }
        catch (error:Error) {
        }
    }

    private function stage_deactivateHandler(event:Event):void {
        this._starling.stop();
        this.stage.addEventListener(Event.ACTIVATE, stage_activateHandler, false, 0, true);
    }

    private function stage_activateHandler(event:Event):void {
        this.stage.removeEventListener(Event.ACTIVATE, stage_activateHandler);
        this._starling.start();
    }
}
}
