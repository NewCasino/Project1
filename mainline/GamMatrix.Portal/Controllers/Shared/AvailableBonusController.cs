using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Mvc;
using CM.Sites;
using CM.State;
using CM.Web;
using GamMatrixAPI;
using GmCore;

namespace GamMatrix.CMS.Controllers.Shared
{
    [HandleError]
    [ControllerExtraInfo(DefaultAction = "Casino")]
    public class AvailableBonusController : AsyncControllerEx
    {
        [HttpGet]
        public ActionResult Casino()
        {
            if (!CustomProfile.Current.IsAuthenticated)
            {
                return this.View("Anonymous");
            }
            try
            {

                using (GamMatrixClient client = GamMatrixClient.Get() )
                {
                    GetUserBonusDetailsRequest request = new GetUserBonusDetailsRequest()
                    {
                        UserID = CustomProfile.Current.UserID
                    };
                    request = client.SingleRequest<GetUserBonusDetailsRequest>(request);
                    var data = request.Data.Where(b => b.VendorID == VendorID.NetEnt || b.VendorID == VendorID.CasinoWallet);

                    List<BonusData> bonuses = new List<BonusData>();

                    List<BonusData> bonusesSort = new List<BonusData>();

                    foreach (BonusData bonus in data)
                    {
                        if (!string.Equals(bonus.Status, "Queued", StringComparison.InvariantCultureIgnoreCase))
                        {
                            if (string.Equals(bonus.Type, "No deposit", StringComparison.InvariantCultureIgnoreCase) ||
                                string.Equals(bonus.Type, "Free Spin bonus", StringComparison.InvariantCultureIgnoreCase))
                            {
                                bonus.ConfiscateAllFundsOnForfeiture = false;
                            }
                        }
                        if (string.Equals(bonus.Status, "Granted", StringComparison.InvariantCultureIgnoreCase))
                        {
                            bonuses.Add(bonus);
                        }
                        else
                        {
                            bonusesSort.Add(bonus);
                        }
                    }

                    bonuses.AddRange(bonusesSort.OrderByDescending(b => b.Priority));

                    return View("Casino", bonuses);
                }
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                this.ViewData["ErrorMessage"] = GmException.TryGetFriendlyErrorMsg(ex);
                return View("Error");
            }
        }

        protected List<BonusData> GetAvailableCasinoBonus()
        {
            List<BonusData> bonuses = null;
            using (GamMatrixClient client = GamMatrixClient.Get())
            {
                GetUserBonusDetailsRequest request = new GetUserBonusDetailsRequest()
                {
                    UserID = CustomProfile.Current.UserID
                };
                request = client.SingleRequest<GetUserBonusDetailsRequest>(request);
                bonuses = request.Data.Where(b => b.VendorID == VendorID.NetEnt || b.VendorID == VendorID.CasinoWallet).ToList();
                foreach (BonusData bonus in bonuses)
                {
                    if (!string.Equals(bonus.Status, "Queued", StringComparison.InvariantCultureIgnoreCase))
                    {
                        if (string.Equals(bonus.Type, "No deposit", StringComparison.InvariantCultureIgnoreCase) ||
                            string.Equals(bonus.Type, "Free Spin bonus", StringComparison.InvariantCultureIgnoreCase))
                        {
                            bonus.ConfiscateAllFundsOnForfeiture = false;
                        }
                    }
                }
            }
            return bonuses;
        }

        [HttpGet]
        public ActionResult Poker()
        {
            if (!CustomProfile.Current.IsAuthenticated)
            {
                return this.View("Anonymous");
            }
            try
            {

                using (GamMatrixClient client = GamMatrixClient.Get())
                {
                    GetUserBonusDetailsRequest request = new GetUserBonusDetailsRequest()
                    {
                        UserID = CustomProfile.Current.UserID
                    };
                    request = client.SingleRequest<GetUserBonusDetailsRequest>(request);
                    List<BonusData> bonuses = request.Data.Where(b => b.VendorID == VendorID.MergeNetwork || b.VendorID == VendorID.CakeNetwork || b.VendorID == VendorID.ENET).ToList();

                    return View("Poker", bonuses);
                }
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                this.ViewData["ErrorMessage"] = GmException.TryGetFriendlyErrorMsg(ex);
                return View("Error");
            }
        }

        [HttpGet]
        public ActionResult Sports()
        {
            if (!CustomProfile.Current.IsAuthenticated)
            {
                return this.View("Anonymous");
            }
            try
            {
                //GetUserAvailableSportsBonusDataRequest rq = new GetUserAvailableSportsBonusDataRequest();

                List<AvailableBonusData> bonuses = new List<AvailableBonusData>();
                if (Settings.IsOMSeamlessWalletEnabled)
                {
                    using (GamMatrixClient client = GamMatrixClient.Get())
                    {
                        GetUserAvailableBonusDetailsRequest request = new GetUserAvailableBonusDetailsRequest()
                        {
                            UserID = CustomProfile.Current.UserID
                        };
                        request = client.SingleRequest<GetUserAvailableBonusDetailsRequest>(request);
                        
                        if (request != null && request.Data != null)
                        {
                            bonuses = request.Data.Where(b => b.VendorID == VendorID.OddsMatrix).ToList();
                        }            
                    }
                }
                return View("Sports", bonuses);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                this.ViewData["ErrorMessage"] = GmException.TryGetFriendlyErrorMsg(ex);
                return View("Error");
            }
        }

        [HttpGet]
        public ActionResult Sportsbook()
        {
            if (!CustomProfile.Current.IsAuthenticated)
            {
                return this.View("Anonymous");
            }
            try
            {
                //GetUserAvailableSportsBonusDataRequest rq = new GetUserAvailableSportsBonusDataRequest();

                List<AvailableBonusData> bonuses = new List<AvailableBonusData>();
                /*if (Settings.IsBetConstructWalletEnabled)
                {
                    using (GamMatrixClient client = GamMatrixClient.Get())
                    {
                        GetUserAvailableBonusDetailsRequest request = new GetUserAvailableBonusDetailsRequest()
                        {
                            UserID = CustomProfile.Current.UserID
                        };
                        request = client.SingleRequest<GetUserAvailableBonusDetailsRequest>(request);

                        if (request != null && request.Data != null)
                        {
                            bonuses = request.Data.Where(b => b.VendorID == VendorID.BetConstruct).ToList();
                        }
                    }
                }*/
                return View("Sportsbook", bonuses);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                this.ViewData["ErrorMessage"] = GmException.TryGetFriendlyErrorMsg(ex);
                return View("Error");
            }
        }


        [HttpPost]
        [CustomValidateAntiForgeryToken]
        public JsonResult ForfeitCasinoBonus(string bonusID)
        {
            try
            {
                if (!CustomProfile.Current.IsAuthenticated)
                    throw new UnauthorizedAccessException();

                AccountData account = GamMatrixClient.GetUserGammingAccounts( CustomProfile.Current.UserID).FirstOrDefault( a => a.Record.VendorID == VendorID.CasinoWallet);
                if( account != null )
                {
                    using (GamMatrixClient client = GamMatrixClient.Get() )
                    {
                        ForfeitCasinoBonusRequest request = new ForfeitCasinoBonusRequest()
                        {
                            AccountID = account.ID,
                            UserCasinoBonusID = long.Parse(bonusID),                            
                        };
                        request = client.SingleRequest<ForfeitCasinoBonusRequest>(request);
                        return this.Json(new { @success = true });
                    }
                }
                return this.Json(new { @success = false, @error = string.Empty });
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false, @error = GmException.TryGetFriendlyErrorMsg(ex) } );
            }
        }


        [HttpPost]
        [CustomValidateAntiForgeryToken]
        public JsonResult ForfeitNetEntBonus(string bonusID)
        {
            try
            {
                if (!CustomProfile.Current.IsAuthenticated)
                    throw new UnauthorizedAccessException();

                AccountData account = GamMatrixClient.GetUserGammingAccounts(CustomProfile.Current.UserID).FirstOrDefault(a => a.Record.VendorID == VendorID.NetEnt);
                if (account != null)
                {
                    using (GamMatrixClient client = GamMatrixClient.Get())
                    {
                        NetEntAPIRequest request = new NetEntAPIRequest()
                        {
                            UserID = CustomProfile.Current.UserID,
                            ForfeitBonusForPlayer = true,
                            ForfeitBonusForPlayerBonusDepositionID = long.Parse(bonusID),
                        };
                        request = client.SingleRequest<NetEntAPIRequest>(request);
                        return this.Json(new { @success = true });
                    }
                }
                return this.Json(new { @success = false, @error = string.Empty });
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false, @error = GmException.TryGetFriendlyErrorMsg(ex) });
            }
        }

        //private JsonResult IovationCheck(string iovationBlackBox)
        //{
        //    if (!CustomProfile.Current.IsAuthenticated || !Settings.IovationDeviceTrack_Enabled)
        //        return null;

        //    string error = null;
        //    if (string.IsNullOrEmpty(iovationBlackBox))
        //    {
        //        error = "iovationBlackBox requreid !";
        //    }
        //    else
        //    {
        //        if (!GamMatrixClient.IovationCheck(CustomProfile.Current.UserID, IovationEventType.Bonus, iovationBlackBox,CasinoBonusType.NoDeposit))
        //        {
        //            error = "you are denied transfer !";
        //        }
        //    }

        //    if (error == null)
        //        return null;

        //    return this.Json(new
        //    {
        //        @success = false,
        //        @error = "iovationBlackBox requreid !"
        //    });
        //}


        [HttpPost]
        [CustomValidateAntiForgeryToken]
        public JsonResult ApplyCasinoBonusCode(string bonusCode, string iovationBlackbox = null)
        {
            try
            {
                if (!CustomProfile.Current.IsAuthenticated)
                    throw new UnauthorizedAccessException();

                AccountData account = GamMatrixClient
                    .GetUserGammingAccounts(CustomProfile.Current.UserID)
                    .Where(a => a.Record.ActiveStatus == ActiveStatus.Active )
                    .FirstOrDefault(a => a.Record.VendorID == VendorID.CasinoWallet || a.Record.VendorID == VendorID.NetEnt);
                if (account != null)
                {
                    using (GamMatrixClient client = GamMatrixClient.Get() )
                    {
                        ApplyBonusRequest request = new ApplyBonusRequest()
                        {
                            IovationBlackBox = iovationBlackbox,
                            AccountID = account.ID,
                            ApplyBonusVendorID = account.Record.VendorID,
                            ApplyBonusCode = bonusCode,
                        };
                        request = client.SingleRequest<ApplyBonusRequest>(request);
                        return this.Json(new { @success = true });
                    }
                }
                return this.Json(new { @success = false, @error = string.Empty });
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false, @error = GmException.TryGetFriendlyErrorMsg(ex) });
            }
        }

        [HttpPost]
        [CustomValidateAntiForgeryToken]
        public JsonResult ApplyBetConstructBonusCode(string bonusCode, string iovationBlackbox = null)
        {
            try
            {
                if (!CustomProfile.Current.IsAuthenticated)
                    throw new UnauthorizedAccessException();

                AccountData account = GamMatrixClient
                    .GetUserGammingAccounts(CustomProfile.Current.UserID)
                    .Where(a => a.Record.ActiveStatus == ActiveStatus.Active)
                    .FirstOrDefault(a => a.Record.VendorID == VendorID.CasinoWallet || a.Record.VendorID == VendorID.NetEnt);
                if (account != null)
                {
                    /*using (GamMatrixClient client = GamMatrixClient.Get())
                    {
                        ApplyBonusRequest request = new ApplyBonusRequest()
                        {
                            IovationBlackBox = iovationBlackbox,
                            AccountID = account.ID,
                            ApplyBonusVendorID = VendorID.BetConstruct,
                            ApplyBonusCode = bonusCode,
                        };
                        request = client.SingleRequest<ApplyBonusRequest>(request);
                        return this.Json(new { @success = true });
                    }*/
                }
                return this.Json(new { @success = false, @error = string.Empty });
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false, @error = GmException.TryGetFriendlyErrorMsg(ex) });
            }
        }

        [HttpPost]
        [CustomValidateAntiForgeryToken]
        public JsonResult ClaimCasinoFPP()
        {
            try
            {
                if (!CustomProfile.Current.IsAuthenticated)
                    throw new UnauthorizedAccessException();

                AccountData account = GamMatrixClient.GetUserGammingAccounts(CustomProfile.Current.UserID).FirstOrDefault(a => a.Record.VendorID == VendorID.CasinoWallet || a.Record.VendorID == VendorID.NetEnt);
                if (account != null)
                {
                    using (GamMatrixClient client = GamMatrixClient.Get() )
                    {
                        NetEntClaimFPPRequest request = new NetEntClaimFPPRequest()
                        {
                            UserID = CustomProfile.Current.UserID,
                            ClaimedByUserID = CustomProfile.Current.UserID,
                        };
                        request = client.SingleRequest<NetEntClaimFPPRequest>(request);
                        return this.Json(new { @success = true });
                    }
                }
                return this.Json(new { @success = false, @error = string.Empty });
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false, @error = GmException.TryGetFriendlyErrorMsg(ex) });
            }
        }

        [HttpPost]
        [CustomValidateAntiForgeryToken]
        public JsonResult TopBonus(long bonusID)
        {
            try
            {
                if (!CustomProfile.Current.IsAuthenticated)
                    throw new UnauthorizedAccessException();

                using (GamMatrixClient client = GamMatrixClient.Get())
                {
                    GetUserBonusDetailsRequest request = new GetUserBonusDetailsRequest()
                    {
                        UserID = CustomProfile.Current.UserID
                    };
                    request = client.SingleRequest<GetUserBonusDetailsRequest>(request);
                    List<BonusData> bonuses = request.Data.Where(b => b.VendorID == VendorID.NetEnt || b.VendorID == VendorID.CasinoWallet).OrderBy(b => b.Priority).ToList();

                    int priority = 0;
                    foreach(BonusData bonus in bonuses)
                    {
                        if(bonus.Priority > priority)
                            priority = bonus.Priority;
                    }

                    Dictionary<long, int> dic = new Dictionary<long, int>();
                    dic.Add(bonusID, priority+1);

                    UpdateQueuedBonusesPriorityRequest requestUpdateQueued = new UpdateQueuedBonusesPriorityRequest()
                    {
                        UserID = CustomProfile.Current.UserID,
                        DomainID = SiteManager.Current.DomainID,
                        QueuedBonusesPriority = dic
                    };
                    requestUpdateQueued = client.SingleRequest<UpdateQueuedBonusesPriorityRequest>(requestUpdateQueued);
                    return this.Json(new { @success = true });
                }
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false, @error = GmException.TryGetFriendlyErrorMsg(ex) });
            }
        }
    }
}
