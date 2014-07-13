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

package infrastructure.thread.impl.factory {
import domain.vo.DownloadFileDescriptor;

import flash.desktop.NativeApplication;
import flash.filesystem.File;
import flash.utils.Dictionary;

import infrastructure.thread.api.downloadFileWorker.IDownloader;
import infrastructure.thread.api.downloadFileWorker.IDownloadFileWorkerUIBinder;
import infrastructure.thread.impl.DownloadFileThread;
import infrastructure.thread.impl.util.RegisterUtil;
import infrastructure.thread.impl.util.db.Registry;

public class DownloadFileThreadFactory {
    public static const DATABASE_NAME:String = "DB.db";

    public static const FLEX_SDK:String = "FLEX_SDK";
    public static const GETFOLDERSIZE:String = "GETFOLDERSIZE";
    public static const UTORRENT:String = "UTORRENT";

    private static const FLEX_SDK_URL:String = "http://mirrors.ibiblio.org/apache/flex/4.12.1/binaries/apache-flex-sdk-4.12.1-bin.zip";
    private static const GETFOLDERSIZE_URL:String = "http://www.thummerer-software-design.de/download/GetFoldersize.zip";
    private static const UTORRENT_URL:String = "http://download-new.utorrent.com/endpoint/utorrent/os/windows/track/stable/";

    private static const FLEX_SDK_FILE_TARGET:String = "flexSDK_4.10.zip";
    private static const GETFOLDERSIZE_FILE_TARGET:String = "GetFoldersize.zip";
    private static const UTORRENT_FILE_TARGET:String = "utorrent.exe";

    private static var __cacheDir:File;
    private static var __initialized:Boolean = initialize();

    private static var __downloaders:Dictionary;

    public static function create(kind:String, bindTo:IDownloadFileWorkerUIBinder = null, ...decorators):IDownloader {
        var fileDescriptor:DownloadFileDescriptor;
        var fileTarget:File;
        var downloader:IDownloader;

        switch (kind) {

            case FLEX_SDK:
                fileTarget = __cacheDir.resolvePath(FLEX_SDK_FILE_TARGET);
                fileDescriptor = new DownloadFileDescriptor(FLEX_SDK_URL, fileTarget.nativePath, 1);
                downloader = bindTo ?
                        new DownloadFileThread(FLEX_SDK, fileDescriptor, bindTo.onProgress, bindTo.onError, bindTo.onCompleted) :
                        new DownloadFileThread(FLEX_SDK, fileDescriptor);
                break;

            case GETFOLDERSIZE:
                fileTarget = __cacheDir.resolvePath(GETFOLDERSIZE_FILE_TARGET);
                fileDescriptor = new DownloadFileDescriptor(GETFOLDERSIZE_URL, fileTarget.nativePath, 1);
                downloader = bindTo ?
                        new DownloadFileThread(GETFOLDERSIZE, fileDescriptor, bindTo.onProgress, bindTo.onError, bindTo.onCompleted) :
                        new DownloadFileThread(GETFOLDERSIZE, fileDescriptor);
                break;

            case UTORRENT:
                fileTarget = __cacheDir.resolvePath(UTORRENT_FILE_TARGET);
                fileDescriptor = new DownloadFileDescriptor(UTORRENT_URL, fileTarget.nativePath, 0);
                downloader = bindTo ?
                        new DownloadFileThread(UTORRENT, fileDescriptor, bindTo.onProgress, bindTo.onError, bindTo.onCompleted) :
                        new DownloadFileThread(UTORRENT, fileDescriptor);
                break;

            default:
                return null;
        }

        if (decorators.length && decorators[0] is Array)
            decorators = decorators[0];

        for each (var decorator:Class in decorators)
            downloader = new decorator(downloader);

        if (bindTo)
            bindTo.downloader = downloader;

        __downloaders[downloader.name] = downloader;

        return downloader;
    }

    private static function initialize():Boolean {
        // Initialize the Registry and the DownloadFileThread to use the application DataBase.
        DownloadFileThread.dbPath = File.applicationStorageDirectory.resolvePath(DATABASE_NAME).nativePath;
        Registry.connect(DownloadFileThread.dbPath, NativeApplication.nativeApplication.applicationID);

        RegisterUtil.registerClassAliases();
        createCache();

        __downloaders = new Dictionary(true);

        return true;
    }

    private static function createCache():void {
        __cacheDir = File.desktopDirectory.resolvePath("cache");
        if (!__cacheDir.exists)
            __cacheDir.createDirectory();
    }

    public static function finalize():void {

        for each (var downloader:IDownloader in __downloaders)
            downloader.terminate();

        Registry.close();
    }
}
}