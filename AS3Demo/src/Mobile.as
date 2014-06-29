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

import feathers.themes.MetalWorksMobileTheme;

import flash.display.Loader;
import flash.display.LoaderInfo;
import flash.display.Sprite;
import flash.display.StageAlign;
import flash.display.StageOrientation;
import flash.display.StageScaleMode;
import flash.events.Event;
import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;
import flash.geom.Rectangle;
import flash.system.Capabilities;
import flash.utils.ByteArray;

import starling.core.Starling;

[SWF(width="960",height="640",frameRate="60",backgroundColor="#4a4137")]
public class Mobile extends Sprite{

    public function Mobile()
    {
        if(this.stage)
        {
            this.stage.scaleMode = StageScaleMode.NO_SCALE;
            this.stage.align = StageAlign.TOP_LEFT;
        }
        this.mouseEnabled = this.mouseChildren = false;
        this.showLaunchImage();
        this.loaderInfo.addEventListener(Event.COMPLETE, loaderInfo_completeHandler);
    }

    private var _starling:Starling;
    private var _launchImage:Loader;
    private var _savedAutoOrients:Boolean;

    private function showLaunchImage():void
    {
        var filePath:String;
        var isPortraitOnly:Boolean = false;
        if(Capabilities.manufacturer.indexOf("iOS") >= 0)
        {
            if(Capabilities.screenResolutionX == 1536 && Capabilities.screenResolutionY == 2048)
            {
                var isCurrentlyPortrait:Boolean = this.stage.orientation == StageOrientation.DEFAULT || this.stage.orientation == StageOrientation.UPSIDE_DOWN;
                filePath = isCurrentlyPortrait ? "Default-Portrait@2x.png" : "Default-Landscape@2x.png";
            }
            else if(Capabilities.screenResolutionX == 768 && Capabilities.screenResolutionY == 1024)
            {
                isCurrentlyPortrait = this.stage.orientation == StageOrientation.DEFAULT || this.stage.orientation == StageOrientation.UPSIDE_DOWN;
                filePath = isCurrentlyPortrait ? "Default-Portrait.png" : "Default-Landscape.png";
            }
            else if(Capabilities.screenResolutionX == 640)
            {
                isPortraitOnly = true;
                if(Capabilities.screenResolutionY == 1136)
                {
                    filePath = "Default-568h@2x.png";
                }
                else
                {
                    filePath = "Default@2x.png";
                }
            }
            else if(Capabilities.screenResolutionX == 320)
            {
                isPortraitOnly = true;
                filePath = "Default.png";
            }
        }

        if(filePath)
        {
            var file:File = File.applicationDirectory.resolvePath(filePath);
            if(file.exists)
            {
                var bytes:ByteArray = new ByteArray();
                var stream:FileStream = new FileStream();
                stream.open(file, FileMode.READ);
                stream.readBytes(bytes, 0, stream.bytesAvailable);
                stream.close();
                this._launchImage = new Loader();
                this._launchImage.loadBytes(bytes);
                this.addChild(this._launchImage);
                this._savedAutoOrients = this.stage.autoOrients;
                this.stage.autoOrients = false;
                if(isPortraitOnly)
                {
                    this.stage.setOrientation(StageOrientation.DEFAULT);
                }
            }
        }
    }

    private function loaderInfo_completeHandler(event:Event):void
    {
        /**
         * Set the default loader to be used as sources for your worker.
         * The default loader should contain the compiled code for easyWorker and your Runnables.
         */
        Thread.DEFAULT_LOADER_INFO = event.target as LoaderInfo;

        Starling.handleLostContext = true;
        Starling.multitouchEnabled = true;
        Main.themeClass = MetalWorksMobileTheme;
        this._starling = new Starling(Main, this.stage);
        this._starling.enableErrorChecking = false;
        this._starling.start();
        if(this._launchImage)
        {
            this._starling.addEventListener("rootCreated", starling_rootCreatedHandler);
        }

        this.stage.addEventListener(Event.RESIZE, stage_resizeHandler, false, int.MAX_VALUE, true);
        this.stage.addEventListener(Event.DEACTIVATE, stage_deactivateHandler, false, 0, true);
    }

    private function starling_rootCreatedHandler(event:Object):void
    {
        if(this._launchImage)
        {
            this.removeChild(this._launchImage);
            this._launchImage.unloadAndStop(true);
            this._launchImage = null;
            this.stage.autoOrients = this._savedAutoOrients;
        }
    }

    private function stage_resizeHandler(event:Event):void
    {
        this._starling.stage.stageWidth = this.stage.stageWidth;
        this._starling.stage.stageHeight = this.stage.stageHeight;

        const viewPort:Rectangle = this._starling.viewPort;
        viewPort.width = this.stage.stageWidth;
        viewPort.height = this.stage.stageHeight;
        try
        {
            this._starling.viewPort = viewPort;
        }
        catch(error:Error) {}
    }

    private function stage_deactivateHandler(event:Event):void
    {
        this._starling.stop();
        this.stage.addEventListener(Event.ACTIVATE, stage_activateHandler, false, 0, true);
    }

    private function stage_activateHandler(event:Event):void
    {
        this.stage.removeEventListener(Event.ACTIVATE, stage_activateHandler);
        this._starling.start();
    }
}
}
