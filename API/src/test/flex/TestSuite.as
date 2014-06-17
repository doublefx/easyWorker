/*
 * Copyright (c) Frédéric Thomas 2014.
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

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
