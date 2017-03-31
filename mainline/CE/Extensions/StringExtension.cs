using System.Collections.Generic;
using System.Text.RegularExpressions;

namespace CE.Extensions
{
    public static class StringExtension
    {
        private static readonly HashSet<string> TrueString = new HashSet<string>(new string[] { "YES", "ON", "OK", "TRUE", "1" });
        private static readonly HashSet<string> FalseString = new HashSet<string>(new string[] { "NO", "OFF", "FALSE", "0" });
        public static bool SafeParseToBool(this string text, bool defValue)
        {
            if (string.IsNullOrWhiteSpace(text))
                return defValue;
            string formattedInput = text.Trim().ToUpperInvariant();

            if (TrueString.Contains(formattedInput))
            {
                return true;
            }
            else if (FalseString.Contains(formattedInput))
            {
                return false;
            }
            else
            {
                return defValue;
            }
        }
    }
}
