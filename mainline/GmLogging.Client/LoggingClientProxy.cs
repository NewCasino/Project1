using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Net;
using System.Text;
using System.Threading.Tasks;

namespace GmLogging.Client
{
    public class LoggingClientProxy
    {
        string apiUrl;
        string addLogUrl;
        string appName;

        public LoggingClientProxy(string apiUrl, string appName)
        {
            if (string.IsNullOrEmpty(apiUrl))
                throw new ArgumentNullException("apiUrl can't be empty");

            if (string.IsNullOrEmpty(appName))
                throw new ArgumentNullException("appName can't be empty");

            this.apiUrl = apiUrl;
            this.appName = appName.Trim();
            addLogUrl = apiUrl.TrimEnd('/') + "/addlog";
        }

        public void AddLogAsync(IDictionary<string, object> values, Action<Exception> onClientException = null, Action<Exception> onServerException = null)
        {
            try
            {
                string message = JsonConvert.SerializeObject(values);

                string url = addLogUrl + string.Format("?appName={0}", appName);
                HttpWebRequest request = (HttpWebRequest)HttpWebRequest.Create(url);
                request.KeepAlive = false;
                request.ContentType = "application/json";
                request.Method = "POST";

                request.BeginGetRequestStream(OnBeginGetRequest, new Tuple<HttpWebRequest, string, Action<Exception>>(request, message, onServerException));
            }
            catch (Exception ex)
            {
                if (onClientException != null)
                    onClientException(ex);
            }
        }

        private void OnBeginGetRequest(IAsyncResult asyncResult)
        {
            Tuple<HttpWebRequest, string, Action<Exception>> args = (Tuple<HttpWebRequest, string, Action<Exception>>)asyncResult.AsyncState;
            HttpWebRequest request = (HttpWebRequest)args.Item1;
            string message = args.Item2;
            Action<Exception> onServerException = args.Item3;

            try
            {
                using (Stream requestStream = request.EndGetRequestStream(asyncResult))
                {
                    using (StreamWriter writer = new StreamWriter(requestStream))
                    {
                        writer.Write(message);
                    }
                }

                request.BeginGetResponse(OnBeginGetResponse, new Tuple<HttpWebRequest, Action<Exception>>(request, onServerException));
            }
            catch (Exception ex)
            {
                if (onServerException != null)
                {
                    onServerException(ex);
                }
            }
        }

        private void OnBeginGetResponse(IAsyncResult asyncResult)
        {
            Tuple<HttpWebRequest, Action<Exception>> args = (Tuple<HttpWebRequest, Action<Exception>>)asyncResult.AsyncState;
            HttpWebRequest request = args.Item1;
            Action<Exception> onServerException = args.Item2;

            try
            {
                HttpWebResponse response = (HttpWebResponse)request.EndGetResponse(asyncResult);
                response.Dispose(); // required to close connection
            }
            catch (Exception ex)
            {
                if (onServerException != null)
                    onServerException(ex);
            }
        }

    }
}
