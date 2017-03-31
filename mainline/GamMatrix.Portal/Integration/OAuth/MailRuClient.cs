using System;
using System.Collections.Generic;
using System.Globalization;
using System.Net;
using System.Security.Cryptography;
using System.Text;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using RestSharp;

namespace OAuth
{

    /// <summary>
    /// http://api.mail.ru/docs/guides/oauth/sites/
    /// http://api.mail.ru/sites/
    /// </summary>
    public class MailRuClient : IExternalAuthClient
    {
        private const string RedirectionUrl = "https://connect.mail.ru/oauth/authorize";
        private const string TokenExchangeUrl = "https://connect.mail.ru/oauth/token";
        private const string ApiUrl = "https://www.appsmail.ru/platform/api";

        private const string DefaultAppID = "718662";
        private const string DefaultSecritKey = "d5826a9b5d0fcb30b87a26703f1ba331";

        public string GetExternalLoginUrl(ReferrerData referrer)
        {
            var appID = ExternalAuthManager.GetAppID(referrer, ExternalAuthParty.MailRu, DefaultAppID);
            var secretKey = ExternalAuthManager.GetSecretID(referrer, ExternalAuthParty.MailRu, DefaultSecritKey);

            return string.Format(
@"<form action=""{0}"" method=""GET"" enctype=""application/x-www-form-urlencoded"">
<input type=""hidden"" name=""client_id"" value=""{1}"" />
<input type=""hidden"" name=""redirect_uri"" value=""{2}"" />
<input type=""hidden"" name=""state"" value=""{3}"" />
<input type=""hidden"" name=""scope"" value=""stream"" />
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

            var appID = ExternalAuthManager.GetAppID(referrer, ExternalAuthParty.MailRu, DefaultAppID);
            var secretKey = ExternalAuthManager.GetSecretID(referrer, ExternalAuthParty.MailRu, DefaultSecritKey);

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
            request.AddParameter("client_id", appID);
            request.AddParameter("client_secret", secretKey);
            request.AddParameter("redirect_uri", referrer.ReturnUrl);
            request.AddParameter("code", code);
            request.AddParameter("grant_type", "authorization_code");
            var response = client.Execute(request);

            if (response.StatusCode != HttpStatusCode.OK)
            {
                return ExternalAuthManager.GetError(referrer, response.Content);
            }

            var info = new ExternalUserInfo();
            referrer.ExternalUserInfo = info;

            // {"refresh_token":"406121ee8ed38007548e8acf54f1697b","expires_in":86400,"access_token":"bc20c003cf5a23ed9d4043a75ddd200d","token_type":"bearer","x_mailru_vid":"10987230173030225085"}
            var dictionary = JsonConvert.DeserializeObject<Dictionary<string, object>>(response.Content);
            string accessToken = dictionary["access_token"].ToString();
            string vid = dictionary["x_mailru_vid"].ToString();
            info.ID = vid;
            referrer.ExternalID = vid;

            // if does not matter if the following operation fails
            try
            {
                var tuples = new List<Tuple<string, string>>();
                tuples.Add(new Tuple<string, string>("app_id", appID));
                tuples.Add(new Tuple<string, string>("method", "users.getInfo"));
                tuples.Add(new Tuple<string, string>("secure", "1"));
                tuples.Add(new Tuple<string, string>("session_key", accessToken));
                tuples.Add(new Tuple<string, string>("uids", vid));
                tuples.Add(new Tuple<string, string>("format", "json"));

                // http://api.mail.ru/docs/reference/rest/users-getinfo/
                // http://api.mail.ru/docs/guides/restapi/
                // compute the sig
                string sig;
                {
                    tuples.Sort();
                    var text = new StringBuilder();
                    foreach (var tuple in tuples)
                    {
                        text.AppendFormat("{0}={1}"
                           , tuple.Item1
                           , tuple.Item2
                           );
                    }
                    text.Append(secretKey);

                    using (MD5 md5 = MD5.Create())
                    {
                        byte[] bytes = System.Text.Encoding.ASCII.GetBytes(text.ToString());
                        byte[] hash = md5.ComputeHash(bytes);

                        sig = BitConverter.ToString(hash).Replace("-", string.Empty).ToLowerInvariant();
                    }
                }

                request = new RestRequest(ApiUrl, Method.GET);
                foreach (var tuple in tuples)
                {
                    request.AddParameter(tuple.Item1, tuple.Item2);
                }

                request.AddParameter("sig", sig);
                response = client.Execute(request);


                if (response.StatusCode != HttpStatusCode.OK)
                {
                    return ExternalAuthManager.GetError(referrer, response.Content);
                }

                JArray jArray = JArray.Parse(response.Content);
                dictionary = jArray[0].ToObject<Dictionary<string, object>>();
                object temp;
                if (dictionary.TryGetValue("first_name", out temp) && temp != null)
                    info.Firstname = temp.ToString();
                if (dictionary.TryGetValue("last_name", out temp) && temp != null)
                    info.Lastname = temp.ToString();
                if (dictionary.TryGetValue("email", out temp) && temp != null)
                    info.Email = temp.ToString();

                if (dictionary.TryGetValue("birthday", out temp) && temp != null)
                {
                    string birth = temp.ToString();
                    DateTime birthDate;
                    if (!string.IsNullOrWhiteSpace(birth) &&
                        DateTime.TryParseExact(birth, "d.M.yyyy", CultureInfo.InvariantCulture, DateTimeStyles.None, out birthDate))
                    {
                        info.Birth = birthDate;
                    }
                }

                if (dictionary.TryGetValue("sex", out temp) && temp != null)
                {
                    string gender = temp.ToString();
                    if (string.Equals(gender, "0", StringComparison.InvariantCultureIgnoreCase))
                        info.IsFemale = false;
                    else if (string.Equals(gender, "1", StringComparison.InvariantCultureIgnoreCase))
                        info.IsFemale = true;
                }
            }
            catch (Exception ex)
            {
                return referrer.SetError(ex.Message);
            }

            referrer.Save();

            return referrer;

        }
    }
}
