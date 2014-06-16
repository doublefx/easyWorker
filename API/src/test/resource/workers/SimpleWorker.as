package workers {
import com.doublefx.as3.thread.api.CrossThreadDispatcher;
import com.doublefx.as3.thread.api.Runnable;

// Don't need to extend Sprite anymore.
public class SimpleWorker implements Runnable {

    /**
     * Mandatory declaration if you want your Worker be able to communicate.
     * This CrossThreadDispatcher is injected at runtime.
     */
    public var dispatcher:CrossThreadDispatcher;

    public function add(v1:Number, v2:Number):Number {
        return v1 + v2;
    }

    // Implements Runnable interface
    public function run(args:Array):void {
        dispatcher.dispatchResult(add(args[0], args[1]));
    }
}
}