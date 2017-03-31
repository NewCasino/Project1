using System;
using System.Web;
using System.Web.Mvc;
using CM.State;
using CM.Web;
using GamMatrixAPI;
using GmCore;

namespace GamMatrix.CMS.Controllers.PlayAdjara
{
    [ControllerExtraInfo(ParameterUrl = "{category}/")]
    /// <summary>
    /// Summary description for PlayAdjaraLiveCasinoController
    /// </summary>
    public class PlayAdjaraLiveCasinoController : GamMatrix.CMS.Controllers.Shared.LiveCasinoLobbyController
    {
        public enum PALiveDealerType
        {
            LiveAutoRoulette,
            LiveDealerRoulette,
            ClassicSlots,
            ClassicSeka,
            ClassicBura,
            ClassicDuraka,
        }

        [HttpGet]
        public void PALoaderAsync(PALiveDealerType type)
        {
            AsyncManager.OutstandingOperations.Increment();
            GetPALiveDealerUrlAsync(type, OnGetPAUrl);
        }

        private void OnGetPAUrl(string url)
        {
            AsyncManager.Parameters["url"] = url;
            AsyncManager.OutstandingOperations.Decrement();
        }

        public ActionResult PALoaderCompleted(string url)
        {
            return this.Redirect(url);
        }


        
        private static void GetPALiveDealerUrlAsync(PALiveDealerType type, Action<string> callback)
        {
            string url;
            switch (type)
            {
                case PALiveDealerType.LiveAutoRoulette:
                    url = Settings.LiveCasino_PALiveAutoRouletteUrl;
                    break;

                case PALiveDealerType.LiveDealerRoulette:
                    url = Settings.LiveCasino_PALiveDealerRouletteUrl;
                    break;

                case PALiveDealerType.ClassicBura:
                    url = Settings.LiveCasino_PAClassicGamesBuraUrl;
                    break;

                case PALiveDealerType.ClassicDuraka:
                    url = Settings.LiveCasino_PAClassicGamesDurakaUrl;
                    break;

                case PALiveDealerType.ClassicSeka:
                    url = Settings.LiveCasino_PAClassicGamesSekaUrl;
                    break;

                case PALiveDealerType.ClassicSlots:
                    url = Settings.LiveCasino_PAClassicGamesSlotsUrl;
                    break;

                default:
                    throw new NotSupportedException();
            }

            if (CustomProfile.Current.IsAuthenticated)
            {
                if (type == PALiveDealerType.LiveAutoRoulette || type == PALiveDealerType.LiveDealerRoulette)
                {
                    PACasinoAPIRequest request = new PACasinoAPIRequest()
                    {
                        RegisterToken = true,
                        RegisterTokenGameCode = "1",
                        RegisterTokenUserID = CustomProfile.Current.UserID,
                    };
                    GamMatrixClient.SingleRequestAsync<PACasinoAPIRequest>(request, OnGetPACasinoUrlCompleted, callback, url);
                }
                else
                {
                    PAClassicAPIRequest request = new PAClassicAPIRequest()
                    {
                        RegisterToken = true,
                        RegisterTokenGameCode = "2",
                        RegisterTokenUserID = CustomProfile.Current.UserID,
                    };
                    GamMatrixClient.SingleRequestAsync<PAClassicAPIRequest>(request, OnGetPAClassicUrlCompleted, callback, url);
                }

                return;
            }
            callback(string.Format(url, string.Empty));
        }

        private static void OnGetPACasinoUrlCompleted(AsyncResult result)
        {
            string token = null;

            try
            {
                PACasinoAPIRequest response = result.EndSingleRequest().Get<PACasinoAPIRequest>();
                token = response.RegisterTokenResponse;
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
            }

            try
            {
                Action<string> callback = result.UserState1 as Action<string>;
                string urlFormat = result.UserState2 as string;
                if (callback != null)
                    callback(string.Format(urlFormat, HttpUtility.UrlEncode(token)));
            }
            catch
            {
            }
        }

        private static void OnGetPAClassicUrlCompleted(AsyncResult result)
        {
            string token = null;

            try
            {
                PAClassicAPIRequest response = result.EndSingleRequest().Get<PAClassicAPIRequest>();
                token = response.RegisterTokenResponse;
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
            }

            try
            {
                Action<string> callback = result.UserState1 as Action<string>;
                string urlFormat = result.UserState2 as string;
                if (callback != null)
                    callback(string.Format(urlFormat, HttpUtility.UrlEncode(token)));
            }
            catch
            {
            }
        }
    }
}