using System;
using System.Collections.Generic;
using System.Globalization;
using System.Net;
using Newtonsoft.Json;
using RestSharp;
using RestSharp.Contrib;

namespace OAuth
{
    /// <summary>
    /// https://developers.facebook.com/docs/facebook-login/manually-build-a-login-flow/
    /// </summary>
    public class FacebookClient : IExternalAuthClient
    {
        private const string RedirectionUrl = "https://www.facebook.com/dialog/oauth";
        private const string TokenExchangeUrl = "https://graph.facebook.com/oauth/access_token";
        private const string UserInfoUrl = "https://graph.facebook.com/me";

        private const string DefaultAppID = "212032622339759";
        private const string DefaultSecritKey = "1aaac7d8dc706155c07f0418e14c820c";

        public string GetExternalLoginUrl(ReferrerData referrer)
        {
            var appID = ExternalAuthManager.GetAppID(referrer, ExternalAuthParty.Facebook, DefaultAppID);
            var secretKey = ExternalAuthManager.GetSecretID(referrer, ExternalAuthParty.Facebook, DefaultSecritKey);

            return string.Format(
@"<form action=""{0}"" method=""GET"" enctype=""application/x-www-form-urlencoded"">
<input type=""hidden"" name=""client_id"" value=""{1}"" />
<input type=""hidden"" name=""redirect_uri"" value=""{2}"" />
<input type=""hidden"" name=""state"" value=""{3}"" />
<input type=""hidden"" name=""scope"" value=""email,user_birthday"" />
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

            var appID = ExternalAuthManager.GetAppID(referrer, ExternalAuthParty.Facebook, DefaultAppID);
            var secretKey = ExternalAuthManager.GetSecretID(referrer, ExternalAuthParty.Facebook, DefaultSecritKey);

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

            // https://graph.facebook.com/oauth/access_token?client_id={0}&redirect_uri={1}&client_secret={2}&code={3}
            var client = ExternalAuthManager.CreateRestClient();
            var request = new RestRequest(TokenExchangeUrl, Method.GET);
            request.AddParameter("client_id", appID);
            request.AddParameter("client_secret", secretKey);
            request.AddParameter("redirect_uri", referrer.ReturnUrl);
            request.AddParameter("code", code);
            var response = client.Execute(request);
            /*
            RestResponse response = new RestResponse()
            {
                StatusCode = HttpStatusCode.OK,
                Content = "access_token=CAADA17Eipq8BAEbBzux0yeUZAeZBxDIrb9tQS7TILEX7nlltMMYnXqPVEKpKGbVME2sdPlohfbc7ZAXxQESahXrdNV7ZA3Dt7pWtJyZAMSkjKOZA1ZBm6z6kahxydSurwCvsxQJF6nwkGI9Gyiv2jYwqvf67aog78gWaI3mGiIFHWZC4ZA2FMjn6l75yXV9tZCZBQwZD&expires=5160146"
            };
            // * */

            if (response.StatusCode != HttpStatusCode.OK)
            {
                return ExternalAuthManager.GetError(referrer, response.Content);
            }

            // access_token=CAADA17Eipq8BAEbBzux0yeUZAeZBxDIrb9tQS7TILEX7nlltMMYnXqPVEKpKGbVME2sdPlohfbc7ZAXxQESahXrdNV7ZA3Dt7pWtJyZAMSkjKOZA1ZBm6z6kahxydSurwCvsxQJF6nwkGI9Gyiv2jYwqvf67aog78gWaI3mGiIFHWZC4ZA2FMjn6l75yXV9tZCZBQwZD&expires=5160146
            var qs = HttpUtility.ParseQueryString(response.Content);
            string accessToken = qs["access_token"];

            // https://graph.facebook.com/me?access_token={0}
            request = new RestRequest(UserInfoUrl, Method.GET);
            request.AddParameter("access_token", accessToken);
            response = client.Execute(request);

            if (response.StatusCode != HttpStatusCode.OK)
            {
                return ExternalAuthManager.GetError(referrer, response.Content);
            }

            dynamic json = JsonConvert.DeserializeObject(response.Content);

            var info = new ExternalUserInfo();
            referrer.ExternalUserInfo = info;

            info.ID = Convert.ChangeType(json.id, typeof(string));
            info.Username = Convert.ChangeType(json.username, typeof(string));
            info.Firstname = Convert.ChangeType(json.first_name, typeof(string));
            info.Lastname = Convert.ChangeType(json.last_name, typeof(string));
            info.Email = Convert.ChangeType(json.email, typeof(string));

            string birth = Convert.ChangeType(json.birthday, typeof(string));
            DateTime birthDate;
            if (!string.IsNullOrWhiteSpace(birth) &&
                DateTime.TryParseExact(birth, "MM/dd/yyyy", CultureInfo.InvariantCulture, DateTimeStyles.None, out birthDate))
            {
                info.Birth = birthDate;
            }
            referrer.ExternalID = info.ID;
            string gender = Convert.ChangeType(json.gender, typeof(string));
            if (string.Equals(gender, "male", StringComparison.InvariantCultureIgnoreCase))
                info.IsFemale = false;
            else if (string.Equals(gender, "female", StringComparison.InvariantCultureIgnoreCase))
                info.IsFemale = true;

            referrer.Save();

            return referrer;
        }


    }
}
