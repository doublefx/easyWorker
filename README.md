easyWorker
==========

Flex / Air library to easily implement Workers.

How to use it ?
----

You first extend a Runnable:

```ActionScript
package workers {
import com.doublefx.as3.thread.api.CrossThreadDispatcher;
import com.doublefx.as3.thread.api.Runnable;
import workers.vo.TermsVo;

// Don't need to extend Sprite anymore.
public class ComplexWorker implements Runnable {

    /**
     * Mandatory declaration if you want your Worker be able to communicate.
     * This CrossThreadDispatcher is injected at runtime.
     */
    public var dispatcher:CrossThreadDispatcher;

    /**
     * Implements Runnable interface.
     *
     * @Param args The elements of the args Array contain the
     * values as you pass them to the Thread.
     */
    public function run(args:Array):void {

        const values:TermsVo = args[0] as TermsVo;

        // The dispatcher provides you functions to send the result,
        // progress and faults occurring in your Worker.

        dispatcher.dispatchResult(add(values));
    }

    /**
     * The task your worker is going to do, note that the library
     * allows you to have complex workers which depend of other Classes
     * and you don't need anymore to register the Class aliases,
     * most of the time, it will be detected and managed for you.
     */
    private function add(obj:TermsVo):Number {
        return obj.v1 + obj.v2;
    }
}
}
```

Now, to use your Runnable inside a Thread.

```ActionScript
        private var _thread:IThread;

        private function applicationCompleteHandler(event:FlexEvent):void {
            _thread = new Thread(ComplexWorker, "nameOfMyThread");

            _thread.addEventListener(ThreadProgressEvent.PROGRESS, thread_progressHandler);
            _thread.addEventListener(ThreadResultEvent.RESULT, thread_resultHandler);
            _thread.addEventListener(ThreadFaultEvent.FAULT, thread_faultHandler);

            _thread.start(new TermsVo(1, 2));
        }
```

The Constructor of the Thread allows you to pass extra dependencies in case they are not
automatically detected, those dependencies will be added to you worker and registered as aliases
allowing you to pass them back and forth the Thread:

```ActionScript
const extraDependencies:Vector.<ClassAlias> = new Vector.<ClassAlias>();
extraDependencies[0] = new ClassAlias("workers.vo.TermsVo", TermsVo);

_thread = new Thread(ComplexWorker, "nameOfMyThread", extraDependencies, loaderInfo, currentDomain);
```

The IThread interface looks like that:

 ```ActionScript
 public interface IThread extends IEventDispatcher{
 
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
```

Note: This is an early stage version, many things have to come:

- Pause and Resume are not implemented yet.
- Terminate has still a basic implementation.
- More to come to interact with your Runnable from the Thread.

The [Issues] [1] is a good place to ask things and raise issues indeed.

How to build it:
----

This project has a Maven structure but is not mavenized yet as the Apache Flex SDK is not at the moment, so, to build it, you will need to create a project based on those sources in your favorite IDE (I use IntelliJ).

This project is compatible with Apache Flex SDK 4.13 which has not been released at the moment I'm writing, I use a nightly built version "Apache Flex 4.13.0 FP 11.5 AIR 3.5". (use the [Apache Flex Intaller 3.1] [2] -will be released in few days- to get it)

Why this minimum requirement ? Because from this version, debugging Workers is possible using FDB or any IDE which use it such as IntelliJ, because Flash Player 11.5 is the first version that allows you to use Worker, Condition and Mutex.

Also, I use the very well done as3-commons-reflect and as3swf libs to reflect and emit the Worker and its dependencies in memory, FlexUnit 4.1 and Hamcrest-as3 for the tests.
Those libs can be found [here] [3]

[1]:https://github.com/doublefx/easyWorker/issues
[2]:http://flex.apache.org/installer.html
[3]:https://drive.google.com/folderview?id=0B0SnI9jZINzGS1M0MUVwMEM5bHM&usp=sharing

Enjoy and don't hesitate to give me your feedback.
