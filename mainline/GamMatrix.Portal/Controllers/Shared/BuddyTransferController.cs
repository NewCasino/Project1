using System;
using System.Globalization;
using System.Text.RegularExpressions;
using System.Web.Mvc;
using CM.db;
using CM.db.Accessor;
using CM.Sites;
using CM.State;
using CM.Web;
using GamMatrixAPI;
using GmCore;

namespace GamMatrix.CMS.Controllers.Shared
{
    [HandleError]
    [ControllerExtraInfo(DefaultAction = "Index", ParameterUrl="{sid}")]
    public class BuddyTransferController : ControllerEx
    {
        private const string DISALLOWED_ROLE_NAME = "Staked Player";
        private const string ALLOWED_ROLE_NAME = "P2P";
        
        /// <summary>
        /// 
        /// </summary>
        /// <returns></returns>
        [HttpGet]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        [Protocol(Action = ProtocolAttribute.ProtocolAction.RequireHttps)]
        public ActionResult Index()
        {
            if (!CustomProfile.Current.IsAuthenticated)
                return View("Anonymous");

            if (CustomProfile.Current.IsInRole(DISALLOWED_ROLE_NAME))
            {
                return View("AccessDenied");
            }

            if (!CustomProfile.Current.IsInRole(ALLOWED_ROLE_NAME))
            {
                using (GamMatrixClient client = GamMatrixClient.Get() )
                {
                    GetUserRolesRequest response = client.SingleRequest<GetUserRolesRequest>(new GetUserRolesRequest()
                    {
                        UserID = CustomProfile.Current.UserID,
                    });
                    if (!response.RolesByName.Exists(r => string.Equals(r, ALLOWED_ROLE_NAME, StringComparison.OrdinalIgnoreCase)))
                    {
                        return View("IdentityNotVerified");
                    }
                }
            }


            return View("Index");
        }

        [HttpPost]
        [CustomValidateAntiForgeryToken]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public JsonResult FindFriend( string username, string email)
        {
            UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
            cmUser user = ua.GetByUsernameAndEmail(SiteManager.Current.DomainID, username, email);

            return this.ValidateFriend(user);
        }

        [HttpPost]
        [CustomValidateAntiForgeryToken]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public JsonResult FindFriendByUserName(string username)
        {
            UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
            cmUser user = ua.GetByUsername(SiteManager.Current.DomainID, username);

            return this.ValidateFriend(user);
        }

        [HttpPost]
        [CustomValidateAntiForgeryToken]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public JsonResult ValidateFriend(long userID)
        {
            UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
            cmUser user = ua.GetByID(userID);
            return this.ValidateFriend(user);
        }

        /// <summary>
        /// Validate a friend
        /// </summary>
        /// <param name="user"></param>
        /// <returns>@result
        /// 0 = success
        /// 1 = username or email incorrect
        /// 2 = friend's email is not verified
        /// 3 = friend is blocked
        /// 4 = friend's identity is not verified
        /// 5 = friend = self </returns>
        private JsonResult ValidateFriend(cmUser user)
        {
            if (user == null)
                return this.Json(new { @success = true, @result = 1 });
            if( user.ID == CustomProfile.Current.UserID )
                return this.Json(new { @success = true, @result = 5 });
            if( !user.IsEmailVerified )
                return this.Json(new { @success = true, @result = 2 });
            if ( user.IsBlocked )
                return this.Json(new { @success = true, @result = 3 });

            using (GamMatrixClient client = GamMatrixClient.Get() )
            {
                GetUserRolesRequest response = client.SingleRequest<GetUserRolesRequest>(new GetUserRolesRequest()
                {
                    UserID = user.ID,
                });
                if (!response.RolesByName.Exists(r => string.Equals(r, ALLOWED_ROLE_NAME, StringComparison.OrdinalIgnoreCase)))
                {
                    return this.Json(new { @success = true, @result = 4 });
                }
            }
            // PrepareStep2 only accept encrypted userid
            return this.Json(new { @success = true, @result = 0, @userid = user.ID.ToString().DefaultEncrypt() });
        }

        [HttpGet]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        [Protocol(Action = ProtocolAttribute.ProtocolAction.RequireHttps)]
        public ActionResult Prepare(string encryptedUserID)
        {
            int userID = int.Parse(encryptedUserID.DefaultDecrypt());
            UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
            cmUser user = ua.GetByID(userID);
            return View("Prepare", user);
        }

        private JsonResult IovationCheck(string iovationBlackBox)
        {
            if (!CustomProfile.Current.IsAuthenticated || !Settings.IovationDeviceTrack_Enabled)
                return null;

            string error = null;
            //if (string.IsNullOrEmpty(iovationBlackBox))
            //{
            //    error = GamMatrixClient.GetIovationError(eventType: IovationEventType.BuddyTransfer); 
            //    //"iovationBlackBox requreid !";
            //}
            //else
            //{
                if (!GamMatrixClient.IovationCheck(CustomProfile.Current.UserID, IovationEventType.BuddyTransfer, iovationBlackBox))
                {
                    error = GamMatrixClient.GetIovationError(false, IovationEventType.BuddyTransfer);
                }
            //}

            if (error == null)
                return null;

            return this.Json(new
            {
                @success = false,
                @error = error
            });
        }


        [HttpPost]
        [CustomValidateAntiForgeryToken]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public ActionResult PrepareTransaction(long debitGammingAccountID
            , long creditUserID
            , long creditGammingAccountID
            , string currency
            , string amount
            , string iovationBlackbox = null
            )
        {
            var iovationResult = IovationCheck(iovationBlackbox);
            if (iovationResult != null)
            {
                return iovationResult;
            }

            try
            {
                if (!CustomProfile.Current.IsAuthenticated)
                    throw new Exception("Please login first!");

                decimal requestAmount = decimal.Parse(Regex.Replace(amount, @"[^(\d\.)]", string.Empty), CultureInfo.InvariantCulture);
                using (GamMatrixClient client = GamMatrixClient.Get())
                {
                    PrepareTransRequest prepareTransRequest = client.SingleRequest<PrepareTransRequest>(
                            new PrepareTransRequest()
                            {
                                IovationBlackBox = iovationBlackbox,
                                Record = new PreTransRec()
                                {
                                    TransType = TransType.User2User,
                                    ContraUserID = creditUserID,
                                    DebitAccountID = debitGammingAccountID,
                                    CreditAccountID = creditGammingAccountID,
                                    RequestAmount = requestAmount,
                                    RequestCurrency = currency,
                                    UserID = CustomProfile.Current.UserID,
                                    UserIP = Request.GetRealUserAddress(),
                                }
                            });

                    cmTransParameter.SaveObject<PrepareTransRequest>(prepareTransRequest.Record.Sid
                        , "PrepareTransRequest"
                        , prepareTransRequest
                        );

                    return this.Json(new
                    {
                        @success = true,
                        @sid = prepareTransRequest.Record.Sid
                    });
                }
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new
                {
                    @success = false,
                    @error = GmException.TryGetFriendlyErrorMsg(ex),
                });
            }
        }

        [HttpGet]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public ActionResult Confirmation(string sid)
        {
            PrepareTransRequest prepareTransRequest = cmTransParameter.ReadObject<PrepareTransRequest>(sid, "PrepareTransRequest");
            if (prepareTransRequest == null)
                throw new ArgumentOutOfRangeException("sid");

            return View("Confirmation", prepareTransRequest);
        }

        [HttpPost]
        [CustomValidateAntiForgeryToken]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public ActionResult Confirm(string sid)
        {
            try
            {
                using (GamMatrixClient client = GamMatrixClient.Get() )
                {
                    ProcessTransRequest processTransRequest = client.SingleRequest<ProcessTransRequest>(new ProcessTransRequest()
                    {
                        SID = sid
                    });
                    cmTransParameter.SaveObject<ProcessTransRequest>(sid
                        , "ProcessTransRequest"
                        , processTransRequest
                        );
                }

                string url = this.Url.RouteUrl("BuddyTransfer", new { @action = "Receipt", @sid = sid });
                return this.Redirect(url);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                this.ViewData["ErrorMessage"] = GmException.TryGetFriendlyErrorMsg(ex);
                return View("Error");
            }
        }


        [HttpGet]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public ActionResult Receipt(string sid)
        {
            try
            {
                PrepareTransRequest prepareTransRequest = cmTransParameter.ReadObject<PrepareTransRequest>(sid, "PrepareTransRequest");
                if (prepareTransRequest == null)
                    throw new ArgumentOutOfRangeException("sid");

                ProcessTransRequest processTransRequest = cmTransParameter.ReadObject<ProcessTransRequest>(sid, "ProcessTransRequest");
                if (processTransRequest == null)
                    throw new ArgumentOutOfRangeException("sid");

                GetTransInfoRequest getTransInfoRequest;
                using (GamMatrixClient client = GamMatrixClient.Get() )
                {
                    getTransInfoRequest = client.SingleRequest<GetTransInfoRequest>(new GetTransInfoRequest()
                    {
                        SID = sid,
                        NoDetails = true,
                    });
                }

                this.ViewData["prepareTransRequest"] = prepareTransRequest;
                this.ViewData["processTransRequest"] = processTransRequest;
                this.ViewData["getTransInfoRequest"] = getTransInfoRequest;

                return View("Receipt");
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                this.ViewData["ErrorMessage"] = GmException.TryGetFriendlyErrorMsg(ex);
                return View("Error");
            }
        }
    }
}
