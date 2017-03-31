using System.Web.Mvc;
using CM.Web;
using GamMatrix.CMS.Controllers.MobileShared;

namespace GamMatrix.CMS.Controllers._777iBetMobile
{
    public class _777iBetMobileWithdrawController : MobileWithdrawController
    {
        [HttpGet]
        [Protocol(Action = ProtocolAttribute.ProtocolAction.RequireHttps)]
        public override ActionResult Index()
        {
            return Redirect(this.Url.RouteUrl("Withdraw", new { @action = "Account", @paymentMethodName = "LocalBank" }));
        }
    }
}
