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

package com.doublefx.as3.thread.util {
import com.codeazur.as3swf.SWF;
import com.codeazur.as3swf.data.SWFSymbol;
import com.codeazur.as3swf.tags.ITag;
import com.codeazur.as3swf.tags.TagDoABC;
import com.codeazur.as3swf.tags.TagEnableDebugger2;
import com.codeazur.as3swf.tags.TagEnd;
import com.codeazur.as3swf.tags.TagFileAttributes;
import com.codeazur.as3swf.tags.TagFrameLabel;
import com.codeazur.as3swf.tags.TagMetadata;
import com.codeazur.as3swf.tags.TagProductInfo;
import com.codeazur.as3swf.tags.TagScriptLimits;
import com.codeazur.as3swf.tags.TagSetBackgroundColor;
import com.codeazur.as3swf.tags.TagShowFrame;
import com.codeazur.as3swf.tags.TagSymbolClass;

import flash.net.FileReference;

import flash.system.Worker;
import flash.system.WorkerDomain;
import flash.utils.ByteArray;
import flash.utils.getQualifiedClassName;

[Exclude]
public class WorkerFactory {

    /**
     * Creates a Worker from a Class.
     * @param clazz the Class to create a Worker from
     * @param bytes SWF ByteArray which must contain the Class definition (usually loaderInfo.bytes)
     * @param dependencies The clazz dependencies
     * @param debug set to tru if you want to debug the Worker
     * @param giveAppPrivileges (default = false) — indicates whether the worker should be given application sandbox privileges in AIR. This parameter is ignored in Flash Player
     * @param domain the WorkerDomain to create the Worker in
     * @return the new Worker
     */
    public static function getWorkerFromClass(bytes:ByteArray, clazz:Class, dependencies:Array, debug:Boolean = true, giveAppPrivileges:Boolean = false, domain:WorkerDomain = null):Worker {
        var swf:SWF = new SWF(bytes);
        var version:Number = swf.version;
        var compression:Boolean = swf.compressed;
        var tags:Vector.<ITag> = swf.tags;
        var className:String = getQualifiedClassName(clazz).replace(/::/g, ".");
        var abcName:String = className.replace(/\./g, "/");

        var classTag:ITag;
        var metaTag:ITag;
        var bgColorTag:ITag;
        var debugTag:ITag;
        var abcTags:Vector.<ITag> = new Vector.<ITag>();
        var scriptLimitTag:ITag;
        var productInfo:ITag;
        var frameLabel:ITag;

        for each (var tag:ITag in tags) {
            if (tag is TagSymbolClass) {
                for each (var symbol:SWFSymbol in TagSymbolClass(tag).symbols) {
                    if (symbol.tagId == 0) {
                        symbol.name = className;
                        classTag = tag;
                        break;
                    }
                }
            }
            else if (tag is TagEnableDebugger2) {
                debugTag = tag;
            }
            else if (tag is TagDoABC) {
                const tagDoABC:TagDoABC = TagDoABC(tag);
                if (tagDoABC.abcName == abcName)
                    abcTags.push(tag);
                else if (dependencies != null) {
                    for each (var depAbcName:String in dependencies) {
                        if (tagDoABC.abcName == depAbcName.replace(/\./g, "/")) {
                            abcTags.push(tag);
                            //trace("Dep: " + depAbcName);
                            break;
                        }
                    }
                }
            } else if (tag is TagSetBackgroundColor) {
                bgColorTag = tag;
            } else if (tag is TagMetadata) {
                metaTag = tag;
            } else if (tag is TagScriptLimits) {
                scriptLimitTag = tag;
            } else if (tag is TagProductInfo) {
                productInfo = tag;
            } else if (tag is TagFrameLabel) {
                TagFrameLabel(tag).frameName = getLabelFromClass(className);
                frameLabel = tag;
            }
        }

        if (classTag) {
            swf = new SWF();
            swf.version = version;
            swf.compressed = compression;

            swf.tags.push(new TagFileAttributes());
            if (debug) swf.tags.push(debugTag);
            if (bgColorTag)
                swf.tags.push(bgColorTag);
            if (metaTag)
                swf.tags.push(metaTag);
            if (scriptLimitTag)
                swf.tags.push(scriptLimitTag);
            if (productInfo)
                swf.tags.push(productInfo);
            if (frameLabel)
                swf.tags.push(frameLabel);
            for (var i:int = 0; i < abcTags.length; i++) {
                swf.tags.push(abcTags[i]);
            }
            swf.tags.push(classTag);
            swf.tags.push(new TagShowFrame());
            swf.tags.push(new TagEnd());

            var swfBytes:ByteArray = new ByteArray();
            swf.publish(swfBytes);
            swfBytes.position = 0;

            /*const file:FileReference = new FileReference();
             file.save(swfBytes, "Worker3.swf");*/

            if (!domain) domain = WorkerDomain.current;

            return domain.createWorker(swfBytes, giveAppPrivileges);
        }

        return null;
    }

    private static function getLabelFromClass(className:String):String {
        var label:String;
        const pos:int = className.lastIndexOf(".");
        if (pos > -1)
            label = className.substring(pos + 1);
        else
            label = className;

        return label;
    }
}
}