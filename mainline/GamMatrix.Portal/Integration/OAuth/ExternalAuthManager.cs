using System;
using System.Collections.Generic;
using System.Configuration;
using BLToolkit.Data;
using BLToolkit.DataAccess;
using CM.Content;
using CM.db;
using CM.db.Accessor;
using CM.Sites;
using Newtonsoft.Json;
using RestSharp;

namespace OAuth
{
    public enum ExternalAuthAction
    {
        Cancel = -3,
        Error = -2,
        Unknown = -1,
        Login = 0,
        Associate = 1,
        ToBeRegistered = 3,
        Unassociate = 5
    }

    public enum ExternalAuthParty
    {
        VKontakte = 1,
        Yandex = 2,
        Twitter = 3,
        MailRu = 4,
        Google = 5,
        Facebook = 6,
        NemID = 7,
        Unknown = 0
    }

    public enum ErrorCode
    {
        NotLogin,
        ExistedParty,
        EmptyParamets,
        ExistedExternalUser,
        ErrorRequest,
        ReferrerIDIsEmpty,
        ErrorAction,
        ErrorToken,
        ConfirmError,
        Register_ValidFail,
        Register_NullData,
        Register_fail,
        Register_Exception,
        Disenable_Register,
        Disenable_Login,
        NoAssociatedUser,
    }

    public enum AssociateStatus
    {
        Associated,
        EmailAlreadyRegistered,
        NotAssociated,
    }
    
    public class ExternalAuthManager
    {
        private static readonly FacebookClient FacebookClient = new FacebookClient();
        private static readonly GoogleClient GoogleClient = new GoogleClient();
        private static readonly TwitterClient TwitterClient = new TwitterClient();
        private static readonly VKontakteClient VkClient = new VKontakteClient();
        private static readonly MailRuClient MailRuClient = new MailRuClient();
        private static readonly YandexClient YandexClient = new YandexClient();

        public static string GetReturnUrl(ExternalAuthParty party, string referrerID)
        {
            if (party == ExternalAuthParty.Twitter)
                return string.Format("{0}?authParty={1}&referrer_id={2}"
                                     , ConfigurationManager.AppSettings["ExternalAuth.ReturnUrl"]
                                     , party.ToString()
                                     , referrerID);

            return string.Format("{0}?authParty={1}"
                                 , ConfigurationManager.AppSettings["ExternalAuth.ReturnUrl"]
                                 , party.ToString());
        }

        public static string GetCallbackUrl(string baseUrl, string referrerID)
        {
            return string.Format("{0}/ExternalLogin/Callback?referrerID={1}", baseUrl, referrerID);
        }

        public static string GetAppID(ReferrerData referrerData, ExternalAuthParty party, string defaultAppID)
        {
            var domain = SiteManager.GetSiteByDistinctName(referrerData.DomainName);
            string path = string.Format("/Metadata/Settings/ThirdPartyConnect/.{0}_APP_ID", party.ToString());
            var value = Metadata.Get(domain, path, null);
            return string.IsNullOrEmpty(value) ? defaultAppID : value;
        }

        public static string GetSecretID(ReferrerData referrerData, ExternalAuthParty party, string defaultSecretKey)
        {
            var domain = SiteManager.GetSiteByDistinctName(referrerData.DomainName);
            string path = string.Format("/Metadata/Settings/ThirdPartyConnect/.{0}_APP_SECRET", party.ToString());
            var value = Metadata.Get(domain, path, null);
            return string.IsNullOrEmpty(value) ? defaultSecretKey : value;
        }

        public static RestClient CreateRestClient()
        {
            var client = new RestClient();
            //client.Proxy = new WebProxy("127.0.0.1", 8087);
            return client;
        }

        public static IExternalAuthClient GetClient(ExternalAuthParty party)
        {
            switch (party)
            {
                case ExternalAuthParty.Facebook:
                    return FacebookClient;

                case ExternalAuthParty.Google:
                    return GoogleClient;

                case ExternalAuthParty.Twitter:
                    return TwitterClient;

                case ExternalAuthParty.VKontakte:
                    return VkClient;

                case ExternalAuthParty.MailRu:
                    return MailRuClient;

                case ExternalAuthParty.Yandex:
                    return YandexClient;

                default:
                    throw new NotSupportedException();
            }
        }

        public static Dictionary<ExternalAuthParty, bool> GetAuthPartyStatus(int domainID, string userName)
        {
            var dicStatus = new Dictionary<ExternalAuthParty, bool>();
            using (var dbManager = new DbManager())
            {
                var eua = DataAccessor.CreateInstance<ExternalLoginAccessor>(dbManager);
                IList<cmExternalLogin> lstExternalUser = eua.GetAuthPartyByUserName(domainID, userName);
                if (lstExternalUser != null)
                {
                    foreach (cmExternalLogin cme in lstExternalUser)
                    {
                        if (!dicStatus.ContainsKey((ExternalAuthParty)cme.AuthParty))
                        {
                            dicStatus.Add((ExternalAuthParty)cme.AuthParty, true);
                        }
                    }
                }
            }
            return dicStatus;
        }

        public static ReferrerData GetError(ReferrerData referrer, string content)
        {
            try
            {
                dynamic obj = JsonConvert.DeserializeObject(content);
                return referrer.SetError(obj.error.ToString());
            }
            catch
            {
                return referrer.SetError(content);
            }
        }

        public static void SaveAssociatedExternalAccount(long userID, string referrerID)
        {
            try
            {
                ReferrerData referrer = ReferrerData.Load(referrerID);

                using (var dbManager = new DbManager())
                {
                    var ela = DataAccessor.CreateInstance<ExternalLoginAccessor>(dbManager);
                    var externalLogin = ela.GetUserByKey(referrer.ExternalID, referrer.DomainID, (int)referrer.AuthParty);
                    if (externalLogin == null)
                        ela.Create(referrer.DomainID, userID, (int)referrer.AuthParty, referrer.ExternalID);
                }
            }
            catch (Exception ex)
            {

            }
        }

        public static void DelAssociatedExternalAccount(int domainID, long userID, ExternalAuthParty party)
        {
            using (var dbManager = new DbManager())
            {
                var eua = DataAccessor.CreateInstance<ExternalLoginAccessor>(dbManager);
                eua.DeleteExternalUserByUserID(domainID, (int)party, userID);
            }
        }
    }

    public class AssociateManager
    {

    }
}
