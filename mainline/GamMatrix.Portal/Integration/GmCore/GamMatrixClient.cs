using System;
using System.Collections.Generic;
using System.Configuration;
using System.IO;
using System.Linq;
using System.Web;
using System.Web.Caching;
using System.Web.Hosting;
using CM.db;
using CM.db.Accessor;
using CM.Sites;
using CM.State;
using GamMatrix.Infrastructure;
using GamMatrixAPI;

namespace GmCore
{
    /// <summary>
    /// Summary description for GamMatrixClient
    /// </summary>
    public class GamMatrixClient : IGmAPIClient, IDisposable
    {
        private const string GMCORE_SESSION_FORMAT = "~/App_Data/{0}/gmcore_session";

        #region IDispose
        public static GamMatrixClient Get()
        {
            return new GamMatrixClient();
        }

        public void Dispose()
        {
        }
        #endregion

        #region Internal Client
        private readonly IGmAPIClient _client;

        public GamMatrixClient()
        {
            _client = new GmAPIRestClient();
        }

        private static IGmAPIClient InternalCreateClient()
        {
            bool enableRestClient = !string.Equals(ConfigurationManager.AppSettings["GmCore.EnableRestClient"], "0", StringComparison.InvariantCultureIgnoreCase);
            if (enableRestClient)
                return new GmAPIRestClient();
            else
                return new GmAPIWcfClient();
        }
        #endregion


        #region Implement IGmAPIClient interface
        public GamMatrixAPI.ReplyResponse Login(GamMatrixAPI.LoginRequest request)
        {
            return _client.Login(request);
        }

        public GamMatrixAPI.ReplyResponse IsLoggedIn(GamMatrixAPI.IsLoggedInRequest request)
        {
            return _client.IsLoggedIn(request);
        }

        public IAsyncResult BeginSingleRequest(GamMatrixAPI.HandlerRequest request
            , Action<AsyncResult> asyncCallback
            , object userState1
            , object userState2
            , object userState3
            )
        {
            return _client.BeginSingleRequest(request, asyncCallback, userState1, userState2, userState3);
        }

        public ReplyResponse SingleRequest(HandlerRequest request, int timeoutMs = -1)
        {
            if (string.IsNullOrEmpty(request.SESSION_ID))
                request.SESSION_ID = GamMatrixClient.GetSessionIDForCurrentOperator();
            if (request.SESSION_USERID <= 0 && CustomProfile.Current.IsAuthenticated)
                request.SESSION_USERID = CustomProfile.Current.UserID;
            return CheckResponse(_client.SingleRequest(request));
        }

        public List<ReplyResponse> MultiRequest(List<HandlerRequest> requests)
        {
            foreach (HandlerRequest request in requests)
            {
                if (string.IsNullOrEmpty(request.SESSION_ID))
                    request.SESSION_ID = GamMatrixClient.GetSessionIDForCurrentOperator();
                if (request.SESSION_USERID <= 0 && CustomProfile.Current.IsAuthenticated)
                    request.SESSION_USERID = CustomProfile.Current.UserID;
            }
            var responses = _client.MultiRequest(requests);
            foreach (var response in responses)
            {
                if (response != null)
                {
                    CheckResponse(response);
                }
            }
            return responses;
        }

        public List<GamMatrixAPI.ReplyResponse> ParallelMultiRequest(List<GamMatrixAPI.HandlerRequest> requests)
        {
            foreach (HandlerRequest request in requests)
            {
                request.SESSION_ID = GamMatrixClient.GetSessionIDForCurrentOperator();
                if (CustomProfile.Current.IsAuthenticated)
                    request.SESSION_USERID = CustomProfile.Current.UserID;
            }
            var responses = _client.ParallelMultiRequest(requests);
            foreach (var response in responses)
            {
                if (response != null)
                {
                    CheckResponse(response);
                }
            }
            return responses;
        }
        #endregion



        #region SESSION
        public static string RenewSessionID(cmSite site, string securityToken, string apiUsername)
        {
            string cacheKey = string.Format("site_session_id_{0}", site.ID);
            string sessionID;
            IGmAPIClient client = InternalCreateClient();
            {
                string plainTextPassword = (apiUsername == "sa") ? "asdfg" : securityToken;

                // exception for live domain
                if (site.ID == 1 && site.DomainID == 1000)
                {
                    apiUsername = ConfigurationManager.AppSettings["GmCore.SuperAdminLogin"];
                    securityToken = ConfigurationManager.AppSettings["GmCore.SuperAdminSecToken"];
                    plainTextPassword = ConfigurationManager.AppSettings["GmCore.SuperAdminPwd"];
                }

                var response = client.Login(new LoginRequest()
                {
                    UserName = apiUsername,
                    PlainTextPassword = plainTextPassword,
                    SecurityToken = securityToken,
                    Type = SessionType.System,
                });
                if (!response.Success)
                {
                    throw new GmException(response);
                }
                sessionID = ((LoginRequest)response.Reply).UserProfile.SessionID;
                Logger.Warning("GmCore Login", "Username={0};SecurityToken={1};", apiUsername, securityToken);

                lock (typeof(LoginRequest))
                {
                    // get the old session id(if avaliable) and log it off
                    // update the cache
                    string oldSessionID = HttpRuntime.Cache[cacheKey] as string;

                    string sessionKeyFile = HostingEnvironment.MapPath(string.Format(GMCORE_SESSION_FORMAT, site.DistinctName));
                    FileSystemUtility.EnsureDirectoryExist(sessionKeyFile);

                    // update cache
                    HttpRuntime.Cache.Insert(cacheKey
                        , sessionID
                        , new CacheDependencyEx(new string[] { sessionKeyFile }, false)
                        , DateTime.Now.AddYears(1)
                        , Cache.NoSlidingExpiration
                        );

                    using (FileStream fs = new FileStream(sessionKeyFile, FileMode.OpenOrCreate, FileAccess.ReadWrite, FileShare.Delete | FileShare.ReadWrite))
                    {
                        using (StreamReader sr = new StreamReader(fs))
                        {
                            using (StreamWriter sw = new StreamWriter(fs))
                            {
                                if (string.IsNullOrWhiteSpace(oldSessionID))
                                {
                                    oldSessionID = sr.ReadLine();
                                }

                                fs.SetLength(0L);
                                fs.Position = 0;
                                sw.Write(sessionID);
                            }
                        }
                    }

                    // logoff the old session
                    if (!string.IsNullOrWhiteSpace(oldSessionID))
                    {
                        try
                        {
                            client.SingleRequest(new LogoutRequest()
                            {
                                SESSION_ID = oldSessionID
                            });
                        }
                        catch
                        {
                        }
                    }
                }
            }

            return sessionID;
        }

        public static string GetSessionID(cmSite site, bool generateNewSession = false)
        {
            string sessionID = null;
            try
            {
                string cacheKey = string.Format("site_session_id_{0}", site.ID);
                sessionID = HttpRuntime.Cache[cacheKey] as string;

                if (string.IsNullOrWhiteSpace(sessionID))
                {
                    string sessionKeyFile = HostingEnvironment.MapPath(string.Format(GMCORE_SESSION_FORMAT, site.DistinctName));
                    if (File.Exists(sessionKeyFile))
                    {
                        using (FileStream fs = new FileStream(sessionKeyFile, FileMode.Open, FileAccess.Read, FileShare.Delete | FileShare.ReadWrite))
                        {
                            using (StreamReader sr = new StreamReader(fs))
                            {
                                sessionID = sr.ReadLine();
                            }
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
            }

            if (!string.IsNullOrWhiteSpace(sessionID))
                return sessionID;

            if (!generateNewSession)
                return string.Empty;

            return RenewSessionID(site
                , site.SecurityToken
                , site.ApiUsername
                );
        }

        public static string GetSessionIDForCurrentOperator()
        {
            return GamMatrixClient.GetSessionID(SiteManager.Current, true);
        }

        ///


        internal ReplyResponse CheckResponse(ReplyResponse response)
        {
            if (!response.Success)
            {
                // renew the session id if SYS_1010 occurs
                if (response.ErrorCode == "SYS_1010" ||
                    response.ErrorCode == "SYS_1012" )
                {
                    Logger.Error("GmCore Login", "SYS_1010 error");
                    GamMatrixClient.RenewSessionID(SiteManager.Current
                        , SiteManager.Current.SecurityToken
                        , SiteManager.Current.ApiUsername
                        );
                }

                throw new GmException(response);
            }
            return response;
        }

        public T SingleRequest<T>(T request, int timeoutMs = -1) where T : HandlerRequest
        {
            if (string.IsNullOrWhiteSpace(request.SESSION_ID))
                request.SESSION_ID = GamMatrixClient.GetSessionIDForCurrentOperator();
            if (request.SESSION_USERID <= 0 && HttpContext.Current != null && CustomProfile.Current.IsAuthenticated)
                request.SESSION_USERID = CustomProfile.Current.UserID;

            if (HttpContext.Current != null)
            {
                try
                {
                    request.SESSION_USERIP = HttpContext.Current.Request.GetRealUserAddress();
                    request.SESSION_USERSESSIONID = CustomProfile.Current.SessionID;
                }
                catch
                {
                }
            }

            using (CodeProfiler.Step(2, string.Format("SingleRequest - {0}", request.GetType().Name)))
            {
                return _client.SingleRequest(request).Get<T>();
            }
        }

        public static IAsyncResult SingleRequestAsync<T>(T request, Action<AsyncResult> callback
            , object userState1 = null
            , object userState2 = null
            , object userState3 = null
            ) where T : HandlerRequest
        {
            if (string.IsNullOrWhiteSpace(request.SESSION_ID))
                request.SESSION_ID = GamMatrixClient.GetSessionIDForCurrentOperator();
            if (request.SESSION_USERID <= 0 && CustomProfile.Current.IsAuthenticated)
                request.SESSION_USERID = CustomProfile.Current.UserID;

            if (HttpContext.Current != null)
            {
                try
                {
                    request.SESSION_USERIP = HttpContext.Current.Request.GetRealUserAddress();
                    request.SESSION_USERSESSIONID = CustomProfile.Current.SessionID;
                }
                catch
                {
                }
            }

            GamMatrixClient client = new GamMatrixClient();
            return client.BeginSingleRequest(request, callback, userState1, userState2, userState3);
        }



        public List<ReplyResponse> ParallelMultiRequestEx(List<HandlerRequest> requests)
        {
            foreach (HandlerRequest request in requests)
            {
                if (string.IsNullOrWhiteSpace(request.SESSION_ID))
                    request.SESSION_ID = GamMatrixClient.GetSessionIDForCurrentOperator();
                if (CustomProfile.Current.IsAuthenticated && request.SESSION_USERID <= 0)
                    request.SESSION_USERID = CustomProfile.Current.UserID;
            }

            return _client.ParallelMultiRequest(requests);
        }

        public List<T> MultiRequest<T>(List<HandlerRequest> requests) where T : HandlerRequest
        {
            foreach (HandlerRequest request in requests)
            {
                if (string.IsNullOrWhiteSpace(request.SESSION_ID))
                    request.SESSION_ID = GamMatrixClient.GetSessionIDForCurrentOperator();
                if (CustomProfile.Current.IsAuthenticated && request.SESSION_USERID <= 0)
                    request.SESSION_USERID = CustomProfile.Current.UserID;
            }
            List<ReplyResponse> replies = _client.MultiRequest(requests);
            List<T> responses = new List<T>();
            foreach (ReplyResponse replyResponse in replies)
            {
                responses.Add(replyResponse.Get<T>());
            }
            return responses;
        }


        #endregion

        public static string GetRoleString(long userID, cmSite site = null)
        {
            if (site == null)
                site = SiteManager.Current;

            GetUserRolesRequest getUserRolesRequest = new GetUserRolesRequest()
            {
                UserID = userID,
            };
            if (site != null)
                getUserRolesRequest.SESSION_ID = GamMatrixClient.GetSessionID(site, true);

            string roleString = string.Empty;
            try
            {
                using (GamMatrixClient client = GamMatrixClient.Get())
                {
                    GetUserRolesRequest resp = client.SingleRequest<GetUserRolesRequest>(getUserRolesRequest, 6000);
                    roleString = string.Join(",", resp.RolesByName);
                }
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
            }

            return roleString;
        }

        public static List<CurrencyData> GetSupportedCurrencies()
        {
            const string CACHE_KEY = "__SupporttedCurrencies";
            List<CurrencyData> currencies = HttpRuntime.Cache[CACHE_KEY] as List<CurrencyData>;
            if (currencies != null)
                return currencies;

            using (GamMatrixClient client = GamMatrixClient.Get())
            {
                GetSupportedCurrencyListRequest response = client.SingleRequest<GetSupportedCurrencyListRequest>(new GetSupportedCurrencyListRequest()
                {
                });
                currencies = response.CurrencyData;
            }

            HttpRuntime.Cache.Insert(CACHE_KEY
                    , currencies
                    , null
                    , DateTime.Now.AddMinutes(30)
                    , TimeSpan.Zero
                    );
            return currencies;
        }

        public static PaymentSolutionDetails GetPaymentSolutionDetails(string paymentSolutionName, string country = null, TransType transType = TransType.Deposit)
        {
            PaymentSolutionDetails details = null;
            
            try
            {
                using (var client = Get())
                {
                    var response = client.SingleRequest(new MoneyMatrixGetPaymentSolutionDetailsRequest
                    {
                        PaymentSolutionName = paymentSolutionName,
                        Country = country,
                        TransactionType = transType
                    });
                    
                    details = response.PaymentSolution;
                }
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
            }

            return details;
        }

        #region IsEverleafPokerUserNameEmailAndAliasAvailableAsync
        public static IAsyncResult IsEverleafPokerUserNameEmailAndAliasAvailableAsync(string username
            , string email
            , string alias
            , Action<bool, bool, bool> callback
            )
        {
            List<VendorRec> accounts = GamMatrixClient.GetGamingVendors();

            EverleafNetworkAPIIsUserNameEmailAndAliasAvailableRequest request = new EverleafNetworkAPIIsUserNameEmailAndAliasAvailableRequest()
            {
                Alias = alias,
                UserName = username,
                Email = email,
            };
            return GamMatrixClient.SingleRequestAsync<EverleafNetworkAPIIsUserNameEmailAndAliasAvailableRequest>(request
                , OnEverleafPokerUserNameEmailAndAliasAvailableVerifyCompleted
                , callback
                );
        }

        private static void OnEverleafPokerUserNameEmailAndAliasAvailableVerifyCompleted(AsyncResult reply)
        {
            Action<bool, bool, bool> callback = reply.UserState1 as Action<bool, bool, bool>;
            try
            {
                EverleafNetworkAPIIsUserNameEmailAndAliasAvailableRequest response
                    = reply.EndSingleRequest().Get<EverleafNetworkAPIIsUserNameEmailAndAliasAvailableRequest>();
                if (callback != null)
                    callback(response.IsUserNameAvailable, response.IsEmailAvailable, response.IsAliasAvailable);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                if (callback != null)
                    callback(true, true, true);
            }
        }
        #endregion


        #region IsAliasAvailable
        /// <summary>
        /// Verify if the alias is available for bluff21
        /// </summary>
        /// <param name="alias"></param>
        /// <returns></returns>
        public static IAsyncResult IsAliasAvailableAsync(string alias, Action<bool> callback)
        {
            IsAliasAvailableRequest request = new IsAliasAvailableRequest()
            {
                Alias = alias
            };
            return GamMatrixClient.SingleRequestAsync<IsAliasAvailableRequest>(request
                , OnAliasAvailableVerifyCompleted, callback);
        }

        private static void OnAliasAvailableVerifyCompleted(AsyncResult result)
        {
            Action<bool> callback = result.UserState1 as Action<bool>;
            try
            {
                IsAliasAvailableRequest response = result.EndSingleRequest().Get<IsAliasAvailableRequest>();
                if (callback != null)
                    callback(response.IsAvailable);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                if (callback != null)
                    callback(true);
            }
        }
        #endregion

        #region GetUserMetadata
        public static string GetUserMetadata(string metaData)
        {
            try
            {
                using (GamMatrixClient client = new GamMatrixClient())
                {
                    GetUserMetadataRequest request = client.SingleRequest<GetUserMetadataRequest>(
                       new GetUserMetadataRequest()
                       {
                           SessionID = CustomProfile.Current.SessionID,
                           MetadataKey = metaData
                       });

                    return request.MetadataValue;
                }
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                throw;
            }
        }
        #endregion

        #region SetUserMetadata
        public static void SetUserMetadata(string metaDataKey, string metaDataValue)
        {
            try
            {
                SetUserMetadataRequest request = new SetUserMetadataRequest()
                {
                    SESSION_ID = GamMatrixClient.GetSessionIDForCurrentOperator(),
                    MetadataKey = metaDataKey,
                    MetadataValue = metaDataValue,
                    UserID = CustomProfile.Current.UserID,
                };

                using (GamMatrixClient client = new GamMatrixClient())
                {
                    client.SingleRequest<SetUserMetadataRequest>(request);
                }
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                throw;
            }
        }
        #endregion

        #region RegisterUser
        public static void RegisterUser(long userID, string curreny,string iovationBlackBox = null)
        {
            try
            {
                RegisterUserRequest request = new RegisterUserRequest()
                {
                    UserID = userID,
                    SystemAccountCurrency = curreny,
                };
                if (!string.IsNullOrEmpty(iovationBlackBox))
                    request.IovationBlackBox = iovationBlackBox;
                using (GamMatrixClient client = GamMatrixClient.Get())
                {
                    client.SingleRequest<RegisterUserRequest>(request);
                    UserAccessor ua = UserAccessor.CreateInstance<CM.db.Accessor.UserAccessor>();
                    ua.SetExported(userID);
                }
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
            }
        }

        public static void RegisterUserAsync(long userID, string curreny)
        {
            RegisterUserRequest request = new RegisterUserRequest()
            {
                UserID = userID,
                SystemAccountCurrency = curreny,
            };
            GamMatrixClient.SingleRequestAsync<RegisterUserRequest>(request, OnRegisterUserCompleted, userID);
        }
        private static void OnRegisterUserCompleted(AsyncResult result)
        {
            try
            {

                RegisterUserRequest response = result.EndSingleRequest().Get<RegisterUserRequest>();
                long userID = (long)result.UserState1;
                UserAccessor ua = UserAccessor.CreateInstance<CM.db.Accessor.UserAccessor>();
                ua.SetExported(userID);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
            }
        }
        #endregion

        #region QuickRegisterUser
        public static void QuickRegisterUser(long userID,string iovationBlackBox = null)
        {
            try
            {
                RegisterUserRequest request = new RegisterUserRequest()
                {
                    UserID = userID,
                    QuickRegistration = true
                };
                if (!string.IsNullOrEmpty(iovationBlackBox))
                    request.IovationBlackBox = iovationBlackBox;
                using (GamMatrixClient client = GamMatrixClient.Get())
                {
                    client.SingleRequest<RegisterUserRequest>(request);
                    UserAccessor ua = UserAccessor.CreateInstance<CM.db.Accessor.UserAccessor>();
                    ua.SetExported(userID);
                }
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
            }
        }

        public static void QuickRegisterUserAsync(long userID)
        {
            RegisterUserRequest request = new RegisterUserRequest()
            {
                UserID = userID,
                QuickRegistration = true
            };
            GamMatrixClient.SingleRequestAsync<RegisterUserRequest>(request, OnQuickRegisterUserCompleted);
        }
        private static void OnQuickRegisterUserCompleted(AsyncResult result)
        {
            try
            {

                RegisterUserRequest response = result.EndSingleRequest().Get<RegisterUserRequest>();
                long userID = (long)result.UserState1;
                UserAccessor ua = UserAccessor.CreateInstance<CM.db.Accessor.UserAccessor>();
                ua.SetExported(userID);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
            }
        }
        #endregion

        #region LoginNotification
        public static void SendLoginNotificationAsync(long userID, string sessionID, string IovationBlackBox = null)
        {
            LoginNotificationRequest request = new LoginNotificationRequest()
            {
                UserID = CustomProfile.Current.UserID,
                SessionID = CustomProfile.Current.SessionID,
                LoginType = LoginType.User,
                IovationBlackBox = IovationBlackBox
            };
            GamMatrixClient.SingleRequestAsync<LoginNotificationRequest>(request, OnLoginNotificationCompleted);
        }
        private static void OnLoginNotificationCompleted(AsyncResult result)
        {
            try
            {
                LoginNotificationRequest response = result.EndSingleRequest().Get<LoginNotificationRequest>();
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
            }
        }
        #endregion


        #region IovationDevice Check
        public static bool IovationCheck(long userId, IovationEventType eventType, string iovationBlackBox, CasinoBonusType? bonusType = null)
        {
            using (GamMatrixClient client = GamMatrixClient.Get())
            {
                var result = client.SingleRequest<IovationCheckDeviceRequest>(new IovationCheckDeviceRequest()
                {
                    UserId = userId,
                    UserIP = HttpContext.Current.Request.GetRealUserAddress(),
                    EventType = eventType,
                    BonusType = bonusType,
                    IovationBlackBox = iovationBlackBox
                });
                Logger.Information("Iovation", "user:{0},eventType:{1},bonusType:{2}", userId, eventType.ToString(), bonusType);
                Logger.Information("IovationResult", "error:{0},deviceId:{1},status:{2}", result.CheckResult.ErrorMessage, result.CheckResult.IovationDeviceID, result.CheckResult.Status.ToString());

                if (result.CheckResult.Status == IovationDeviceStatus.Deny)
                    return false;

                if(result.CheckResult.Status == IovationDeviceStatus.Failed)
                {
                    Logger.Warning("GamMatrixClient.IovationCheck", "Got Faield:{0}", result.CheckResult.ErrorMessage);
                }

                return true;
            }
        }

        public static string GetIovationError(bool isRequiredMessage = true, IovationEventType? eventType = null)
        {
            var metaPathFormat = "/Components/_IovationTrack_ascx.{0}{1}_Message";
            var msgType = "Required";
            if (!isRequiredMessage) {
                msgType = "Denied";
            }

            string eventTypeStr = string.Empty;
            if (eventType != null)
            {
                eventTypeStr = eventType.ToString() + "_";
            }

            string errorMessage = CM.Content.Metadata.Get(string.Format(metaPathFormat, eventTypeStr, msgType)).HtmlEncodeSpecialCharactors();
            if (!string.IsNullOrEmpty(eventTypeStr) && string.IsNullOrEmpty(errorMessage))
            {
                errorMessage = CM.Content.Metadata.Get(string.Format(metaPathFormat, string.Empty, msgType)).HtmlEncodeSpecialCharactors();
            }

            if (HttpContext.Current != null)
                Logger.Error("Iovation", "got nothing from client,message from Client : {0}", HttpContext.Current.Request["iovationBlackBox_info"].DefaultIfNullOrEmpty("empty"));

            return errorMessage;

        }
        #endregion
        public static List<VendorRec> GetGamingVendors()
        {
            string cacheKey = string.Format("GamMatrixClient.GetGamingVendors.{0}", SiteManager.Current.DistinctName);
            List<VendorRec> ret = HttpRuntime.Cache[cacheKey] as List<VendorRec>;
            if (ret != null)
                return ret;

            try
            {
                using (GamMatrixClient client = GamMatrixClient.Get())
                {
                    GetVendorsRequest request = client.SingleRequest(new GetVendorsRequest
                    {
                        PagedData = new PagedDataOfVendorRec()
                        {
                            PageNumber = 0,
                            PageSize = int.MaxValue
                        }
                    });

                    if (request.PagedData == null && request.PagedData.Records == null)
                        return new List<VendorRec>();
                    ret = request.PagedData.Records.Where(r => r.Type == VendorType.Gaming).ToList();
                    HttpRuntime.Cache.Insert(cacheKey, ret, null, Cache.NoAbsoluteExpiration, TimeSpan.FromMinutes(30));
                    return ret;
                }
            }
            catch
            {
                return new List<VendorRec>();
            }
        }

        #region GetUserGammingAccounts
        private const string USERS_ACCOUNTS_CACHE_FORMAT = "GamMatrixClient.GetUserGammingAccounts.{0}";
        public static IAsyncResult GetUserGammingAccountsAsync(long userID, Action<List<AccountData>> callback, bool useCache = true)
        {
            string cacheKey = string.Format(USERS_ACCOUNTS_CACHE_FORMAT, userID);
            List<AccountData> cached;
            if (useCache)
            {
                cached = HttpRuntime.Cache[cacheKey] as List<AccountData>;
                if (cached != null)
                {
                    callback(cached);
                    return null;
                }
            }

            GetUserAccountsRequest request = new GetUserAccountsRequest()
            {
                UserID = userID,
                NoBalance = false,
            };

            return GamMatrixClient.SingleRequestAsync<GetUserAccountsRequest>(request
                , GetUserGammingAccountsCompleted
                , callback
                , userID
                , cacheKey
                );
        }

        private static void GetUserGammingAccountsCompleted(AsyncResult reply)
        {
            Action<List<AccountData>> callback = reply.UserState1 as Action<List<AccountData>>;
            try
            {
                GetUserAccountsRequest response = reply.EndSingleRequest().Get<GetUserAccountsRequest>();

                List<AccountData> list;
                if (response != null && response.Data.Count > 0)
                {
                    list = response.Data.Where(a => a.Record.Type == AccountType.Ordinary).ToList();
                    HttpRuntime.Cache.Insert(reply.UserState3 as string
                        , list
                        , null
                        , Cache.NoAbsoluteExpiration
                        , new TimeSpan(0, 5, 0)
                        );
                }
                else
                {
                    list = new List<AccountData>();
                }
                callback(list);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                if (callback != null)
                    callback(null);
            }
        }

        public static List<AccountData> GetUserGammingAccounts(int userID, bool useCache = true)
        {
            string cacheKey = string.Format(USERS_ACCOUNTS_CACHE_FORMAT, userID);
            List<AccountData> cached;
            if (useCache)
            {
                cached = HttpRuntime.Cache[cacheKey] as List<AccountData>;
                if (cached != null)
                    return cached;
            }

            GetUserAccountsRequest request = new GetUserAccountsRequest()
            {
                UserID = userID,
                NoBalance = false,
            };

            using (GamMatrixClient client = GamMatrixClient.Get())
            {
                request = client.SingleRequest<GetUserAccountsRequest>(request);
            }

            if (request != null)
            {
                cached = request.Data.Where(a => a.Record.Type == AccountType.Ordinary).ToList();
                if (cached.Count > 0)
                    HttpRuntime.Cache.Insert(cacheKey, cached, null, DateTime.Now.AddMinutes(5), Cache.NoSlidingExpiration);
            }
            else
            {
                cached = new List<AccountData>();
            }

            return cached;
        }
        #endregion


        public static Dictionary<string, CurrencyExchangeRateRec> GetCurrencyRates()
        {
            Dictionary<string, CurrencyExchangeRateRec> dic;
            string cacheKey = "GamMatrixClient.GetCurrencyRates";
            dic = HttpRuntime.Cache[cacheKey] as Dictionary<string, CurrencyExchangeRateRec>;
            if (dic != null)
                return dic;

            lock (typeof(GetCurrencyRatesRequest))
            {
                dic = HttpRuntime.Cache[cacheKey] as Dictionary<string, CurrencyExchangeRateRec>;
                if (dic != null)
                    return dic;

                dic = new Dictionary<string, CurrencyExchangeRateRec>(StringComparer.OrdinalIgnoreCase);
                using (GamMatrixClient client = GamMatrixClient.Get())
                {
                    var list = client.SingleRequest<GetCurrencyRatesRequest>(new GetCurrencyRatesRequest() { }).Data;
                    foreach (var item in list)
                    {
                        dic[item.ISO4217_Alpha] = item;
                    }
                }

                HttpRuntime.Cache.Insert(cacheKey
                    , dic
                    , null
                    , DateTime.Now.AddHours(6)
                    , Cache.NoSlidingExpiration
                    );
            }
            return dic;
        }

        #region PayCards

        private const string GM_PAYCARD_FORMAT = "gm_pay_card_{0}_{1}";
        /// <summary>
        /// Get the pay card by id
        /// </summary>
        /// <param name="payCardID"></param>
        /// <param name="useCache"></param>
        /// <returns></returns>
        public static PayCardInfoRec GetPayCard(long payCardID, bool useCache = true, bool loadAllMoneyMatrixPayCards = false)
        {
            string cacheKey = string.Format(GM_PAYCARD_FORMAT, CustomProfile.Current.UserID, payCardID);
            PayCardInfoRec payCard = HttpRuntime.Cache[cacheKey] as PayCardInfoRec;
            if (useCache && payCard != null)
                return payCard;

            using (GamMatrixClient client = GamMatrixClient.Get())
            {
                List<PayCardInfoRec> payCards = client.SingleRequest<GetUserPayCardsRequest>(
                    new GetUserPayCardsRequest()
                    {
                        UserID = CustomProfile.Current.UserID,
                        ShowMMNotCCPayCards = loadAllMoneyMatrixPayCards
                    }).Data;

                payCard = payCards.FirstOrDefault(p => p.ID == payCardID);
                if (payCard == null)
                    return payCard;
            }

            HttpRuntime.Cache.Insert(cacheKey
                , payCard
                , null
                , DateTime.Now.AddHours(1)
                , Cache.NoSlidingExpiration
                );
            return payCard;
        }

        public static List<PayCardInfoRec> GetPayCards(bool loadAllMoneyMatrixPayCards = false)
        {
            using (GamMatrixClient client = GamMatrixClient.Get())
            {
                List<PayCardInfoRec> payCards = client.SingleRequest<GetUserPayCardsRequest>(
                    new GetUserPayCardsRequest()
                    {
                        UserID = CustomProfile.Current.UserID,
                        ShowMMNotCCPayCards = loadAllMoneyMatrixPayCards
                    }).Data;

                foreach (PayCardInfoRec payCard in payCards)
                {
                    string cacheKey = string.Format(GM_PAYCARD_FORMAT, CustomProfile.Current.UserID, payCard.ID);
                    HttpRuntime.Cache.Insert(cacheKey
                        , payCard
                        , null
                        , DateTime.Now.AddHours(1)
                        , Cache.NoSlidingExpiration
                        );
                }

                return payCards.Where(p => p.ActiveStatus == ActiveStatus.Active)
                    .OrderByDescending(p => p.LastSettledDepositDate)
                    .ToList();
            }
        }

        public static List<EnterCashRequestBankInfo> GetEnterCashBankInfo(bool useCache = true)
        {
            useCache = false;
            string cacheKey = string.Format("GamMatrixClient.EnterCashGetBankInfoRequest.{0}", SiteManager.Current.DistinctName);

            List<EnterCashRequestBankInfo> banks = HttpRuntime.Cache[cacheKey] as List<EnterCashRequestBankInfo>;
            if (useCache && banks != null && banks.Any())
                return banks;

            EnterCashGetBankInfoRequest request = new EnterCashGetBankInfoRequest()
            {
                SESSION_ID = GamMatrixClient.GetSessionID(SiteManager.Current, true),
            };

            Func<List<EnterCashRequestBankInfo>> func = () =>
            {
                try
                {
                    using (GamMatrixClient client = new GamMatrixClient())
                    {
                        request = client.SingleRequest<EnterCashGetBankInfoRequest>(request);
                        return request.Data;
                    }
                }
                catch (Exception ex)
                {
                    Logger.Exception(ex);
                    throw;
                }
            };

            banks = func();
            HttpRuntime.Cache.Insert(cacheKey
                , banks
                , null
                , DateTime.Now.AddHours(1)
                , Cache.NoSlidingExpiration
                );

            return banks;
        }

        public static string GetInPayCountryAndBanksXml(cmSite site, CustomProfile profile)
        {
            try
            {
                InPayCountriesAndBanksRequest request = new InPayCountriesAndBanksRequest
                {
                    SESSION_ID = GamMatrixClient.GetSessionID(site, true),
                    SESSION_USERID = profile.UserID,
                    //CountryIso2 = CountryManager.GetAllCountries(site.DistinctName).FirstOrDefault(c => c.InternalID == profile.UserCountryID).ISO_3166_Alpha2Code
                };

                using (GamMatrixClient client = new GamMatrixClient())
                {
                    request = client.SingleRequest<InPayCountriesAndBanksRequest>(request);
                    return request.ApiResponseXml;
                }
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                throw;
            }
        }

        /// <summary>
        /// Returns the paycards for current logged in user
        /// </summary>
        /// <param name="vendorID"></param>
        /// <returns></returns>
        public static List<PayCardInfoRec> GetPayCards(VendorID vendorID)
        {
            return GetPayCards().Where(p => p.VendorID == vendorID).ToList();
        }
        
        public static List<PayCardInfoRec> GetMoneyMatrixPayCards()
        {
            return GetPayCards(loadAllMoneyMatrixPayCards: true).Where(p => p.VendorID == VendorID.MoneyMatrix).ToList();
        }

        public static List<PayCardInfoRec> GetMoneyMatrixPayCardsByPaymentSolutionNameOrDummy(string paymentSolutionName)
        {
            return GetMoneyMatrixPayCards().Where(pc => pc.CardName == paymentSolutionName || pc.IsDummy).ToList();
        }

        public static List<PayCardInfoRec> GetMoneyMatrixPayCardsByPaymentSolutionNamesOrDummy(string[] paymentSolutionName)
        {
            var notDummyPayCards = GetMoneyMatrixPayCards().LastOrDefault(pc => paymentSolutionName.Contains(pc.CardName));
            var dummyPayCards = GetMoneyMatrixPayCards().FirstOrDefault(pc => pc.IsDummy);
            var resultList = new List<PayCardInfoRec>
            {
                dummyPayCards
            };

            if (notDummyPayCards != null)
            {
                resultList.Add(notDummyPayCards);
            }

            return resultList;
        }

        /// <summary>
        /// Returns the new created paycard ID
        /// </summary>
        /// <param name="payCard"></param>
        /// <returns></returns>
        public static long RegisterPayCard(PayCardRec payCard, Dictionary<string, string> requestDynamicFields = null)
        {
            payCard.UserID = CustomProfile.Current.UserID;
            payCard.Type = PayCardType.Ordinary;
            payCard.ActiveStatus = ActiveStatus.Active;
            using (GamMatrixClient client = GamMatrixClient.Get())
            {
                RegisterPayCardRequest request = client.SingleRequest<RegisterPayCardRequest>(
                    new RegisterPayCardRequest()
                    {
                        Record = payCard,
                        RequestDynamicFields = requestDynamicFields
                    });

                return request.Record.ID;
            }
        }

        /// <summary>
        /// Update pay card status
        /// </summary>
        /// <param name="payCardID"></param>
        /// <param name="newStatus"></param>
        /// <returns></returns>
        public static void UpdatePayCardStatus(long payCardID, ActiveStatus newStatus)
        {
            using (GamMatrixClient client = GamMatrixClient.Get())
            {
                UpdatePayCardStatusRequest request = client.SingleRequest<UpdatePayCardStatusRequest>(
                    new UpdatePayCardStatusRequest()
                    {
                        PayCardID = payCardID,
                        NewStatus = newStatus
                    });
            }
        }

        #endregion

        public static void UpdateUserDetails(cmUser user)
        {
            UserRec userRec = new UserRec()
            {
                Alias = user.Alias,
                Avatar = user.Avatar,
                Currency = user.Currency,
                PreferredCurrency = user.PreferredCurrency,
                ID = user.ID,
                Title = user.Title,
                FirstName = user.FirstName,
                MiddleName = user.MiddleName,
                LastName = user.Surname,
                BirthDate = user.Birth.HasValue ? user.Birth.Value : DateTime.MinValue,
                Gender = (user.Gender == "M") ? Gender.Male : Gender.Female,
                Email = user.Email,
                CountryID = user.CountryID,
                TaxCode = user.TaxCode,
                Address1 = user.Address1,
                Address2 = user.Address2,
                Address3 = user.Address3,
                City = user.City,
                State = user.State,
                Zip = user.Zip,
                MobilePrefix = user.MobilePrefix,
                Mobile = user.Mobile,
                PhonePrefix = user.PhonePrefix,
                Phone = user.Phone,
                Language = user.Language,
                AllowNewsEmail = user.AllowNewsEmail,
                AllowSmsOffer = user.AllowSmsOffer,
                SecurityQuestion = user.SecurityQuestion,
                SecurityAnswer = user.SecurityAnswer,
                AffiliateMarker = user.AffiliateMarker,
                PersonalID = user.PersonalID,
                IsEmailVerified = user.IsEmailVerified,
                CompleteProfile = user.CompleteProfile,
                IntendedVolume = (IntendedVolume)user.intendedVolume,
                AcceptBonusByDefault = (long)user.AcceptBonusByDefault,
            };
            using (GamMatrixClient client = GamMatrixClient.Get())
            {
                UpdateUserDetailsRequest updateUserDetailsRequest = client.SingleRequest<UpdateUserDetailsRequest>(new UpdateUserDetailsRequest()
                {
                    Record = userRec,
                });
            }
        }

        public static long AddUserImageRequest(long userID, string fileName, string contentType, byte[] fileBytes, bool isPassport)
        {
            try
            {
                using (GamMatrixClient client = GamMatrixClient.Get())
                {
                    AddUserImageRequest addUserImageRequest = new AddUserImageRequest()
                    {
                        UserID = userID,
                        FileName = fileName,
                        FileContentType = contentType,
                        FileContent = fileBytes
                    };
                    AddUserImageRequest resp = client.SingleRequest<AddUserImageRequest>(addUserImageRequest);
                    if (resp != null)
                    {
                        if (isPassport)
                        {
                            UserAccessor ua = UserAccessor.CreateInstance<CM.db.Accessor.UserAccessor>();
                            ua.SetImageID(userID, resp.ImageID);
                        }
                        
                        return resp.ImageID;
                    }
                    else
                    {
                        Logger.Error("UploadPassport", string.Format("Can't get response from gmcore side, userid: {0}"));
                        return -1L;
                    }
                    
                }
            }
            catch (Exception ex)
            {
                Logger.Error("UploadPassport", ex.Message);
                return -1L;
            }
        }

        public static GetUserImageRequest GetUserImageRequest(long userID, long ImageID)
        {
            if (ImageID <= 0L) return null;

            try
            {
                using (GamMatrixClient client = GamMatrixClient.Get())
                {
                    GetUserImageRequest getUserImageRequest = new GamMatrixAPI.GetUserImageRequest()
                    {
                        UserID = userID,
                        ImageID = ImageID
                    };

                    return client.SingleRequest<GetUserImageRequest>(getUserImageRequest);
                }
            }
            catch (Exception ex)
            {
                Logger.Error("UploadPassport", ex.Message);
                return null;
            }
        }

        public static bool SetUserLicenseLTContractValidityRequest(long userId, string contractValidity, string language)
        {
            try
            {
                long contractImageID = -1L;
                using (System.Net.WebClient pdfClient = new System.Net.WebClient())
                {
                    var request = HttpContext.Current.Request;
                    byte[] pdfData = pdfClient.DownloadData(string.Format("{0}://{1}:{2}//{3}/GenerateContract.ashx?userid={4}&contractValidity={5}"
                        , request.IsHttps() ? "https" : "http"
                        , request.Url.Host
                        , request.Url.Port
                        , language
                        , userId
                        , contractValidity));
                    contractImageID = AddUserImageRequest(userId, string.Format("{0}_{1}.pdf", userId, DateTime.Now.ToString("yyyyMMDD_hhmmss")), "application/pdf", pdfData, false);
                }

                LicenseLTContractValidity licenseContractValidity = LicenseLTContractValidity.Unlimited;
                Enum.TryParse<LicenseLTContractValidity>(contractValidity, out licenseContractValidity);
                using (GamMatrixClient client = GamMatrixClient.Get())
                {
                    SetUserLicenseLTContractValidityRequest request = new SetUserLicenseLTContractValidityRequest()
                    {
                        UserID = userId,
                        ContractImageID = contractImageID,
                        ContractValidityPeriod = licenseContractValidity
                    };

                    client.SingleRequest<SetUserLicenseLTContractValidityRequest>(request);
                    return true;
                }
            } 
            catch (Exception ex)
            {
                Logger.Error("Contract", ex.Message);
                return false;
            }
        }

        public static GetUserLicenseLTContractValidityRequest GetUserLicenseLTContractValidityRequest(long userId)
        {
            try
            {
                using (GamMatrixClient client = GamMatrixClient.Get())
                {
                    GetUserLicenseLTContractValidityRequest request = new GetUserLicenseLTContractValidityRequest()
                    {
                        UserID = userId,
                    };

                    return client.SingleRequest<GetUserLicenseLTContractValidityRequest>(request);
                }
            }
            catch (Exception ex)
            {
                Logger.Error("Contract", ex.Message);
                return null;
            }
        }

        #region GetUserPersonalDetailsBySSN
        public static IAsyncResult GetUserPersonalDetailsBySSNAsync(string personalNumber, Action<GetUserPersonalDetailsSSNRequest> callback)
        {
            GetUserPersonalDetailsSSNRequest getUserPersonalDetailsSSNRequest = new GetUserPersonalDetailsSSNRequest()
            {
                PersonalNumber = personalNumber
            };
            return GamMatrixClient.SingleRequestAsync<GetUserPersonalDetailsSSNRequest>(getUserPersonalDetailsSSNRequest
                , OnUserPersonalDetailsBySSNCompleted
                , callback
                );
        }
        public static void OnUserPersonalDetailsBySSNCompleted(AsyncResult result)
        {
            Action<GetUserPersonalDetailsSSNRequest> callback = result.UserState1 as Action<GetUserPersonalDetailsSSNRequest>;
            try
            {
                GetUserPersonalDetailsSSNRequest response = result.EndSingleRequest().Get<GetUserPersonalDetailsSSNRequest>();

                callback(response);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                if (callback != null)
                    callback(null);
            }
        }

        public static GetUserPersonalDetailsSSNRequest GetUserPersonalDetailsBySSN(string personalNumber)
        {
            GetUserPersonalDetailsSSNRequest getUserPersonalDetailsSSNRequest = new GetUserPersonalDetailsSSNRequest()
            {
                PersonalNumber = personalNumber
            };
            try
            {
                using (GamMatrixClient client = GamMatrixClient.Get())
                {
                    GetUserPersonalDetailsSSNRequest response = client.SingleRequest(getUserPersonalDetailsSSNRequest);
                    return response;
                }
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return null;
            }
        }
        #endregion GetUserPersonalDetailsBySSN

        #region Translations
        public static IAsyncResult GetTransactionsAsync(TransSelectParams transSelectParams,int PageNumber, int PageSize, Action<List<TransInfoRec>> callback)
        {            
            GetTransRequest getTransRequest = new GetTransRequest()
                {
                    SelectionCriteria = transSelectParams,
                    PagedData = new PagedDataOfTransInfoRec
                    {
                        PageSize = PageSize,
                        PageNumber = PageNumber,
                    }
                };

            return GamMatrixClient.SingleRequestAsync<GetTransRequest>(getTransRequest, OnGetTransactionsCompleted, callback);
        }

        public static void OnGetTransactionsCompleted(AsyncResult result)
        {
            Action<List<TransInfoRec>> callback = result.UserState1 as Action<List<TransInfoRec>>;
            try
            {
                List<TransInfoRec> list = new List<TransInfoRec>();
                GetTransRequest response = result.EndSingleRequest().Get<GetTransRequest>();
                if (response != null &&
                    response.PagedData != null &&
                    response.PagedData.Records != null &&
                    response.PagedData.Records.Count > 0)
                {
                    list = response.PagedData.Records
                        .ToList();
                }

                callback(list);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                if (callback != null)
                    callback(null);
            }
        }
        
        public static List<TransInfoRec> GetTransactions(TransType[] types, TransStatus[] statuses, VendorID? vendorID = null, int? PageNumber=0, int? PageSize=int.MaxValue)
        {
            TransSelectParams transSelectParams = new TransSelectParams()
            {
                ByTransTypes = types.Length > 0,
                ParamTransTypes = types.ToList(),
                ByUserID = true,
                ParamUserID = CustomProfile.Current.UserID,
                ByTransStatuses = statuses.Length > 0,
                ParamTransStatuses = statuses.ToList(),
            };
            if (vendorID.HasValue)
            {
                transSelectParams.ByPayItemVendorID = true;
                transSelectParams.ParamPayItemVendorID = vendorID.Value;
            }

            using (GamMatrixClient client = GamMatrixClient.Get())
            {
                GetTransRequest getTransRequest = client.SingleRequest<GetTransRequest>(new GetTransRequest()
                {
                    SelectionCriteria = transSelectParams,
                    PagedData = new PagedDataOfTransInfoRec
                    {
                        PageSize = PageSize.HasValue ? PageSize.Value : int.MaxValue,
                        PageNumber = PageNumber.HasValue ? PageNumber.Value : 0,
                    }
                });

                if (getTransRequest != null &&
                    getTransRequest.PagedData != null &&
                    getTransRequest.PagedData.Records != null &&
                    getTransRequest.PagedData.Records.Count > 0)
                {
                    return getTransRequest.PagedData.Records
                        .ToList();
                }
            }

            return new List<TransInfoRec>();
        }
        #endregion

        public static List<PaymentVendorInfo> GetActivePaymentVendors(cmSite site)
        {
            using (GamMatrixClient client = GamMatrixClient.Get())
            {
                GetActivePaymentVendorsRequest getActivePaymentVendorsRequest = new GetActivePaymentVendorsRequest()
                    {
                        SESSION_ID = GamMatrixClient.GetSessionID(site),
                        ContextDomainID = site.DomainID,
                    };
                getActivePaymentVendorsRequest = client.SingleRequest<GetActivePaymentVendorsRequest>(getActivePaymentVendorsRequest);
                return getActivePaymentVendorsRequest.ActivePaymentVendorList;
            }
        }

        #region pending deposits
        /// <summary>
        /// Only supports ArtemisSMS, TurkeySMS and TurkeyBankWire
        /// </summary>
        /// <param name="paymentVendorID"></param>
        /// <param name="userID"></param>
        /// <returns></returns>
        public static int GetPendingDepositCount(VendorID paymentVendorID, long userID)
        {
            int _count = 0;
            switch (paymentVendorID)
            { 
                case VendorID.ArtemisSMS:
                    var artemisSMSDeposits = GetArtemisSMSPendingDeposits(userID);
                    if(artemisSMSDeposits!=null) 
                        _count = artemisSMSDeposits.Count;
                    break;
                case VendorID.TurkeySMS:
                    var turkeySMSDeposits = GetTurkeySMSPendingDeposits(userID);
                    if (turkeySMSDeposits != null)
                        _count = turkeySMSDeposits.Count;
                    break;
                case VendorID.TurkeyBankWire:
                    var turkeyBankWireDeposits = GetTurkeyBankWirePendingDeposits(userID);
                    if (turkeyBankWireDeposits != null)
                        _count = turkeyBankWireDeposits.Count;
                    break;
            }

            return _count;
        }

        public static List<ArtemisSMSInfoRec> GetArtemisSMSPendingDeposits(long userID, int pageSize = 20, int pageNumber = 0)
        {
            return GetArtemisSMSDeposits(TransStatus.Setup, userID, pageSize, pageNumber);
        }
        private static List<ArtemisSMSInfoRec> GetArtemisSMSDeposits(TransStatus transStatus, long userID, int pageSize, int pageNumber)
        {
            using (GamMatrixClient client = GamMatrixClient.Get())
            {
                ArtemisSMSPaymentsRequest artemisSMSPaymentsRequest = new ArtemisSMSPaymentsRequest()
                {
                    SelectionCriteria = new ArtemisSMSSelectParams()
                    {
                        ByTransStatus = true,
                        ParamTransStatus = transStatus,
                        UserID = userID,

                    },
                    PagedData = new PagedDataOfArtemisSMSInfoRec()
                    {
                        PageSize = pageSize,
                        PageNumber = pageNumber,
                    }
                };

                artemisSMSPaymentsRequest = client.SingleRequest<ArtemisSMSPaymentsRequest>(artemisSMSPaymentsRequest);

                return artemisSMSPaymentsRequest.PagedData.Records;
            }
        }

        public static List<TurkeySMSInfoRec> GetTurkeySMSPendingDeposits(long userID, int pageSize = 1, int pageNumber = 0)
        {
            return GetTurkeySMSDeposits(TransStatus.Setup, userID, pageSize, pageNumber);
        }
        private static List<TurkeySMSInfoRec> GetTurkeySMSDeposits(TransStatus transStatus, long userID, int pageSize, int pageNumber)
        {
            using (GamMatrixClient client = GamMatrixClient.Get())
            {
                TurkeySMSPaymentsRequest turkeySMSPaymentsRequest = new TurkeySMSPaymentsRequest()
                {
                    SelectionCriteria = new TurkeySMSSelectParams
                    {
                        ByTransStatus = true,
                        ParamTransStatus = transStatus,
                        UserID = userID,

                    },
                    PagedData = new PagedDataOfTurkeySMSInfoRec
                    {
                        PageSize = pageSize,
                        PageNumber = pageNumber,
                    }
                };

                turkeySMSPaymentsRequest = client.SingleRequest<TurkeySMSPaymentsRequest>(turkeySMSPaymentsRequest);

                return turkeySMSPaymentsRequest.PagedData.Records;
            }
        }


        public static List<TurkeyBankWireInfoRec> GetTurkeyBankWirePendingDeposits(long userID, int pageSize = 1, int pageNumber = 0)
        {
            return GetTurkeyBankWireDeposits(TransStatus.Setup, userID, pageSize, pageNumber);
        }
        private static List<TurkeyBankWireInfoRec> GetTurkeyBankWireDeposits(TransStatus transStatus, long userID, int pageSize, int pageNumber)
        {
            using (GamMatrixClient client = GamMatrixClient.Get())
            {
                TurkeyBankWirePaymentsRequest turkeyBankWirePaymentsRequest = new TurkeyBankWirePaymentsRequest()
                {
                    SelectionCriteria = new TurkeyBankWireSelectParams
                    {
                        ByTransStatus = true,
                        ParamTransStatus = transStatus,
                        UserID = userID,

                    },
                    PagedData = new PagedDataOfTurkeyBankWireInfoRec
                    {
                        PageSize = pageSize,
                        PageNumber = pageNumber,
                    }
                };

                turkeyBankWirePaymentsRequest = client.SingleRequest<TurkeyBankWirePaymentsRequest>(turkeyBankWirePaymentsRequest);

                return turkeyBankWirePaymentsRequest.PagedData.Records;
            }
        }

        #endregion

        #region SdkUrl, MonitoringUrl

        public static string GetSdkUrl(string userAgent, string clientIp = null)
        {
            try
            {
                using (var client = GamMatrixClient.Get())
                {
                    var request = new MoneyMatrixGetSdkUrlRequest
                    {
                        ContextDomainID = SiteManager.Current.DomainID,
                        UserAgent = userAgent
                    };

                    if (clientIp != null)
                    {
                        request.ClientIp = clientIp;
                    }

                    request = client.SingleRequest(request);

                    return request.Url;
                }
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
            }

            return string.Empty;
        }

        public static string GetMonitoringUrl(string userAgent, string clientIp = null)
        {
            try
            {
                using (var client = GamMatrixClient.Get())
                {
                    var request = new MoneyMatrixGetMonitoringUrlRequest
                    {
                        ContextDomainID = SiteManager.Current.DomainID,
                        UserAgent = userAgent
                    };

                    if (clientIp != null)
                    {
                        request.ClientIp = clientIp;
                    }

                    request = client.SingleRequest(request);

                    return request.Url;
                }
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
            }

            return string.Empty;
        }

        #endregion
    }
}