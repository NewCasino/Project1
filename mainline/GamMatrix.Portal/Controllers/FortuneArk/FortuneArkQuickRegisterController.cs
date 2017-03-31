using CM.State;
using GamMatrix.CMS.Controllers.Shared;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Web.Mvc;

namespace GamMatrix.CMS.Controllers.FortuneArk
{
    public class FortuneArkQuickRegisterController : QuickRegistrationController
    {
        [HttpPost]
        public void VerifyCaptchaAsync(string captcha, string message)
        {
            AsyncManager.Parameters["captcha"] = captcha;
            AsyncManager.Parameters["message"] = message;
            try
            {
                string captchaToCompare = CustomProfile.Current.Get("captcha");
                //CustomProfile.Current.Set("captcha", null);
                AsyncManager.Parameters["isSuccess"] = string.Equals(captcha.Trim(), captchaToCompare, StringComparison.InvariantCultureIgnoreCase);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
            }
        }

        public JsonResult VerifyCaptchaCompleted(string captcha, string message)
        {
            return this.Json(new
            {
                @success = (bool)AsyncManager.Parameters["isSuccess"],
                @value = captcha,
                @error = message,
            });
        }
    }
}
