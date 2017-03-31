using System;
using System.Collections.Generic;
using System.Configuration;
using System.IO;
using System.Net;
using CE.Utils;
using GamMatrixAPI;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace GmGamingAPI
{
    public class GmGamingRestClient : IDisposable
    {
        public void Dispose() { }

        private const int TIMEOUT_MS = 150 * 1000;

        private string _serviceURL;
        private int _timeoutMs;

        public GmGamingRestClient()
            : this(ConfigurationManager.AppSettings["GmGaming.RestURL"], TIMEOUT_MS) { }

        public GmGamingRestClient(string serviceURL)
            : this(serviceURL, TIMEOUT_MS) { }

        public GmGamingRestClient(string serviceURL, int timeoutMs)
        {
            this._serviceURL = serviceURL;
            this._timeoutMs = timeoutMs;
        }

        public TokenResponse GetToken(long domainId, long userId, VendorID vendorId, bool logActivity = false)
        {
            TokenRequest tokenRequest = new TokenRequest()
            {
                DomainId = domainId, 
                UserID = userId, 
                VendorID = vendorId,
            };

            return GetToken(tokenRequest, logActivity);
        }

        public TokenResponse GetToken(TokenRequest tokenRequest, bool logActivity = false)
        {
            string path = string.Format("/token/{0}/create", tokenRequest.VendorID);
            string responseContent = Request(tokenRequest, path);

            JObject jObj = JObject.Parse(responseContent);
            TokenResponse tokenResponse = jObj.ToObject<TokenResponse>();

            if (logActivity)
            {
                var tokenParams = new Dictionary<string, object>();
                tokenParams.Add("VendorID", tokenRequest.VendorID);
                tokenParams.Add("DomainID", tokenRequest.DomainId);
                tokenParams.Add("UserSession", tokenRequest.UserID);
                tokenParams.Add("ResponseContent", responseContent);
                GmLogger.Instance.Trace(tokenParams, "GetToken at {0}, {1}, {2}", tokenRequest.VendorID.ToString(), tokenRequest.DomainId, tokenRequest.UserID);
            }
            return tokenResponse;
        }      

        #region
        private string GetApiURL(string path)
        {
            return string.Format("{0}{1}", this._serviceURL, path);
        }

        private string Request<T>(T request, string path) where T : GmGamingRequestBase
        {           
            using(GamMatrixClient gmClient = new GamMatrixClient())
            {
                request.SessionId = gmClient.GetApiParameters(request.DomainId, false).SessionID;
            }
            
            JObject jObj = JObject.FromObject(request);

            return Post(jObj.ToString(), path);
        }

        private string Post(string data, string path)
        {
            WebRequest request = HttpWebRequest.Create(GetApiURL(path));
            request.Method = "POST";
            request.ContentType = "application/json";
            request.Timeout = this._timeoutMs;

            using (StreamWriter writer = new StreamWriter(request.GetRequestStream()))
            {
                writer.Write(data);
            }

            WebResponse response = null;
            try
            {
                response = request.GetResponse();
                using (StreamReader reader = new StreamReader(response.GetResponseStream()))
                {
                    return reader.ReadToEnd();
                }
            }
            finally
            {
                if(response!=null)
                    response.Close();
            }
        }
        #endregion
    }
}