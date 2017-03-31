using System;
using System.Collections.Generic;
using System.Net;
using Newtonsoft.Json;
using RestSharp;

namespace OAuth
{
    /// <summary>
    /// https://oauth.yandex.com
    /// https://oauth.yandex.com/client/my
    /// </summary>
    public class YandexClient : IExternalAuthClient
    {
        private const string RedirectionUrl = "https://oauth.yandex.com/authorize";
        private const string ExchangeUrl = "https://oauth.yandex.com/token";
        private const string InfoUrl = "https://login.yandex.ru/info";

        private const string DefaultAppID = "4b9fcf167c224d54ba99fad71387858d";
        private const string DefaultSecritKey = "c5df801da7df48eaa534528b89b8430b";

        public string GetExternalLoginUrl(ReferrerData referrer)
        {
            var appID = ExternalAuthManager.GetAppID(referrer, ExternalAuthParty.Yandex, DefaultAppID);
            var secretKey = ExternalAuthManager.GetSecretID(referrer, ExternalAuthParty.Yandex, DefaultSecritKey);

            return string.Format(
                @"<form action=""{0}"" method=""GET"" enctype=""application/x-www-form-urlencoded"">
<input type=""hidden"" name=""client_id"" value=""{1}"" />
<input type=""hidden"" name=""redirect_uri"" value=""{2}"" />
<input type=""hidden"" name=""state"" value=""{3}"" />
<input type=""hidden"" name=""display"" value=""popup"" />
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

            var appID = ExternalAuthManager.GetAppID(referrer, ExternalAuthParty.Yandex, DefaultAppID);
            var secretKey = ExternalAuthManager.GetSecretID(referrer, ExternalAuthParty.Yandex, DefaultSecritKey);

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

            var client = ExternalAuthManager.CreateRestClient();
            var request = new RestRequest(ExchangeUrl, Method.POST);
            request.AddParameter("client_id", appID);
            request.AddParameter("client_secret", secretKey);
            request.AddParameter("grant_type", "authorization_code");
            request.AddParameter("code", code);
            var response = client.Execute(request);

            if (response.StatusCode != HttpStatusCode.OK)
            {
                return ExternalAuthManager.GetError(referrer, response.Content);
            }

            string accessToken = null;
            // {"access_token": "ea135929105c4f29a0f5117d2960926f", "expires_in": 2592000}
            var map = JsonConvert.DeserializeObject<Dictionary<string, object>>(response.Content);
            object temp;
            if (map.TryGetValue("access_token", out temp) && temp != null)
                accessToken = temp.ToString();

            request = new RestRequest(InfoUrl, Method.GET);
            request.AddParameter("oauth_token", accessToken);
            request.AddParameter("format", "json");

            response = client.Execute(request);

            if (response.StatusCode != HttpStatusCode.OK)
            {
                return ExternalAuthManager.GetError(referrer, response.Content);
            }


            //{"id": "250740142"}
            map = JsonConvert.DeserializeObject<Dictionary<string, object>>(response.Content);

            if (map.TryGetValue("id", out temp) && temp != null)
            {
                referrer.ExternalUserInfo = new ExternalUserInfo();
                referrer.ExternalUserInfo.ID = temp.ToString();
                referrer.ExternalID = referrer.ExternalUserInfo.ID;
            }
            else
                throw new Exception(response.Content);

            referrer.Save();

            return referrer;
        }
    }
}
