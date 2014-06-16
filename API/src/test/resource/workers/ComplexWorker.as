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

    private function add(obj:TermsVo):Number {
        return obj.v1 + obj.v2;
    }

    // Implements Runnable interface
    public function run(args:Array):void {
        const values:TermsVo = args[0] as TermsVo;
        dispatcher.dispatchResult(add(values));
    }
}
}