using System;
using System.Collections.Concurrent;
using System.Collections.Generic;

namespace GmCore
{
    /// <summary>
    /// Summary description for GmAPIWcfClient
    /// </summary>
    public sealed class GmAPIWcfClient : IGmAPIClient
    {
        private static ConcurrentBag<GamMatrixAPI.APIServiceClient> s_Pool = new ConcurrentBag<GamMatrixAPI.APIServiceClient>();

        private static GamMatrixAPI.APIServiceClient GetClient()
        {
            GamMatrixAPI.APIServiceClient client;
            if (s_Pool.TryTake(out client))
                return client;

            else return new GamMatrixAPI.APIServiceClient();
        }

        private static void ReleaseClient(GamMatrixAPI.APIServiceClient client)
        {
            s_Pool.Add(client);
        }

        public GamMatrixAPI.ReplyResponse Login(GamMatrixAPI.LoginRequest request)
        {
            GamMatrixAPI.APIServiceClient client = GetClient();
            try
            {
                return client.Login(request);
            }
            finally
            {
                ReleaseClient(client);
            }
        }

        public GamMatrixAPI.ReplyResponse IsLoggedIn(GamMatrixAPI.IsLoggedInRequest request)
        {
            GamMatrixAPI.APIServiceClient client = GetClient();
            try
            {
                return client.IsLoggedIn(request);
            }
            finally
            {
                ReleaseClient(client);
            }
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="request"></param>
        /// <param name="timeoutMs">not used for WCF client</param>
        /// <returns></returns>
        public GamMatrixAPI.ReplyResponse SingleRequest(GamMatrixAPI.HandlerRequest request, int timeoutMs = -1)
        {
            GamMatrixAPI.APIServiceClient client = GetClient();
            try
            {
                return client.SingleRequest(request);
            }
            finally
            {
                ReleaseClient(client);
            }
        }

        private sealed class CustomizedParameters
        {
            public AsyncResult AsyncResult;
            public GamMatrixAPI.APIServiceClient APIServiceClient;
        }

        public IAsyncResult BeginSingleRequest(GamMatrixAPI.HandlerRequest request
            , Action<AsyncResult> asyncCallback
            , object userState1
            , object userState2
            , object userState3
            )
        {
            
            AsyncResult result = new AsyncResult(asyncCallback) 
            { 
                UserState1 = userState1,
                UserState2 = userState2,
                UserState3 = userState3,
            };

            GamMatrixAPI.APIServiceClient client = GetClient();
            CustomizedParameters cp = new CustomizedParameters()
            {
                AsyncResult = result,
                APIServiceClient = client,
            };
            return client.BeginSingleRequest(request, OnSingleRequestCompleted, cp);
        }

        private void OnSingleRequestCompleted(IAsyncResult ar)
        {
            CustomizedParameters cp = ar.AsyncState as CustomizedParameters;
            try
            {
                GamMatrixAPI.ReplyResponse replyResponse = cp.APIServiceClient.EndSingleRequest(ar);
                cp.AsyncResult.Complete(null, replyResponse);
            }
            catch (Exception ex)
            {
                cp.AsyncResult.Complete(ex, null);
            }
            finally
            {
                ReleaseClient(cp.APIServiceClient);
            }
        }

        public List<GamMatrixAPI.ReplyResponse> MultiRequest(List<GamMatrixAPI.HandlerRequest> requests)
        {
            GamMatrixAPI.APIServiceClient client = GetClient();
            try
            {
                return client.MultiRequest(requests);
            }
            finally
            {
                ReleaseClient(client);
            }
        }

        public List<GamMatrixAPI.ReplyResponse> ParallelMultiRequest(List<GamMatrixAPI.HandlerRequest> requests)
        {
            GamMatrixAPI.APIServiceClient client = GetClient();
            try
            {
                return client.ParallelMultiRequest(requests);
            }
            finally
            {
                ReleaseClient(client);
            }
        }
    }
}