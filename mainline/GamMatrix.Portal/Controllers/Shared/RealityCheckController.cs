using CM.db;
using CM.db.Accessor;
using CM.Sites;
using CM.State;
using CM.Web;
using GamMatrixAPI;
using GmCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Web.Mvc;

namespace GamMatrix.CMS.Controllers.Shared
{
    [HandleError]
    [ControllerExtraInfo(DefaultAction = "Index")]
    public class RealityCheckController : ControllerEx
    {
        [HttpGet]
        [Protocol(Action = ProtocolAttribute.ProtocolAction.RequireHttps)]
        public ActionResult Index()
        {
            return View("Index");
        }

        [HttpPost]
        [CustomValidateAntiForgeryToken]
        public ActionResult SetRealityCheck(string realityCheckOption)
        {
            if (!CustomProfile.Current.IsAuthenticated)
                return View("Anonymous");

            try
            {
                using (GamMatrixClient client = GamMatrixClient.Get())
                {
                    SetUserRealityCheckRequest setUserRealityCheckRequest = client.SingleRequest<SetUserRealityCheckRequest>(new SetUserRealityCheckRequest()
                    {
                        UserID = CustomProfile.Current.UserID,
                        RealityCheckValue = realityCheckOption,
                    });
                }
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                this.ViewData["ErrorMessage"] = GmException.TryGetFriendlyErrorMsg(ex);
                return this.View("Error");
            }

            return this.View("Success");
        }
    }
}
