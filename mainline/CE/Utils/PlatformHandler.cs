using System.Text.RegularExpressions;
using System.Web;

namespace CE.Utils
{
    public class PlatformHandler
    {
        public static bool IsMobile
        {
            get{
                return isTarget(true);
            }            
        }
        
        private static bool isTarget(bool targetIsMobile)
        {
            try
            {
                string userAgent = HttpContext.Current.Request.UserAgent;
                if (Regex.IsMatch(userAgent, @"\biPad\b", RegexOptions.Compiled | RegexOptions.CultureInvariant))
                    return targetIsMobile; // iPad

                if (Regex.IsMatch(userAgent, @"\biPhone\b", RegexOptions.Compiled | RegexOptions.CultureInvariant))
                    return targetIsMobile; //iPhone

                if (Regex.IsMatch(userAgent, @"\bAndroid\b", RegexOptions.Compiled | RegexOptions.CultureInvariant))
                    return targetIsMobile; // Android;

                if (Regex.IsMatch(userAgent, @"\bWindows(\s+)Phone(\s+)OS(\s+)7", RegexOptions.Compiled | RegexOptions.CultureInvariant))
                    return targetIsMobile; // WP7;

                if (Regex.IsMatch(userAgent, @"\bWindows(\s+)Phone(\s+)8", RegexOptions.Compiled | RegexOptions.CultureInvariant))
                    return targetIsMobile; // WP8;

                if (Regex.IsMatch(userAgent, @"\bWindows(\s+)Phone(\s+)8\.[1-9]+", RegexOptions.Compiled | RegexOptions.CultureInvariant))
                    return !targetIsMobile; // WP81;

                //if (Regex.IsMatch(userAgent, @"\bWindows(\s+)NT(\s+)6\.[3-9]+", RegexOptions.Compiled | RegexOptions.CultureInvariant))
                //    return !targetIsMobile; //Windows81;
            }
            catch
            {
            }

            return !targetIsMobile;
        }
    }
}
