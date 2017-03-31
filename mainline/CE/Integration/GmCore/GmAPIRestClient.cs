using System;
using System.Collections.Generic;
using System.Configuration;
using System.IO;
using System.Net;
using System.Runtime.Serialization;
using System.Text;

namespace GamMatrixAPI
{
    public class GmAPIRestClient : IDisposable
    {
        public void Dispose()
        {
        }

        #region Constants
        private const int TIMEOUT_MS = 150 * 1000; //timeout in milliseconds, default set to 1 minute
        #endregion

        #region Constructor
        public GmAPIRestClient()
            : this(ConfigurationManager.AppSettings["GmCore.RestURL"], TIMEOUT_MS) { }

        public GmAPIRestClient(string serviceURL) 
            : this(serviceURL, TIMEOUT_MS) { }

        public GmAPIRestClient(string serviceURL, int timeoutMs)
        {
            this._serviceURL = serviceURL;
            this._timeoutMs = timeoutMs;
        }
        #endregion

        #region Properties
        private string _serviceURL;
        private int _timeoutMs;
        #endregion
        
        #region Public methods
        public void Open() { }

        public void Close() { }

        public GamMatrixAPI.ReplyResponse Login(GamMatrixAPI.LoginRequest request) 
        { 
            return SendRequest(request); 
        }

        public GamMatrixAPI.ReplyResponse IsLoggedIn(GamMatrixAPI.IsLoggedInRequest request) 
        { 
            return SendRequest(request); 
        }

        public GamMatrixAPI.ReplyResponse SingleRequest(GamMatrixAPI.HandlerRequest request) 
        { 
            return SendRequest(request); 
        }

        public List<GamMatrixAPI.ReplyResponse> MultiRequest(List<GamMatrixAPI.HandlerRequest> requests) 
        { 
            return SendMultiRequest(requests, GamMatrixAPI.CoreAPIMessageType.MultiRequest); 
        }

        public List<GamMatrixAPI.ReplyResponse> ParallelMultiRequest(List<GamMatrixAPI.HandlerRequest> requests) 
        { 
            return SendMultiRequest(requests, GamMatrixAPI.CoreAPIMessageType.ParallelMultiRequest); 
        }
        #endregion

        #region Async

        //delegates
        public delegate GamMatrixAPI.ReplyResponse AsyncLogin(GamMatrixAPI.LoginRequest request);
        public delegate GamMatrixAPI.ReplyResponse AsyncIsLoggedIn(GamMatrixAPI.IsLoggedInRequest request);
        public delegate GamMatrixAPI.ReplyResponse AsyncSingleRequest(GamMatrixAPI.HandlerRequest request);
        public delegate List<GamMatrixAPI.ReplyResponse> AsyncMultiRequest(List<GamMatrixAPI.HandlerRequest> requests);
        public delegate List<GamMatrixAPI.ReplyResponse> AsyncParallelMultiRequest(List<GamMatrixAPI.HandlerRequest> requests);

        //methods
        public IAsyncResult BeginLogin(GamMatrixAPI.LoginRequest request, AsyncCallback callback, object asyncState)
        {
            AsyncLogin caller = new AsyncLogin(this.Login);
            return caller.BeginInvoke(request, callback, new object[] { caller, asyncState });
        }

        public GamMatrixAPI.ReplyResponse EndLogin(IAsyncResult result)
        {
            AsyncLogin caller = (AsyncLogin)((object[])result.AsyncState)[0];
            return caller.EndInvoke(result);
        }

        public IAsyncResult BeginIsLoggedIn(GamMatrixAPI.IsLoggedInRequest request, AsyncCallback callback, object asyncState)
        {
            AsyncIsLoggedIn caller = new AsyncIsLoggedIn(this.IsLoggedIn);
            return caller.BeginInvoke(request, callback, new object[] { caller, asyncState });
        }

        public GamMatrixAPI.ReplyResponse EndIsLoggedIn(IAsyncResult result)
        {
            AsyncIsLoggedIn caller = (AsyncIsLoggedIn)((object[])result.AsyncState)[0];
            return caller.EndInvoke(result);
        }

        public IAsyncResult BeginSingleRequest(GamMatrixAPI.HandlerRequest request, AsyncCallback callback, object asyncState)
        {
            AsyncSingleRequest caller = new AsyncSingleRequest(this.SingleRequest);
            return caller.BeginInvoke(request, callback, new object[] { caller, asyncState });
        }

        public GamMatrixAPI.ReplyResponse EndSingleRequest(IAsyncResult result)
        {
            AsyncSingleRequest caller = (AsyncSingleRequest)((object[])result.AsyncState)[0];
            return caller.EndInvoke(result);
        }

        public IAsyncResult BeginMultiRequest(List<GamMatrixAPI.HandlerRequest> requests, AsyncCallback callback, object asyncState)
        {
            AsyncMultiRequest caller = new AsyncMultiRequest(this.MultiRequest);
            return caller.BeginInvoke(requests, callback, new object [] { caller, asyncState });
        }

        public List<GamMatrixAPI.ReplyResponse> EndMultiRequest(IAsyncResult result)
        {
            AsyncMultiRequest caller = (AsyncMultiRequest)((object[])result.AsyncState)[0];
            return caller.EndInvoke(result);
        }

        public IAsyncResult BeginParallelMultiRequest(List<GamMatrixAPI.HandlerRequest> requests, AsyncCallback callback, object asyncState)
        {
            AsyncParallelMultiRequest caller = new AsyncParallelMultiRequest(this.ParallelMultiRequest);
            return caller.BeginInvoke(requests, callback, new object[] { caller, asyncState });
        }

        public List<GamMatrixAPI.ReplyResponse> EndParallelMultiRequest(IAsyncResult result)
        {
            AsyncParallelMultiRequest caller = (AsyncParallelMultiRequest)((object[])result.AsyncState)[0];
            return caller.EndInvoke(result);
        }
        #endregion

        #region Private methods
        private GamMatrixAPI.ReplyResponse SendRequest(GamMatrixAPI.HandlerRequest request)
        {
            var msg = new GamMatrixAPI.CoreAPIMessageRequest
            {
                Type = GamMatrixAPI.CoreAPIMessageType.SingleRequest,
                ClassName = new List<string> { request.GetType().Name },
                SerializedRequest = new List<string> { Encoding.UTF8.GetString(Serialize(request)) }
            };
            return (GamMatrixAPI.ReplyResponse)
                Deserialize(typeof(GamMatrixAPI.ReplyResponse),
                    Encoding.UTF8.GetBytes(Send(msg, _timeoutMs)));
        }

        private List<GamMatrixAPI.ReplyResponse> SendMultiRequest(List<GamMatrixAPI.HandlerRequest> requests, GamMatrixAPI.CoreAPIMessageType type)
        {
            var msg = new GamMatrixAPI.CoreAPIMessageRequest
            {
                Type = type,
                ClassName = new List<string>(),
                SerializedRequest = new List<string>()
            };
            requests.ForEach(request =>
            {
                msg.ClassName.Add(request.GetType().Name);
                msg.SerializedRequest.Add(Encoding.UTF8.GetString(Serialize(request)));
            });
            return (List<GamMatrixAPI.ReplyResponse>)
                Deserialize(typeof(List<GamMatrixAPI.ReplyResponse>),
                    Encoding.UTF8.GetBytes(Send(msg, _timeoutMs)));
        }

        private string Send(object obj, int timeoutMs)
        {
            return new WebRequestHelper(_serviceURL, Serialize(obj), timeoutMs).Send().ResponseText;
        }

        private byte[] Serialize(object obj)
        {
            var formatter = new DataContractSerializer(obj.GetType());
            using (var ms = new MemoryStream())
            {
                formatter.WriteObject(ms, obj);
                return ms.ToArray();
            }
        }

        private object Deserialize(Type type, byte[] data)
        {
            var formatter = new DataContractSerializer(type);
            using (var ms = new MemoryStream(data))
            {
                return formatter.ReadObject(ms);
            }
        }
        #endregion

        #region Web helpers
        private class WebRequestHelper
        {
            #region Constructor
            public WebRequestHelper(string url, byte [] rawPOSTData, int timeoutMs)
            {
                this.Url = url;
                this.RawPOSTData = rawPOSTData;
                this.TimeoutMs = timeoutMs;
            }
            #endregion

            #region Properties
            public string Url { get; private set; }
            public byte[] RawPOSTData { get; set; }
            public int TimeoutMs { get; set; }
            #endregion

            #region Public methods
            public WebResponseHelper Send()
            {
                return new WebResponseHelper(this);
            }           
            #endregion
        }

        private class WebResponseHelper
        {
            #region Constructor
            public WebResponseHelper(WebRequestHelper request)
            {
                Post(request);
            }
            #endregion

            #region Properties
            private byte[] _responseBytes;
            public byte[] ResponseBytes
            {
                get { return _responseBytes; }
            }

            public string ResponseText
            {
                get { return Encoding.UTF8.GetString(_responseBytes); }
            }
            #endregion

            #region Private methods
            private void Post(WebRequestHelper request)
            {
                HttpWebRequest req = (HttpWebRequest)WebRequest.Create(request.Url);
                req.Method = "POST";
                req.Timeout = request.TimeoutMs;
                byte[] paramByteArray = request.RawPOSTData;
                req.ContentType = "application/x-www-form-urlencoded";
                req.ContentLength = paramByteArray.Length;
                using (Stream dataStream = req.GetRequestStream())
                {
                    dataStream.Write(paramByteArray, 0, paramByteArray.Length);
                }
                GetResponse(req);
            }

            private void GetResponse(HttpWebRequest req)
            {
                HttpWebResponse resp = null;
                try
                {
                    resp = (HttpWebResponse)req.GetResponse();                    
                    using (Stream dataStream = resp.GetResponseStream())
                    {
                        _responseBytes = ReadStream(dataStream);
                    }
                }
                finally
                {
                    if (resp != null)
                    {
                        resp.Close();
                    }
                }
            }

            private byte[] ReadStream(Stream stream)
            {
                byte[] buffer = new byte[32768];
                using (MemoryStream ms = new MemoryStream())
                {
                    while (true)
                    {
                        int read = stream.Read(buffer, 0, buffer.Length);
                        if (read <= 0)
                            return ms.ToArray();
                        ms.Write(buffer, 0, read);
                    }
                }
            }
            #endregion
        }
        #endregion
    }    
}
