using System;
using System.Linq;
using System.Text;
using System.Collections.Generic;
using System.Web.Mvc;
using System.Web.Routing;
using System.Diagnostics;

using CE.Utils;

namespace CasinoEngine
{
    // Note: For instructions on enabling IIS6 or IIS7 classic mode, 
    // visit http://go.microsoft.com/?LinkId=9394801

    public class MvcApplication : System.Web.HttpApplication
    {
        public static void RegisterRoutes(RouteCollection routes)
        {
            routes.IgnoreRoute("{resource}.axd/{*pathInfo}");
            routes.IgnoreRoute("node");

            RouteTable.Routes.MapRoute(
                "XmlFeeds",
                "XmlFeeds/{action}/{apiUsername}",
                new { controller = "XmlFeeds", apiUsername = UrlParameter.Optional }
            );

            RouteTable.Routes.MapRoute(
                "Api",
                "Api/{action}/{apiUsername}",
                new { controller = "Api", apiUsername = UrlParameter.Optional }
            );

            RouteTable.Routes.MapRoute(
                "Loader",
                "Loader/{action}/{domainID}/{id}/",
                new { controller = "Loader", action = "Start", id = UrlParameter.Optional }
            );


            RouteTable.Routes.MapRoute(
                "Configuration",
                "Configuration/{domainID}/{action}",
                new { controller = "Configuration", action = "Index", domainID = "0" }
            );

            RouteTable.Routes.MapRoute(
                "VendorManagement",
                "VendorManagement/{domainID}/{action}",
                new { controller = "VendorManagement", action = "Index", domainID = "0" }
            );

            RouteTable.Routes.MapRoute(
                "LiveCasinoTableManagement",
                "LiveCasinoTableManagement/{domainID}/{action}",
                new { controller = "LiveCasinoTableManagement", action = "Index", domainID = "0" }
            );

            RouteTable.Routes.MapRoute(
                "GameManagement",
                "GameManagement/{domainID}/{action}",
                new { controller = "GameManagement", action = "Index", domainID = "0" }
            );

            RouteTable.Routes.MapRoute(
                "GameMonitor",
                "GameMonitor/{domainID}/{action}",
                new { controller = "GameMonitor", action = "Index", domainID = "0" }
            );

            RouteTable.Routes.MapRoute(
                "Logs",
                "Logs/{domainID}/{action}",
                new { controller = "Logs", action = "Index", domainID = "0" }
            );

            RouteTable.Routes.MapRoute(
                "JackpotManagement",
                "JackpotManagement/{domainID}/{action}",
                new { controller = "JackpotManagement", action = "Index", domainID = "0" }
            );

            RouteTable.Routes.MapRoute(
                "Cache",
                "Cache/{action}",
                new { controller = "Cache", action = "Index" }
            );

            RouteTable.Routes.MapRoute(
                "GameHistory",
                "GameHistory/{domainID}/{action}",
                new { controller = "GameHistory", action = "Index", domainID = "0" }
            );

            RouteTable.Routes.MapRoute(
                "Game",
                "Game/{action}/{domainID}/{id}/{language}",
                new { controller = "Game", action = "Information", language = UrlParameter.Optional }
            );

            RouteTable.Routes.MapRoute(
                "ContentProviderManagement",
                "ContentProviderManagement/{domainID}/{action}",
                new { controller = "ContentProviderManagement", action = "Index", domainID = "0" }
            );

            RouteTable.Routes.MapRoute(
                "RestfulAPI",
                "RestfulAPI/{action}/{apiUsername}",
                new { controller = "RestfulAPI", apiUsername = UrlParameter.Optional }
            );

            RouteTable.Routes.MapRoute(
                "Health",
                "Health/{action}",
                new { controller = "Health", action = "Index"}
            );

            RouteTable.Routes.MapRoute(
                "GameError",
                "{controller}/{action}/{*param}",
                new { controller = "Game", action = "Error" }
            );
            // This route should be last one in list, because it contains {*params}, and routes below it can work not correctly
        }


        protected void Application_Start()
        {
            AreaRegistration.RegisterAllAreas();
            base.Error += Application_Error;

            if (Environment.ProcessorCount > 1)
            {
                List<int> cpus = new List<int>();
                for (int i = 0; i < Environment.ProcessorCount - 1; i++)
                    cpus.Add(i);
                SetProcessorAffinity(cpus.ToArray());
            }

            RegisterRoutes(RouteTable.Routes);

            CE.BackendThread.ChangeNotifier.Init();
            CE.BackendThread.ScalableThumbnailProcessor.Begin();
        }


        protected void Application_Error(object sender, EventArgs e)
        {
            Exception ex = Server.GetLastError();

            Logger.Exception(ex);

            // If this is an error in AJAX request, return friendly error message
            if (Request.AcceptTypes != null &&
                Request.AcceptTypes.FirstOrDefault(t => string.Compare(t, "application/json", true) == 0) != null)
            {
                Server.ClearError();

                Response.Clear();
                Response.ClearHeaders();
                Response.ContentType = "application/json";
                Response.Write(string.Format("{{\"success\":false, \"error\":\"{0}\"}}", ex.Message.SafeJavascriptStringEncode() ));
                Response.Flush();
                Response.End();
                return;
            }

            Server.ClearError();

            Response.Clear();
            Response.ContentType = "text/html";

            StringBuilder sb = new StringBuilder();
            sb.Append(@"<!DOCTYPE html PUBLIC ""-//W3C//DTD XHTML 1.0 Transitional//EN"" ""http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd""><head>
<style type=""text/css"">
h1 { color:#FF0000; }
h2 { color:#990000; }
h3 { color:#660000; }
h4 { color:#330000; }
h5 { color:#000000; }
</style>
</head><body>"
                );

            Exception exception = null;
            sb.AppendLine("<!--");
            do
            {
                sb.AppendFormat("{0}", ex.Message);
                sb.AppendFormat("\r\nStack Track:\r\n{0}\r\n\r\n", ex.StackTrace);

                if (exception == null)
                    exception = ex as GmException;
                if (exception == null)
                    exception = ex as CeException;
                if (exception == null)
                    exception = ex as UnauthorizedAccessException;

                ex = ex.InnerException;
            } while (ex != null);
            sb.AppendLine("\n--></head><body>");

            if (exception != null)
                sb.AppendFormat("<h3 style=\"color:red\">{0}</h3>"
                    , exception.Message
                    );
            else
                sb.AppendFormat("<h3 style=\"color:red\">Error occured at {0} {1}.</h3>"
                    , DateTime.Now
                    , System.Environment.MachineName
                    );

            sb.Append(@"</body></html>");


            Response.Write(sb.ToString());
            Response.Flush();
            Response.End();
        }

        /// <summary>
        /// Sets the processor affinity
        /// </summary>
        /// <param name="cpus">A list of CPU numbers. The values should be
        /// between 0 and <see cref="Environment.ProcessorCount"/>.</param>
        static void SetProcessorAffinity(params int[] cpus)
        {
            if (cpus == null)
                throw new ArgumentNullException("cpus");
            if (cpus.Length == 0)
                throw new ArgumentException("You must specify at least one CPU.", "cpus");

            // Supports up to 64 processors
            long cpuMask = 0;
            foreach (int cpu in cpus)
            {
                if (cpu < 0 || cpu >= Environment.ProcessorCount)
                    throw new ArgumentException("Invalid CPU number.");

                cpuMask |= 1L << cpu;
            }

            Process.GetCurrentProcess().ProcessorAffinity = new IntPtr(cpuMask);
        }

    }
}