using System;
using System.Collections.Generic;

namespace GmCore
{
    /// <summary>
    /// Summary description for IGmAPIClient
    /// </summary>
    public interface IGmAPIClient
    {
        GamMatrixAPI.ReplyResponse Login(GamMatrixAPI.LoginRequest request);

        GamMatrixAPI.ReplyResponse IsLoggedIn(GamMatrixAPI.IsLoggedInRequest request);

        GamMatrixAPI.ReplyResponse SingleRequest(GamMatrixAPI.HandlerRequest request, int timeoutMs = -1);

        IAsyncResult BeginSingleRequest(GamMatrixAPI.HandlerRequest request
            , Action<AsyncResult> asyncCallback
            , object userState1
            , object userState2
            , object userState3
            );

        List<GamMatrixAPI.ReplyResponse> MultiRequest(List<GamMatrixAPI.HandlerRequest> requests);

        List<GamMatrixAPI.ReplyResponse> ParallelMultiRequest(List<GamMatrixAPI.HandlerRequest> requests);
    }
}