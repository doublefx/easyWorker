/**
 * User: Frederic THOMAS Date: 14/06/2014 Time: 15:13
 */
package com.doublefx.as3.thread.event {
import flash.events.Event;

[RemoteClass(alias="com.doublefx.as3.thread.event.ThreadFaultEvent")]
public class ThreadFaultEvent extends Event {
    public static const FAULT:String = "fault";

    private var _fault:Error;

    public function ThreadFaultEvent(fault:Error = null, bubbles:Boolean = false, cancelable:Boolean = false) {
        super(FAULT, bubbles, cancelable);
        _fault = fault;
    }

    public function get fault():Error {
        return _fault;
    }

    public override function clone():Event {
        var evt:ThreadFaultEvent = new ThreadFaultEvent(fault, this.bubbles, this.cancelable);
        return evt;
    }

    public function set fault(value:Error):void {
        _fault = value;
    }
}
}
