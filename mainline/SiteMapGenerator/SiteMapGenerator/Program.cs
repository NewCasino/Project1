using System;
using System.IO;
using System.Linq;
using System.Net;
using System.Text;
using System.Xml;
using System.Collections.Generic;
using System.Configuration;
using System.ServiceProcess;
using System.Text.RegularExpressions;
using System.Threading.Tasks;

namespace SiteMapGenerator
{
    static class Program
    {
        /// <summary>
        /// 应用程序的主入口点。
        /// </summary>
        static void Main()
        {
            /*ServiceBase[] ServicesToRun;
            ServicesToRun = new ServiceBase[] 
            { 
                new Service1() 
            };
            ServiceBase.Run(ServicesToRun);*/
            GenerateSiteMap();
        } 
        public static void GenerateSiteMap()
        {
            string logName = DateTime.Now.Year.ToString() + DateTime.Now.Month.ToString() + DateTime.Now.Day.ToString() + "errorlog.txt";
            WebClient client = null;
            try
            {
                client = new WebClient();

                string sites_xml = client.DownloadString(ConfigurationManager.AppSettings["GetSiteListUrl"] + "/_get_sites_info.ashx");
                XmlDocument xml = new XmlDocument();
                xml.LoadXml(sites_xml);
                XmlNodeList list = xml.SelectNodes("/Root/Sites/Site");
                foreach (XmlNode item in list)
                {
                    try
                    {
                        string host = item.SelectSingleNode("Url").InnerText;
                        XmlNodeList languages = item.SelectNodes("Languages/Language");
                        List<string> languageList = new List<string>();
                        foreach (XmlNode language in languages)
                        {
                            languageList.Add(language.InnerText);
                        }
                        string distinctName = item.SelectSingleNode("DistinctName").InnerText;

                        SiteMapHelper sitemapClient = new SiteMapHelper(host, distinctName, languageList);
                        sitemapClient.Start();
                    }
                    catch (Exception ex)
                    {
                        StreamWriter errorWriter = null;
                        try
                        {
                            errorWriter = new StreamWriter(File.Open(logName, FileMode.OpenOrCreate));
                            errorWriter.WriteLine("static GenerateSiteMap Method: " + ex.Message);
                            errorWriter.Flush();
                        }
                        catch
                        {
                        }
                        finally
                        {
                            if (errorWriter != null)
                            {
                                errorWriter.Close();
                                errorWriter.Dispose();
                            }
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                StreamWriter errorWriter = null;
                try
                {
                    errorWriter = new StreamWriter(File.Open(logName, FileMode.OpenOrCreate));
                    errorWriter.WriteLine("static GenerateSiteMap Method2: " + ex.Message);
                    errorWriter.Flush();
                }
                catch
                {
                }
                finally
                {
                    if (errorWriter != null)
                    {
                        errorWriter.Close();
                        errorWriter.Dispose();
                    }
                }
            }
            finally
            {
                if (client != null)
                {
                    client.Dispose();
                }
            }
            Console.WriteLine("game over...");
            Console.ReadLine();
        }
    }

    public class SiteMapHelper
    {
        public string Host { get; set; }
        public string DistinctName { get; set; }
        public List<string> LanguageList { get; set; }
        private List<string> LinkList = new List<string>();
        private List<string> ExceptList = new List<string>();

        public SiteMapHelper(string host, string distinctName, List<string> languages)
        {
            Host = host;
            DistinctName = distinctName;
            LanguageList = languages;
        }

        public void Start()
        {
            GetAllLinks(Host, LinkList, ExceptList);
            LinkList = LinkList.Except(ExceptList).Distinct<string>().ToList<string>();

            GenerateSiteMap(LinkList);
        }

        public void GetAllLinks(string url, List<string> linkList, List<string> exceptList)
        {
            string logName = DateTime.Now.Year.ToString() + DateTime.Now.Month.ToString() + DateTime.Now.Day.ToString() + "errorlog.txt";
            if (!(url.Contains("http://") || url.Contains("https://")))
            {
                url = "http://" + url;
            }

            WebClient client = null;
            try
            {
                client = new WebClient();
                string result = client.DownloadString(url);

                Regex linkRegex = new Regex(@"(?is)<a[^>]*?href=(['""]?)(?<url>[^'""\s>]+)\1[^>]*>(?<text>(?:(?!</?a\b).)*)</a>");

                string regex = "\\<(\\s*)meta(\\s+)name(\\s*)\\=(\\s*)\\\"robots\\\"(\\s+)([^\\<\\>]+(\\<\\%(.*?)\\%\\>)|[^\\>\\<]*)*?\\>";
                MatchCollection matches = Regex.Matches(result, regex, RegexOptions.IgnoreCase);

                if (matches.Count > 0)
                {
                    string tempurl = url.Replace("#", "").Replace("https://" + Host, "").Replace("http://" + Host, "").Replace(Host, "");
                    foreach (var language in LanguageList)
                    {
                        string lang = string.Format("/{0}/", language);
                        if (tempurl.Contains(lang))
                        {
                            tempurl = tempurl.Replace(lang, "/");
                            break;
                        }
                    }
                    foreach (Match match in matches)
                    {
                        if (match.Value.ToLowerInvariant().Contains("noindex") && !exceptList.Contains(tempurl))
                        {
                            exceptList.Add(tempurl);
                        }
                    }
                }

                MatchCollection linkCollection = linkRegex.Matches(result);

                foreach (Match href in linkCollection)
                {
                    string link = href.Groups["url"].Value.ToLowerInvariant();
                    link = link.Replace("#", "").Replace("https://" + Host, "").Replace("http://" + Host, "").Replace(Host, "");
                    if (string.IsNullOrEmpty(link) || string.Equals(link, "/") || link.Contains("http") || link.Contains("javascript") || link.LastIndexOf(".") > 0) continue;
                    foreach (var language in LanguageList)
                    {
                        string lang = string.Format("/{0}/", language);
                        if (link.Contains(lang))
                        {
                            link = link.Replace(lang, "/");
                            break;
                        }
                    }


                    if (!(linkList.Contains(link) || (link.EndsWith("/") && linkList.Contains(link.Substring(0, link.Length -1)))))
                    {
                        linkList.Add(link);
                        string domain = Host;
                        if (!Host.StartsWith("http://") && !Host.StartsWith("https://"))
                        {
                            domain = "http://" + Host;
                        }
                        GetAllLinks(string.Format("{0}{1}", domain, link), linkList, exceptList);
                    }
                }
            }
            catch (Exception ex) 
            {
                StreamWriter errorWriter = null;
                try
                {
                    errorWriter = new StreamWriter(File.Open(logName, FileMode.Append, FileAccess.Write));
                    errorWriter.WriteLine("GetAllLinks Method: " + url +" " + DateTime.Now.ToString());
                    errorWriter.WriteLine(ex.Message);
                    errorWriter.Flush();
                }
                catch
                {
                }
                finally
                {
                    if (errorWriter != null)
                    {
                        errorWriter.Close();
                        errorWriter.Dispose();
                    }
                }
            }
            finally
            {
                if (client != null)
                {
                    client.Dispose();
                }
            }
        }

        public void GenerateSiteMap(List<string> links)
        {
            string logName = DateTime.Now.Year.ToString() + DateTime.Now.Month.ToString() + DateTime.Now.Day.ToString() + "errorlog.txt";
            string sitemapTemplate = @"<?xml version=""1.0"" encoding=""UTF-8""?>
<urlset xmlns=""http://www.sitemaps.org/schemas/sitemap/0.9"" xmlns:xsi=""http://www.w3.org/2001/XMLSchema-instance"" xsi:schemaLocation=""http://www.sitemaps.org/schemas/sitemap/0.9 http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd"" xmlns:xhtml=""http://www.w3.org/1999/xhtml"">
    {0}
</urlset>";
            string urlTemplate = @"<url>
                                    <loc>{0}</loc>
                                    <changefreq>daily</changefreq>
                                    <priority>0.85</priority>
                                    {1}
                                  </url>";
            string xhtmlTemplate = @"<xhtml:link rel=""alternate"" hreflang=""{0}"" href=""{1}"" />";

            StringBuilder sbSitemap = new StringBuilder();
            StringBuilder sbUrl = new StringBuilder();
            StringBuilder sbXhtml = new StringBuilder();
            string domain = Host;
            if (!Host.StartsWith("http://") && !Host.StartsWith("https://"))
            {
                domain = "http://" + Host;
            }
            foreach (string language in LanguageList)
            {
                sbXhtml.AppendLine(string.Format(xhtmlTemplate
                                            , language
                                            , string.Format("{0}/{1}/", domain, language)));
            }
            foreach (string language in LanguageList)
            {
                sbUrl.AppendLine(string.Format(urlTemplate
                                        , string.Format("{0}/{1}/", domain, language)
                                        , sbXhtml.ToString()));
            }
            foreach (string link in links)
            {
                sbXhtml.Clear();
                foreach (string language in LanguageList)
                {
                    sbXhtml.AppendLine(string.Format(xhtmlTemplate, language, string.Format("{0}/{1}{2}", domain, language, link)));
                }
                foreach (string language in LanguageList)
                {
                    sbUrl.AppendLine(string.Format(urlTemplate
                                            , string.Format("{0}/{1}{2}", domain, language, link)
                                            , sbXhtml.ToString()));
                }
            }

            sbSitemap.AppendFormat(sitemapTemplate, sbUrl.ToString());
            string path = string.Format("{0}\\{1}", ConfigurationManager.AppSettings["BasePath"], DistinctName);

            if (!Directory.Exists(path))
            {
                Directory.CreateDirectory(path);
            }

            StreamWriter writer = null;
            FileStream file = null; 
            string configPath = path + "\\Metadata\\Settings.SitemapName";
            string metadataName = "sitemap.xml";
            try {
                if (File.Exists(configPath))
                { 
                    using (FileStream fs = File.OpenRead(configPath))
                    {
                        byte[] b = new byte[1024];
                        UTF8Encoding temp = new UTF8Encoding(true);
                        while (fs.Read(b, 0, b.Length) > 0)
                        {
                            metadataName = (temp.GetString(b));
                        }
                    }
                    if (!string.IsNullOrEmpty(metadataName) && metadataName.Length > 4)
                    {
                        metadataName = metadataName.Substring(0, (metadataName.Length - 4));
                    }
                    else {
                        metadataName = "sitemap";
                    }
                }
            }
            catch (Exception ex) {
                StreamWriter errorWriter = null;
                try
                {
                    errorWriter = new StreamWriter(File.Open(logName, FileMode.Append, FileAccess.Write));
                    errorWriter.WriteLine("Read configuation path: " + configPath + " " + DateTime.Now.ToString());
                    errorWriter.WriteLine(ex.Message);
                    errorWriter.Flush();
                }
                catch
                {
                } 
            }
            try
            {
                file = File.Open(path + "\\" + metadataName + ".xml", FileMode.Create);
                writer = new StreamWriter(file);
                writer.Write(sbSitemap.ToString());
                writer.Flush();
                file.Close();

                file = File.Open(path + "\\sitemap_log.txt", FileMode.Create);
                writer = new StreamWriter(file);
                writer.WriteLine( metadataName +".xml" + " file is updated at: " + DateTime.Now.ToString());
                writer.Flush();
                file.Close();
            }
            catch (Exception ex)
            {
                StreamWriter errorWriter = null;
                try
                {
                    errorWriter = new StreamWriter(File.Open(logName, FileMode.Append, FileAccess.Write));
                    errorWriter.WriteLine("GenerateSiteMap Method: " + DateTime.Now.ToString());
                    errorWriter.WriteLine(ex.Message);
                    errorWriter.Flush();
                }
                catch
                {
                }
                finally
                {
                    if (errorWriter != null)
                    {
                        errorWriter.Close();
                        errorWriter.Dispose();
                    }
                }
            }
            finally
            {
                if (file != null)
                {
                    file.Close();
                    file.Dispose();
                }
            }


        }

    }
}
