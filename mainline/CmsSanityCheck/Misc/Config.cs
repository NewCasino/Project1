using System;
using System.Collections.Generic;
using System.Configuration;
using System.Collections.Specialized;
using System.Xml.Linq;
using System.IO;

namespace CmsSanityCheck.Misc
{
    using Model;

    public static class Config
    {
        #region Email Configuration
        public static string EmailSmtpServer
        {
            get
            {
                return ConfigurationManager.AppSettings["EmailSmtpServer"];
            }
        }

        public static int EmailSmtpPort
        {
            get
            {
                return Convert.ToInt32(ConfigurationManager.AppSettings["EmailSmtpPort"]);
            }
        }

        public static bool EmailSmtpRequireAuthentication
        {
            get
            {
                return Convert.ToBoolean(ConfigurationManager.AppSettings["EmailSmtpRequireAuthentication"]);
            }
        }

        public static string EmailSmtpUsername
        {
            get
            {
                return ConfigurationManager.AppSettings["EmailSmtpUsername"];
            }
        }

        public static string EmailSmtpPassword
        {
            get
            {
                return ConfigurationManager.AppSettings["EmailSmtpPassword"];
            }
        }

        public static string FromEmail
        {
            get
            {
                return ConfigurationManager.AppSettings["FromEmail"];
            }
        }

        public static string LogEmail
        {
            get
            {
                return ConfigurationManager.AppSettings["LogEmail"];
            }
        }

        public static string SiteAlertReceiver
        {
            get
            {
                return ConfigurationManager.AppSettings["SiteAlertReceiver"];
            }
        }

        public static string ServerAlertReceiver
        {
            get
            {
                return ConfigurationManager.AppSettings["ServerAlertReceiver"];
            }
        }
        #endregion

        public static int Interval
        {
            get
            {
                int interval;
                if (int.TryParse(ConfigurationManager.AppSettings["Interval"], out interval))
                    return interval;

                //default: 5 minute
                return 5;
            }
        }

        public static int RetryTimes
        {
            get
            {
                int retryTimes;
                if (int.TryParse(ConfigurationManager.AppSettings["RetryTimes"], out retryTimes))
                    return retryTimes;

                //default: 5
                return 5;
            }
        }

        public static int Threads
        {
            get
            {
                int threads;
                if (int.TryParse(ConfigurationManager.AppSettings["Threads"], out threads))
                    return threads;

                //default: 5
                return 5;
            }
        }

        public static int Timeout
        {
            get
            {
                int timeout;
                if (int.TryParse(ConfigurationManager.AppSettings["Timeout"], out timeout))
                    return timeout;

                //default: 60 seconds
                return 60;
            }
        }

        public static int CriticalElapsedSeconds
        {
            get
            {
                int criticalElapsedSeconds;
                if (int.TryParse(ConfigurationManager.AppSettings["CriticalElapsedSeconds"], out criticalElapsedSeconds))
                    return criticalElapsedSeconds;

                //default: 30 seconds
                return 30;
            }
        }

        public static int CriticalWeight
        {
            get
            {
                int criticalWeight;
                if (int.TryParse(ConfigurationManager.AppSettings["CriticalWeight"], out criticalWeight))
                    return criticalWeight;

                //default: 100
                return 100;
            }
        }

        public static Dictionary<int, int> Weights
        {
            get
            {
                var nvc = ConfigurationManager.GetSection("weights") as NameValueCollection;
                Dictionary<int, int> weights = new Dictionary<int, int>();
                foreach (var keyName in nvc.Keys)
                {
                    int domainID;
                    int weight;
                    if (int.TryParse(keyName.ToString(), out domainID) && int.TryParse(nvc[keyName.ToString()], out weight))
                        weights.Add(domainID, weight);
                }
                return weights;
            }
        }

        public static List<Service> LoadServices()
        {
            using (StreamReader reader = new StreamReader(Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "config.xml"), true))
            {
                List<Service> list = new List<Service>();

                string xml = reader.ReadToEnd();
                XDocument doc = XDocument.Parse(xml);

                var services = doc.Root.Element("services").Elements("service");
                foreach (var service in services)
                {
                    Service s = new Service();
                    s.Name = service.Element("name").Value;
                    s.ConnectionString = service.Element("connectionString").Value;
                    var ipAddresses = service.Element("ipAddresses").Elements("ipAddress");
                    foreach (var ipAddress in ipAddresses)
                        s.IPAddresses.Add(ipAddress.Value);
                    var testUrls = service.Element("testUrls").Elements("testUrl");
                    foreach (var testUrl in testUrls)
                        s.TestUrls.Add(testUrl.Value);
                    s.Host = service.Element("host") != null ? service.Element("host").Value : string.Empty;
                    s.DomainID = service.Element("domainID") != null ? Convert.ToInt32(service.Element("domainID").Value) : 0;
                    list.Add(s);
                }

                return list;
            }

            

            //services.Add(new GammatrixService()
            //{
            //    Name = "CE PROD I",
            //    ConnectionString = "Data Source=10.0.10.17; Initial Catalog=cm;Max Pool Size=500;User ID=cmapp;Password=cmapp123;Connection Timeout=0",
            //    Host = "casino.gammatrix.com",
            //    IPAddresses = new string[] { "10.0.10.236", "10.0.10.239", "10.0.10.226" },
            //    TestUrls = new string[] { "http://{0}/xmlfeeds/gamelist/Jetbull_COM" },
            //});

            //services.Add(new GammatrixService()
            //{
            //    Name = "CE PROD III",
            //    ConnectionString = "Data Source=10.0.10.131; Initial Catalog=cm;Max Pool Size=500;User ID=cmapp;Password=cmapp123;Connection Timeout=0",
            //    Host = "casino3.gammatrix.com",
            //    IPAddresses = new string[] { "10.0.11.60", "10.0.11.61" },
            //    TestUrls = new string[] { "http://{0}/xmlfeeds/gamelist/Jetbull_COM" },
            //});

            //services.Add(new GammatrixService()
            //{
            //    Name = "CMS PROD I",
            //    ConnectionString = "Data Source=10.0.10.17; Initial Catalog=cm;Max Pool Size=500;User ID=cmapp;Password=cmapp123;Connection Timeout=0",
            //    IPAddresses = new string[] { "10.0.10.237", "10.0.10.240", "10.0.10.202" },
            //    TestUrls = new string[] { "http://{0}", "http://{0}/Register", "http://{0}/Deposit" },
            //});

            //services.Add(new GammatrixService()
            //{
            //    Name = "CMS PROD III",
            //    ConnectionString = "Data Source=10.0.10.131; Initial Catalog=cm;Max Pool Size=500;User ID=cmapp;Password=cmapp123;Connection Timeout=0",
            //    IPAddresses = new string[] { "10.0.11.57", "10.0.11.58" },
            //    TestUrls = new string[] { "http://{0}", "http://{0}/Register", "http://{0}/Deposit" },
            //});

            //services.Add(new Service()
            //{
            //    Name = "CE DEV",
            //    ConnectionString = "Data Source=109.205.92.37,14331;Initial Catalog=cm;User ID=cmsapp;Password=abc123;Min Pool Size=1;Max Pool Size=500;",
            //    Host = "casino.gammatrix-dev.net",
            //    IPAddresses = new string[] { "109.205.93.50" },
            //    TestUrls = new string[] { "http://{0}/xmlfeeds/gamelist/Jetbull_COM", "http://{0}/xmlfeeds/gamelist/Jetbull_COM" },
            //});

            //services.Add(new Service()
            //{
            //    Name = "CMS DEV",
            //    ConnectionString = "Data Source=109.205.92.37,14331;Initial Catalog=cm;User ID=cmsapp;Password=abc123;Min Pool Size=1;Max Pool Size=500;",
            //    IPAddresses = new string[] { "109.205.93.50" },
            //    TestUrls = new string[] { "http://{0}", "http://{0}/Register", "http://{0}/Deposit" },
            //});

            //services.Add(new Service()
            //{
            //    Name = "CMS DEV",
            //    ConnectionString = "Data Source=109.205.92.37,14331;Initial Catalog=cm;User ID=cmsapp;Password=abc123;Min Pool Size=1;Max Pool Size=500;",
            //    IPAddresses = new string[] { "127.0.0.1", "109.205.93.50" },
            //    TestUrls = new string[] { "http://{0}" },
            //});

            //return services;
        }
    }
}
