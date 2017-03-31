using System;
using System.Configuration;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Diagnostics;
using System.Linq;
using System.ServiceProcess;
using System.Text;
using System.Threading.Tasks;
using System.Timers;
using System.Xml;
using System.Net;
using System.IO;

namespace SiteMapGenerator
{
    public partial class Service1 : ServiceBase
    {
        public Service1()
        {
            InitializeComponent();
        }

        protected override void OnStart(string[] args)
        {
            double delayTime = 1;

            double.TryParse(ConfigurationManager.AppSettings["DelayTime"], out delayTime);
            delayTime = delayTime * 1000;
            Timer timer = new Timer(delayTime);
            timer.Elapsed += GenerateSiteMap;
            timer.AutoReset = true;
            timer.Enabled = true; 
        }

        protected override void OnStop()
        {
        }

        protected void GenerateSiteMap(object source, System.Timers.ElapsedEventArgs e)
        {
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
                            errorWriter = new StreamWriter(File.Open("errorlog.txt", FileMode.Append, FileAccess.Write));
                            errorWriter.WriteLine("static GenerateSiteMap Method: " + DateTime.Now.ToString());
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
                }
            }
            catch (Exception ex)
            {
                StreamWriter errorWriter = null;
                try
                {
                    errorWriter = new StreamWriter(File.Open("errorlog.txt", FileMode.Append, FileAccess.Write));
                    errorWriter.WriteLine("static GenerateSiteMap Method2: " + DateTime.Now.ToString());
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
    }
}
