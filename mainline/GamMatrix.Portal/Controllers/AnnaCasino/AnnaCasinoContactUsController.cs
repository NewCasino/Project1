using System;
using System.Web.Mvc;
using CM.Web;
using GamMatrix.CMS.Controllers.Shared;
using GmCore;

namespace GamMatrix.CMS.Controllers.AnnaCasino
{
    [HandleError]
    [ControllerExtraInfo(DefaultAction = "Index")]
    public class AnnaCasinoContactUsController : ContactUsController
    {
        [HttpPost]
        public virtual ActionResult SendEx(string email, string name, string subject, string content)
        {
            // send the email
            try
            {
                SendEmailToUser(email, name, subject, content);
                return this.Json(new { success = true });
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { success = false, error = GmException.TryGetFriendlyErrorMsg(ex) });
            }
        }
    }
}
