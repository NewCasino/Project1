using System;
using System.Text.RegularExpressions;
using CM.Content;

namespace CM.Web
{
    public class CustomAntiForgeryConfig
    {
        public static bool Enabled
        {
            get {
                return SafeParseBoolString(Metadata.Get("Metadata/Settings.AntiFakery_Enabled"), false);
            }
        }

        public static bool DebugMode
        {
            get
            {
                return SafeParseBoolString(Metadata.Get("Metadata/Settings.AntiFakery_DebugMode"), true);
            }
        }

        public static string Salt
        {
            get {
                return "EM_2015@";
            }
        }


        private static bool SafeParseBoolString(string text, bool defValue)
        {
            if (string.IsNullOrWhiteSpace(text))
                return defValue;

            text = text.Trim();

            if (Regex.IsMatch(text, @"(YES)|(ON)|(OK)|(TRUE)|(\1)", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant | RegexOptions.Compiled))
                return true;

            if (Regex.IsMatch(text, @"(NO)|(OFF)|(FALSE)|(\0)", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant | RegexOptions.Compiled))
                return false;

            return defValue;
        }
    }
}
