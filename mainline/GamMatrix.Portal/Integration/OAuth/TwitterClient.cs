using System;
using System.Collections.Generic;
using System.Net;
using Newtonsoft.Json;
using RestSharp;
using RestSharp.Authenticators;
using RestSharp.Contrib;

namespace OAuth
{
    /// <summary>
    /// https://dev.twitter.com/docs/auth/implementing-sign-twitter
    /// https://apps.twitter.com/app
    /// </summary>
    public class TwitterClient : IExternalAuthClient
    {
        private const string RequestTokenUrl = "https://api.twitter.com/oauth/request_token";
        private const string RedirectionUrl = "https://api.twitter.com/oauth/authenticate";
        private const string TokenExchangeUrl = "https://api.twitter.com/oauth/access_token";
        private const string UserInfoUrl = "https://api.twitter.com/1.1/account/verify_credentials.json";

        private const string DefaultAppID = "IKgjiQ2RmBGlRUCVztszQ";
        private const string DefaultSecritKey = "ADkpXYtpATMgMdYgyykDRceZkqGXZJUi9CJNEOUyGU";

        public string GetExternalLoginUrl(ReferrerData referrer)
        {
            var appID = ExternalAuthManager.GetAppID(referrer, ExternalAuthParty.Twitter, DefaultAppID);
            var secretKey = ExternalAuthManager.GetSecretID(referrer, ExternalAuthParty.Twitter, DefaultSecritKey);

            var client = ExternalAuthManager.CreateRestClient();
            client.Authenticator = OAuth1Authenticator.ForRequestToken(appID,
                                                                       secretKey,
                                                                       referrer.ReturnUrl);
            var request = new RestRequest(RequestTokenUrl, Method.POST);
            var response = client.Execute(request);

            if (response.StatusCode != HttpStatusCode.OK)
            {
                throw new Exception(response.Content);
            }

            // oauth_token=NPcudxy0yU5T3tBzho7iCotZ3cnetKwcTIRlX0iwRl0&oauth_token_secret=veNRnAWe6inFuo8o2u8SLLZLjolYDmDP7SzL0YfYI&oauth_callback_confirmed=true
            var qs = HttpUtility.ParseQueryString(response.Content);
            referrer.OAuthToken = qs["oauth_token"];
            referrer.OAuthTokenSecret = qs["oauth_token_secret"];
            referrer.Save();

            return string.Format(
                @"<form action=""{0}"" method=""GET"" enctype=""application/x-www-form-urlencoded"">
<input type=""hidden"" name=""oauth_token"" value=""{1}"" />
</form>"
                , RedirectionUrl
                , referrer.OAuthToken.SafeHtmlEncode());
        }

        public ReferrerData CheckReturn(Dictionary<string, string> fields)
        {
            ReferrerData referrer = null;
            string referrerID;
            if (fields.TryGetValue("referrer_id", out referrerID))
            {
                referrer = ReferrerData.Load(referrerID);
            }
            if (referrer == null)
                throw new Exception("Invalid [referrer_id]");

            var appID = ExternalAuthManager.GetAppID(referrer, ExternalAuthParty.Twitter, DefaultAppID);
            var secretKey = ExternalAuthManager.GetSecretID(referrer, ExternalAuthParty.Twitter, DefaultSecritKey);

            string verifier;
            if (!fields.TryGetValue("oauth_verifier", out verifier) ||
                string.IsNullOrWhiteSpace(verifier))
            {
                return referrer.SetError("Invalid [oauth_verifier]");
            }

            var client = ExternalAuthManager.CreateRestClient();
            client.Authenticator = OAuth1Authenticator.ForAccessToken(appID
                , secretKey
                , referrer.OAuthToken
                , referrer.OAuthTokenSecret
                , verifier
                );
            var request = new RestRequest(TokenExchangeUrl, Method.POST);
            var response = client.Execute(request);

            if (response.StatusCode != HttpStatusCode.OK)
            {
                return ExternalAuthManager.GetError(referrer, response.Content);
            }

            // oauth_token=1185290226-m0XvwuMZmPiTlIITFYF3OMYcrHabPm9KtnKjUc0&oauth_token_secret=8FcrTTDvBmSL9MQSBnJl8oaN4JmvBmDJAsp6cajDS8FGO&user_id=1185290226&screen_name=wangjia184
            var qs = HttpUtility.ParseQueryString(response.Content);
            string token = qs["oauth_token"];
            string tokenSecret = qs["oauth_token_secret"];

            client.Authenticator = OAuth1Authenticator.ForProtectedResource(appID
                , secretKey
                , token
                , tokenSecret
                );
            request = new RestRequest(UserInfoUrl, Method.GET);
            response = client.Execute(request);

            if (response.StatusCode != HttpStatusCode.OK)
            {
                return ExternalAuthManager.GetError(referrer, response.Content);
            }

            var map = JsonConvert.DeserializeObject<Dictionary<string, object>>(response.Content);

            var info = new ExternalUserInfo();
            referrer.ExternalUserInfo = info;

            object temp;
            if (map.TryGetValue("id", out temp) && temp != null)
                info.ID = temp.ToString();
            if (map.TryGetValue("screen_name", out temp) && temp != null)
                info.Username = temp.ToString();
            referrer.ExternalID = info.ID;

            referrer.Save();

            return referrer;
        }
    }
}
