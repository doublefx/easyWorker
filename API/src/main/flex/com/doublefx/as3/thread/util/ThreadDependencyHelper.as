/**
 * User: Frederic THOMAS Date: 15/06/2014 Time: 14:48
 */
package com.doublefx.as3.thread.util {
import mx.collections.ArrayList;

import org.as3commons.bytecode.reflect.ByteCodeMethod;
import org.as3commons.bytecode.reflect.ByteCodeParameter;
import org.as3commons.bytecode.reflect.ByteCodeType;
import org.as3commons.lang.StringUtils;
import org.as3commons.reflect.Accessor;
import org.as3commons.reflect.Constant;
import org.as3commons.reflect.Field;
import org.as3commons.reflect.Method;
import org.as3commons.reflect.Type;
import org.as3commons.reflect.Variable;
import org.as3commons.reflect.as3commons_reflect;

use namespace as3commons_reflect;

public class ThreadDependencyHelper {

    public static function collectDependencies(codeType:ByteCodeType, returnArray:ArrayList = null):ArrayList {
        if (!returnArray)
            returnArray = new ArrayList();

        if (codeType && isValidTypeName(codeType.fullName)) {

            var fullName:String = codeType.fullName;

            if (addUniquely(fullName, returnArray)) {
                var extendsClasses:Array = codeType.extendsClasses;
                if (extendsClasses.length > 0) {
                    for each (var extendsClass:String in extendsClasses) {
                        if (isValidTypeName(extendsClass)) {
                            collectDependencies(ByteCodeType.forName(extendsClass, codeType.applicationDomain), returnArray);
                        }
                    }
                }

                var interfaces:Array = codeType.interfaces;
                if (interfaces.length > 0) {
                    for each (var interfaceName:String in interfaces) {
                        if (isValidTypeName(interfaceName)) {
                            collectDependencies(ByteCodeType.forName(interfaceName, codeType.applicationDomain), returnArray);
                        }
                    }
                }

                var instanceConstructor:ByteCodeMethod = codeType.instanceConstructor;
                var parameters:Array = instanceConstructor.parameters;
                var parameter:ByteCodeParameter;
                var parameterType:Type;

                if (parameters.length > 0) {
                    for each (parameter in parameters) {
                        try {
                            parameterType = parameter.type;
                        } catch (e:Error) {
                            continue;
                        }
                        if (parameterType && isValidTypeName(parameterType.fullName)) {
                            collectDependencies(ByteCodeType.forName(parameterType.fullName, parameterType.applicationDomain), returnArray);
                        }
                    }
                }
                for each (var accessor:Accessor in codeType.accessors) {
                    var accessorType:Type;
                    try {
                        accessorType = accessor.type;
                    } catch (e:Error) {
                        continue;
                    }
                    if (accessorType && isValidTypeName(accessorType.fullName)) {
                        collectDependencies(ByteCodeType.forName(accessorType.fullName, accessorType.applicationDomain), returnArray);
                    }
                }
                for each (var variable:Variable in codeType.variables) {
                    var variableType:Type;
                    try {
                        variableType = variable.type;
                    } catch (e:Error) {
                        continue;
                    }
                    if (variableType && isValidTypeName(variableType.fullName)) {
                        try {
                            collectDependencies(ByteCodeType.forName(variableType.fullName, variableType.applicationDomain), returnArray);
                        } catch (e:Error) {

                        }
                    }
                }
                for each (var constant:Constant in codeType.constants) {
                    var constantType:Type;
                    try {
                        constantType = constant.type;
                    } catch (e:Error) {
                        continue;
                    }
                    if (constantType && isValidTypeName(constantType.fullName)) {
                        collectDependencies(ByteCodeType.forName(constantType.fullName, constantType.applicationDomain), returnArray);
                    }
                }
                for each (var field:Field in codeType.fields) {
                    var fieldType:Type;
                    try {
                        fieldType = field.type;
                    } catch (e:Error) {
                        continue;
                    }
                    if (fieldType && isValidTypeName(fieldType.fullName)) {
                        collectDependencies(ByteCodeType.forName(fieldType.fullName, fieldType.applicationDomain), returnArray);
                    }
                }
                for each (var method:Method in codeType.methods) {
                    var returnTypeName:String = method.returnTypeName;
                    if (isValidTypeName(returnTypeName)) {
                        var returnType:Type;
                        try {
                            returnType = method.returnType;
                        } catch (e:Error) {
                            continue;
                        }
                        collectDependencies(ByteCodeType.forName(returnType.fullName, returnType.applicationDomain), returnArray);
                    }
                    parameters = method.parameters;
                    if (parameters.length > 0) {
                        for each (parameter in parameters) {
                            try {
                                var typeName:String = parameter.typeName;
                                parameterType = isValidTypeName(typeName) ? parameter.type : null;
                            } catch (e:Error) {
                                continue;
                            }
                            if (parameterType) {
                                collectDependencies(ByteCodeType.forName(parameterType.fullName, parameterType.applicationDomain), returnArray);
                            }
                        }
                    }
                }
            }
        }
        return returnArray;
    }

    public static function isValidTypeName(typeName:String):Boolean {
        if (StringUtils.isEmpty(typeName))
            return false;

        return (typeName != "*" && !ByteCodeType.isNativeName(typeName));
    }

    public static function addUniquely(item:Object, array:ArrayList):Boolean {
        if (item != null && array.getItemIndex(item) == -1) {
            array.addItem(item);
            return true;
        }
        return false;
    }
}
}
