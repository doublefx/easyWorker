/*
 * Copyright (c) 2014 Frédéric Thomas
 *
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

package infrastructure.thread.impl.util.db {
import flash.data.SQLConnection;
import flash.data.SQLResult;
import flash.data.SQLStatement;
import flash.filesystem.File;

public class Database {

    protected static var __dbPath:String;
    private static var __conn:SQLConnection;
    private static var __connectionName:String;

    public static function connect(dbPath:String, connectionName:String = null, throwError:Boolean = false):Boolean {
        var result:Boolean;

        if (!__conn) {
            __dbPath = dbPath;
            __connectionName = connectionName;
            trace(connectionName + ": Connecting DB: " + dbPath);
            __conn = new SQLConnection();

            var dbFile:File = new File(dbPath);

            try {
                __conn.open(dbFile);
                result = true;
                trace(__connectionName + ": The database was created / opened successfully.");
            } catch (error:Error) {
                if (throwError)
                    throw error;
                else {
                    traceError("connect", error);
                }
            }
        } else result = true;

        return result;
    }

    public static function close():void {
        if (__conn) {
            __conn.close();
            __conn = null;
            trace(__connectionName + ": The database was closed successfully.");
        }
    }

    public static function execute(stmt:SQLStatement, throwError:Boolean = false):SQLResult {
        stmt.sqlConnection = __conn;
        var result:SQLResult;

        try {
            stmt.execute();
            trace(__connectionName + ": SQL: " + stmt.text + " has been executed successfully.");

            result = stmt.getResult();

        } catch (error:Error) {
            if (throwError)
                throw error;
            else {
                traceError("execute", error, stmt.text);
            }
        }

        return result;
    }

    protected static function traceError(fctName:String, error:Error, sql:String = null):void {
        trace(__connectionName + ": function name: " + fctName + (sql != null) ? " SQL: " + sql : "");
        trace("Error message:", error.message);

        if (error["details"])
            trace("Details:", error["details"]);
    }
}
}
