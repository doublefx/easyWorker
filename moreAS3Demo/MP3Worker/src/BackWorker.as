package {
import com.doublefx.as3.thread.api.CrossThreadDispatcher;
import com.doublefx.as3.thread.api.Runnable;

import flash.events.Event;
import flash.events.ProgressEvent;
import flash.utils.ByteArray;

import fr.kikko.lab.ShineMP3Encoder;

public class BackWorker implements Runnable {
    private var mp3Encoder:ShineMP3Encoder;

    public var dispatcher:CrossThreadDispatcher;


    public function run(args:Array):void {
        const fileToEncode:ByteArray = args[0] as ByteArray;
        encode(fileToEncode);
    }

    protected function encode(fileToEncode:ByteArray):void {
        if (mp3Encoder == null) {
            mp3Encoder = new ShineMP3Encoder(fileToEncode);
            mp3Encoder.addEventListener(Event.COMPLETE, encodeComplete);
            mp3Encoder.addEventListener(ProgressEvent.PROGRESS, onProgress);
            mp3Encoder.start();
        }
    }

    protected function onProgress(event:ProgressEvent):void {
        dispatcher.dispatchProgress(event.bytesLoaded, event.bytesTotal);
    }

    protected function encodeComplete(event:Event):void {
        dispatcher.dispatchResult(mp3Encoder.mp3Data);
    }
}
}