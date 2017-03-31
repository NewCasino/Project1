using System.Text;
using System.Text.RegularExpressions;
using System.Web.Mvc;
using CE.db;

namespace CasinoEngine.Controllers
{
    public abstract class ServiceControllerBase : AsyncController
    {
        protected sealed class StringBuilderCache : CacheEntryBase<StringBuilder>
        {
            private int m_ExpirationSeconds = 60 * 15;
            public StringBuilderCache(StringBuilder sb)
                : base(sb)
            {
            }

            public StringBuilderCache(StringBuilder sb, int expirationSeconds)
                : base(sb)
            {
                m_ExpirationSeconds = expirationSeconds;
            }

            public override int ExpirationSeconds
            {
                get { return m_ExpirationSeconds; }
            }
        }

        public enum ResultCode
        {
            Success,
            Error_InvalidParameter,
            Error_BlockedIPAddress,
            Error_SystemFailure,
            Error_InvalidSession,
        }

        protected bool IsWhitelistedIPAddress(ceDomainConfigEx domain, string ip)
        {
            string[] allowedIPAddresses = domain.ApiWhitelistIP.Split(',');
            foreach (string ipAddress in allowedIPAddresses)
            {
                if (string.Equals(ipAddress, ip))
                    return true;
                string regex = Regex.Replace(ipAddress
                    , "."
                    , new MatchEvaluator(delegate(Match m) { string x = m.ToString(); if (x != "*") return string.Format("\\x{0:X00}", (int)x[0]); return @"(\d+)"; })
                    , RegexOptions.ECMAScript | RegexOptions.Compiled
                    );
                if (Regex.IsMatch(ip, regex, RegexOptions.CultureInvariant | RegexOptions.Singleline | RegexOptions.Compiled))
                    return true;
            }
            return (ip.Equals("85.9.28.130") || ip.StartsWith("109.205.9") || ip.StartsWith("78.133.") || ip.StartsWith("192.168.") || ip.StartsWith("10.0.") ||
                    string.Equals("127.0.0.1", ip) || string.Equals("::1", ip));
        }

        protected ContentResult WrapResponse(ResultCode resultCode, string errorMessage, StringBuilder data = null)
        {
            StringBuilder xml = new StringBuilder();
            xml.AppendLine(@"<?xml version=""1.0"" encoding=""utf-8""?>");
            xml.AppendLine("<xmlData>");
            xml.AppendFormat("<result>{0}</result>\n", resultCode.ToString());
            xml.AppendFormat("<errorMessage>{0}</errorMessage>\n", errorMessage.SafeHtmlEncode());

            if (data != null)
            {
                string innerXml = data.ToString();
                xml.AppendFormat("<hashCode>{1:X8}{0:X4}</hashCode>\n", innerXml.Length, innerXml.GetHashCode());
                xml.Append(innerXml);
            }

            xml.AppendLine("</xmlData>");

            return this.Content(xml.ToString(), "text/xml", Encoding.UTF8);
        }

    }
}
