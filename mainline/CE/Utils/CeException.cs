using System;

namespace CE.Utils
{
    public class CeException : Exception
    {
        private static string FormatMessage( string format, params object[] arguments )
        {
            if (arguments == null || arguments.Length == 0)
                return format;

            return string.Format(format, arguments);
        }

        public CeException(string format, params object[] arguments)
            : base(FormatMessage( format, arguments) )
        {
        }
    }
}
