using System;
using System.Resources;
using System.Globalization;

namespace CM.Web
{
    public static class MvcResourcesProxy
    {
        private static ResourceManager _ResourceManager;


        public static string AntiForgeryToken_ValidationFailed
        {
            get
            {
                return MvcResourcesProxy.GetString("AntiForgeryToken_ValidationFailed");
            }
        }

        public static string Common_NullOrEmpty
        {
            get
            {
                return MvcResourcesProxy.GetString("Common_NullOrEmpty");
            }
        }

        public static string HttpContextUnavailable
        {
            get
            {
                return GetString("HttpContextUnavailable");
            }
        }

        public static string GetString(string key)
        {
            return _ResourceManager.GetString(key, CultureInfo.CurrentUICulture);
        }
    }
}
