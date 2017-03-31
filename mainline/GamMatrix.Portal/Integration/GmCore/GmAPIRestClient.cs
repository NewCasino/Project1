using System;
using System.Collections.Generic;
using System.Configuration;
using System.IO;
using System.Net;
using System.Text;

namespace GmCore
{
    public class GmAPIRestClient : IGmAPIClient
    {
        #region Constants
        private const int TIMEOUT_MS = 180 * 1000; //timeout in milliseconds, default set to 180 seconds
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
        public GamMatrixAPI.ReplyResponse Login(GamMatrixAPI.LoginRequest request)
        {
            return SendRequest(request);
        }

        public GamMatrixAPI.ReplyResponse IsLoggedIn(GamMatrixAPI.IsLoggedInRequest request)
        {
            return SendRequest(request);
        }

        public GamMatrixAPI.ReplyResponse SingleRequest(GamMatrixAPI.HandlerRequest request, int timeoutMs = -1)
        {
            return SendRequest(request, timeoutMs);
        }



        public IAsyncResult BeginSingleRequest(GamMatrixAPI.HandlerRequest request
            , Action<AsyncResult> asyncCallback
            , object userState1
            , object userState2
            , object userState3
            )
        {
            
            GamMatrixAPI.CoreAPIMessageRequest msg = new GamMatrixAPI.CoreAPIMessageRequest
            {
                Type = GamMatrixAPI.CoreAPIMessageType.SingleRequest,
                ClassName = new List<string> { request.GetType().Name },
                SerializedRequest = new List<string> { Encoding.UTF8.GetString(ObjectHelper.XmlSerialize(request)) }
            };
            WebRequestHelper req = new WebRequestHelper(_serviceURL, ObjectHelper.XmlSerialize(msg), _timeoutMs);
            req.TypeName = request.GetType().Name;

            return req.SendSingleRequestAsync(asyncCallback, userState1, userState2, userState3);
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

        #region Private methods
        private GamMatrixAPI.ReplyResponse SendRequest(GamMatrixAPI.HandlerRequest request, int timeoutMs = -1)
        {
            GamMatrixAPI.CoreAPIMessageRequest msg = new GamMatrixAPI.CoreAPIMessageRequest
            {
                Type = GamMatrixAPI.CoreAPIMessageType.SingleRequest,
                ClassName = new List<string> { request.GetType().Name },
                SerializedRequest = new List<string> { Encoding.UTF8.GetString(ObjectHelper.XmlSerialize(request)) }
            };
            WebRequestHelper req = new WebRequestHelper(_serviceURL
                , ObjectHelper.XmlSerialize(msg)
                , timeoutMs > 0 ? timeoutMs : _timeoutMs
                );

            return req.SendSingleRequest();
        }

        private List<GamMatrixAPI.ReplyResponse> SendMultiRequest(List<GamMatrixAPI.HandlerRequest> requests, GamMatrixAPI.CoreAPIMessageType type)
        {
            GamMatrixAPI.CoreAPIMessageRequest msg = new GamMatrixAPI.CoreAPIMessageRequest
            {
                Type = type,
                ClassName = new List<string>(),
                SerializedRequest = new List<string>()
            };
            requests.ForEach(request =>
            {
                msg.ClassName.Add(request.GetType().Name);
                msg.SerializedRequest.Add(Encoding.UTF8.GetString(ObjectHelper.XmlSerialize(request)));
            });
            WebRequestHelper req = new WebRequestHelper(_serviceURL, ObjectHelper.XmlSerialize(msg), _timeoutMs);

            return req.SendMultiRequest();
        }

        
        #endregion


        private sealed class WebRequestHelper
        {
            public WebRequestHelper(string url, byte[] rawPOSTData, int timeoutMs)
            {
                this.HttpWebRequest = (HttpWebRequest)WebRequest.Create(url);
                this.HttpWebRequest.Method = "POST";
                this.HttpWebRequest.Timeout = timeoutMs;
                this.HttpWebRequest.ContentType = "application/x-www-form-urlencoded";
                this.HttpWebRequest.ContentLength = rawPOSTData.Length;

                this.RawPOSTData = rawPOSTData;
            }


            public HttpWebRequest HttpWebRequest { get; private set; }
            public byte[] RawPOSTData { get; private set; }
            public byte[] ResponseBytes { get; private set; }
            public string TypeName { get; internal set; }
            private long StartTick { get; set; }

            public GamMatrixAPI.ReplyResponse SendSingleRequest()
            {
                return ObjectHelper.XmlDeserialize<GamMatrixAPI.ReplyResponse>(SendRequest());
            }

            public List<GamMatrixAPI.ReplyResponse> SendMultiRequest()
            {
                return ObjectHelper.XmlDeserialize<List<GamMatrixAPI.ReplyResponse>>(SendRequest());
            }

            private byte[] SendRequest()
            {
                using (Stream dataStream = this.HttpWebRequest.GetRequestStream())
                {
                    dataStream.Write(this.RawPOSTData, 0, this.RawPOSTData.Length);
                }

                HttpWebResponse resp = null;
                try
                {
                    resp = (HttpWebResponse)this.HttpWebRequest.GetResponse();
                    using (Stream dataStream = resp.GetResponseStream())
                    {
                        return ReadStream(dataStream);
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

            public IAsyncResult SendSingleRequestAsync(Action<AsyncResult> asyncCallback
                , object userState1
                , object userState2
                , object userState3
                )
            {
                this.StartTick = DateTime.Now.Ticks;

                AsyncResult async = new AsyncResult(asyncCallback);
                async.UserState1 = userState1;
                async.UserState2 = userState2;
                async.UserState3 = userState3;
                this.HttpWebRequest.BeginGetRequestStream(this.OnGetRequestStreamCompleted, async);

                return async;
            }

            private void OnGetRequestStreamCompleted(IAsyncResult ar)
            {
                AsyncResult async = ar.AsyncState as AsyncResult;
                try
                {
                    decimal elapsedSeconds = (DateTime.Now.Ticks - StartTick) / 10000000.000M;
                    if( elapsedSeconds > 2.0M )
                        Logger.CodeProfiler("Diagnose", "GMCore API [{0}] {1:f2}s;", this.TypeName, elapsedSeconds);

                    using (Stream dataStream = this.HttpWebRequest.EndGetRequestStream(ar))
                    {
                        dataStream.Write(this.RawPOSTData, 0, this.RawPOSTData.Length);
                    }

                    this.HttpWebRequest.BeginGetResponse(this.OnGetResponseCompleted, async);
                }
                catch (Exception ex)
                {
                    ex.Source = string.Format( "GmCore API [{0}]", TypeName);
                    Logger.Exception(ex);
                    async.Complete(ex, null);
                }
            }


            private void OnGetResponseCompleted(IAsyncResult ar)
            {
                AsyncResult async = ar.AsyncState as AsyncResult;
                try
                {
                    HttpWebResponse resp = this.HttpWebRequest.EndGetResponse(ar) as HttpWebResponse;
                    using (Stream dataStream = resp.GetResponseStream())
                    {
                        byte [] bytes = ReadStream(dataStream);
                        GamMatrixAPI.ReplyResponse replyResponse = ObjectHelper.XmlDeserialize<GamMatrixAPI.ReplyResponse>(bytes);
                        async.Complete(null, replyResponse);
                    }                    
                }
                catch (Exception ex)
                {
                    ex.Source = string.Format("GmCore API [{0}]", TypeName);
                    Logger.Exception(ex);
                    async.Complete(ex, null);
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
        }// WebRequestHelper

    } 
}
