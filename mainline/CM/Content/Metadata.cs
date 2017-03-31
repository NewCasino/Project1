using System;
using System.Collections;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Web;
using System.Web.Caching;
using System.Web.Hosting;
using System.Xml.Linq;
using BLToolkit.DataAccess;
using CM.db;
using CM.db.Accessor;
using CM.Sites;
using CM.State;
using GamMatrix.Infrastructure;
using System.Collections.Concurrent;

namespace CM.Content
{
    public static class Metadata
    {
        public static void ClearCache(cmSite site)
        {
            List<string> list = new List<string>();
            IDictionaryEnumerator enumerator = HttpRuntime.Cache.GetEnumerator();
            while (enumerator.MoveNext())
            {
                string key = enumerator.Key.ToString();
                if (key.StartsWith(string.Format("metadata_children_{0}_", site.ID)) ||
                    key.StartsWith(string.Format("metadata_{0}_", site.DistinctName)) ||
                    key.StartsWith(string.Format("snippet_{0}_", site.DistinctName)))
                {
                    list.Add(key);
                }
            }

            foreach (string key in list)
            {
                HttpRuntime.Cache.Remove(key);
            }
        }



        /// <summary>
        /// Read first available entry in given path
        /// </summary>
        /// <param name="paths"></param>
        /// <returns></returns>
        private static string ReadFirstAvailableEntry(List<string> paths)
        {
            foreach (string path in paths)
            {
                string physicalPath;
                FileInfo fileInfo;
                try
                {
                    physicalPath = HostingEnvironment.MapPath(path);
                    fileInfo = new FileInfo(physicalPath);
                    if (!fileInfo.Exists)
                        continue;
                }
                catch
                {
                    continue;
                }

                // verify the metadata is not disabled
                try
                {
                    string propertiesXml = Path.Combine(Path.GetDirectoryName(physicalPath), ".properties.xml");
                    XDocument doc = PropertyFileHelper.OpenReadWithoutLock(propertiesXml);
                    if (string.Compare(doc.Root.GetElementValue("IsDisabled", "false"), "true", true) == 0)
                        continue;
                }
                catch
                {
                }

                // if value is empty, then continue
                if (fileInfo.Length == 0L)
                    continue;
                string ret = WinFileIO.ReadWithoutLock(physicalPath);
                if (!string.IsNullOrWhiteSpace(ret))
                    return ret;
            }
            return string.Empty;
        }

        public static string ResolvePath(string currentMetadataPath, string path)
        {
            if (path.StartsWith("/"))
                return path;
            path = Regex.Replace(path, @"^((\./)*)", string.Empty, RegexOptions.Compiled);
            currentMetadataPath = Regex.Replace(currentMetadataPath, @"(\/\.(\w|\-|_)+)$", string.Empty, RegexOptions.Compiled);

            while (path.StartsWith("../"))
            {
                path = Regex.Replace(path, @"^(\.\./)", string.Empty, RegexOptions.Compiled);
                currentMetadataPath = Regex.Replace(currentMetadataPath, @"(\/(\w|\-|_)+)$", string.Empty, RegexOptions.Compiled);
            }
            if (!path.StartsWith("."))
                return string.Format("{0}/{1}", currentMetadataPath, path.TrimStart('/'));
            return string.Format("{0}{1}", currentMetadataPath, path);
        }


        private static string Parse(cmSite domain, string text, string lang, string currentMetadataPath, int level, List<string> dependedFiles)
        {
            if (string.IsNullOrWhiteSpace(text))
                return text;

            Dictionary<Match, string> parsedContent = new Dictionary<Match, string>();

            // [list-start:<path>] <content> [list-end]
            MatchCollection matches = Regex.Matches(text
                , @"\[(\s*)list\-start(\s*)\:(\s*)(?<path>(\w|\/|\-|\_|\.)+)(\s*)\](?<content>(.|\r|\n)*?)\[(\s*)list\-end(\s*)\]"
                , RegexOptions.Multiline | RegexOptions.ECMAScript | RegexOptions.Compiled | RegexOptions.IgnoreCase | RegexOptions.CultureInvariant
                );
            foreach (Match match in matches)
            {
                string content = match.Groups["content"].Value;
                string metadataPath = Metadata.ResolvePath(currentMetadataPath, match.Groups["path"].Value);

                StringBuilder sb = new StringBuilder();
                var children = Metadata.GetChildren(domain, metadataPath).Keys;
                foreach (var child in children)
                {
                    sb.Append(ParseTags(domain, content, lang, child, level, dependedFiles));
                }
                parsedContent[match] = sb.ToString();
            }

            foreach (Match match in parsedContent.Keys.OrderByDescending(m => m.Index))
            {
                text = text.Substring(0, match.Index) + parsedContent[match] + text.Substring(match.Index + match.Length);
            }

            return ParseTags(domain, text, lang, currentMetadataPath, level, dependedFiles);
        }

        // [metadata:htmlencode(/Metadata.LOGIN-MESSAGE)]
        // [metadata:scriptencode(/Metadata.LOGIN-MESSAGE)]
        // [metadata:value(/Metadata.LOGIN-MESSAGE)]  
        private static string ParseTags(cmSite domain, string text, string lang, string currentMetadataPath, int level, List<string> dependedFiles)
        {
            // max recursion level check
            if (level > 10)
                return string.Empty;

            Dictionary<Match, string> parsedContent = new Dictionary<Match, string>();

            MatchCollection matches = Regex.Matches(text
                , @"\[(\s*)metadata(\s*)\:(\s*)(?<method>((htmlencode)|(scriptencode)|(value)))(\s*)\((\s*)(?<path>(\w|\/|\-|\_|\.)+)(\s*)\)(\s*)\]"
                , RegexOptions.Multiline | RegexOptions.ECMAScript | RegexOptions.Compiled | RegexOptions.IgnoreCase | RegexOptions.CultureInvariant
                );
            foreach (Match match in matches)
            {
                string method = match.Groups["method"].Value.ToLower(CultureInfo.InvariantCulture);
                string metadataPath = Metadata.ResolvePath(currentMetadataPath, match.Groups["path"].Value);

                parsedContent[match] = Metadata.Get(domain, metadataPath, lang, false, true, level + 1, dependedFiles);
                switch (method)
                {
                    case "htmlencode": parsedContent[match] = parsedContent[match].SafeHtmlEncode(); break;
                    case "scriptencode": parsedContent[match] = parsedContent[match].SafeJavascriptStringEncode(); break;
                }
            }
            foreach (Match match in parsedContent.Keys.OrderByDescending(m => m.Index))
            {
                text = text.Substring(0, match.Index) + parsedContent[match] + text.Substring(match.Index + match.Length);
            }

            return text;
        }

        public static string Get(string path, bool useCache = true, bool parseTags = true, bool ignoreUKLicense = false)
        {
            cmSite domain = SiteManager.Current;
            string lang = null; //= //domain.DefaultCulture;
            if (HttpContext.Current != null)
            {
                lang = HttpContext.Current.GetLanguage();
            }
            if (lang == null)
            {
                lang = domain.DefaultCulture;
            }
            //return Metadata.Get(domain, path, lang, useCache, parseTags);
            if (!ignoreUKLicense && IsUKLicense)
            {
                if (path.EndsWith("_UKLicense", StringComparison.InvariantCultureIgnoreCase))
                    return Metadata.Get(domain, path, lang, useCache, parseTags);

                string temp = Metadata.Get(domain, path + "_UKLicense", lang, useCache, parseTags);
                return string.IsNullOrWhiteSpace(temp) ? Metadata.Get(domain, path, lang, useCache, parseTags) : temp;
            }
            else
            {
                return Metadata.Get(domain, path, lang, useCache, parseTags);
            }
        }

        public static string Get(string path, string lang, bool useCache = true, bool parseTags = true, bool ignoreUKLicense = false)
        {
            //return Metadata.Get(SiteManager.Current, path, lang, useCache, parseTags);

            if (!ignoreUKLicense && IsUKLicense)
            {
                if (path.EndsWith("_UKLicense", StringComparison.InvariantCultureIgnoreCase))
                    return Metadata.Get(SiteManager.Current, path, lang, useCache, parseTags);

                string temp = Metadata.Get(SiteManager.Current, path + "_UKLicense", lang, useCache, parseTags);
                return string.IsNullOrWhiteSpace(temp) ? Metadata.Get(SiteManager.Current, path, lang, useCache, parseTags) : temp;
            }
            else
            {
                return Metadata.Get(SiteManager.Current, path, lang, useCache, parseTags);
            }
        }

        public static string Get(cmSite domain, string path, string lang, bool useCache = true, bool parseTags = true, int level = 0, List<string> dependedFiles = null)
        {
            // fix the path to filesystem path
            string cacheKey = string.Format("metadata_{0}_{1}_{2}_{3}", domain.DistinctName, lang, parseTags ? 1 : 0, path);
            string value = HttpRuntime.Cache[cacheKey] as string;

            if (value != null && useCache)
            {
                return value;
            }

            path = Regex.Replace(path, @"([^\/]\.(\w|\-|_)+)$"
                , new MatchEvaluator(delegate (Match m) { string x = m.ToString(); return x[0].ToString() + "/" + x.Substring(1); })
                , RegexOptions.Compiled | RegexOptions.ECMAScript | RegexOptions.CultureInvariant
                );

            List<string> paths = new List<string>();
            if (!string.IsNullOrWhiteSpace(lang))
            {
                paths.Add(string.Format("~/Views/{0}/{1}.{2}", domain.DistinctName, path.TrimStart('/'), lang));
                if (!string.IsNullOrWhiteSpace(domain.TemplateDomainDistinctName))
                    paths.Add(string.Format("~/Views/{0}/{1}.{2}", domain.TemplateDomainDistinctName, path.TrimStart('/'), lang));
            }
            paths.Add(string.Format("~/Views/{0}/{1}", domain.DistinctName, path.TrimStart('/')));
            if (!string.IsNullOrWhiteSpace(domain.TemplateDomainDistinctName))
                paths.Add(string.Format("~/Views/{0}/{1}", domain.TemplateDomainDistinctName, path.TrimStart('/')));

            value = ReadFirstAvailableEntry(paths);

            if (dependedFiles == null)
                dependedFiles = new List<string>();

            if (parseTags)
            {
                value = Parse(domain, value, lang, path, level, dependedFiles);
            }

            dependedFiles.Add(string.Format("~/Views/{0}/{1}", domain.DistinctName, path.TrimStart('/')));
            if (!string.IsNullOrWhiteSpace(domain.TemplateDomainDistinctName))
                dependedFiles.Add(string.Format("~/Views/{0}/{1}", domain.TemplateDomainDistinctName, path.TrimStart('/')));
            if (!string.IsNullOrWhiteSpace(lang))
            {
                dependedFiles.Add(string.Format("~/Views/{0}/{1}.{2}", domain.DistinctName, path.TrimStart('/'), lang));
                if (!string.IsNullOrWhiteSpace(domain.TemplateDomainDistinctName))
                    dependedFiles.Add(string.Format("~/Views/{0}/{1}.{2}", domain.TemplateDomainDistinctName, path.TrimStart('/'), lang));
            }

            HttpRuntime.Cache.Insert(cacheKey
                , value
                , new CacheDependencyEx(dependedFiles.ToArray(), true)
                , DateTime.Now.AddHours(36)
                , Cache.NoSlidingExpiration
                , CacheItemPriority.NotRemovable
                , null
                );

            return value;
        }

        private static bool IsDisabled(string path)
        {
            // verify the metadata is not disabled
            try
            {
                string propertiesXml = Path.Combine(path, ".properties.xml");
                XDocument doc = PropertyFileHelper.OpenReadWithoutLock(propertiesXml);
                if (!string.Equals(doc.Root.GetElementValue("Type"), "Metadata", StringComparison.OrdinalIgnoreCase))
                    return true;
                return string.Equals(doc.Root.GetElementValue("IsDisabled", "false"), "true", StringComparison.OrdinalIgnoreCase);
            }
            catch
            {
                return true;
            }
        }

        private static bool IsInherited(string path)
        {
            // verify the metadata is inherited
            try
            {
                string propertiesXml = Path.Combine(path, ".properties.xml");
                XDocument doc = PropertyFileHelper.OpenReadWithoutLock(propertiesXml);
                if (!string.Equals(doc.Root.GetElementValue("Type"), "Metadata", StringComparison.OrdinalIgnoreCase))
                    return true;
                return string.Equals(doc.Root.GetElementValue("IsInherited", "false"), "true", StringComparison.OrdinalIgnoreCase);
            }
            catch
            {
                return true;
            }
        }

        private static void GetProperties(string path, out DateTime validFrom, out DateTime expiryTime,
            out bool availableForUKLicense, out bool availableForNonUKLicense)
        {
            // verify the metadata is not disabled
            try
            {
                string propertiesXml = Path.Combine(path, ".properties.xml");
                XDocument doc = PropertyFileHelper.OpenReadWithoutLock(propertiesXml);
                if (!string.Equals(doc.Root.GetElementValue("Type"), "Metadata", StringComparison.OrdinalIgnoreCase))
                {
                    validFrom = DateTime.MinValue;
                    expiryTime = DateTime.MaxValue;
                    availableForUKLicense = true;
                    availableForNonUKLicense = true;
                    return;
                }
                validFrom = ConvertHelper.ToDateTime(doc.Root.GetElementValue("ValidFrom"), DateTime.MinValue);
                expiryTime = ConvertHelper.ToDateTime(doc.Root.GetElementValue("ExpiryTime"), DateTime.MaxValue);
                if (expiryTime == DateTime.MinValue)
                    expiryTime = DateTime.MaxValue;
                availableForUKLicense = ConvertHelper.ToBoolean(doc.Root.GetElementValue("AvailableForUKLicense", "1"), true);
                availableForNonUKLicense = ConvertHelper.ToBoolean(doc.Root.GetElementValue("AvailableForNonUKLicense", "1"), true);
            }
            catch
            {
                validFrom = DateTime.MinValue;
                expiryTime = DateTime.MaxValue;
                availableForUKLicense = true;
                availableForNonUKLicense = true;
            }
        }

        /// <summary>
        /// Read the metadata children nodes in given path
        /// </summary>
        /// <param name="domain"></param>
        /// <param name="path"></param>
        /// <param name="useCache">Indicates if use cache</param>
        /// <returns>path -- inherited pairs</returns>
        private static Dictionary<string, bool> GetChildren(cmSite domain, string path, bool useCache = true)
        {
            Dictionary<string, bool> children;
            children = new Dictionary<string, bool>(StringComparer.OrdinalIgnoreCase);

            // read from template site first(if availiable)
            string physicalPath = HostingEnvironment.MapPath(
                   string.Format("~/Views/{0}/{1}", domain.TemplateDomainDistinctName, path.TrimStart('/'))
                   );
            if (!string.IsNullOrWhiteSpace(domain.TemplateDomainDistinctName) && Directory.Exists(physicalPath))
            {
                var dirs = Directory.EnumerateDirectories(physicalPath, "*", SearchOption.TopDirectoryOnly);
                foreach (string dir in dirs)
                {
                    if (Metadata.IsDisabled(dir)) continue;
                    string dirname = Path.GetFileName(dir);
                    children[string.Format("{0}/{1}", path.TrimEnd('/'), dirname)] = true;
                }
            }

            // read from own site
            physicalPath = HostingEnvironment.MapPath(
                    string.Format("~/Views/{0}/{1}", domain.DistinctName, path.TrimStart('/'))
                    );
            if (Directory.Exists(physicalPath))
            {
                var dirs = Directory.EnumerateDirectories(physicalPath, "*", SearchOption.TopDirectoryOnly);
                foreach (string dir in dirs)
                {
                    string dirname = Path.GetFileName(dir);
                    string key = string.Format("{0}/{1}", path.TrimEnd('/'), dirname);
                    if (Metadata.IsDisabled(dir))
                    {
                        if (children.ContainsKey(key))
                            children.Remove(key);
                        continue;
                    }
                    children[key] = false;
                }
            }

            return children;
        }



        public static string[] GetChildrenPaths(cmSite domain, string path, bool useCache = true, bool ignoreUKLicense = false)
        {
            string cacheKey = string.Format("metadata_children_{0}_{1}_{2}", domain.ID, path, IsUKLicense);
            string[] paths = HttpRuntime.Cache[cacheKey] as string[];
            if (useCache && paths != null)
                return paths;

            // sort
            List<string> dependedFiles = new List<string>();
            List<string> priority = new List<string>();
            {
                string orderList = null;
                string physicalPath = HostingEnvironment.MapPath(
                    string.Format("~/Views/{0}/{1}", domain.DistinctName, path.TrimStart('/'))
                    );
                dependedFiles.Add(physicalPath);
                physicalPath = Path.Combine(physicalPath, "_orderlist");
                if (!File.Exists(physicalPath))
                {
                    if (!string.IsNullOrEmpty(domain.TemplateDomainDistinctName))
                    {
                        physicalPath = HostingEnvironment.MapPath(
                            string.Format("~/Views/{0}/{1}", domain.TemplateDomainDistinctName, path.TrimStart('/'))
                            );
                        dependedFiles.Add(physicalPath);
                        physicalPath = Path.Combine(physicalPath, "_orderlist");
                    }
                }
                orderList = WinFileIO.ReadWithoutLock(physicalPath);
                if (orderList != null)
                {
                    priority = orderList.Split(',').Where(i => !string.IsNullOrEmpty(i)).ToList();
                }
            }

            Dictionary<string, bool> ret = GetChildren(domain, path);
            Dictionary<string, bool> tempDic = new Dictionary<string, bool>();
            {
                foreach (var item in priority)
                {
                    string key = string.Format("{0}/{1}", path.TrimEnd('/'), item);
                    if (ret.ContainsKey(key))
                    {
                        tempDic.Add(key, ret[key]);
                        ret.Remove(key);
                    }
                }
            }
            foreach (KeyValuePair<string, bool> item in ret)
            {
                tempDic.Add(item.Key, item.Value);
            }

            DateTime now = DateTime.Now;
            DateTime cacheExpiryTime = now.AddHours(1);
            List<string> temp = new List<string>();
            {
                foreach (KeyValuePair<string, bool> item in tempDic)
                {
                    DateTime validFrom;
                    DateTime expiryTime;
                    bool availableForUKLicense;
                    bool availableForNonUKLicense;

                    string physicalPath = HostingEnvironment.MapPath(
                                                string.Format("~/Views/{0}/{1}"
                                                , item.Value ? domain.TemplateDomainDistinctName : domain.DistinctName
                                                , item.Key.TrimStart('/'))
                                              );
                    if (IsInherited(physicalPath))
                        physicalPath = HostingEnvironment.MapPath(string.Format("~/Views/{0}/{1}", domain.TemplateDomainDistinctName, item.Key.TrimStart('/')));

                    Metadata.GetProperties(physicalPath, out validFrom, out expiryTime, out availableForUKLicense, out availableForNonUKLicense);

                    if (ignoreUKLicense
                        || (IsUKLicense && availableForUKLicense)
                        || (!IsUKLicense && availableForNonUKLicense))
                    {
                        if (now >= validFrom && now <= expiryTime)
                            temp.Add(item.Key);

                        if (cacheExpiryTime > validFrom && validFrom > now)
                            cacheExpiryTime = validFrom;

                        if (cacheExpiryTime > expiryTime && expiryTime > now)
                            cacheExpiryTime = expiryTime;
                    }
                }
            }

            HttpRuntime.Cache.Insert(cacheKey
                , temp.ToArray()
                , new CacheDependencyEx(dependedFiles.ToArray(), false)
                , cacheExpiryTime//, DateTime.Now.AddHours(1)
                , Cache.NoSlidingExpiration
                , CacheItemPriority.NotRemovable
                , null
                );

            return temp.ToArray();
        }

        public static string[] GetChildrenPaths(string path)
        {
            return GetChildrenPaths(SiteManager.Current, path);
        }


        /// <summary>
        /// Read the raw value from file, this method is used by the Metadata Editor
        /// </summary>
        /// <param name="domain"></param>
        /// <param name="path"></param>
        /// <param name="lang"></param>
        /// <returns></returns>
        public static string ReadRawValue(cmSite domain, string path, string lang = null)
        {
            // fix the path to filesystem path
            path = Regex.Replace(path, @"([^\/]\.(\w|\-|_)+)$"
                , new MatchEvaluator(delegate (Match m) { string x = m.ToString(); return x[0].ToString() + "/" + x.Substring(1); })
                , RegexOptions.Compiled | RegexOptions.ECMAScript
                );

            string postfix = string.IsNullOrWhiteSpace(lang) ? string.Empty : "." + lang;
            string physicalPath = HostingEnvironment.MapPath(
                string.Format("~/Views/{0}/{1}{2}", domain.DistinctName, path.TrimStart('/'), postfix)
                );
            if (!File.Exists(physicalPath) && !string.IsNullOrWhiteSpace(domain.TemplateDomainDistinctName))
                physicalPath = HostingEnvironment.MapPath(
                    string.Format("~/Views/{0}/{1}{2}", domain.TemplateDomainDistinctName, path.TrimStart('/'), postfix)
                );
            string rawValue = WinFileIO.ReadWithoutLock(physicalPath);
            if(rawValue != null)
            {
                return rawValue;
            }
            return string.Empty;
        }

        private static Regex nameRegex = new Regex(@"^\.(?<name>[^\.]+)$", RegexOptions.ECMAScript | RegexOptions.Compiled);
        public static Dictionary<string, ContentNode.ContentNodeStatus> GetAllEntries(cmSite domain, string path)
        {
            Dictionary<string, ContentNode.ContentNodeStatus> entries
                = new Dictionary<string, ContentNode.ContentNodeStatus>(StringComparer.OrdinalIgnoreCase);

            string physicalPath = HostingEnvironment.MapPath(
                    string.Format("~/Views/{0}/{1}", domain.DistinctName, path.TrimStart('/'))
                    );
            if (Directory.Exists(physicalPath))
            {
                var files = Directory.EnumerateFiles(physicalPath, ".*", SearchOption.TopDirectoryOnly);
                foreach (string file in files)
                {
                    string filename = Path.GetFileName(file);
                    Match match = nameRegex.Match(filename);
                    if (match.Success)
                    {
                        entries[match.Groups["name"].Value] = ContentNode.ContentNodeStatus.Normal;
                    }
                }
            }

            if (!string.IsNullOrWhiteSpace(domain.TemplateDomainDistinctName))
            {
                physicalPath = HostingEnvironment.MapPath(
                    string.Format("~/Views/{0}/{1}", domain.TemplateDomainDistinctName, path.TrimStart('/'))
                    );
                if (Directory.Exists(physicalPath))
                {
                    var files = Directory.EnumerateFiles(physicalPath, ".*", SearchOption.TopDirectoryOnly);
                    foreach (string file in files)
                    {
                        string filename = Path.GetFileName(file);
                        Match match = nameRegex.Match(filename);
                        if (match.Success)
                        {
                            if (entries.ContainsKey(match.Groups["name"].Value))
                                entries[match.Groups["name"].Value] = ContentNode.ContentNodeStatus.Overrode;
                            else
                                entries[match.Groups["name"].Value] = ContentNode.ContentNodeStatus.Inherited;
                        }
                    }
                }
            }

            return entries;
        }

        private static ConcurrentDictionary<string, Regex> patterns = new ConcurrentDictionary<string, Regex>();

        /// <summary>
        /// Get the metadata entries for special languages
        /// </summary>
        /// <param name="domain"></param>
        /// <param name="path"></param>
        /// <param name="lang"></param>
        /// <returns></returns>
        public static Dictionary<string, string> GetSpecialLanguageEntries(cmSite domain, string path, string lang)
        {
            Dictionary<string, string> entries
                = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            string physicalPath;
            if (!string.IsNullOrWhiteSpace(domain.TemplateDomainDistinctName))
            {
                physicalPath = HostingEnvironment.MapPath(
                    string.Format("~/Views/{0}/{1}", domain.TemplateDomainDistinctName, path.TrimStart('/'))
                    );
                if (Directory.Exists(physicalPath))
                {
                    var files = Directory.EnumerateFiles(physicalPath, ".*", SearchOption.TopDirectoryOnly);
                    foreach (string file in files)
                    {
                        Regex pattern;
                        if (!patterns.TryGetValue(lang, out pattern))
                        {
                            pattern = new Regex(string.Format(@"^\.(?<name>[^\.]+)\.{0}$", lang.Replace("-", "\\-")), RegexOptions.ECMAScript | RegexOptions.Compiled);
                            patterns[lang] = pattern;
                        }
                        string filename = Path.GetFileName(file);
                        Match match = pattern.Match(filename);
                        if (match.Success)
                        {
                            entries[match.Groups["name"].Value] = WinFileIO.ReadWithoutLock(file);
                        }
                    }
                }
            }

            physicalPath = HostingEnvironment.MapPath(
                    string.Format("~/Views/{0}/{1}", domain.DistinctName, path.TrimStart('/'))
                    );
            if (Directory.Exists(physicalPath))
            {
                var files = Directory.EnumerateFiles(physicalPath, ".*", SearchOption.TopDirectoryOnly);
                foreach (string file in files)
                {
                    Regex pattern;
                    if (!patterns.TryGetValue(lang, out pattern))
                    {
                        pattern = new Regex(string.Format(@"^\.(?<name>[^\.]+)\.{0}$", lang.Replace("-", "\\-")), RegexOptions.ECMAScript | RegexOptions.Compiled);
                        patterns[lang] = pattern;
                    }
                    string filename = Path.GetFileName(file);
                    Match match = pattern.Match(filename);
                    if (match.Success)
                    {
                        entries[match.Groups["name"].Value] = WinFileIO.ReadWithoutLock(file);
                    }
                }
            }

            return entries;
        }

        /// <summary>
        /// Write the metadata entry
        /// </summary>
        /// <param name="site"></param>
        /// <param name="path"></param>
        /// <param name="lang">If language is null, then default value is written</param>
        /// <param name="name"></param>
        /// <param name="value"></param>
        /// <returns></returns>
        public static bool Save(cmSite site, string path, string lang, string name, string value)
        {
            string postfix = string.IsNullOrWhiteSpace(lang) ? string.Empty : "." + lang;
            string physicalPath = HostingEnvironment.MapPath(
                    string.Format("~/Views/{0}/{1}/.{2}{3}", site.DistinctName, path.TrimStart('/').TrimEnd('/'), name, postfix)
                    );

            ContentTree.EnsureDirectoryExistsForFile(site, physicalPath);

            SqlQuery<cmRevision> query = new SqlQuery<cmRevision>();
            string filePath;
            string localFile;
            string metadataPath = path.TrimEnd('/') + "/." + name + postfix;

            if (File.Exists(physicalPath))
            {
                // nothing changed
                if (WinFileIO.ReadWithoutLock(physicalPath) == value)
                    return false;

                // if last revision not exist, backup first
                {
                    RevisionAccessor ra = DataAccessor.CreateInstance<RevisionAccessor>();
                    cmRevision revision = ra.GetLastRevision(site.ID, metadataPath);
                    if (revision == null || !File.Exists(Revisions.GetLocalPath(revision.FilePath)))
                    {
                        localFile = Revisions.GetNewFilePath(out filePath);
                        File.Copy(physicalPath, localFile);

                        revision = new cmRevision();
                        revision.Comments = string.Format("No revision found for [{0}], language=[{1}], make a backup.", name, lang.DefaultIfNullOrEmpty("default"));
                        revision.SiteID = site.ID;
                        revision.FilePath = filePath;
                        revision.Ins = DateTime.Now;
                        revision.RelativePath = metadataPath;
                        revision.UserID = CustomProfile.Current.UserID;
                        query.Insert(revision);
                    }
                }
            }
            else if (!string.IsNullOrWhiteSpace(site.TemplateDomainDistinctName))
            {
                string inheritedPath = HostingEnvironment.MapPath(
                    string.Format("~/Views/{0}/{1}/.{2}{3}", site.TemplateDomainDistinctName, path.TrimStart('/').TrimEnd('/'), name, postfix)
                    );
                if (File.Exists(inheritedPath))
                {
                    // nothing changed
                    if (WinFileIO.ReadWithoutLock(inheritedPath) == value)
                        return false;
                }
                else if (string.IsNullOrWhiteSpace(value))
                    return false;
            }
            else if (string.IsNullOrWhiteSpace(value))
                return false;

            using (FileStream fs = new FileStream(physicalPath, FileMode.OpenOrCreate, FileAccess.Write, FileShare.Delete | FileShare.ReadWrite))
            {
                fs.SetLength(0);
                using (StreamWriter sw = new StreamWriter(fs, Encoding.UTF8))
                {
                    sw.Write(value);
                }
            }

            // copy the file to backup
            localFile = Revisions.GetNewFilePath(out filePath);
            File.Copy(physicalPath, localFile);

            // save to cmRevision
            {
                cmRevision revision = new cmRevision();
                revision.Comments = string.Format("update the entry [{0}], language=[{1}].", name, lang.DefaultIfNullOrEmpty("default"));
                revision.SiteID = site.ID;
                revision.FilePath = filePath;
                revision.Ins = DateTime.Now;
                revision.RelativePath = metadataPath;
                revision.UserID = CustomProfile.Current.UserID;
                query.Insert(revision);
            }


            return true;
        }


        public static void Delete(cmSite domain, string path, string name)
        {
            string physicalPath = HostingEnvironment.MapPath(
                    string.Format("~/Views/{0}/{1}", domain.DistinctName, path.TrimStart('/').TrimEnd('/'))
                    );
            var files = Directory.EnumerateFiles(physicalPath, "." + name + "*", SearchOption.TopDirectoryOnly);
            foreach (string file in files)
            {
                string postfix = Path.GetFileName(file).Substring(("." + name).Length);
                if (string.IsNullOrEmpty(postfix) || postfix[0] == '.')
                    File.Delete(file);
            }
        }

        /// <summary>
        /// Create metadata directory
        /// </summary>
        /// <param name="site">Site</param>
        /// <param name="path">Path</param>
        public static bool CreateMetadata(cmSite site, string path)
        {
            string physicalPath = HostingEnvironment.MapPath(
                    string.Format("~/Views/{0}/{1}", site.DistinctName, path.TrimStart('/').TrimEnd('/'))
                    );
            if (!Directory.Exists(physicalPath))
            {
                Directory.CreateDirectory(physicalPath);
                string template = HostingEnvironment.MapPath("~/App_Data/metadata_source");
                string dest = Path.Combine(physicalPath, ".properties.xml");
                global::System.IO.File.Copy(template, dest, true);
                return true;
            }
            return false;
        }

        public static bool CopyMetadata(cmSite site, string fromPath, string toPath)
        {
            string[] fromPhysicalPaths = new string[2];
            fromPhysicalPaths[0] = HostingEnvironment.MapPath(
                    string.Format("~/Views/{0}/{1}", site.DistinctName, fromPath.TrimStart('/').TrimEnd('/'))
                    );
            fromPhysicalPaths[1] = HostingEnvironment.MapPath(
                    string.Format("~/Views/{0}/{1}", site.TemplateDomainDistinctName, fromPath.TrimStart('/').TrimEnd('/'))
                    );

            bool isFromValid = false;
            for (int i = 0; i < fromPhysicalPaths.Length; i++)
            {
                if (Directory.Exists(fromPhysicalPaths[i]))
                {
                    isFromValid = true;
                    break;
                }
            }

            if (!isFromValid)
                return false;

            string toPhysicalPath = HostingEnvironment.MapPath(
                    string.Format("~/Views/{0}/{1}", site.DistinctName, toPath.TrimStart('/').TrimEnd('/'))
                    );

            if (Directory.Exists(toPhysicalPath))
                return false;

            //create directory
            Directory.CreateDirectory(toPhysicalPath);

            for (var i = 0; i < fromPhysicalPaths.Length; i++)
            {
                string fromPhysicalPath = fromPhysicalPaths[i];
                if (!Directory.Exists(fromPhysicalPath))
                    continue;

                //copy .properties.xml
                string from = Path.Combine(fromPhysicalPath, ".properties.xml");
                string to = Path.Combine(toPhysicalPath, ".properties.xml");
                if (!global::System.IO.File.Exists(to))
                    global::System.IO.File.Copy(from, to);

                //copy entries
                //var languages = site.GetSupporttedLanguages();
                var files = Directory.EnumerateFiles(fromPhysicalPath, ".*", SearchOption.TopDirectoryOnly);
                foreach (string file in files)
                {
                    string filename = Path.GetFileName(file);
                    Match matchDefault = nameRegex.Match(filename);

                    /*
                     operator want to copy translations
                     from PMCSD-126  2017-03-02
                     */
                    //if (matchDefault.Success)   
                    //{
                    from = Path.Combine(fromPhysicalPath, filename);
                    to = Path.Combine(toPhysicalPath, filename);
                    if (!global::System.IO.File.Exists(to))
                        global::System.IO.File.Copy(from, to);
                    //}

                    //don't copy the translations
                    //foreach (var language in languages)
                    //{
                    //    string pattern = string.Format(@"^\.(?<name>[^\.]+)\.{0}$", language.LanguageCode.Replace("-", "\\-"));
                    //    Match matchSpecialLanguage = Regex.Match(filename, pattern, RegexOptions.ECMAScript | RegexOptions.Compiled);
                    //    if (matchSpecialLanguage.Success)
                    //    {
                    //        from = Path.Combine(fromPhysicalPath, filename);
                    //        to = Path.Combine(toPhysicalPath, filename);
                    //        if (!global::System.IO.File.Exists(to))
                    //            global::System.IO.File.Copy(from, to);
                    //    }
                    //}
                }
            }

            return true;
        }

        public static bool IsUKLicense
        {
            get
            {
                if (!SafeParseBoolString(Metadata.Get("Metadata/Settings.IsUKLicense", ignoreUKLicense: true), false))
                    return false;

                try
                {
                    string[] countryIDs = SafeParseArray(Metadata.Get("Metadata/Settings.UKLicense_CountryIDs", ignoreUKLicense: true));
                    return CheckUserCountryId(countryIDs);
                }
                catch (Exception ex)
                {
                    Logger.Exception(ex);
                    return false;
                }
            }
        }

        public static bool IsDKLicense
        {
            get
            {
                if (!SafeParseBoolString(Metadata.Get("Metadata/Settings.IsDKLicense", ignoreUKLicense: true), false))
                    return false;
                try
                {
                    var dkCountryId = Metadata.Get("Metadata/Settings.DKLicense_CountryIDs", ignoreUKLicense: true);
                    string[] countryIDs = null;
                    if (string.IsNullOrEmpty(dkCountryId))
                        countryIDs = new[] { "64" };
                    else
                        countryIDs = SafeParseArray(dkCountryId);

                    return CheckUserCountryId(countryIDs);
                }
                catch (Exception ex)
                {
                    Logger.Exception(ex);
                    return false;
                }
            }
        }

        private static bool CheckUserCountryId(string[] countryIDs)
        {
            int countryId = 0;
            if (!CustomProfile.Current.IsAuthenticated)
            {
                IPLocation ipLocation = IPLocation.GetByIP(HttpContext.Current.Request.GetRealUserAddress());
                countryId = ipLocation.CountryID;
            }
            else
            {
                countryId = CustomProfile.Current.UserCountryID;
            }
            return countryIDs.Contains(countryId.ToString(CultureInfo.InvariantCulture));

        }

        //private static Regex yesRegex = new Regex(@"(YES)|(ON)|(OK)|(TRUE)|(\1)", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant | RegexOptions.Compiled);
        //private static Regex noRegex = new Regex(@"(NO)|(OFF)|(FALSE)|(\0)", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant | RegexOptions.Compiled);

        private static readonly HashSet<string> TrueString = new HashSet<string>(new string[] { "YES", "ON", "OK", "TRUE", "1" });
        private static readonly HashSet<string> FalseString = new HashSet<string>(new string[] { "NO", "OFF", "FALSE", "0" });

        private static bool SafeParseBoolString(string text, bool defValue)
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

        private static string[] SafeParseArray(string text)
        {
            if (string.IsNullOrWhiteSpace(text))
                return new string[0];

            List<string> array = new List<string>();
            using (StringReader sr = new StringReader(text))
            {
                while (true)
                {
                    string item = sr.ReadLine();
                    if (item == null)
                        break;
                    if (!string.IsNullOrWhiteSpace(item))
                        array.Add(item.Trim());
                }
            }
            return array.ToArray();
        }


    }
}
