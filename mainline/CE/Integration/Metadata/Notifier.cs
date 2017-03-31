using System;
using System.Collections.Generic;
using System.Collections.Specialized;
using System.Configuration;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Net;
using System.Text;
using System.Threading.Tasks;

namespace CE.Integration.Metadata
{
    using CE.db;

    public class Notifier
    {
        public static void Send(long domainID)
        {
            List<ceDomainConfigEx> domains = DomainManager.GetDomains();

            if (domainID == Constant.SystemDomainID)
            {
                ceDomainConfigEx sysDomain = DomainManager.GetSysDomain();
                Send(sysDomain);

                foreach (ceDomainConfigEx domain in domains)
                {
                    Send(domain);
                }
            }
            else
            {
                ceDomainConfigEx domain = domains.FirstOrDefault(d => d.DomainID == domainID);
                Send(domain);
            }
        }

        public static void Send(ceDomainConfigEx domain)
        {
            //Dictionary<string, ceCasinoGameBaseEx> games = CacheManager.GetGameDictionary(Constant.SystemDomainID);

            List<Translation> translations = new CasinoGameMgr(CasinoGameMgr.METADATA_DESCRIPTION).Get(domain, 1000);

            List<string> messages = new List<string>();
            messages.Add(CreateMetadataChangeMessage(domain.TemplateID, "/casino/games"));
            foreach (Translation translation in translations)
            {
                if (translation.Code == ">")
                    continue;

                messages.Add(CreateTranslationChangeMessage(domain.TemplateID, translation.Code));
            }

            Broadcast(messages);
        }

        private static string CreateMetadataChangeMessage(int templateID, string path)
        {
            return string.Format("METADATA_CHANGE|{0}|{1}", templateID, path);
        }

        private static string CreateTranslationChangeMessage(int templateID, string lang)
        {
            return string.Format("TRANSLATION_CHANGE|{0}|{1}", templateID, lang);
        }

        private static void Broadcast(List<string> messages)
        {
            string message = string.Join("\r\n", messages);
            var data = "=" + WebUtility.HtmlEncode(message);

            NameValueCollection metadataNotificationUrls = ConfigurationManager.GetSection("metadataNotificationUrls") as NameValueCollection;
            if (metadataNotificationUrls == null || metadataNotificationUrls.Count == 0)
                throw new Exception("Error, can not find the notification configration.");

            List<Task> tasks = new List<Task>();

            foreach (string key in metadataNotificationUrls.Keys)
            {
                string url = metadataNotificationUrls[key];

                tasks.Add(Task.Factory.StartNew(() =>
                {
                    Upload(url, data);
                }));
            }

            Task.WhenAll(tasks);
        }

        static string Download(string url)
        {
            try
            {
                HttpWebRequest request = HttpWebRequest.Create(url) as HttpWebRequest;
                request.Method = "GET";
                using (HttpWebResponse resp = (HttpWebResponse)(request.GetResponse()))
                using (Stream stream = resp.GetResponseStream())
                using (StreamReader sr = new StreamReader(stream))
                {
                    return sr.ReadToEnd();
                }
            }
            catch (Exception ex)
            {
                return null;
            }
        }

        static string Upload(string url, string data)
        {
            using (var client = new WebClientEx(int.MaxValue))
            {
                client.Headers[HttpRequestHeader.ContentType] = "application/x-www-form-urlencoded";
                try
                {
                    var result = client.UploadString(url, "POST", data);
                    return result;
                }
                catch (Exception ex)
                {
                    System.Diagnostics.Debug.WriteLine(ex.Message);
                    return ex.Message;
                }
            }
        }
    }
}
