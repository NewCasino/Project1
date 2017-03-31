using System.Web.Mvc;
using CM.Web;
using GamMatrix.CMS.Controllers.MobileShared;

namespace GamMatrix.CMS.Controllers.Daebak88Mobile
{
    public class Daebak88MobileWithdrawController : MobileWithdrawController
    {
        [HttpGet]
        [Protocol(Action = ProtocolAttribute.ProtocolAction.RequireHttps)]
        public override ActionResult Index()
        {
            return Redirect(this.Url.RouteUrl("Withdraw", new { @action = "Account", @paymentMethodName = "LocalBank" }));//"/Withdraw/Account/LocalBank");
        }
    }
}
