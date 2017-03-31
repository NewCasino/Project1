using System.Web.Mvc;
using CM.Web;
using GamMatrix.CMS.Controllers.MobileShared;

namespace GamMatrix.CMS.Controllers.Ins999Mobile
{
    public class Ins999MobileWithdrawController: MobileWithdrawController
    {
        [HttpGet]
        [Protocol(Action = ProtocolAttribute.ProtocolAction.RequireHttps)]
        public override ActionResult Index()
        {
            return Redirect(this.Url.RouteUrl("Withdraw", new { @action = "Account", @paymentMethodName = "LocalBank" }));
        }
    }
}
