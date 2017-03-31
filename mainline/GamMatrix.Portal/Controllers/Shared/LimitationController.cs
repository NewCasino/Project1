using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Text.RegularExpressions;
using System.Web.Mvc;
using CM.Sites;
using CM.State;
using CM.Web;
using GamMatrixAPI;
using GmCore;

namespace GamMatrix.CMS.Controllers.Shared
{
    [HandleError]
    [ControllerExtraInfo(DefaultAction = "Index")]
    public class LimitationController : ControllerEx
    {
        [HttpGet]
        [Protocol(Action = ProtocolAttribute.ProtocolAction.RequireHttps)]
        public ActionResult Index()
        {
            if (!CustomProfile.Current.IsAuthenticated)
                return this.View("Anonymous");

            using (GamMatrixClient client = GamMatrixClient.Get() )
            {
                List<HandlerRequest> requests = new List<HandlerRequest>();

                if (Settings.Limitation.Deposit_MultipleSet_Enabled)
                {
                    GetUserRgDepositLimitListRequest getUserRgDepositLimitListRequest = new GetUserRgDepositLimitListRequest
                    {
                        UserID = CustomProfile.Current.UserID
                    };
                    requests.Add(getUserRgDepositLimitListRequest);
                }
                else
                {
                    GetUserRgDepositLimitRequest getUserRgDepositLimitRequest = new GetUserRgDepositLimitRequest()
                    {
                        UserID = CustomProfile.Current.UserID
                    };
                    requests.Add(getUserRgDepositLimitRequest);
                }
                GetUserRgLossLimitRequest getUserRgLossLimitRequest = new GetUserRgLossLimitRequest()
                {
                    UserID = CustomProfile.Current.UserID
                };
                requests.Add(getUserRgLossLimitRequest);

                GetUserRgWageringLimitRequest getUserRgWageringLimitRequest = new GetUserRgWageringLimitRequest()
                {
                    UserID = CustomProfile.Current.UserID
                };
                requests.Add(getUserRgWageringLimitRequest);

                GetUserRgSessionLimitRequest getUserRgSessionLimitRequest = new GetUserRgSessionLimitRequest()
                {
                    UserID = CustomProfile.Current.UserID
                };
                requests.Add(getUserRgSessionLimitRequest);

                /*NegativeBalanceLimitRequest negativeBalanceLimitRequest = new NegativeBalanceLimitRequest()
                {
                    UserID = CustomProfile.Current.UserID,
                    ContextDomainID = SiteManager.Current.DomainID
                };

                requests.Add(negativeBalanceLimitRequest);*/

                GetUserRgMaxStakeLimitRequest getUserRgMaxStakeLimitRequest = new GetUserRgMaxStakeLimitRequest()
                {
                    UserID = CustomProfile.Current.UserID,
                    ContextDomainID = SiteManager.Current.DomainID
                };

                requests.Add(getUserRgMaxStakeLimitRequest);

                List<HandlerRequest> responses = client.MultiRequest(requests).Select(r => r.Reply).ToList();

                return View("Index", responses);
            }
        }

        [HttpGet]
        [Protocol(Action = ProtocolAttribute.ProtocolAction.RequireHttps)]
        public ActionResult Deposit(RgDepositLimitPeriod? period, long limitID = 0)
        {
            if (!CustomProfile.Current.IsAuthenticated)
                return this.View("Anonymous");
            //RgDepositLimitPeriod period = RgDepositLimitPeriod.None;
            //if (!string.IsNullOrWhiteSpace(periodType))
            //{
            //    Enum.TryParse(periodType, out period);
            //}

            RgDepositLimitInfoRec rgDepositLimitInfoRec = null;
            if (limitID > 0)
            {
                rgDepositLimitInfoRec = GetDepositLimit(limitID);
            }
            else if (!period.HasValue)
            {
                rgDepositLimitInfoRec = GetDepositLimit();
            }

            this.ViewData["Period"] = period.HasValue ? period.Value : rgDepositLimitInfoRec != null ? rgDepositLimitInfoRec.Period : RgDepositLimitPeriod.None;

            return View("DepositLimit", rgDepositLimitInfoRec);
        }

        private RgDepositLimitInfoRec GetDepositLimit()
        {
            GetUserRgDepositLimitRequest getUserRgDepositLimitRequest = new GetUserRgDepositLimitRequest()
            {
                UserID = CustomProfile.Current.UserID
            };
            using (GamMatrixClient client = GamMatrixClient.Get())
            {                
                getUserRgDepositLimitRequest = client.SingleRequest<GetUserRgDepositLimitRequest>(getUserRgDepositLimitRequest);
                return getUserRgDepositLimitRequest.Record;
            }
        }
        private RgDepositLimitInfoRec GetDepositLimit(long limitID)
        {
            List<RgDepositLimitInfoRec> list = GetDepositLimits();
            if (list != null && list.Exists(r => r.ID == limitID))
                return list.FirstOrDefault(r => r.ID == limitID);

            return null;
        }
        private List<RgDepositLimitInfoRec> GetDepositLimits()
        {
            GetUserRgDepositLimitListRequest getUserRgDepositLimitListRequest = new GetUserRgDepositLimitListRequest
            {
                UserID = CustomProfile.Current.UserID
            };
            using (GamMatrixClient client = GamMatrixClient.Get())
            {
                getUserRgDepositLimitListRequest = client.SingleRequest<GetUserRgDepositLimitListRequest>(getUserRgDepositLimitListRequest);                

                return getUserRgDepositLimitListRequest.DepositLimitRecords;
            }
        }

        [HttpGet]
        [Protocol(Action = ProtocolAttribute.ProtocolAction.RequireHttps)]
        public ActionResult Loss()
        {
            if (!CustomProfile.Current.IsAuthenticated)
                return this.View("Anonymous");

            using (GamMatrixClient client = GamMatrixClient.Get())
            {
                GetUserRgLossLimitRequest getUserRgLossLimitRequest = new GetUserRgLossLimitRequest()
                {
                    UserID = CustomProfile.Current.UserID
                };

                getUserRgLossLimitRequest = client.SingleRequest<GetUserRgLossLimitRequest>(getUserRgLossLimitRequest);


                return View("LossLimit", getUserRgLossLimitRequest.Record);
            }
        }


        [HttpGet]
        [Protocol(Action = ProtocolAttribute.ProtocolAction.RequireHttps)]
        public ActionResult Wagering()
        {
            if (!CustomProfile.Current.IsAuthenticated)
                return this.View("Anonymous");

            using (GamMatrixClient client = GamMatrixClient.Get())
            {
                GetUserRgWageringLimitRequest getUserRgWageringLimitRequest = new GetUserRgWageringLimitRequest()
                {
                    UserID = CustomProfile.Current.UserID
                };

                getUserRgWageringLimitRequest = client.SingleRequest<GetUserRgWageringLimitRequest>(getUserRgWageringLimitRequest);


                return View("WageringLimit", getUserRgWageringLimitRequest.Record);
            }
        }

        [HttpGet]
        [Protocol(Action = ProtocolAttribute.ProtocolAction.RequireHttps)]
        public new ActionResult Session()
        {
            if (!CustomProfile.Current.IsAuthenticated)
                return this.View("Anonymous");

            using (GamMatrixClient client = GamMatrixClient.Get())
            {
                GetUserRgSessionLimitRequest getUserRgSessionLimitRequest = new GetUserRgSessionLimitRequest()
                {
                    UserID = CustomProfile.Current.UserID
                };

                getUserRgSessionLimitRequest = client.SingleRequest<GetUserRgSessionLimitRequest>(getUserRgSessionLimitRequest);

                return View("SessionTimeLimit", getUserRgSessionLimitRequest.Record);
            }
        }

        [HttpGet]
        [Protocol(Action = ProtocolAttribute.ProtocolAction.RequireHttps)]
        public ActionResult MaxStake()
        {
            if (!CustomProfile.Current.IsAuthenticated)
                return this.View("Anonymous");

            using (GamMatrixClient client = GamMatrixClient.Get())
            {
                GetUserRgMaxStakeLimitRequest getUserRgMaxStakeLimitRequest = new GetUserRgMaxStakeLimitRequest()
                {
                    UserID = CustomProfile.Current.UserID,
                    ContextDomainID = SiteManager.Current.DomainID
                };

                getUserRgMaxStakeLimitRequest = client.SingleRequest<GetUserRgMaxStakeLimitRequest>(getUserRgMaxStakeLimitRequest);

                return View("MaxStakeLimit", getUserRgMaxStakeLimitRequest.Record);
            }
        }

        [HttpPost]
        [CustomValidateAntiForgeryToken]
        public ActionResult SetDepositLimit(RgDepositLimitPeriod depositLimitPeriod, string currency, string amount)
        {
            if (!CustomProfile.Current.IsAuthenticated)
                return this.View("Anonymous");

            try
            {
                decimal requestAmount = decimal.Parse(Regex.Replace(amount, @"[^\d\.]", string.Empty), CultureInfo.InvariantCulture);
                using (GamMatrixClient client = GamMatrixClient.Get())
                {
                    client.SingleRequest<SetUserRgDepositLimitRequest>(new SetUserRgDepositLimitRequest()
                    {
                        UserID = CustomProfile.Current.UserID,
                        Period = depositLimitPeriod,
                        Amount = requestAmount,
                        Currency = currency,                        
                    });
                }
                return this.View("Success");
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                this.ViewData["ErrorMessage"] = GmException.TryGetFriendlyErrorMsg(ex);
                return this.View("Error");
            }
        }


        [HttpPost]
        [CustomValidateAntiForgeryToken]
        public ActionResult RemoveDepositLimit(RgDepositLimitPeriod? period = null)
        {
            if (!CustomProfile.Current.IsAuthenticated)
                return this.View("Anonymous");

            try
            {
                RemoveUserRgDepositLimitRequest removeUserRgDepositLimitRequest = new RemoveUserRgDepositLimitRequest() {
                    UserID = CustomProfile.Current.UserID,
                };
                if (period.HasValue)
                {
                    removeUserRgDepositLimitRequest.Period = period.Value;
                }
                using (GamMatrixClient client = GamMatrixClient.Get())
                {
                    client.SingleRequest<RemoveUserRgDepositLimitRequest>(removeUserRgDepositLimitRequest);
                }
                return this.View("Success");
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                this.ViewData["ErrorMessage"] = GmException.TryGetFriendlyErrorMsg(ex);
                return this.View("Error");
            }
        }


        [HttpPost]
        [CustomValidateAntiForgeryToken]
        public ActionResult SetLossLimit(RgLossLimitPeriod lossLimitPeriod, string currency, string amount)
        {
            if (!CustomProfile.Current.IsAuthenticated)
                return this.View("Anonymous");

            try
            {
                decimal requestAmount = decimal.Parse(Regex.Replace(amount, @"[^\d\.]", string.Empty), CultureInfo.InvariantCulture);
                using (GamMatrixClient client = GamMatrixClient.Get())
                {
                    client.SingleRequest<SetUserRgLossLimitRequest>(new SetUserRgLossLimitRequest()
                    {
                        UserID = CustomProfile.Current.UserID,
                        Period = lossLimitPeriod,
                        Amount = requestAmount,
                        Currency = currency,
                    });
                }
                return this.View("Success");
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                this.ViewData["ErrorMessage"] = GmException.TryGetFriendlyErrorMsg(ex);
                return this.View("Error");
            }
        }


        [HttpPost]
        [CustomValidateAntiForgeryToken]
        public virtual ActionResult RemoveLossLimit()
        {
            if (!CustomProfile.Current.IsAuthenticated)
                return this.View("Anonymous");

            try
            {
                using (GamMatrixClient client = GamMatrixClient.Get())
                {
                    client.SingleRequest<RemoveUserRgLossLimitRequest>(new RemoveUserRgLossLimitRequest()
                    {
                        UserID = CustomProfile.Current.UserID,
                    });
                }
                return this.View("Success");
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                this.ViewData["ErrorMessage"] = GmException.TryGetFriendlyErrorMsg(ex);
                return this.View("Error");
            }
        }


        [HttpPost]
        [CustomValidateAntiForgeryToken]
        public ActionResult SetWageringLimit(RgWageringLimitPeriod wageringLimitPeriod, string currency, string amount)
        {
            if (!CustomProfile.Current.IsAuthenticated)
                return this.View("Anonymous");

            try
            {
                decimal requestAmount = decimal.Parse(Regex.Replace(amount, @"[^\d\.]", string.Empty), CultureInfo.InvariantCulture);
                using (GamMatrixClient client = GamMatrixClient.Get())
                {
                    client.SingleRequest<SetUserRgWageringLimitRequest>(new SetUserRgWageringLimitRequest()
                    {
                        UserID = CustomProfile.Current.UserID,
                        Period = wageringLimitPeriod,
                        Amount = requestAmount,
                        Currency = currency,
                    });
                }
                return this.View("Success");
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                this.ViewData["ErrorMessage"] = GmException.TryGetFriendlyErrorMsg(ex);
                return this.View("Error");
            }
        }


        [HttpPost]
        [CustomValidateAntiForgeryToken]
        public virtual ActionResult RemoveWageringLimit()
        {
            if (!CustomProfile.Current.IsAuthenticated)
                return this.View("Anonymous");

            try
            {
                using (GamMatrixClient client = GamMatrixClient.Get())
                {
                    client.SingleRequest<RemoveUserRgWageringLimitRequest>(new RemoveUserRgWageringLimitRequest()
                    {
                        UserID = CustomProfile.Current.UserID,
                    });
                }
                return this.View("Success");
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                this.ViewData["ErrorMessage"] = GmException.TryGetFriendlyErrorMsg(ex);
                return this.View("Error");
            }
        }


        [HttpPost]
        [CustomValidateAntiForgeryToken]
        public ActionResult SetSessionLimit(string minutes)
        {
            if (!CustomProfile.Current.IsAuthenticated)
                return this.View("Anonymous");

            try
            {
                int requestMinutes = int.Parse(Regex.Replace(minutes, @"[^\d\.]", string.Empty), CultureInfo.InvariantCulture);
                using (GamMatrixClient client = GamMatrixClient.Get())
                {
                    client.SingleRequest<SetUserRgSessionLimitRequest>(new SetUserRgSessionLimitRequest()
                    {
                        UserID = CustomProfile.Current.UserID,
                        Amount = requestMinutes * 60,
                    });
                }
                return this.View("Success");
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                this.ViewData["ErrorMessage"] = GmException.TryGetFriendlyErrorMsg(ex);
                return this.View("Error");
            }
        }


        [HttpPost]
        [CustomValidateAntiForgeryToken]
        public virtual ActionResult RemoveSessionLimit()
        {
            if (!CustomProfile.Current.IsAuthenticated)
                return this.View("Anonymous");

            try
            {
                using (GamMatrixClient client = GamMatrixClient.Get())
                {
                    client.SingleRequest<RemoveUserRgSessionLimitRequest>(new RemoveUserRgSessionLimitRequest()
                    {
                        UserID = CustomProfile.Current.UserID,
                    });
                }
                return this.View("Success");
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                this.ViewData["ErrorMessage"] = GmException.TryGetFriendlyErrorMsg(ex);
                return this.View("Error");
            }
        }

        [HttpPost]
        [CustomValidateAntiForgeryToken]
        public ActionResult SetMaxStakeLimit(string currency, string amount)
        {
            if (!CustomProfile.Current.IsAuthenticated)
                return this.View("Anonymous");

            try
            {
                decimal requestAmount = decimal.Parse(Regex.Replace(amount, @"[^\d\.]", string.Empty), CultureInfo.InvariantCulture);
                using (GamMatrixClient client = GamMatrixClient.Get())
                {
                    client.SingleRequest<SetUserRgMaxStakeLimitRequest>(new SetUserRgMaxStakeLimitRequest()
                    {
                        UserID = CustomProfile.Current.UserID,
                        Amount = requestAmount,
                        Currency = currency,  
                        ContextDomainID = SiteManager.Current.DomainID
                    });
                }
                return this.View("Success");
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                this.ViewData["ErrorMessage"] = GmException.TryGetFriendlyErrorMsg(ex);
                return this.View("Error");
            }
        }

        [HttpPost]
        [CustomValidateAntiForgeryToken]
        public virtual ActionResult RemoveMaxStakeLimit()
        {
            if (!CustomProfile.Current.IsAuthenticated)
                return this.View("Anonymous");

            try
            {
                using (GamMatrixClient client = GamMatrixClient.Get())
                {
                    client.SingleRequest<RemoveUserRgMaxStakeLimitRequest>(new RemoveUserRgMaxStakeLimitRequest()
                    {
                        UserID = CustomProfile.Current.UserID,
                        ContextDomainID = SiteManager.Current.DomainID
                    });
                }
                return this.View("Success");
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                this.ViewData["ErrorMessage"] = GmException.TryGetFriendlyErrorMsg(ex);
                return this.View("Error");
            }
        }
    }
}
