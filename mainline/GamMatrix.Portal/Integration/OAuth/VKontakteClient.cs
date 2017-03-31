using System;
using System.Collections.Generic;
using System.Globalization;
using System.Net;
using Newtonsoft.Json;
using RestSharp;

namespace OAuth
{
    /// <summary>
    /// Authorizing Client Applications : http://vk.com/pages?oid=-17680044&p=Authorizing_Client_Applications
    /// https://vk.com/dev
    /// </summary>
    public class VKontakteClient : IExternalAuthClient
    {
        private const string RedirectionUrl = "https://api.vkontakte.ru/oauth/authorize";
        private const string TokenUrl = "https://api.vkontakte.ru/oauth/access_token";
        private const string InfoUrl = "https://api.vkontakte.ru/method/getProfiles";

        private const string DefaultAppID = "4265370";
        private const string DefaultSecritKey = "94g4aPX1h8QuKWtiLQmk";

        public string GetExternalLoginUrl(ReferrerData referrer)
        {
            var appID = ExternalAuthManager.GetAppID(referrer, ExternalAuthParty.VKontakte, DefaultAppID);
            var secretKey = ExternalAuthManager.GetSecretID(referrer, ExternalAuthParty.VKontakte, DefaultSecritKey);

            return string.Format(
                @"<form action=""{0}"" method=""GET"" enctype=""application/x-www-form-urlencoded"">
<input type=""hidden"" name=""client_id"" value=""{1}"" />
<input type=""hidden"" name=""redirect_uri"" value=""{2}"" />
<input type=""hidden"" name=""state"" value=""{3}"" />
<input type=""hidden"" name=""scope"" value=""notes,pages"" />
<input type=""hidden"" name=""response_type"" value=""code"" />
</form>"
                , RedirectionUrl
                , appID.SafeHtmlEncode()
                , referrer.ReturnUrl.SafeHtmlEncode()
                , referrer.ID
                );
        }

        public ReferrerData CheckReturn(Dictionary<string, string> fields)
        {
            ReferrerData referrer = null;
            string referrerID;
            if (fields.TryGetValue("state", out referrerID))
            {
                referrer = ReferrerData.Load(referrerID);
            }
            if (referrer == null)
                throw new Exception("Invalid [state]");

            var appID = ExternalAuthManager.GetAppID(referrer, ExternalAuthParty.VKontakte, DefaultAppID);
            var secretKey = ExternalAuthManager.GetSecretID(referrer, ExternalAuthParty.VKontakte, DefaultSecritKey);

            string code;
            string error;
            string errorDesc;
            fields.TryGetValue("code", out code);
            fields.TryGetValue("error", out error);
            fields.TryGetValue("error_description", out errorDesc);
            if (string.IsNullOrWhiteSpace(code))
            {
                if (error == "access_denied")
                    return referrer.Cancel();
                return referrer.SetError(errorDesc ?? error ?? "Unknown error");
            }

            // https://api.vkontakte.ru/oauth/access_token?client_id={0}&redirect_uri={1}&client_secret={2}&code={3}
            var client = ExternalAuthManager.CreateRestClient();
            var request = new RestRequest(TokenUrl, Method.GET);
            request.AddParameter("client_id", appID);
            request.AddParameter("client_secret", secretKey);
            request.AddParameter("redirect_uri", referrer.ReturnUrl);
            request.AddParameter("code", code);
            var response = client.Execute(request);

            if (response.StatusCode != HttpStatusCode.OK)
            {
                return ExternalAuthManager.GetError(referrer, response.Content);
            }

            string accessToken = null;
            string userID = null;

            // {"access_token":"a3d0e2d27c7b1c479bf26b4f90ccd58219fbad5f5fec02070856324d81cf3f647453269efbc457c34a44e","expires_in":86382,"user_id":247610255}
            var map = JsonConvert.DeserializeObject<Dictionary<string, object>>(response.Content);
            object temp;
            if (map.TryGetValue("access_token", out temp) && temp != null)
                accessToken = temp.ToString();
            if (map.TryGetValue("user_id", out temp) && temp != null)
                userID = temp.ToString();

            referrer.ExternalID = userID;
            var info = new ExternalUserInfo();
            referrer.ExternalUserInfo = info;
            referrer.ExternalUserInfo.ID = userID;

            // if the following operation fails, it does not matter except we don't have enough details
            request = new RestRequest(InfoUrl, Method.GET);
            request.AddParameter("access_token", accessToken);
            request.AddParameter("uid", userID);
            response = client.Execute(request);

            if (response.StatusCode != HttpStatusCode.OK)
            {
                return ExternalAuthManager.GetError(referrer, response.Content);
            }
            else
            {
                // {"response":[{"uid":247610255,"first_name":"Jerry","last_name":"Wang","nickname":"","bdate":"30.12.1994","sex":2}]}
                dynamic json = JsonConvert.DeserializeObject(response.Content);

                info.Firstname = Convert.ChangeType(json.response[0].first_name, typeof (string));
                info.Lastname = Convert.ChangeType(json.response[0].last_name, typeof (string));

                string birth = Convert.ChangeType(json.response[0].bdate, typeof (string));
                DateTime birthDate;
                if (!string.IsNullOrWhiteSpace(birth) &&
                    DateTime.TryParseExact(birth, "d.M.yyyy", CultureInfo.InvariantCulture, DateTimeStyles.None,
                                           out birthDate))
                {
                    info.Birth = birthDate;
                }

                string gender = Convert.ChangeType(json.response[0].sex, typeof (string));
                if (string.Equals(gender, "1", StringComparison.InvariantCultureIgnoreCase))
                    info.IsFemale = false;
                else if (string.Equals(gender, "2", StringComparison.InvariantCultureIgnoreCase))
                    info.IsFemale = true;

                referrer.Save();
                return referrer;
            }
        }
    }
}
