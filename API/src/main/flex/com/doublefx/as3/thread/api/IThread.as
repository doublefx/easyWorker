/**
 * User: Frederic THOMAS Date: 15/06/2014 Time: 16:35
 */
package com.doublefx.as3.thread.api {
import com.doublefx.as3.thread.util.ClassAlias;

import flash.events.IEventDispatcher;

/**
 * All we need to play with the Thread class.
 */
public interface IThread extends IEventDispatcher{

    /**
     * Call a particular function on the Runnable.
     * Should disappear, it is preferable to use Interfaces and Proxies instead.
     *
     * @param runnableClassName The Runnable class name.
     * @param runnableMethod The method to call on the Runnable.
     * @param args The arguments to pass to the workerMethod.
     */
    function command(runnableClassName:String, runnableMethod:String, ...args):void;

    /**
     * Start a Thread and call the Runnable's run method.
     *
     * @param args The arguments to pass to the Runnable's run method.
     */
    function start(...args):void;

    /**
     * Terminate Thread.
     */
    function terminate():void;

    /**
     * Pause a running Thread.
     *
     * @param milli Optional number of milliseconds to pause.
     */
    function pause(milli:Number = 0):void;

    /**
     * Resume a paused Thread.
     */
    function resume():void;

    /**
     * The Thread's id, should be the same than the one seen via FDB.
     */
    function get id():uint;

    /**
     * The Thread's name.
     */
    function get name():String;

    /**
     * @see flash.system.WorkerState
     */
    function get state():String;
}
}
