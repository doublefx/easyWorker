/**
 * User: Frederic THOMAS Date: 16/06/2014 Time: 09:43
 */
package workers.vo {

[RemoteClass(alias="workers.vo.TermsVo")]
public class TermsVo {
    public var v1:uint;
    public var v2:uint;

    public function TermsVo(v1:uint = 0, v2:uint = 0) {
        this.v1 = v1;
        this.v2 = v2;
    }
}
}
