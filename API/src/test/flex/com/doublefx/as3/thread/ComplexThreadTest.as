/**
 * User: Frederic THOMAS Date: 16/06/2014 Time: 09:53
 */
package com.doublefx.as3.thread {
import com.doublefx.as3.thread.event.ThreadFaultEvent;
import com.doublefx.as3.thread.event.ThreadResultEvent;
import com.doublefx.as3.thread.namespace.thread_diagnostic;
import com.doublefx.as3.thread.util.ClassAlias;
import workers.*;
import workers.vo.TermsVo;

import org.flexunit.asserts.assertEquals;
import org.flexunit.async.Async;
import org.hamcrest.assertThat;

use namespace thread_diagnostic;

public class ComplexThreadTest extends SimpleThreadTest {

    [Before]
    override public function setUp():void {
        const extraDependencies:Vector.<ClassAlias> = new Vector.<ClassAlias>();
        extraDependencies[0] = new ClassAlias("workers.vo.TermsVo", TermsVo);

        _thread = new Thread(ComplexWorker, "complexRunnable", extraDependencies, loaderInfo, currentDomain);
    }

    [Test(description="Verify the name of the Thread")]
    override public function testName():void {
        assertEquals("Should be equal to 'complexRunnable'", _thread.name, "complexRunnable");
    }

    [Test(description="Verify dependencies")]
    override public function testDependenciesExistence():void {
        super.testDependenciesExistence();
    }

    [Test(description="Verify dependencies content")]
    override public function testDependenciesContent():void {
        const dependencies:Array = ["mx.core.DebuggableWorker",
            "com.doublefx.as3.thread.api.CrossThreadDispatcher",
            "com.doublefx.as3.thread.util.ClassAlias",
            "com.doublefx.as3.thread.event.ThreadFaultEvent",
            "com.doublefx.as3.thread.event.ThreadResultEvent",
            "com.doublefx.as3.thread.event.ThreadProgressEvent",
            "workers.ComplexWorker",
            "com.doublefx.as3.thread.api.Runnable",
            "workers.vo.TermsVo"];

        assertThat(Thread(_thread).dependencies.toArray(), arrayExact(dependencies));
    }

    [Test(description="Verify the Runnable class name")]
    override public function testRunnableClassName():void {
        assertEquals(Thread(_thread).runnableClassName, "workers.ComplexWorker");
    }

    [Test(async, description="Verify the Runnable 'run' method can be call with valide complex values")]
    override public function testStartThreadWithValidValues():void {
        _thread.addEventListener(ThreadResultEvent.RESULT, Async.asyncHandler(this, thread_resultHandler, 2000, null, thread_faultHandler), false, 0, true);
        _thread.addEventListener(ThreadFaultEvent.FAULT, thread_faultHandler);
        _thread.start(new TermsVo(1, 2));
    }

    [Ignore(description="Not valid in this context")]
    [Test(async, description="Verify the Runnable 'run' method can be call with invalide complex values")]
    override public function testStartThreadWithNotValidValues():void {
        super.testStartThreadWithNotValidValues();
    }
}
}
