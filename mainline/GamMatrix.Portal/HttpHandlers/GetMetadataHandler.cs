using System;
using System.Collections.Generic;
using System.Text;
using System.Text.RegularExpressions;
using System.Web;
using CM.Content;
using CM.Sites;

namespace GamMatrix.CMS.HttpHandlers
{
    /// <summary>
    /// Summary description for GetMetadataHandler
    /// </summary>
    public sealed class GetMetadataHandler : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            string path = context.Request.QueryString["path"];
            Match match = Regex.Match(path, @"(?<path>[^\.]+)(\.(?<name>(\w+)))?", RegexOptions.Singleline | RegexOptions.Compiled);
            if (string.IsNullOrWhiteSpace(path))
                throw new HttpException(404, "Page not found.");


            StringBuilder sb = new StringBuilder();
            string type = context.Request.QueryString["type"].DefaultIfNullOrEmpty("text").ToLowerInvariant();
            string contentType = "text/plain";
            switch (type)
            {
                case "xml":
                    sb.AppendLine("<?xml version=\"1.0\"?>");
                    ReadXmlData(match.Groups["path"].Value, sb);
                    contentType = "text/xml";
                    break;
                case "html":
                    contentType = "text/html";
                    sb.Append(ProcessImages(Metadata.Get(path)).HtmlEncodeSpecialCharactors());
                    break;
                case "json":
                    contentType = "text/javascript";
                    ReadJsonData(path, sb);
                    break;
                case "jsonp":
                    string jsoncallback = context.Request.QueryString["jsoncallback"];
                    if (string.IsNullOrEmpty(jsoncallback))
                        sb.Append("Error: jsoncallback is not indicated");
                    else
                    {
                        contentType = "text/javascript";
                        sb.AppendFormat("{0}(", jsoncallback);
                        ReadJsonData(path, sb);
                        sb.Append(')');
                    }
                    break;

                default:
                    type = "text";
                    contentType = "text/javascript";
                    sb.Append(ProcessImages(Metadata.Get(path)));
                    break;
            }

            context.Response.ClearHeaders();
            context.Response.ContentType = contentType;
            context.Response.AddHeader("Content-Length", sb.Length.ToString());
            context.Response.Write(sb.ToString());
        }

        private void ReadXmlData(string path, StringBuilder sb)
        {
            Dictionary<string, ContentNode.ContentNodeStatus> dic = Metadata.GetAllEntries(SiteManager.Current, path);
            sb.AppendFormat("\n<metadata name=\"{0}\">", VirtualPathUtility.GetFileName(path).SafeHtmlEncode());
            foreach (var entry in dic)
            {
                sb.AppendFormat("\n<entry name=\"{0}\">{1}</entry>"
                    , entry.Key.SafeHtmlEncode()
                    , ProcessImages(Metadata.Get(string.Format("{0}.{1}", path, entry.Key))).SafeHtmlEncode()
                    );
            }

            string[] paths = Metadata.GetChildrenPaths(path);
            foreach (string subpath in paths)
            {
                ReadXmlData(subpath, sb);
            }
            sb.Append("\n</metadata>");
        }

        private void ReadJsonData(string path, StringBuilder sb)
        {
            sb.Append("{");
            Dictionary<string, ContentNode.ContentNodeStatus> dic = Metadata.GetAllEntries(SiteManager.Current, path);
            foreach (var entry in dic)
            {
                sb.AppendFormat("\"{0}\":\"{1}\","
                    , entry.Key.SafeJavascriptStringEncode()
                    , ProcessImages(Metadata.Get(string.Format("{0}.{1}", path, entry.Key))).SafeJavascriptStringEncode()
                    );
            }
            sb.Append("\"_children\":[");
            {
                string[] paths = Metadata.GetChildrenPaths(path);
                foreach (string subpath in paths)
                {
                    if (sb[sb.Length - 1] != '[')
                        sb.Append(',');
                    ReadJsonData(subpath, sb);
                }
            }
            sb.Append("]");
            sb.Append("}");
        }

        private string OnImageMatched(Match m)
        {
            if (m.Success)
            {
                if (m.Groups["src"].Value.StartsWith("/", StringComparison.CurrentCultureIgnoreCase) &&
                    !m.Groups["src"].Value.StartsWith("//:", StringComparison.CurrentCultureIgnoreCase) )
                {
                    string baseUrl = string.Format("http://{0}{1}"
                        , HttpContext.Current.Request.Url.Host
                        , (SiteManager.Current.HttpPort != 80) ? (":" + SiteManager.Current.HttpPort.ToString()) : string.Empty
                        );
                    if (string.Equals(HttpContext.Current.Request.QueryString["secure"], "true", StringComparison.OrdinalIgnoreCase))
                    {
                        baseUrl = string.Format("https://{0}{1}"
                            , HttpContext.Current.Request.Url.Host
                            , (SiteManager.Current.HttpsPort != 443) ? (":" + SiteManager.Current.HttpsPort.ToString()) : string.Empty
                            );
                    }

                    return m.Value.Insert(m.Groups["src"].Index - m.Index, baseUrl);
                }

                return m.Value;
            }
            return string.Empty;
        }

        private string ProcessImages(string html)
        {
            html = Regex.Replace(html
                , @"\<(\s*)img(\s+)([^\>]*?)src(\s*)\=(\s*)(?<quot>(\""|\'))(?<src>.+?)\k<quot>([^\>]+)\>"
                , new MatchEvaluator(this.OnImageMatched)
                , RegexOptions.Compiled | RegexOptions.Multiline | RegexOptions.ECMAScript | RegexOptions.IgnoreCase | RegexOptions.CultureInvariant
                );

            html = Regex.Replace(html
                , @"\burl(\s*)\((\s*)(?<src>[^\)\""\']+?)(\s*)\)"
                , new MatchEvaluator(this.OnImageMatched)
                , RegexOptions.Compiled | RegexOptions.Multiline | RegexOptions.ECMAScript | RegexOptions.IgnoreCase | RegexOptions.CultureInvariant
                );

            return html;
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