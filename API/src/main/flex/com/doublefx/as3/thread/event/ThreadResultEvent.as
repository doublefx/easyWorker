/**
 * User: Frederic THOMAS Date: 14/06/2014 Time: 15:13
 */
package com.doublefx.as3.thread.event {
import flash.events.Event;

[RemoteClass(alias="com.doublefx.as3.thread.event.ThreadResultEvent")]
public class ThreadResultEvent extends Event {
    public static const RESULT:String = "result";

    private var _result:*;

    public function ThreadResultEvent(result:* = null, bubbles:Boolean = false, cancelable:Boolean = false) {
        super(RESULT, bubbles, cancelable);
        _result = result;
    }

    public function get result():* {
        return _result;
    }

    public override function clone():Event {
        var evt:ThreadResultEvent = new ThreadResultEvent(_result, this.bubbles, this.cancelable);
        return evt;
    }

    public function set result(value:*):void {
        _result = value;
    }
}
}
