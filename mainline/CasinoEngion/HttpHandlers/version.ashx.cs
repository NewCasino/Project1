using System;
using System.Linq;
using System.Reflection;
using System.Web;

namespace CasinoEngine.HttpHandlers
{
    /// <summary>
    /// Summary description for version
    /// </summary>
    public class version : IHttpHandler
    {

        public void ProcessRequest(HttpContext context)
        {
            string[] names = new string[] { "CE.dll", "GamMatrix.Infrastructure.dll", "CasinoEngine.dll" };
            Assembly[] assemblies = AppDomain.CurrentDomain.GetAssemblies();
            foreach (Assembly assembly in assemblies)
            {
                if (assembly.ManifestModule == null)
                    continue;

                string name = assembly.ManifestModule.Name;
                if (names.FirstOrDefault(n => string.Equals(name, n, StringComparison.InvariantCultureIgnoreCase)) == null)
                    continue;

                context.Response.Write(string.Format("{0} : v{1}\n", name, assembly.GetName().Version.ToString()));
            }

            context.Response.ContentType = "text/plain";
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