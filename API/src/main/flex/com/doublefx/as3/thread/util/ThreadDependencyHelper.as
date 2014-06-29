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
import org.as3commons.reflect.Method;
import org.as3commons.reflect.Parameter;
import org.as3commons.reflect.Type;
import org.as3commons.reflect.as3commons_reflect;

use namespace as3commons_reflect;

[Exclude]
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


    public static function collectDependencies(codeType:Type, returnArray:Array = null):Array {
        if (!returnArray)
            returnArray = [];

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
                        collectDependencies(Type.forName(returnType.fullName, returnType.applicationDomain), returnArray);
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
            }
        }
        return returnArray;
    }

    private static function collectMembers(member:IMember, returnArray:Array):void {
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

    public static function addUniquely(item:Object, array:Array):Boolean {
        if (item != null && getItemIndex(array, item) == -1) {
            array[array.length] = item;
            return true;
        }
        return false;
    }

    private static function getItemIndex(array:Array, item:*):int {
        var index:int = -1;

        if (array) {
            for (var i:uint = 0; i < array.length; i++) {
                var anItem:* = array [i];
                if (anItem == item) {
                    index = i;
                    break;
                }
            }
        }

        return index;
    }

}
}
