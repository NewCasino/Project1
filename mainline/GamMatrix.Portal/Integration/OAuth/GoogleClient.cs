using System;
using System.Collections.Generic;
using System.Net;
using JWT;
using Newtonsoft.Json;
using RestSharp;

namespace OAuth
{
    /// <summary>
    /// https://developers.google.com/accounts/docs/OAuth2Login
    /// Google Developer Console : https://console.developers.google.com/project
    /// Discovery document : https://accounts.google.com/.well-known/openid-configuration
    /// </summary>
    public class GoogleClient : IExternalAuthClient
    {
        private const string RedirectionUrl = "https://accounts.google.com/o/oauth2/auth";
        private const string TokenExchangeUrl = "https://accounts.google.com/o/oauth2/token";
        private const string UserInfoUrl = "https://www.googleapis.com/plus/v1/people/me/openIdConnect";

        private const string DefaultAppID = "1096884915117-3ujonkcpkpjocc5v4k8j6d6r9g9ru35k.apps.googleusercontent.com";
        private const string DefaultSecritKey = "ZqSkRtS45LvycQ-WbyCOZaUg";

        public string GetExternalLoginUrl(ReferrerData referrer)
        {
            var appID = ExternalAuthManager.GetAppID(referrer, ExternalAuthParty.Google, DefaultAppID);
            var secretKey = ExternalAuthManager.GetSecretID(referrer, ExternalAuthParty.Google, DefaultSecritKey);

            return string.Format(
@"<form action=""{0}"" method=""GET"" enctype=""application/x-www-form-urlencoded"">
<input type=""hidden"" name=""client_id"" value=""{1}"" />
<input type=""hidden"" name=""redirect_uri"" value=""{2}"" />
<input type=""hidden"" name=""state"" value=""{3}"" />
<input type=""hidden"" name=""scope"" value=""openid profile email"" />
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

            var appID = ExternalAuthManager.GetAppID(referrer, ExternalAuthParty.Google, DefaultAppID);
            var secretKey = ExternalAuthManager.GetSecretID(referrer, ExternalAuthParty.Google, DefaultSecritKey);

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
            var request = new RestRequest(TokenExchangeUrl, Method.POST);
            request.AddParameter("code", code);
            request.AddParameter("client_id", appID);
            request.AddParameter("client_secret", secretKey);
            request.AddParameter("redirect_uri", referrer.ReturnUrl);
            request.AddParameter("grant_type", "authorization_code");

            var response = client.Execute(request);

            if (response.StatusCode != HttpStatusCode.OK)
            {
                return ExternalAuthManager.GetError(referrer, response.Content);
            }

            string idToken;
            string accessToken;
            var dictionary = JsonConvert.DeserializeObject<Dictionary<string, string>>(response.Content);
            dictionary.TryGetValue("access_token", out accessToken);
            dictionary.TryGetValue("id_token", out idToken);

            request = new RestRequest(UserInfoUrl, Method.GET);
            request.AddParameter("access_token", accessToken);

            response = client.Execute(request);

            if (response.StatusCode != HttpStatusCode.OK)
            {
                return ExternalAuthManager.GetError(referrer, response.Content);
            }

            var info = new ExternalUserInfo();
            referrer.ExternalUserInfo = info;

            string temp;
            dictionary = JsonConvert.DeserializeObject<Dictionary<string, string>>(response.Content);
            if (dictionary.TryGetValue("sub", out temp))
                info.ID = temp;
            if (dictionary.TryGetValue("given_name", out temp))
                info.Firstname = temp;
            if (dictionary.TryGetValue("family_name", out temp))
                info.Lastname = temp;
            if (dictionary.TryGetValue("email", out temp))
                info.Email = temp;
            if (dictionary.TryGetValue("gender", out temp))
            {
                if (string.Equals(temp, "male", StringComparison.InvariantCultureIgnoreCase))
                    info.IsFemale = false;
                else if (string.Equals(temp, "female", StringComparison.InvariantCultureIgnoreCase))
                    info.IsFemale = true;
            }
            referrer.ExternalID = info.ID;

            // if failed to retreive the information from Google+, then decode the id_token
            if (string.IsNullOrWhiteSpace(info.ID))
            {
                string json = JsonWebToken.Decode(idToken, appID, false);
                dictionary = JsonConvert.DeserializeObject<Dictionary<string, string>>(json);
                if (dictionary.TryGetValue("sub", out temp))
                    info.ID = temp;
                if (dictionary.TryGetValue("email", out temp))
                    info.Email = temp;
            }

            referrer.Save();
            return referrer;
        }
    }
}
