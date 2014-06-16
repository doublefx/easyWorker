/**
 * User: Frederic THOMAS Date: 15/06/2014 Time: 15:51
 */
package com.doublefx.as3.thread.util {

[RemoteClass(alias="com.doublefx.as3.thread.util.ClassAlias")]
public class ClassAlias {
    public var alias:String;
    public var classObject:Class;

    public function ClassAlias(alias:String = null, classObject:Class = null):void {
        this.alias = alias;
        this.classObject = classObject;
    }
}
}
