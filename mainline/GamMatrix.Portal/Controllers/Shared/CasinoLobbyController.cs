using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Mvc;
using Casino;
using CM.Sites;
using CM.State;
using CM.Web;
using GamMatrixAPI;
using GmCore;

namespace GamMatrix.CMS.Controllers.Shared
{
    [HandleError]
    [ControllerExtraInfo(DefaultAction = "Index")]
    public class CasinoLobbyController : ControllerEx
    {
        [HttpGet]
        public ActionResult Index()
        {
            return this.View();
        }


        [HttpGet]
        public ActionResult JackpotRotator()
        {
            List<JackpotInfo> jackpots = GameManager.GetJackpots(CustomProfile.Current.IsAuthenticated ? CustomProfile.Current.UserCurrency : "EUR");
            return this.View("JackpotRotator", jackpots);
        }

        [HttpGet]
        public ActionResult LastWinners()
        {
            List<Winner> winners = GameManager.GetLastWinners();
            return this.View("LastWinners", winners);
        }

        public JsonResult GetNetEntFrequentPlayerPoints()
        {
            if( !CustomProfile.Current.IsAuthenticated )
                throw new UnauthorizedAccessException();

            using (GamMatrixClient client = GamMatrixClient.Get() )
            {
                decimal minClaimPoints = 99999.00M;
                var account = GamMatrixClient.GetUserGammingAccounts(CustomProfile.Current.UserID)
                    .FirstOrDefault(a => a.Record.VendorID == VendorID.NetEnt);
                if (account != null)
                {
                    NetEntGetClaimFPPDetailsRequest netEntGetClaimFPPDetailsRequest = new NetEntGetClaimFPPDetailsRequest()
                    {
                        AccountID = account.ID,
                    };
                    netEntGetClaimFPPDetailsRequest = client.SingleRequest<NetEntGetClaimFPPDetailsRequest>(netEntGetClaimFPPDetailsRequest);
                    minClaimPoints = netEntGetClaimFPPDetailsRequest.ClaimRec.CfgConvertionMinClaimPoints;
                }

                NetEntAPIRequest request = new NetEntAPIRequest()
                {
                    GetUserFrequentPlayerPointsBalance = true,
                    UserID = CustomProfile.Current.UserID,
                };
                request = client.SingleRequest<NetEntAPIRequest>(request);
                decimal points = request.GetUserFrequentPlayerPointsBalanceResponse;
                return this.Json(new { @success = true, @points = points, @claimable = points >= minClaimPoints }, JsonRequestBehavior.AllowGet);
            }
        }

        public JsonResult ClaimNetEntFrequentPlayerPoints()
        {
            if( !CustomProfile.Current.IsAuthenticated )
                throw new UnauthorizedAccessException();

            using (GamMatrixClient client = GamMatrixClient.Get() )
            {
                NetEntClaimFPPRequest request = new NetEntClaimFPPRequest()
                {
                    UserID = CustomProfile.Current.UserID,
                    ClaimedByUserID = CustomProfile.Current.UserID,
                };
                request = client.SingleRequest<NetEntClaimFPPRequest>(request);

                if (request == null || request.Record.Status != PreTransStatus.Success)
                    return this.Json(new { @success = false, @error = string.Empty }, JsonRequestBehavior.AllowGet);

                return this.Json(new { @success = true }, JsonRequestBehavior.AllowGet);
            }
        }

                


    }
}
