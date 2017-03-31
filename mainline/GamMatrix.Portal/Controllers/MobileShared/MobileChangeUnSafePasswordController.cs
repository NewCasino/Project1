using System.Web.Mvc;
using CM.Web;
using GamMatrix.CMS.Controllers.Shared;

namespace GamMatrix.CMS.Controllers.MobileShared
{
    [ControllerExtraInfo(DefaultAction = "Index")]
    public class MobileChangeUnSafePasswordController : ChangePwdController
    {
        public override string getSuccessView()
        {
            return "Success";
        }
    }
}
