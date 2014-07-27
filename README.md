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

[1]:https://github.com/doublefx/easyWorker/issues
[8]:http://www.sharebeast.com/940onmjnfsws
[9]:https://github.com/doublefx/easyWorker

Enjoy and don't hesitate to give me your feedback.
