using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Script.Serialization;
using System.Configuration;

using LibGit2Sharp;

namespace CmsStyle.Publish
{
    /// <summary>
    /// Git 的摘要说明
    /// </summary>
    public class Git : IHttpHandler
    {
        string workingCopyPath = ConfigurationManager.AppSettings["Git.WorkingCopy.Path"];
        string svnUsername = ConfigurationManager.AppSettings["Git.Username"];
        string svnPassword = ConfigurationManager.AppSettings["Git.Password"];
 
        public void ProcessRequest(HttpContext context)
        {
            //git archive --format zip --output test.zip --remote=git@git.oschina.net:cnmud/test master 2

            context.Response.ContentType = "text/plain";
            context.Response.Write("Hello World");
        }

        private void Process()
        {
            using (var repo = new Repository(workingCopyPath))
            {
                var obj = repo.Lookup("cms-style");
                //obj.Sha 
            }
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