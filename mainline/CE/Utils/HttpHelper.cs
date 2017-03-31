using System;
using System.Collections.Generic;
using System.Collections.Specialized;
using System.IO;
using System.Linq;
using System.Net;
using System.Net.Cache;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;

namespace CE.Utils
{
    public class HttpHelper
    {
        public static string GetData(Uri resourceLocation, NameValueCollection headers = null, HttpRequestCacheLevel cachingLevel = HttpRequestCacheLevel.Default)
        {
            var http = (HttpWebRequest)WebRequest.Create(resourceLocation);

            http.CachePolicy = new HttpRequestCachePolicy(cachingLevel);
            http.Method = WebRequestMethods.Http.Get;

            ApplyHeaders(http, headers);

            using (WebResponse response = http.GetResponse())
            {
                using (Stream stream = response.GetResponseStream())
                {
                    if (stream == null)
                        return string.Empty;

                    return new StreamReader(stream).ReadToEnd();
                }
            }
        }

        public static string PostData(Uri resourceLocation, string bodyContent, NameValueCollection headers = null)
        {
            var http = (HttpWebRequest)WebRequest.Create(resourceLocation);

            //http.Accept = "application/json";
            http.ContentType = "application/json";
            http.Method = WebRequestMethods.Http.Post;

            ApplyHeaders(http, headers);

            Byte[] bytes = Encoding.UTF8.GetBytes(bodyContent ?? "");

            using (Stream newStream = http.GetRequestStream())
            {
                newStream.Write(bytes, 0, bytes.Length);
            }

            using (WebResponse response = http.GetResponse())
            {
                using (var stream = response.GetResponseStream())
                {
                    if (stream == null)
                        return string.Empty;

                    return new StreamReader(stream).ReadToEnd();
                }
            }
        }
        public static string PostFormUrlEncodedContent(Uri baseUrl, string requestUrl, Dictionary<string, string> bodyContent, Dictionary<string, string> headers = null)
        {
            HttpClient client = new HttpClient { BaseAddress = baseUrl };
            HttpRequestMessage request = new HttpRequestMessage(HttpMethod.Post, requestUrl)
            {
                Content = new FormUrlEncodedContent(bodyContent)
            };

            if (headers != null)
            {
                foreach (KeyValuePair<string, string> pair in headers)
                {
                    if (!string.IsNullOrEmpty(pair.Value) && !request.Headers.Contains(pair.Key))
                    {
                        request.Headers.Add(pair.Key, pair.Value);
                    }
                }
            }

            HttpResponseMessage result = client.SendAsync(request).Result;

            if (result != null && result.Content != null)
            {
                return Encoding.UTF8.GetString(result.Content.ReadAsByteArrayAsync().Result);
            }
            return string.Empty;
        }

        public static string DeleteData(Uri resourceLocation, NameValueCollection headers = null)
        {
            var http = (HttpWebRequest)WebRequest.Create(resourceLocation);

            http.Method = "DELETE";

            ApplyHeaders(http, headers);

            using (WebResponse response = http.GetResponse())
            {
                using (Stream stream = response.GetResponseStream())
                {
                    if (stream == null)
                        return string.Empty;

                    return new StreamReader(stream).ReadToEnd();
                }
            }
        }

        public static void ApplyHeaders(HttpWebRequest request, NameValueCollection headers)
        {
            if (request == null || headers == null)
                return;

            // Restricted headers that should be modified through properties only
            request.UserAgent = headers.Get("User-Agent");
            if (headers.Get("KeepAlive") != null)
            {
                request.KeepAlive = headers.Get("KeepAlive").ParseToBool(true);
            }

            if (headers.Get("Content-Type") != null)
            {
                request.ContentType = headers.Get("Content-Type");
            }

            if (headers.Get("Host") != null)
            {
                request.Host = headers.Get("Host");
            }

            // Add all not restricted headers
            foreach (var headerKey in headers.AllKeys)
            {
                if (!WebHeaderCollection.IsRestricted(headerKey))
                {
                    request.Headers.Add(headerKey, headers[headerKey]);
                }
            }
        }

        public static void ApplyHeaders(WebClient client, NameValueCollection headers)
        {
            if (client == null || headers == null)
                return;

            client.Headers.Add(headers);
        }
    }
}
