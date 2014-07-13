package domain.vo {
[Bindable]
[RemoteClass(alias="domain.vo.DownloadFileDescriptor")]
public class DownloadFileDescriptor {
    public var fileUrl:String;
    public var fileTargetPath:String;
    public var progressPrecision:uint;
    public var bytesLoaded:Number = 0;
    public var bytesTotal:Number = 0;

    public function DownloadFileDescriptor(fileUrl:String = null, fileTarget:String = null, progressPrecision:uint = 0) {
        this.fileUrl = fileUrl;
        this.fileTargetPath = fileTarget;
        this.progressPrecision = progressPrecision;
    }
}
}