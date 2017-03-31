using System;
using System.Web.Mvc;
using CM.Content;
using CM.db;
using CM.db.Accessor;
using CM.Sites;
using CM.State;
using CM.Web;
using GmCore;
using System.Net;
using System.IO;
using System.Text;
using GamMatrix.CMS.Controllers.Shared;

namespace GamMatrix.CMS.Controllers.Kirsikka
{
    [HandleError]
    [ControllerExtraInfo(DefaultAction = "Index")]
    public class KirsikkaContactUsController : ContactUsController
    {
        [HttpPost]
        public override ActionResult Send(string email, string name, string subject, string content, string captcha)
        {
            if (!CheckCaptcha(captcha))
                return this.Json(new { @success = false, @error = Metadata.Get("/Components/_Captcha_ascx.Captcha_Invalid") });

            // send the email
            try
            {
                HttpWebRequest request = HttpWebRequest.Create(Metadata.Get("/ContactUs/_InputView_ascx.URL_SupportSystem")) as HttpWebRequest;
                if (request == null)
                    return this.Json(new { success = false, error = "bad request" });

                request.Headers.Add("X-API-Key", Metadata.Get(string.Format("/ContactUs/_InputView_ascx.{0}_APIKey", HttpContext.Server.MachineName.Replace(" ", string.Empty))));
                request.Method = "POST";

                string strJson = string.Format("{{\"name\": \"{0}\",\"email\": \"{1}\",\"subject\": \"{2}\",\"message\": \"data:text/html,{3}\"}}",
                name,
                email,
                subject,
                content);

                using (Stream stream = request.GetRequestStream())
                {
                    byte[] buffer = Encoding.UTF8.GetBytes(strJson);
                    stream.Write(buffer, 0, buffer.Length);
                    stream.Flush();
                }
                HttpWebResponse response = request.GetResponse() as HttpWebResponse;
                if (response!=null && response.StatusCode == HttpStatusCode.Created)
                    return this.Json(new { success = true });
                else
                    return this.Json(new { success = false, error = "bad request" });
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { success = false, error = GmException.TryGetFriendlyErrorMsg(ex)+ ":" + HttpContext.Server.MachineName.Replace(" ", string.Empty) });
            }
        }
    }
}
