/**
 * User: Frederic THOMAS Date: 14/06/2014 Time: 15:13
 */
package com.doublefx.as3.thread.event {
import flash.events.Event;

[RemoteClass(alias="com.doublefx.as3.thread.event.ThreadProgressEvent")]
public class ThreadProgressEvent extends Event {
    public static const PROGRESS:String = "progress";

    private var _current:uint;
    private var _total:uint;

    public function ThreadProgressEvent(current:uint = 0, total:uint = 100, bubbles:Boolean = false, cancelable:Boolean = false) {
        super(PROGRESS, bubbles, cancelable);
        _current = current;
        _total = total;
    }

    public function get current():uint {
        return _current;
    }

    public function get total():uint {
        return _total;
    }

    public override function clone():Event {
        var evt:ThreadProgressEvent = new ThreadProgressEvent(_current, _total, this.bubbles, this.cancelable);
        return evt;
    }

    public function set current(value:uint):void {
        _current = value;
    }

    public function set total(value:uint):void {
        _total = value;
    }
}
}
