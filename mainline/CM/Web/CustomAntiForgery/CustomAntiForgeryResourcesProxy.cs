using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CM
{
    public static class CustomAntiForgeryResources
    {
        public static string AntiForgeryToken_ValidationFailed
        {
            get {
                return "Anti forgery token invalid";
            }
        }

        public static string HttpContextUnavailable
        {
            get {
                return "HttpContext unavailable";
            }
        }
        public static string Common_NullOrEmpty
        {
            get {
                return "token is null";
            }
        }
        
    }
}
