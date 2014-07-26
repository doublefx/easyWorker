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
import com.codeazur.as3swf.tags.IDefinitionTag;
import com.codeazur.as3swf.tags.ITag;
import com.codeazur.as3swf.tags.TagDefineBinaryData;
import com.codeazur.as3swf.tags.TagDoABC;
import com.codeazur.as3swf.tags.TagEnableDebugger2;
import com.codeazur.as3swf.tags.TagEnd;
import com.codeazur.as3swf.tags.TagExportAssets;
import com.codeazur.as3swf.tags.TagFileAttributes;
import com.codeazur.as3swf.tags.TagFrameLabel;
import com.codeazur.as3swf.tags.TagMetadata;
import com.codeazur.as3swf.tags.TagProductInfo;
import com.codeazur.as3swf.tags.TagScriptLimits;
import com.codeazur.as3swf.tags.TagSetBackgroundColor;
import com.codeazur.as3swf.tags.TagShowFrame;
import com.codeazur.as3swf.tags.TagSymbolClass;

import flash.display.LoaderInfo;
import flash.system.Worker;
import flash.system.WorkerDomain;
import flash.utils.ByteArray;
import flash.utils.getQualifiedClassName;

[ExcludeClass]
public class WorkerFactory {

    /**
     * Creates a Worker from a Class.
     * @param clazz the Class to create a Worker from
     * @param loaderInfo LoaderInfo which must contain the Class definition (usually loaderInfo)
     * @param dependencies The clazz dependencies
     * @param debug set to tru if you want to debug the Worker
     * @param giveAppPrivileges (default = false) — indicates whether the worker should be given application sandbox privileges in AIR. This parameter is ignored in Flash Player
     * @param domain the WorkerDomain to create the Worker in
     * @return the new Worker
     */
    public static function getWorkerFromClass(loaderInfo:LoaderInfo, clazz:Class, dependencies:Vector.<String>, debug:Boolean = true, giveAppPrivileges:Boolean = false, domain:WorkerDomain = null):Worker {
        var swf:SWF = new SWF(loaderInfo.bytes);
        var version:Number = swf.version;
        var compression:Boolean = swf.compressed;
        var tags:Vector.<ITag> = swf.tags;
        var className:String = getQualifiedClassName(clazz).replace(/::/g, ".");
        var abcName:String = className.replace(/\./g, "/");

        var tag:ITag;
        var classTag:ITag;
        var metaTag:ITag;
        var bgColorTag:ITag;
        var debugTag:ITag;
        var abcTags:Vector.<ITag> = new Vector.<ITag>();
        var scriptLimitTag:ITag;
        var productInfo:ITag;
        var frameLabel:ITag;
        var definitionTags:Vector.<IDefinitionTag> = new Vector.<IDefinitionTag>();
        var definitionTag:IDefinitionTag;
        var characterId:uint;
        var exportAssets:Vector.<TagExportAssets> = new Vector.<TagExportAssets>();
        var exportSymbols:Vector.<TagSymbolClass> = new Vector.<TagSymbolClass>();
        var swfSymbols:Vector.<SWFSymbol>;
        var classSymbols:Vector.<SWFSymbol>;
        var symbol:SWFSymbol;

        for each (tag in tags) {
            if (tag is TagSymbolClass) {
                // Collect the main class symbol and others.
                const tagSymbolClass:TagSymbolClass = tag as TagSymbolClass;
                swfSymbols = tagSymbolClass.symbols;
                for (var s0:uint = 0; s0 < swfSymbols.length; s0++) {
                    symbol = swfSymbols[s0];
                    if (symbol.tagId == 0) {
                        symbol.name = className;
                        classTag = tag;
                    } else if (dependencies.indexOf(symbol.name) > -1) {
                        exportSymbols[exportSymbols.length] = tag as TagSymbolClass;
                    } else {
                        swfSymbols.splice(s0--, 1);
                    }
                }
            }
            // Collect each dependent TagExportAssets and its symbols (embeds) removing the unused ones.
            else if (tag is TagExportAssets) {
                // Collect each dependent TagExportAssets symbols (embeds) and removed the unused ones.
                swfSymbols = TagExportAssets(tag).symbols;
                for (var s1:uint = 0; s1 < swfSymbols.length; s1++) {
                    symbol = swfSymbols[s1];
                    if (dependencies.indexOf(symbol.name) > -1) {
                        exportAssets[exportAssets.length] = tag as TagExportAssets;
                    } else
                        swfSymbols.splice(s1--, 1);
                }
            } else if (tag is TagEnableDebugger2) {
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
                            trace("Dep: " + depAbcName + " tag: " + tag.toString(0, 0x01));
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

        /**
         * Collect the IDefinitionTag for each TagExportAssets symbol and add the symbol to the main class.
         */
        for each (var assets:TagExportAssets in exportAssets) {
            for each (var swfSymbol:SWFSymbol in assets.symbols) {
                for each (tag in tags) {
                    if (tag is IDefinitionTag) {
                        definitionTag = tag as IDefinitionTag;
                        characterId = definitionTag.characterId;
                        if (swfSymbol.tagId == definitionTag.characterId) {
                            definitionTags[definitionTags.length] = tag as IDefinitionTag;
                            classSymbols = TagSymbolClass(classTag).symbols;
                            addUniquely(classSymbols, swfSymbol);
                            break;
                        }
                    }
                }
            }
        }

        for each (var symbolClass:TagSymbolClass in exportSymbols) {
            for each (swfSymbol in symbolClass.symbols) {
                for each (tag in tags) {
                    if (tag is TagDefineBinaryData) {
                        definitionTag = tag as IDefinitionTag;
                        characterId = definitionTag.characterId;
                        if (swfSymbol.tagId == characterId) {
                            definitionTags[definitionTags.length] = definitionTag;
                            classSymbols = TagSymbolClass(classTag).symbols;
                            addUniquely(classSymbols, swfSymbol);
                            break;
                        }
                    }
                }
            }
        }

        if (classTag) {
            var i:int;

            swf = new SWF();
            swf.version = version;
            swf.compressed = compression;

            const tagFileAttributes:TagFileAttributes = new TagFileAttributes();
            tagFileAttributes.hasMetadata = metaTag != null;
            swf.tags.push(tagFileAttributes);
            if (debug && debugTag)
                swf.tags.push(debugTag);
            if (bgColorTag)
                swf.tags.push(bgColorTag);
            if (metaTag) {
                swf.tags.push(metaTag);
            }
            for (i = 0; i < definitionTags.length; i++) {
                swf.tags.push(definitionTags[i]);
            }
            for (i = 0; i < exportAssets.length; i++) {
                swf.tags.push(exportAssets[i]);
            }
            if (scriptLimitTag)
                swf.tags.push(scriptLimitTag);
            if (productInfo)
                swf.tags.push(productInfo);
            if (frameLabel)
                swf.tags.push(frameLabel);
            for (i = 0; i < abcTags.length; i++) {
                swf.tags.push(abcTags[i]);
            }
            swf.tags.push(classTag);
            swf.tags.push(new TagShowFrame());
            swf.tags.push(new TagEnd());

            var swfBytes:ByteArray = new ByteArray();
            swf.publish(swfBytes);
            swfBytes.position = 0;

            /*const file:FileReference = new FileReference();
             file.save(swfBytes, "Worker.swf");*/

            trace(swf);

            if (!domain) domain = WorkerDomain.current;

            return domain.createWorker(swfBytes, giveAppPrivileges);
        }

        return null;
    }

    private static function addUniquely(classSymbols:Vector.<SWFSymbol>, swfSymbol:SWFSymbol):void {
        for each (var symbol:SWFSymbol in classSymbols) {
            if (symbol.tagId == swfSymbol.tagId && symbol.name == swfSymbol.name) {
                return;
            }
        }
        classSymbols[classSymbols.length] = swfSymbol;
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