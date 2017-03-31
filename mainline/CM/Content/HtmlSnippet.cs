using System;
using System.Collections.Generic;
using System.Text;
using System.Text.RegularExpressions;
using System.Web;
using System.Web.Script.Serialization;
using System.Web.Hosting;
using System.Web.Caching;
using System.IO;
using System.Globalization;

using CM.db;
using CM.Sites;
using GamMatrix.Infrastructure;
using Jint;
using Jint.Native;
using System.Collections.Concurrent;
using System.Threading;

namespace CM.Content
{
    public static class HtmlSnippet
    {
        internal sealed class PreparsedContentTag
        {
            internal int StartIndex { get; set; }
            internal int Length { get; set; }
            internal string Method { get; set; } // htmlencode / scriptencode / value
            internal string MetadataPath { get; set; }
        }
        internal sealed class PreparsedContent
        {
            internal string Content { get; set; }
            internal List<PreparsedContentTag> Tags { get; set; }
            internal List<string> DependedFiles { get; set; }

            internal PreparsedContent()
            {
                Tags = new List<PreparsedContentTag>();
                DependedFiles = new List<string>();
            }
        }

        private static string ServerSideJavascriptEnvironment
        {
            get
            {
                
                string cacheKey = "~/App_Data/server_side_environment.js";
                string template = HttpRuntime.Cache[cacheKey] as string;
                if (!string.IsNullOrEmpty(template))
                    return template;

                string file = HostingEnvironment.MapPath(cacheKey);
                template = WinFileIO.ReadWithoutLock(file);
                HttpRuntime.Cache.Insert(cacheKey
                    , template
                    , new CacheDependency(file)
                    , Cache.NoAbsoluteExpiration
                    , Cache.NoSlidingExpiration
                    );
                return template;
            }
        }

        public static string SafeHtmlEncode(string str)
        {
            if (string.IsNullOrEmpty(str)) return string.Empty;

            StringBuilder sb = new StringBuilder();
            foreach (char c in str)
            {
                uint code = (uint)c;
                if (c < 0x7F)
                {
                    if (c > 0x1F)
                    {
                        switch (code)
                        {
                            case 0x26: // &
                                sb.Append("&amp;");
                                break;

                            case 0x22: // "
                                sb.Append("&quot;");
                                break;

                            case 0x3c: // <
                                sb.Append("&lt;");
                                break;

                            case 0x3E: // >
                                sb.Append("&gt;");
                                break;

                            case 0x27: // '
                            case 0x5c: // \
                                {
                                    sb.AppendFormat("&#{0};", code);
                                    break;
                                }

                            default:
                                sb.Append(c);
                                break;
                        }
                    }
                    else
                    {
                        switch (code)
                        {
                            case 0x0A: // \r
                            case 0x0D: // \n
                                {
                                    sb.AppendFormat("&#{0};", code);
                                    break;
                                }

                            default:
                                break;
                        }
                    }
                }
                else
                    sb.AppendFormat("&#{0};", code);
            }

            return sb.ToString();
        }

        public static string SafeScriptEncode(string str)
        {
            if (string.IsNullOrEmpty(str)) return string.Empty;

            StringBuilder sb = new StringBuilder();
            foreach (char c in str)
            {
                int code = (int)c;
                if (code > 0 && c < 0x7F)
                {
                    if (c > 0x1F)
                    {
                        switch (code)
                        {
                            case 0x26: // &
                            case 0x22: // "
                            case 0x27: // '
                            case 0x5c: // \
                            case 0x3c: // <
                            case 0x3E: // >
                                {
                                    sb.AppendFormat("\\u{0:X4}", code);
                                    break;
                                }

                            default:
                                sb.Append(c);
                                break;
                        }
                    }
                    else
                    {
                        switch (code)
                        {
                            case 0x0A: // \r
                            case 0x0D: // \n
                                {
                                    sb.AppendFormat("\\u{0:X4}", code);
                                    break;
                                }

                            default:
                                break;
                        }
                    }
                }
                else
                    sb.AppendFormat("\\u{0:X4}", code);
            }


            return sb.ToString();
        }

        private static ConcurrentDictionary<int, ConcurrentQueue<JsValue>> functions = new ConcurrentDictionary<int, ConcurrentQueue<JsValue>>();
        public static JsValue Create(string template)
        {
            Engine javascriptEngine = new Engine();
            javascriptEngine.SetValue("_htmlEncode", new Func<string, string>(SafeHtmlEncode));
            javascriptEngine.SetValue("_scriptEncode", new Func<string, string>(SafeScriptEncode));
            javascriptEngine.Execute(ServerSideJavascriptEnvironment);
            return javascriptEngine
                .Execute("function fillTemplate(data) { " +
                "  var html='" + template.SafeJavascriptStringEncode() + "';\n" +
                "  return _parseTemplate(html, JSON.parse(data)); \n" +
                "}")
                .GetValue("fillTemplate");
        }

        private const int TEMPLATE_FUNCTIONS_PER_TEMPLATE = 10;
        private const int TEMPLATE_AQUIRE_FAILURE_DELAY_MS = 10;
        private const int TEMPLATE_AQUIRE_ATTEMPTS = 10;

        public static string Render(string template, string data, int attemptsLeft = TEMPLATE_AQUIRE_ATTEMPTS)
        {
            int templateHashCode = template.GetHashCode();
            if (!functions.ContainsKey(templateHashCode))
            {
                ConcurrentQueue<JsValue> queue = new ConcurrentQueue<JsValue>();
                for (int i = 0; i < TEMPLATE_FUNCTIONS_PER_TEMPLATE; i++)
                {
                    queue.Enqueue(Create(template));
                }
                functions[templateHashCode] = queue;
            }
            ConcurrentQueue<JsValue> functionQueue = functions[templateHashCode];
            JsValue function;
            if (functionQueue.TryDequeue(out function))
            {
                JsValue result = function.Invoke(new JsValue(data));
                functionQueue.Enqueue(function);
                return result.AsString();
            }
            else
            {
                if (attemptsLeft > 0)
                {
                    Thread.Sleep(TEMPLATE_AQUIRE_FAILURE_DELAY_MS);
                    return Render(template, data, attemptsLeft - 1);
                } else
                {
                    throw new Exception("Could not aquire template function");
                }
            }
        }

        public static string Populate(cmSite site, string lang, string path, object data = null, object config = null, bool isDataJson = false)
        {
            string template = HtmlSnippet.Get(site, lang, path, config);
            JavaScriptSerializer jss = new JavaScriptSerializer();
            string encodedData = null;
            if (isDataJson)
            {
                if (data != null)
                {
                    encodedData = data as string;
                } else
                {
                    encodedData = "{}";
                }
            }
            else
            {
                encodedData = jss.Serialize(data);
            }
            try
            {
                return Render(template, encodedData);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return ex.Message;
            }
        }

        private static PreparsedContent GetPreparsedContent(cmSite site, string path)
        {
            string cacheKey = string.Format("snippet_{0}_preparsed_{1}", site.DistinctName, path);
            PreparsedContent preparsedContent = HttpRuntime.Cache[cacheKey] as PreparsedContent;
            if (preparsedContent != null)
                return preparsedContent;
            
            preparsedContent = new PreparsedContent();

            List<string> paths = new List<string>();
            paths.Add(string.Format(CultureInfo.InvariantCulture, "~/Views/{0}/{1}", site.DistinctName, path.TrimStart('/')));
            if (!string.IsNullOrEmpty(site.TemplateDomainDistinctName))
                paths.Add(string.Format(CultureInfo.InvariantCulture, "~/Views/{0}/{1}", site.TemplateDomainDistinctName, path.TrimStart('/')));

            string content = null;
            foreach (string relativePath in paths)
            {
                string physicalPath = HostingEnvironment.MapPath(relativePath);
                preparsedContent.DependedFiles.Add(physicalPath);
                content = WinFileIO.ReadWithoutLock(physicalPath);
                if(content == null)
                    continue;
                break;
            }

            if (!string.IsNullOrEmpty(content))
            {
                // remove comments
                content = Regex.Replace(content
                    , @"(\<\!\-\-)(.*?)(\-\-\>)"
                    , string.Empty
                    , RegexOptions.Compiled | RegexOptions.CultureInvariant | RegexOptions.Singleline
                    );
                preparsedContent.Content = content;

                // parse tags
                string currentMetadataPath = Regex.Replace(path
                        , @"(\/[^\/]+)$"
                        , delegate(Match m) { return string.Format( CultureInfo.InvariantCulture, "/_{0}", Regex.Replace(m.ToString().TrimStart('/'), @"[^\w\-_]", "_", RegexOptions.Compiled)); }
                        , RegexOptions.Compiled);

                MatchCollection matches = Regex.Matches(content
                    , @"\[(\s*)metadata(\s*)\:(\s*)(?<method>((htmlencode)|(scriptencode)|(value)))(\s*)\((\s*)(?<path>(\w|\/|\-|\_|\.)+)(\s*)\)(\s*)\]"
                    , RegexOptions.Multiline | RegexOptions.ECMAScript | RegexOptions.Compiled | RegexOptions.IgnoreCase | RegexOptions.CultureInvariant
                    );
                foreach (Match match in matches)
                {
                    PreparsedContentTag tag = new PreparsedContentTag()
                    {
                        StartIndex = match.Index,
                        Length = match.Length,
                        Method = match.Groups["method"].Value.ToLowerInvariant(),
                        MetadataPath = Metadata.ResolvePath(currentMetadataPath, match.Groups["path"].Value)
                    };
                    preparsedContent.Tags.Add(tag);
                }
                preparsedContent.Tags.Sort((a, b) =>
                {
                    if (a.StartIndex > b.StartIndex)
                        return 1;
                    else if (a.StartIndex < b.StartIndex)
                        return -1;
                    else
                        return 0;
                });
            }

            HttpRuntime.Cache.Insert(cacheKey
                , preparsedContent
                , new CacheDependencyEx(preparsedContent.DependedFiles.ToArray(), false)
                , Cache.NoAbsoluteExpiration
                , Cache.NoSlidingExpiration
                , CacheItemPriority.NotRemovable
                , null
                );

            return preparsedContent;
        }

        public static string Get(cmSite site, string lang, string path, object config)
        {
            if (config != null)
            {
                JavaScriptSerializer jss = new JavaScriptSerializer();
                return string.Format(CultureInfo.InvariantCulture, "<# var config = {0}; #>\n{1}"
                    , jss.Serialize(config)
                    , Get( site, lang, path )
                    );
            }
            return Get(site, lang, path);
        }

        private static string Get(cmSite site, string lang, string path)
        {
            if (site == null)
                site = SiteManager.Current;
            if (string.IsNullOrEmpty(lang))
                lang = MultilingualMgr.GetCurrentCulture();

            string cacheKey = string.Format("snippet_{0}_{1}_{2}", site.DistinctName, lang, path);
            string value = HttpRuntime.Cache[cacheKey] as string;

            if (value != null)
                return value;

            PreparsedContent preparsedContent = GetPreparsedContent(site, path);
            StringBuilder content = new StringBuilder();

            int startIndex = 0;
            int endIndex = 0;
            int nextTagIndex = 0;

            PreparsedContentTag tag = null;
            if (!string.IsNullOrEmpty(preparsedContent.Content))
            {
                for (; ; )
                {
                    if (nextTagIndex < preparsedContent.Tags.Count)
                    {
                        tag = preparsedContent.Tags[nextTagIndex];
                        endIndex = tag.StartIndex;
                    }
                    else
                    {
                        tag = null;
                        endIndex = preparsedContent.Content.Length;
                    }

                    if (endIndex > startIndex)
                        content.Append(preparsedContent.Content.Substring(startIndex, endIndex - startIndex));

                    if (tag == null)
                        break;

                    string metadata = Metadata.Get(site, tag.MetadataPath, lang);
                    switch (tag.Method)
                    {
                        case "htmlencode":
                            content.Append(metadata.SafeHtmlEncode());
                            break;

                        case "scriptencode":
                            content.Append(metadata.SafeJavascriptStringEncode());
                            break;

                        default:
                            content.Append(metadata);
                            break;
                    }
                    
                    startIndex = tag.StartIndex + tag.Length;
                    nextTagIndex++;
                }
            }

            HttpRuntime.Cache.Insert(cacheKey
                , content
                , new CacheDependencyEx(preparsedContent.DependedFiles.ToArray(), false)
                , Cache.NoAbsoluteExpiration
                , Cache.NoSlidingExpiration
                , CacheItemPriority.NotRemovable
                , null
                );
            

            return content.ToString();
        }
    }
}
