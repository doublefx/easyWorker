/**
 * User: Frederic THOMAS Date: 16/06/2014 Time: 22:22
 */
package {
import com.doublefx.as3.thread.ComplexThreadTest;
import com.doublefx.as3.thread.SimpleThreadTest;
import com.doublefx.as3.thread.ThreadTestBase;

[Suite]
[RunWith("org.flexunit.runners.Suite")]
public class TestSuite {

    public var testThreadWithNoRunnable:ThreadTestBase;
    public var simpleTestThread:SimpleThreadTest;
    public var complexTestThread:ComplexThreadTest;

}
}
