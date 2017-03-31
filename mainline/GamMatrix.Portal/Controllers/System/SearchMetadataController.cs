using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using System.Threading.Tasks;
using System.Web;
using System.Web.Mvc;
using CM.Content;
using CM.db;
using CM.Sites;
using CM.Web;

namespace GamMatrix.CMS.Controllers.System
{
    [HandleError]
    [ControllerExtraInfo(DefaultAction = "Index", ParameterUrl = "{distinctName}")]
    [SystemAuthorize( Roles = "CMS Domain Admin,CMS System Admin")]
    public class SearchMetadataController : ControllerEx
    {
        /// <summary>
        /// The class stores the search task information
        /// </summary>
        internal sealed class SearchTaskInfo
        {
            public string ID { get; set; }
            public string Content { get; set; }
            public cmSite Site { get; set; }
            public string Language { get; set; }
            public bool MatchWholeString { get; set; }
            public AutoResetEvent AutoResetEvent { get; private set; }
            public bool IsCompleted { get; set; }
            public Regex Regex { get; set; }
            public ConcurrentQueue<SearchResult> ResultQueue { get; private set; }

            public SearchTaskInfo()
            {
                this.IsCompleted = false;
                this.AutoResetEvent = new AutoResetEvent(false);
                this.ResultQueue = new ConcurrentQueue<SearchResult>();
            }
        }

        internal sealed class SearchResult
        {
            public string Html { get; set; }
            public string RelativePath { get; set; }
            public string Url { get; set; }
        }

        private static Dictionary<string, SearchTaskInfo> s_SearchTasks = new Dictionary<string, SearchTaskInfo>();

        /// <summary>
        /// Main view
        /// </summary>
        /// <param name="distinctName"></param>
        /// <returns></returns>
        [HttpGet]
        public ActionResult Index(string distinctName)
        {
            distinctName = distinctName.DefaultDecrypt();
            cmSite site = SiteManager.GetSiteByDistinctName(distinctName);
            if (site == null)
                throw new ArgumentException("distinctName");

            return View(site);
        }

        /// <summary>
        /// start the search
        /// </summary>
        /// <param name="distinctName"></param>
        /// <param name="content"></param>
        /// <param name="language"></param>
        /// <param name="matchWholeString"></param>
        /// <param name="caseSensitive"></param>
        /// <returns></returns>
        [HttpPost]
        [ValidateInput(false)]
        public RedirectResult StartSearch(string distinctName
            , string content
            , string language
            , bool matchWholeString
            , bool caseSensitive
            )
        {
            distinctName = distinctName.DefaultDecrypt();
            cmSite site = SiteManager.GetSiteByDistinctName(distinctName);
            if (site == null)
                throw new ArgumentException("distinctName");

            SearchTaskInfo info = new SearchTaskInfo()
            {
                ID = Guid.NewGuid().ToString(),
                Content = content,
                Site = site,
                Language = language,
                MatchWholeString = matchWholeString,
            };
            s_SearchTasks[info.ID] = info;

            StringBuilder pattern = new StringBuilder();
            if (matchWholeString)
                pattern.Append(@"\b");

            pattern.Append("(");
            foreach (char c in content)
            {
                pattern.AppendFormat(@"\u{0:X4}", (int)c);
            }
            pattern.Append(")");

            if (matchWholeString)
                pattern.Append(@"\b");

            RegexOptions options = RegexOptions.Multiline | RegexOptions.CultureInvariant | RegexOptions.Compiled;
            if( !caseSensitive )
                options |= RegexOptions.IgnoreCase;
            info.Regex = new Regex( pattern.ToString(), options);

            Task.Factory.StartNew(() => SearchProcess(info));

            string url = this.Url.Action("Result", new { @distinctName = distinctName.DefaultEncrypt(), @taskID = info.ID } );
            return this.Redirect(url);
        }

        [HttpGet]
        public ActionResult Result(string distinctName, string taskID )
        {
            distinctName = distinctName.DefaultDecrypt();
            cmSite site = SiteManager.GetSiteByDistinctName(distinctName);
            if (site == null)
                throw new ArgumentException("distinctName");

            this.ViewData["TaskID"] = taskID;
            return this.View("Result", site);
        }

        [HttpGet]
        public ActionResult GetResult(string distinctName, string taskID)
        {
            SearchTaskInfo info = s_SearchTasks[taskID];
            if (info == null)
                return this.Json(new { @success = false, @error = "Error, cannot the special task." }, JsonRequestBehavior.AllowGet);

            if (!info.IsCompleted)
                info.AutoResetEvent.WaitOne(10000);

            List<SearchResult> results = new List<SearchResult>();
            SearchResult result = null;
            while (info.ResultQueue.TryDequeue(out result))
            {
                results.Add(result);
            }

            return this.Json(new { @success = true, @isCompleted = info.IsCompleted, @results = results.ToArray() }, JsonRequestBehavior.AllowGet);
        }

        private static void SearchProcess(SearchTaskInfo info)
        {
            ContentTree contentTree = ContentTree.GetByDistinctName(info.Site.DistinctName, info.Site.TemplateDomainDistinctName);
            ContentNode node = contentTree.Root;
            SearchNode(info, node);
            info.IsCompleted = true;
            info.AutoResetEvent.Set();
        }

        private static void SearchNode(SearchTaskInfo info, ContentNode node)
        {
            foreach (var child in node.Children)
            {
                switch (child.Value.NodeType)
                {
                    case ContentNode.ContentNodeType.Metadata:
                        if( !child.Value.RelativePath.StartsWith("/Metadata/Settings", StringComparison.OrdinalIgnoreCase) )
                            SearchMetadataEntries(info, child.Value.RelativePath);
                        break;
                }

                SearchNode(info, child.Value);
            }
        }

        private static void SearchMetadataEntries(SearchTaskInfo info, string path)
        {
            Dictionary<string, ContentNode.ContentNodeStatus> entries = Metadata.GetAllEntries(info.Site, path);
            foreach (var entry in entries)
            {
                string metadataPath = string.Format( "{0}.{1}", path, entry.Key);

                // if searching default value, indicate dummy language code 00, and the method returns default value.
                string content = Metadata.Get(info.Site, metadataPath, info.Language.DefaultIfNullOrEmpty("00"));
                if (string.IsNullOrWhiteSpace(content))
                    continue;

                MatchCollection mc = info.Regex.Matches(content);
                if (mc.Count > 0)
                {
                    string rawValue = Metadata.ReadRawValue(info.Site, metadataPath, info.Language);
                    if (!Regex.IsMatch(rawValue, @"^(\[(\S*)metadata(\S*)\:(\S*))(.*?)(\])$", RegexOptions.Compiled | RegexOptions.IgnoreCase | RegexOptions.CultureInvariant))
                    {
                        StringBuilder html = new StringBuilder();

                        int lastIndex = 0;
                        foreach (Match m in mc)
                        {
                            html.Append(content.Substring(lastIndex, m.Index - lastIndex).SafeHtmlEncode());
                            html.AppendFormat("<span style=\"color:red\">{0}</span>", content.Substring(m.Index, m.Length).SafeHtmlEncode());
                            lastIndex = m.Index + m.Length;
                        }
                        if (lastIndex < content.Length)
                            html.Append(content.Substring(lastIndex).SafeHtmlEncode());

                        SearchResult result = new SearchResult()
                        {
                            Html = html.ToString(),
                            RelativePath = metadataPath,
                        };
                        result.Url = string.Format("/MetadataEditor/Index/{0}/{1}/?language={2}&key={3}"
                            , info.Site.DistinctName.DefaultEncrypt()
                            , path.DefaultEncrypt()
                            , HttpUtility.UrlEncode(info.Language)
                            , HttpUtility.UrlEncode(entry.Key)
                            );
                        info.ResultQueue.Enqueue(result);
                        info.AutoResetEvent.Set();
                    }
                    
                }
            }
        }
    }
}
