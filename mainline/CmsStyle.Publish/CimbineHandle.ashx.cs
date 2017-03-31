using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Script.Serialization;
using System.Configuration;

namespace CmsStyle.Publish
{
    /// <summary>
    /// Handler 的摘要说明
    /// </summary>
    public class CimbineHandle : IHttpHandler
    {

        public void ProcessRequest(HttpContext context)
        {
            JavaScriptSerializer jss = new JavaScriptSerializer();
            string script=string.Empty;
            try
            {
                string[] targetDirs = new string[] { };
                if (!string.IsNullOrWhiteSpace(context.Request["target"]))
                {
                    if (context.Request["target"].Equals("all", StringComparison.InvariantCultureIgnoreCase))
                    {
                        targetDirs = new string[] { "" };
                    }
                    else
                        targetDirs = context.Request["target"].Split(new char[] { ',' }, StringSplitOptions.RemoveEmptyEntries);
                }
                foreach (string targetDir in targetDirs)
                {
                    CombineCSS.CombineCSSFile(targetDir);
                }

                script = jss.Serialize(new
                {
                    @success = true,
                    @error = string.Empty,
                });
            }
            catch (Exception ex)
            {
                script = jss.Serialize(new
                {
                    @success = false,
                    @error = ex.Message,
                });
            }
            context.Response.ContentType = "application/json";
            context.Response.AddHeader("Access-Control-Allow-Origin", "*");
            context.Response.Write(script);
        }

        public bool IsReusable
        {
            get
            {
                return false;
            }
        }
    }
}