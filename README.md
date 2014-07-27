easyWorker
==========

Flex / Air library to easily implement Workers.

No more burden to create an other project and / or an extra SWF for your Worker,
everything is in-memory, don't deal anymore with MessageChannel and other low level API, use Thread an Events.

Includes all the used classes and nothing more (except if you want to),
register for you your typed object to pass them back and forth the Worker.

[Download easyWorker.swc] [8] (Deselect "Download with Sharebeast downloader" and click on the green Download button)
The PureAS3 version can be found [here] [9]

How to use it ?
----

You first implement a Runnable:

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

    public function add(obj:TermsVo):Number {
        return obj.v1 + obj.v2;
    }

    // Implements Runnable interface
    public function run(args:Array):void {
        const values:TermsVo = args[0] as TermsVo;
        dispatcher.dispatchResult(add(values));
    }
}
}
```

Now, to use your Runnable inside a Thread.

```ActionScript
<s:Application xmlns:fx="http://ns.adobe.com/mxml/2009"
               xmlns:s="library://ns.adobe.com/flex/spark"
               applicationComplete="applicationCompleteHandler(event)">
    <fx:Script><![CDATA[
        import com.doublefx.as3.thread.Thread;
        import com.doublefx.as3.thread.api.IThread;
        import com.doublefx.as3.thread.event.ThreadFaultEvent;
        import com.doublefx.as3.thread.event.ThreadProgressEvent;
        import com.doublefx.as3.thread.event.ThreadResultEvent;
        import com.doublefx.as3.thread.event.ThreadStateEvent;

        import mx.events.FlexEvent;

        import workers.ComplexWorker;
        import workers.vo.TermsVo;

        [Bindable]
        private var _thread:IThread;

        private function applicationCompleteHandler(event:FlexEvent):void {
            _thread = new Thread(ComplexWorker, "complexRunnable");

            _thread.addEventListener(ThreadStateEvent.THREAD_STATE, onThreadState);
            _thread.addEventListener(ThreadProgressEvent.PROGRESS, thread_progressHandler);
            _thread.addEventListener(ThreadResultEvent.RESULT, thread_resultHandler);
            _thread.addEventListener(ThreadFaultEvent.FAULT, thread_faultHandler);

            //Start a Thread in Pause, click on Start to resume it.
            _thread.pause();
            _thread.start(new TermsVo(1, 2));
        }

        private function onThreadState(event:ThreadStateEvent):void {
            trace("Thread State: " + _thread.state);
        }

        private function thread_resultHandler(event:ThreadResultEvent):void {
            result.text += event.result;
            _thread.terminate();
        }

        private function thread_faultHandler(event:ThreadFaultEvent):void {
            result.text += event.fault.message;
            _thread.terminate();
        }

        private function thread_progressHandler(event:ThreadProgressEvent):void {
        }
        ]]></fx:Script>

    <s:VGroup>
        <s:Label id="result" text="Result: "/>
        <s:HGroup enabled="false">
            <s:CheckBox label="NEW" selected="{_thread.isNew}"/>
            <s:CheckBox label="RUNNING" selected="{_thread.isRunning}"/>
            <s:CheckBox label="PAUSED" selected="{_thread.isPaused}"/>
            <s:CheckBox label="TERMINATED" selected="{_thread.isTerminated}"/>
        </s:HGroup>
        <s:Button click="_thread.resume()" label="Start" enabled="{_thread.isPaused}"/>
    </s:VGroup>

</s:Application>
```

The Constructor of the Thread allows you to pass extra dependencies in case they are not
automatically detected, those dependencies will be added to you worker and registered as aliases
if they contain the [RemoteClass] tag allowing you to pass them back and forth the Thread:

```ActionScript
const extraDependencies:Vector.<String> = Vector.<String>(["workers.vo.TermsVo"]);

_thread = new Thread(ComplexWorker, "nameOfMyThread", false, extraDependencies, loaderInfo, workerDomain);
```

You can intercept a call to pause, resume and terminate from your Runnable, see:
 ```ActionScript
 package workers {
 import com.doublefx.as3.thread.api.CrossThreadDispatcher;
 import com.doublefx.as3.thread.api.Runnable;
 import com.doublefx.as3.thread.event.ThreadActionRequestEvent;
 import com.doublefx.as3.thread.event.ThreadActionResponseEvent;

 import workers.vo.TermsVo;

 // Don't need to extend Sprite anymore.
 public class ComplexWorker implements Runnable {

     /**
      * Mandatory declaration if you want your Worker be able to communicate.
      * This CrossThreadDispatcher is injected at runtime.
      */
     private var _dispatcher:CrossThreadDispatcher;

     public function add(obj:TermsVo):Number {
         return obj.v1 + obj.v2;
     }

     // Implements Runnable interface
     public function run(args:Array):void {
         const values:TermsVo = args[0] as TermsVo;
         _dispatcher.dispatchResult(add(values));
     }

     public function get dispatcher():CrossThreadDispatcher {
         return _dispatcher;
     }

     public function set dispatcher(value:CrossThreadDispatcher):void {
         _dispatcher = value;

         if (_dispatcher) {
             _dispatcher.addEventListener(ThreadActionRequestEvent.PAUSE_REQUESTED, dispatcher_pauseRequestedHandler);
             _dispatcher.addEventListener(ThreadActionRequestEvent.RESUME_REQUESTED, dispatcher_resumeRequestedHandler);
             _dispatcher.addEventListener(ThreadActionRequestEvent.TERMINATE_REQUESTED, dispatcher_terminateRequestedHandler);
         }
     }

     // Won't be call if IThread.pause() has been called before start();
     private function dispatcher_pauseRequestedHandler(event:ThreadActionRequestEvent):void {
         trace("Pause requested, I do the eventual job to before Paused...");
         _dispatcher.dispatchEvent(new ThreadActionResponseEvent(ThreadActionResponseEvent.PAUSED));
     }

     // Won't be call if IThread.resume() has been called before start();
     private function dispatcher_resumeRequestedHandler(event:ThreadActionRequestEvent):void {
         trace("Resume requested, I do the eventual job to before Resumed...");
         _dispatcher.dispatchEvent(new ThreadActionResponseEvent(ThreadActionResponseEvent.RESUMED));
     }

     // Won't be call if IThread.terminate() has been called before start();
     private function dispatcher_terminateRequestedHandler(event:ThreadActionRequestEvent):void {
         trace("Terminate requested, I do the eventual job to before Terminated...");
         _dispatcher.dispatchEvent(new ThreadActionResponseEvent(ThreadActionResponseEvent.TERMINATED));
     }
 }
 }
```

NOTE: You should compile your swf with -optimize=false

How to build it ?
----

This project has a Maven structure but is not mavenized yet as the Apache Flex SDK is not at the moment, so, to build it, you will need to create a project based on those sources in your favorite IDE (I use IntelliJ).

This project is compatible with Apache Flex SDK 4.13 which has not been released at the moment I'm writing, I use a nightly built version "Apache Flex 4.13.0 FP 11.5 AIR 3.5". (use the [Apache Flex Intaller 3.1] [2] -will be released in few days- to get it)

Why this minimum requirement ? Because from this version, debugging Workers is possible using FDB or any IDE which use it such as IntelliJ, because Flash Player 11.5 is the first version that allows you to use Worker, Condition and Mutex.

Also, I use the very well done [as3-commons-reflect] [5] and [as3swf] [3] libs to reflect and emit the Worker and its dependencies in memory, FlexUnit 4.1 for the tests.

Examples :
----

You will find in the sub-directory of the Master and PureAS3 branches, some 
web, desktop and mobile examples for Flex/AIR and pure AS3 project, the last ones :
 
 https://github.com/doublefx/easyWorker/tree/master/moreFlexDemo/downloadFileThread-Demo
 
 A thread based implementation of a simple tool to download / copy files running in a Thread, with persistent pause / resume capabilities and automatic re-download if the file has changed on the server after a long pause.
 
 https://github.com/doublefx/easyWorker-ActiveAIRCord
  
 Requested by the creator of ActiveAIRCord https://github.com/riadvice/ActiveAIRCord , An easy to use library using the Active Record pattern to access SQLite
 
 https://github.com/doublefx/easyWorker/tree/master/moreFlexDemo/BankAccount
 
 Simple Thread based application to demonstrate how to manage concurrent access to the same data
 
 https://github.com/doublefx/easyWorker/tree/PureAS3/moreAS3Demo/MP3Worker
 
 Thread based implementation of the original MP3Worker. http://gotoandlearn.com/play.php?id=169
 
 It runs a WAV->MP3 converter in a Thread
 
 Limitations :
----
 
 You can't easily use big dependent Flex SDK classes in your worker, this is because:
 
 1- The Adobe worker limitation itself:
 
 "Several runtime APIs are not available in code running in a background worker. 
 These primarily consist of APIs related to user input and output mechanisms, or operating system elements like windows and dragging. 
 As a rule, for any API that isn't supported in all contexts, use the isSupported, available, and similar properties to check whether 
 the API is available in the background worker context before attempting to use the API.
 
 Workers are useful because they decrease the chances of the frame rate dropping due to the main rendering thread being blocked 
 by other code. However, workers require additional system memory and CPU use, which can be costly to overall application performance. 
 Because each worker uses its own instance of the runtime virtual machine, even the overhead of a trivial worker can be large. 
 When using workers, test your code across all your target platforms to ensure that the demands on the system are not too large. 
 Adobe recommends that you do not use more than one or two background workers in a typical scenario."
 
 ANE's are not supported either.
 
 2- Limitations relative to the Flex SDK class dependencies.
 
 Well, it is not a technical limitation, it is simply not a good practice to use classes such as ArrayCollection (which has tons of dependencies) in your worker, better to use Array for example.
 
 easyWorker will detect and import in your in-memory worker each Type it will meet in non private instance or static methods, properties and variables that has been used in your Runnable.
 For those private, use extraDependency from the Thread constructor.

Enjoy and don't hesitate to give me your feedback.

Bug tracker
----

Have a bug, a question? Please create an issue [here on GitHub] [1]

Disclaimer, Copyright and license
----

This library is inspired by [worker-from-class] [6] and [Developer-friendly AS Workers API] [7]

Copyright 2014 Frédéric Thomas. Released under Apache 2.0.


Follow me on twitter [@webdoublefx] [10]
 
 
[1]:https://github.com/doublefx/easyWorker/issues
[2]:http://flex.apache.org/installer.html
[3]:https://github.com/claus/as3swf
[4]:http://www.sharebeast.com/759c4zz7d4sf
[5]:http://www.as3commons.org/as3-commons-reflect/introduction.html
[6]:https://github.com/bortsen/worker-from-class
[7]:http://myappsnippet.com/developer-friendly-workers-api/
[8]:http://www.sharebeast.com/er9n45ly0s8c
[9]:https://github.com/doublefx/easyWorker/tree/PureAS3
[10]:https://twitter.com/webDoubleFx
