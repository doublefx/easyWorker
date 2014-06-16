/**
 * User: Frederic THOMAS Date: 15/06/2014 Time: 14:00
 */
package com.doublefx.as3.thread.api {
public interface CrossThreadDispatcher {
    function dispatchProgress(current:uint, total:uint):void;
    function dispatchError(error:Error):void;
    function dispatchResult(result:*):void;
}
}
