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
 * User: Frederic THOMAS Date: 15/06/2014 Time: 14:48
 */
package com.doublefx.as3.thread.util {
import flash.utils.Dictionary;

import org.as3commons.lang.ClassUtils;
import org.as3commons.lang.StringUtils;
import org.as3commons.reflect.Constructor;
import org.as3commons.reflect.IMember;
import org.as3commons.reflect.Metadata;
import org.as3commons.reflect.Method;
import org.as3commons.reflect.Parameter;
import org.as3commons.reflect.Type;
import org.as3commons.reflect.as3commons_reflect;

use namespace as3commons_reflect;

[ExcludeClass]
public class ThreadDependencyHelper {

    // START: Copied from org.as3commons.bytecode.reflect.ByteCodeType
    private static const FLASH_NATIVE_PACKAGE_PREFIX:String = 'flash.';
    private static const nativeClassNames:Dictionary = new Dictionary();

    {
        nativeClassNames['*'] = true;
        nativeClassNames['void'] = true;
        nativeClassNames['Boolean'] = true;
        nativeClassNames['int'] = true;
        nativeClassNames['uint'] = true;
        nativeClassNames['Number'] = true;
        nativeClassNames['String'] = true;
        nativeClassNames['Object'] = true;
        nativeClassNames['Function'] = true;
        nativeClassNames['RegExp'] = true;
        nativeClassNames['Array'] = true;
        nativeClassNames['Error'] = true;
        nativeClassNames['DefinitionError'] = true;
        nativeClassNames['EvalError'] = true;
        nativeClassNames['RangeError'] = true;
        nativeClassNames['ReferenceError'] = true;
        nativeClassNames['SecurityError'] = true;
        nativeClassNames['SyntaxError'] = true;
        nativeClassNames['TypeError'] = true;
        nativeClassNames['URIError'] = true;
        nativeClassNames['VerifyError'] = true;
        nativeClassNames['UninitializedError'] = true;
        nativeClassNames['ArgumentError'] = true;
    }

    private static function isNativeName(name:String):Boolean {
        return (
                (StringUtils.startsWith(name, FLASH_NATIVE_PACKAGE_PREFIX)) || //
                (nativeClassNames[name] == true) || //
                (StringUtils.startsWith(name, '__AS3__.')) //
                );
    }

    // END: Copied from org.as3commons.bytecode.reflect.ByteCodeType


    public static function collectDependencies(codeType:Type, returnArray:Vector.<String> = null):Vector.<String> {
        if (!returnArray)
            returnArray = new Vector.<String>();

        if (codeType && isValidTypeName(codeType.fullName)) {

            var fullName:String = codeType.fullName;

            if (addUniquely(ClassUtils.convertFullyQualifiedName(fullName), returnArray)) {
                var extendsClasses:Array = codeType.extendsClasses;
                if (extendsClasses.length > 0) {
                    for each (var extendsClass:String in extendsClasses) {
                        if (isValidTypeName(extendsClass)) {
                            collectDependencies(Type.forName(extendsClass, codeType.applicationDomain), returnArray);
                        }
                    }
                }

                var interfaces:Array = codeType.interfaces;
                if (interfaces.length > 0) {
                    for each (var interfaceName:String in interfaces) {
                        if (isValidTypeName(interfaceName)) {
                            collectDependencies(Type.forName(interfaceName, codeType.applicationDomain), returnArray);
                        }
                    }
                }

                var constructor:Constructor = codeType.constructor;
                var parameters:Array;
                var parameter:Parameter;
                var parameterType:Type;
                var member:IMember;

                if (constructor) {
                    parameters = constructor.parameters;
                    if (parameters.length > 0) {
                        for each (parameter in parameters) {
                            parameterType = parameter.type;
                            if (parameterType && isValidTypeName(parameterType.fullName)) {
                                collectDependencies(Type.forName(parameterType.fullName, parameterType.applicationDomain), returnArray);
                            }
                        }
                    }
                }

                const codeTypes:Array = [codeType.accessors,
                    codeType.variables,
                    codeType.staticVariables,
                    codeType.constants,
                    codeType.staticConstants,
                    codeType.fields];

                for each (var members:Array in codeTypes) {
                    for each (member in members) {
                        collectMembers(member, returnArray);
                    }
                }

                for each (var method:Method in codeType.methods) {
                    const returnTypeName:String = method.returnTypeName;
                    if (isValidTypeName(returnTypeName)) {
                        const returnType:Type = method.returnType;
                        fullName = getFullName(returnType, method.returnTypeName);
                        if (fullName)
                            collectDependencies(Type.forName(fullName, returnType ? returnType.applicationDomain : null), returnArray);
                    }
                    parameters = method.parameters;
                    if (parameters.length > 0) {
                        for each (parameter in parameters) {
                            parameterType = parameter.type;
                            if (isValidTypeName(parameterType.fullName)) {
                                collectDependencies(Type.forName(parameterType.fullName, parameterType.applicationDomain), returnArray);
                            }
                        }
                    }
                }

                const embeds:Array = collectEmbeds(codeType);
                for each (var embed:String in embeds) {
                    if (isValidTypeName(embed)) {
                        collectDependencies(Type.forName(embed, codeType.applicationDomain), returnArray);
                    }
                }
            }
        }
        return returnArray;
    }

    private static function getFullName(returnType:Type, returnTypeName:String):String {
        var fullName:String;
        if (returnType)
            fullName = returnType.fullName;
        else {
            var indexOf:int = returnTypeName.indexOf("::");
            if (indexOf > -1)
                fullName = returnTypeName.substring(indexOf + 2);
        }
        return fullName;
    }

    public static function collectAliases(dependency:Type):ClassAlias {

        if (dependency.metadata)
            for each (var metadata:Metadata in dependency.metadata) {
                if (metadata.name == "remoteclass") {
                    var fullyQualifiedName:String = ClassUtils.convertFullyQualifiedName(dependency.fullName);
                    var alias:String;
                    if (metadata.hasArgumentWithKey("alias"))
                        alias = metadata.getArgument("alias").value;
                    else
                        alias = fullyQualifiedName;

                    return new ClassAlias(fullyQualifiedName, alias);
                }
            }

        return null;
    }

    /**
     * Collect the Embeds.
     * The best way I found to collect Embeds as I can't check for the metadata until I assume the dependencies from libraries won't be compile with -keep-as3-metadata+=Embed
     * The compiler generate a class for the Embed starting with the qualified name of the class followed by "_".
     *
     * @param dependency
     * @return
     */
    private static function collectEmbeds(dependency:Type):Array {
        const more:Array = [];

        const embedBase:String = dependency.fullName + "_";

        const definitionNames:Vector.<String> = dependency.applicationDomain.getQualifiedDefinitionNames();

        const embeds:Vector.<String> = definitionNames.filter(function (item:*, index:int, array:Vector.<String>):Boolean {
            return (String(item).indexOf(embedBase) == 0)
        });

        if (embeds.length > 0)
            for each (var definition:String in embeds) {
                more[more.length] = definition;
            }

        return more;
    }

    private static function collectMembers(member:IMember, returnArray:Vector.<String>):void {
        const memberType:Type = member.type;
        if (memberType && isValidTypeName(memberType.fullName)) {
            collectDependencies(Type.forName(memberType.fullName, memberType.applicationDomain), returnArray);
        }
    }

    public static function isValidTypeName(typeName:String):Boolean {
        if (StringUtils.isEmpty(typeName))
            return false;

        return (!isNativeName(typeName));
    }

    public static function addUniquely(item:String, array:Vector.<String>):Boolean {
        if (item != null && array.indexOf(item) == -1) {
            array[array.length] = item;
            return true;
        }
        return false;
    }
}
}
