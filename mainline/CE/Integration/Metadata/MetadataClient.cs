using System.Configuration;
using System.IO;
using System.Net;
using CE.db;

namespace CE.Integration.Metadata
{
    internal static class MetadataClient
    {
        private static readonly string DEFAULT_URL = ConfigurationManager.AppSettings["Metadata.DefaultUrl"];

        // {0}/HttpHandlers/GetMetadata.ashx?tid={1}&type=json&path={2}
        private static readonly string GET_METADATA_URL = ConfigurationManager.AppSettings["Metadata.GetMetadataURL"];

        // {0}/HttpHandlers/DumpTranslation.ashx?tid={1}&lang={2}
        private static readonly string DUMP_TRANSLATION_URL = ConfigurationManager.AppSettings["Metadata.DumpTransactionURL"];

        // {0}/HttpHandlers/CreateForContent.ashx?content={1}
        private static readonly string CREATE_TRANSLATION_URL = ConfigurationManager.AppSettings["Metadata.CreateTranslation"];

        // {0}/HttpHandlers/ReportTranslationUsage.ashx?tid={1}
        private static readonly string UPLOAD_STATISTIC_URL = ConfigurationManager.AppSettings["Metadata.UploadStatisticURL"];

        // {0}/HttpHandlers/GetTranslation.ashx?tid={1}&path={2}
        private static readonly string GET_TRANSLATION_URL = ConfigurationManager.AppSettings["Metadata.GetTranslationURL"];

        // {0}/HttpHandlers/UpdateTranslation.ashx?tid={1}&path={2}
        private static readonly string UPDATE_TRANSLATION_URL = ConfigurationManager.AppSettings["Metadata.UpdateTranslationURL"];

        // {0}/HttpHandlers/DeleteTranslation.ashx?tid={1}&path={2}
        private static readonly string DELETE_TRANSLATION_URL = ConfigurationManager.AppSettings["Metadata.DeleteTranslationURL"];

        static string Download(string url)
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

        static string Upload(string url, string data)
        {
            HttpWebRequest request = HttpWebRequest.Create(url) as HttpWebRequest;
            request.Method = "POST";
            using (Stream stream = request.GetRequestStream())
            using (StreamWriter writer = new StreamWriter(stream))
            {
                writer.Write(data);
                writer.Flush();
            }
            using (HttpWebResponse resp = (HttpWebResponse)(request.GetResponse()))
            using (Stream stream = resp.GetResponseStream())
            using (StreamReader sr = new StreamReader(stream))
            {
                return sr.ReadToEnd();
            }
        }

        public static string UploadStatistic(int templateID, string json)
        {
            string url = string.Format(UPLOAD_STATISTIC_URL
                , DEFAULT_URL
                , templateID
                );
            return Upload(url, json);
        }

        public static string CreateTranslation(string content)
        {
            string url = string.Format(CREATE_TRANSLATION_URL
                , DEFAULT_URL
                , WebUtility.UrlEncode(content)
                );
            return Download(url);
        }

        public static string GetLanguages(ceDomainConfig domain)
        {
            string url = string.Format(GET_METADATA_URL
                , domain.MetadataUrl.DefaultIfNullOrWhiteSpace(DEFAULT_URL)
                , domain.TemplateID
                , WebUtility.UrlEncode("/config/languages/*")
                );
            return Download(url);
        }

        public static string GetCurrencies(ceDomainConfig domain)
        {
            string url = string.Format(GET_METADATA_URL
                , domain.MetadataUrl.DefaultIfNullOrWhiteSpace(DEFAULT_URL)
                , domain.TemplateID
                , WebUtility.UrlEncode("/config/currencies/*")
                );
            return Download(url);
        }

        public static string GetPhonePrefixes(ceDomainConfig domain)
        {
            string url = string.Format(GET_METADATA_URL
                , domain.MetadataUrl.DefaultIfNullOrWhiteSpace(DEFAULT_URL)
                , domain.TemplateID
                , WebUtility.UrlEncode("/config/phone-code-prefixes/*")
                );
            return Download(url);
        }

        public static string GetPaymentMethods(ceDomainConfig domain)
        {
            string url = string.Format(GET_METADATA_URL
                , domain.MetadataUrl.DefaultIfNullOrWhiteSpace(DEFAULT_URL)
                , domain.TemplateID
                , WebUtility.UrlEncode("/config/payment-methods/*")
                );
            return Download(url);
        }

        public static string GetPaymentMethodCategories(ceDomainConfig domain)
        {
            string url = string.Format(GET_METADATA_URL
                , domain.MetadataUrl.DefaultIfNullOrWhiteSpace(DEFAULT_URL)
                , domain.TemplateID
                , WebUtility.UrlEncode("/config/payment-method-categories/*")
                );
            return Download(url);
        }

        public static string GetPaymentMethodsInCategory(ceDomainConfig domain, string catetory)
        {
            string url = string.Format(GET_METADATA_URL
                , domain.MetadataUrl.DefaultIfNullOrWhiteSpace(DEFAULT_URL)
                , domain.TemplateID
                , WebUtility.UrlEncode(string.Format("/config/payment-method-categories/{0}/*", catetory))
                );
            return Download(url);
        }

        public static string GetDumpedTranslation(ceDomainConfig domain, string lang)
        {
            string url = string.Format(DUMP_TRANSLATION_URL
                , domain.MetadataUrl.DefaultIfNullOrWhiteSpace(DEFAULT_URL)
                , domain.TemplateID
                , lang
                );
            return Download(url);
        }

        public static string GetPendingWithdrawalCfg(ceDomainConfig domain)
        {
            string url = string.Format(GET_METADATA_URL
                , domain.MetadataUrl.DefaultIfNullOrWhiteSpace(DEFAULT_URL)
                , domain.TemplateID
                , WebUtility.UrlEncode("/config/pending-withdrawal")
                );
            return Download(url);
        }

        public static string GetRegistrationCfg(ceDomainConfig domain)
        {
            string url = string.Format(GET_METADATA_URL
                , domain.MetadataUrl.DefaultIfNullOrWhiteSpace(DEFAULT_URL)
                , domain.TemplateID
                , WebUtility.UrlEncode("/config/registration")
                );
            return Download(url);
        }

        public static string GetExternalAuthCfg(ceDomainConfig domain)
        {
            string url = string.Format(GET_METADATA_URL
                , domain.MetadataUrl.DefaultIfNullOrWhiteSpace(DEFAULT_URL)
                , domain.TemplateID
                , WebUtility.UrlEncode("/config/external-authentication")
                );
            return Download(url);
        }

        public static string GetGeneralCfg(ceDomainConfig domain)
        {
            string url = string.Format(GET_METADATA_URL
                , domain.MetadataUrl.DefaultIfNullOrWhiteSpace(DEFAULT_URL)
                , domain.TemplateID
                , WebUtility.UrlEncode("/config/general")
                );
            return Download(url);
        }

        public static string GetSessionCfg(ceDomainConfig domain)
        {
            string url = string.Format(GET_METADATA_URL
                , domain.MetadataUrl.DefaultIfNullOrWhiteSpace(DEFAULT_URL)
                , domain.TemplateID
                , WebUtility.UrlEncode("/config/session")
                );
            return Download(url);
        }

        public static string GetConstantCfg(ceDomainConfig domain)
        {
            string url = string.Format(GET_METADATA_URL
                , domain.MetadataUrl.DefaultIfNullOrWhiteSpace(DEFAULT_URL)
                , domain.TemplateID
                , WebUtility.UrlEncode("/constant")
                );
            return Download(url);
        }

        public static string GetEmailTemplates(ceDomainConfig domain)
        {
            string url = string.Format(GET_METADATA_URL
                , domain.MetadataUrl.DefaultIfNullOrWhiteSpace(DEFAULT_URL)
                , domain.TemplateID
                , WebUtility.UrlEncode("/email-templates/*")
                );
            return Download(url);
        }

        public static string GetCountries(ceDomainConfig domain)
        {
            string url = string.Format(GET_METADATA_URL
                , domain.MetadataUrl.DefaultIfNullOrWhiteSpace(DEFAULT_URL)
                , domain.TemplateID
                , WebUtility.UrlEncode("/config/countries/*")
                );
            return Download(url);
        }

        public static string GetGamingAccounts(ceDomainConfig domain)
        {
            string url = string.Format(GET_METADATA_URL
                , domain.MetadataUrl.DefaultIfNullOrWhiteSpace(DEFAULT_URL)
                , domain.TemplateID
                , WebUtility.UrlEncode("/config/gaming-accounts/*")
                );
            return Download(url);
        }

        public static string GetBonuses(ceDomainConfig domain, GamMatrixAPI.VendorID vendor)
        {
            string url = string.Format(GET_METADATA_URL
                , domain.MetadataUrl.DefaultIfNullOrWhiteSpace(DEFAULT_URL)
                , domain.TemplateID
                , WebUtility.UrlEncode(string.Format("/config/gaming-accounts/{0}/bonus/*", vendor.ToString()))
                );
            return Download(url);
        }

        public static string GetRegions(ceDomainConfig domain, string country)
        {
            string url = string.Format(GET_METADATA_URL
                , domain.MetadataUrl.DefaultIfNullOrWhiteSpace(DEFAULT_URL)
                , domain.TemplateID
                , WebUtility.UrlEncode(string.Format("/config/countries/{0}/*", country))
                );
            return Download(url);
        }

        public static string GetCasinoGames(ceDomainConfig domain)
        {
            string url = string.Format(GET_METADATA_URL
                , domain.MetadataUrl.DefaultIfNullOrWhiteSpace(DEFAULT_URL)
                , domain.TemplateID
                , WebUtility.UrlEncode(string.Format("/casino/games/*"))
                );
            return Download(url);
        }

        public static string GetTranslation(ceDomainConfig domain, string path)
        {
            string url = string.Format(GET_TRANSLATION_URL
                , domain.MetadataUrl.DefaultIfNullOrWhiteSpace(DEFAULT_URL)
                , domain.TemplateID
                , WebUtility.UrlEncode(path)
                );
            return Download(url);
        }

        public static string UpdateTranslation(ceDomainConfig domain, string path, string translation)
        {
            string url = string.Format(UPDATE_TRANSLATION_URL
                , domain.MetadataUrl.DefaultIfNullOrWhiteSpace(DEFAULT_URL)
                , domain.TemplateID
                , WebUtility.UrlEncode(path)
                );
            return Upload(url, translation);
        }

        public static string DeleteTranslation(ceDomainConfig domain, string path, string translation)
        {
            string url = string.Format(DELETE_TRANSLATION_URL
                , domain.MetadataUrl.DefaultIfNullOrWhiteSpace(DEFAULT_URL)
                , domain.TemplateID
                , WebUtility.UrlEncode(path)
                );
            return Upload(url, translation);
        }


    }
}
