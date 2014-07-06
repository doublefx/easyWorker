easyWorkerAS3
==========

Pure AS3 library to easily implement Workers.

No more burden to create an other project and / or an extra SWF for your Worker,
everything is in-memory, don't deal anymore with MessageChannel and other low level API, use Thread an Events.

Includes all the used classes and nothing more (except if you want to),
register for you your typed object to pass them back and forth the Worker.

[Download easyWorkerAS3.swc] [8] (Deselect "Download with Sharebeast downloader" and click on the green Download button)
The Flex / AIR version can be found [here] [9]

How to use it ?
----

See the description in the [Master branch] [9], the only differences are the properties are not Bindable 
and you may need to set the Thread.DEFAULT_LOADER_INFO as described in the ASDoc
```ActionScript
/**
     * The Default LoaderInfo used by all new created Threads when none is provided to its constructor.
     *
     * For Flex / AIR, the default is FlexGlobals.topLevelApplication.loaderInfo
     * For Flash, there is no default, you need to provide the one containing this easyWorker library and your runnables,
     * could be stage.loaderInfo for example if everything is compiled in the same application.
     */
    public static var DEFAULT_LOADER_INFO:LoaderInfo;
```

The [Issues] [1] is a good place to ask things and raise issues indeed.

How to build it:
----

This project has a Maven structure but is not mavenized yet as the Apache Flex SDK is not at the moment, so, to build it, you will need to create a project based on those sources in your favorite IDE (I use IntelliJ).

This project is compatible with Apache Flex SDK 4.13 which has not been released at the moment I'm writing, I use a nightly built version "Apache Flex 4.13.0 FP 11.5 AIR 3.5". (use the [Apache Flex Intaller 3.1] [2] -will be released in few days- to get it)

Why this minimum requirement ? Because from this version, debugging Workers is possible using FDB or any IDE which use it such as IntelliJ, because Flash Player 11.5 is the first version that allows you to use Worker, Condition and Mutex.

Also, I use the very well done [as3-commons-reflect] [5] and [as3swf] [3] libs to reflect and emit the Worker and its dependencies in memory, FlexUnit 4.1 for the tests.
Those libs can be found [here] [4].

For the PureAS3 Demos, I use starling/feathers and some their themes, those libs can be found [here] [10]

This library is inspired by [worker-from-class] [6] and [Developer-friendly AS Workers API] [7]

[1]:https://github.com/doublefx/easyWorker/issues
[2]:http://flex.apache.org/installer.html
[3]:https://github.com/claus/as3swf
[4]:http://www.sharebeast.com/759c4zz7d4sf
[5]:http://www.as3commons.org/as3-commons-reflect/introduction.html
[6]:https://github.com/bortsen/worker-from-class
[7]:http://myappsnippet.com/developer-friendly-workers-api/
[8]:http://www.sharebeast.com/ab7wbd1rwqh2
[9]:https://github.com/doublefx/easyWorker
[10]:http://www.sharebeast.com/yhxzr2jbkem0

Enjoy and don't hesitate to give me your feedback.
