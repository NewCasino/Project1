using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Configuration;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using System.Threading.Tasks;
using System.Web;
using System.Web.Caching;
using System.Web.Profile;

using BLToolkit.Data;
using BLToolkit.DataAccess;

using CM.db;
using CM.db.Accessor;
using CM.Misc;
using CM.Sites;

using EveryMatrix.SessionAgent;
using EveryMatrix.SessionAgent.Protocol;

using GamMatrix.Infrastructure;
using GamMatrixAPI;
using TwoFactorAuth;

namespace CM.State
{
    /// <summary>
    /// Custom profile class inherited from ProfileBase
    /// </summary>
    public class CustomProfile : ProfileBase
    {
        private static AgentClient _agentClient = new AgentClient(
            ConfigurationManager.AppSettings["SessionAgent.ZooKeeperConnectionString"],
            ConfigurationManager.AppSettings["SessionAgent.ClusterName"],
            ConfigurationManager.AppSettings["SessionAgent.UseProtoBuf"] == "1"
            );

        //private static NonBlockingRedisClient _redisClient 
        //    = new NonBlockingRedisClient(ConfigurationManager.AppSettings["SessionAgent.RedisServer"] ?? "10.0.10.38:6379");
        private static readonly NonBlockingRedisClient _redisClient = string.Equals(ConfigurationManager.AppSettings["SessionAgent.UseSentinel"], "true", StringComparison.InvariantCultureIgnoreCase)
            ? new NonBlockingRedisClient(ConfigurationManager.AppSettings["SessionAgent.SentinelAddress"].Split(";".ToCharArray(), StringSplitOptions.RemoveEmptyEntries), ConfigurationManager.AppSettings["SessionAgent.SentinelMasterName"])
            : new NonBlockingRedisClient(ConfigurationManager.AppSettings["SessionAgent.RedisServer"] ?? "10.0.10.38:6379");

        private SessionPayload _sessionPayload;

        private static readonly int _failedLogin_LockUser_Duration = 30;
        private static readonly int _failedLogin_RequiresCaptcha_Attempts = 2;
        //private static readonly int _failedLogin_LockUser_Attempts = 2;        

        public static int _touchLock = 0;
        public static long _lastTouchTime = DateTime.UtcNow.Ticks;
        public static ConcurrentDictionary<string, object> _guidsToBeTouched = new ConcurrentDictionary<string, object>();

        public void Set(string fieldName, string text)
        {
            _redisClient.SetBySessionID(this.SessionID, fieldName, text);
            //if (_redis == null || _redis.State != RedisConnectionBase.ConnectionState.Open)
            //{
            //    _redis = new RedisConnectionEx();
            //    _redis.Open().Wait();
            //}
            //if (text == null)
            //    _redis.Hashes.Remove(0, this.SessionID, fieldName).ContinueWith(c =>
            //    {
            //        ExceptionHandler.Process(c.Exception);
            //    },
            //                TaskContinuationOptions.OnlyOnFaulted |
            //                TaskContinuationOptions.ExecuteSynchronously);
            //else
            //    _redis.Hashes.Set(0, this.SessionID, fieldName, Encoding.UTF8.GetBytes(text)).ContinueWith(c =>
            //    {
            //        ExceptionHandler.Process(c.Exception);
            //    },
            //                TaskContinuationOptions.OnlyOnFaulted |
            //                TaskContinuationOptions.ExecuteSynchronously);
            
        }

        public string Get(string fieldName)
        {
            return _redisClient.GetBySessionID(this.SessionID, fieldName);
            //if (_redis == null || _redis.State != RedisConnectionBase.ConnectionState.Open )
            //{
            //    _redis = new RedisConnectionEx();
            //    _redis.Open().Wait();
            //}
            //Task<string> task = _redis.Hashes.GetString(0, this.SessionID, fieldName);
            //task.Wait();
            //return task.Result;
        }
        /*
        public RedisSession RedisSession
        {
            get
            {
                return _redisSession;
            }
        }

        private RedisSession _redisSession;
         * */

        /// <summary>
        /// The session guid
        /// </summary>
        [SettingsAllowAnonymous(true)]
        public string SessionID
        {
            get
            {
                if (_sessionPayload != null)
                    return _sessionPayload.Guid;
                return null;
            }
        }

        /// <summary>
        /// user id
        /// </summary>
        [SettingsAllowAnonymous(false)]
        public int UserID
        {
            get
            {
                if (_sessionPayload != null)
                    return (int)_sessionPayload.UserID;
                return 0;
            }
        }

        /// <summary>
        /// domain id
        /// </summary>
        [SettingsAllowAnonymous(true)]
        public int DomainID
        {
            get
            {
                if (_sessionPayload != null)
                    return _sessionPayload.DomainID;
                return 0;
            }
        }

        /// <summary>
        /// country id of this user
        /// </summary>
        [SettingsAllowAnonymous(true)]
        public int UserCountryID
        {
            get
            {
                if (_sessionPayload != null)
                    return _sessionPayload.UserCountryID;
                return 0;
            }
        }

        private int ipCountryID = 0;
        /// <summary>
        /// country id of the ip
        /// </summary>
        [SettingsAllowAnonymous(true)]
        public int IpCountryID
        {
            get
            {
                if (_sessionPayload != null && _sessionPayload.IpCountryID > 0)
                    return _sessionPayload.IpCountryID;
                return ipCountryID;
            }
            set
            {
                ipCountryID = value;
            }
        }

        /// <summary>
        /// display name
        /// </summary>
        [SettingsAllowAnonymous(true)]
        public string DisplayName
        {
            get;
            set;
        }

        /// <summary>
        /// First name
        /// </summary>
        [SettingsAllowAnonymous(true)]
        public string FirstName
        {
            get
            {
                if (_sessionPayload != null)
                    return _sessionPayload.Firstname;
                return null;
            }
        }

        /// <summary>
        /// Sur Name  
        /// </summary>
        [SettingsAllowAnonymous(true)]
        public string SurName
        {
            get
            {
                if (_sessionPayload != null)
                    return _sessionPayload.Surname;
                return null;
            }
        }

        /// <summary>
        /// Alias 
        /// </summary>
        [SettingsAllowAnonymous(true)]
        public string Alias
        {
            get;
            set;
        }

        /// <summary>
        /// bool indicates if it is authenticated user
        /// </summary>
        [SettingsAllowAnonymous(true)]
        public bool IsAuthenticated
        {
            get
            {
                if (_sessionPayload != null)
                    return _sessionPayload.IsAuthenticated == true;
                return false;
            }
        }

        /// <summary>
        /// Role string of this user
        /// </summary>
        [SettingsAllowAnonymous(true)]
        public string RoleString
        {
            get
            {
                if (_sessionPayload != null && _sessionPayload.Roles != null)
                    return string.Join(",", _sessionPayload.Roles);
                return null;
            }
            set
            {
                if (value != null)
                {
                    _agentClient.UpdateSession(new SessionPayload()
                    {
                        Guid = _sessionPayload.Guid,
                        Roles = value.Split(','),
                    });
                }
            }
        }

        /// <summary>
        /// LastAccess of this session
        /// </summary>
        [SettingsAllowAnonymous(true)]
        public DateTime LastAccess
        {
            get
            {
                if (_sessionPayload != null)
                    return _sessionPayload.LastAccess;
                return DateTime.MinValue;
            }
        }

        /// <summary>
        /// LoginTime
        /// </summary>
        [SettingsAllowAnonymous(true)]
        public DateTime LoginTime
        {
            get
            {
                if (_sessionPayload != null)
                    return _sessionPayload.Login;
                return DateTime.MinValue;
            }
        }

        /// <summary>
        /// LoginTime
        /// </summary>
        [SettingsAllowAnonymous(true)]
        public DateTime LastLoginTime
        {
            get
            {
                if (_sessionPayload != null)
                    return _sessionPayload.LastLogin;
                return DateTime.MinValue;
            }
        }

        /// <summary>
        /// The seconds to limit the session time
        /// </summary>
        public int SessionLimitSeconds
        {
            get
            {
                if (_sessionPayload != null && _sessionPayload.SessionLimitSeconds.HasValue)
                    return _sessionPayload.SessionLimitSeconds.Value;
                return 0;
            }
        }

        /// <summary>
        /// currency of this user
        /// </summary>
        [SettingsAllowAnonymous(true)]
        public string UserCurrency
        {
            get
            {
                if (_sessionPayload != null)
                    return _sessionPayload.Currency;
                return null;
            }
        }


        [SettingsAllowAnonymous(true)]
        public string PreferredCurrency
        {
            get
            {
                if (_sessionPayload != null)
                    return _sessionPayload.Currency;
                return null;
            }
        }

        [SettingsAllowAnonymous(true)]
        public string Email
        {
            get
            {
                if (_sessionPayload != null)
                    return _sessionPayload.Email;
                return null;
            }
        }

        /// <summary>
        /// AM
        /// </summary>
        [SettingsAllowAnonymous(true)]
        public string AffiliateMarker
        {
            get
            {
                if (_sessionPayload != null)
                    return _sessionPayload.AffiliateMarker;
                return null;
            }
        }

        /// <summary>
        /// LoginIP
        /// </summary>
        [SettingsAllowAnonymous(true)]
        public string LoginIP
        {
            get
            {
                if (_sessionPayload != null)
                    return _sessionPayload.IP;
                return null;
            }
        }

        /// <summary>
        /// LoginIP
        /// </summary>
        [SettingsAllowAnonymous(false)]
        public bool IsExternal
        {
            get
            {
                if (_sessionPayload != null)
                    return _sessionPayload.IsExternal == true;
                return false;
            }
        }

        /// <summary>
        /// IsEmailVerified
        /// </summary>
        [SettingsAllowAnonymous(false)]
        public bool IsEmailVerified
        {
            get
            {
                if (_sessionPayload != null)
                    return _sessionPayload.IsEmailVerified == true;
                return false;
            }
            set
            {
                // TO DO
                if (value != this.IsEmailVerified)
                {
                    try
                    {
                        SessionPayload p = new SessionPayload()
                        {
                            Guid = this.SessionID,
                            IsEmailVerified = value,
                        };
                        _agentClient.UpdateSession(p);
                    }
                    catch
                    {
                    }
                }
            }
        }

        /// <summary>
        /// JoinTime
        /// </summary>
        [SettingsAllowAnonymous(false)]
        public DateTime JoinTime
        {
            get
            {
                if (_sessionPayload != null)
                    return _sessionPayload.Registration;
                return DateTime.MinValue;
            }
        }

        public int NumberOfDaysForLoginWithoutEmailVerification
        {
            get
            {
                int days = 7;
                if (int.TryParse(CM.Content.Metadata.Get("Metadata/Settings.NumberOfDaysForLoginWithoutEmailVerification"), out days))
                {
                    return days;
                }
                return 7;
            }
        }

        private bool? _IsCaptchaEnabledForLogin;
        private bool IsCaptchaEnabledForLogin
        {
            get
            {
                if (!_IsCaptchaEnabledForLogin.HasValue)
                {
                    _IsCaptchaEnabledForLogin = CM.Content.Metadata.Get("Metadata/Settings/Login.IsCaptchaEnabled").ParseToBool(false);                    
                }
                return _IsCaptchaEnabledForLogin.Value;
            }
        }

        public int FailedLoginAttempts_LockUser
        {
            get
            {
                var attempts = IsCaptchaEnabledForLogin ? 5 : 3;
                var metadataPath = "Metadata/Settings." + (IsCaptchaEnabledForLogin ? "FailedLoginAttempts_LockUser_CaptchaEnabled" : "FailedLoginAttempts_LockUser");
                int.TryParse(CM.Content.Metadata.Get(metadataPath), out attempts);
                return attempts;
            }
        }
        


        private bool? _IsSecondFactorAuthenticationEnabled;
        private bool IsSecondFactorAuthenticationEnabled
        {
            get
            {
                if (!_IsSecondFactorAuthenticationEnabled.HasValue)
                {
                    _IsSecondFactorAuthenticationEnabled = CM.Content.Metadata.Get("Metadata/Settings/Session.SecondFactorAuthenticationEnabled").ParseToBool(false);
                }
                return _IsSecondFactorAuthenticationEnabled.Value;
            }
        }

        private bool? _IsSecondStepsAuthenticationEnabled;
        private bool IsSecondStepsAuthenticationEnabled
        {
            get
            {
                if (!_IsSecondStepsAuthenticationEnabled.HasValue)
                {
                    _IsSecondStepsAuthenticationEnabled = CM.Content.Metadata.Get("Metadata/Settings.SecondStepsAuthenticationEnabled").ParseToBool(false);
                }
                return _IsSecondStepsAuthenticationEnabled.Value;
            }
        }

        /// <summary>
        /// Clear session cache from memcached server
        /// </summary>
        /// <param name="sessionGuid"></param>
        public static void ClearSessionCache(string sessionGuid)
        {
            //RedisSession.Remove(sessionGuid);
        }


        public static void ReloadSessionCache(long userID)
        {
            _agentClient.ReloadAliveSessionCache(userID);
        }

        public static void UpdateSessions(long userID, Func<SessionPayload, bool> callback)
        {
            if (callback != null)
            {
                string[] guids = _agentClient.GetLoggedInSessions(userID);
                if (guids != null)
                {
                    foreach (string guid in guids)
                    {
                        SessionPayload sess = _agentClient.GetSessionByGuid(guid);
                        if (sess != null && sess.IsAuthenticated == true)
                        {
                            if (callback(sess))
                                _agentClient.UpdateSession(sess);
                        }
                    }
                }
            }
        }

        /// <summary>
        /// Constructor
        /// </summary>
        public CustomProfile()
        {
        }



        /// <summary>
        /// Detect if user is assigned with the roles
        /// </summary>
        /// <param name="roles">role names</param>
        /// <returns></returns>
        public bool IsInRole(params string[] roles)
        {
            if (roles == null || roles.Length == 0)
                return false;

            if (string.IsNullOrEmpty(this.RoleString))
                return false;

            return roles.Intersect(this.RoleString.Split(','), StringComparer.InvariantCultureIgnoreCase).Count() > 0;
        }

        /// <summary>
        /// Get current profile instance
        /// </summary>
        public static CustomProfile Current
        {
            get
            {
                return HttpContext.Current.Profile as CustomProfile;
            }
        }

        /// <summary>
        /// Initialize Anonymous session
        /// </summary>
        /// <param name="httpContext"></param>
        public void InitAnonymous(HttpContext httpContext)
        {
            string sessionID = "Anonymous" + Guid.NewGuid().ToString();
            _sessionPayload = new SessionPayload()
            { 
                Guid = sessionID,
                Roles = new string[] { "Anonymous" },
                DomainID = SiteManager.Current.DomainID,
            };
        }


        public void Init(HttpContext httpContext)
        {
            Init(httpContext, false);
        }

        private static Regex ipRegex = new Regex(@"^(?<a1>\d+)\.(?<a2>\d+)\.(\d+)\.(\d+)$", RegexOptions.Compiled | RegexOptions.ECMAScript);

        /// <summary>
        /// initialize the profile with HttpContext
        /// </summary>
        /// <param name="httpContext">HttpContext</param>
        /// <param name="ignoreIpVerification">true if should ignore Ip Verification</param>
        public void Init(HttpContext httpContext, bool ignoreIpVerification)
        {
            cmSite site = SiteManager.Current;
            if (site != null)
            {
                // get the session id from HttpOnly cookie
                HttpCookie cookie = httpContext.Request.Cookies[site.SessionCookieName];
                string currentSessionID = null;
                if (cookie != null && !string.IsNullOrEmpty(cookie.Value))
                {
                    currentSessionID = cookie.Value;
                }

                // detect _sid
                string sid = httpContext.Request.QueryString["_sid"];
                

                // if no session cookie found
                if (!string.IsNullOrWhiteSpace(sid) || string.IsNullOrWhiteSpace(currentSessionID))
                {
                    currentSessionID = sid.DefaultIfNullOrEmpty("Anonymous" + Guid.NewGuid().ToString());
                    cookie = new HttpCookie(site.SessionCookieName, currentSessionID);
                    if (!string.IsNullOrWhiteSpace(site.SessionCookieDomain))
                        cookie.Domain = site.SessionCookieDomain.Trim();
                    cookie.HttpOnly = true;
                    cookie.Secure = SafeParseBoolString(CM.Content.Metadata.Get("Metadata/Settings.EnableSecureCookie").DefaultIfNullOrEmpty("no"), false);
                    httpContext.Response.Cookies.Add(cookie);
                }

                if (!currentSessionID.StartsWith("Anonymous"))
                {
                    _sessionPayload = _redisClient.ReadByGuid(currentSessionID);

                    if (!string.IsNullOrWhiteSpace(sid) && (_sessionPayload == null || true != _sessionPayload.IsAuthenticated))
                    {
                        _sessionPayload = _agentClient.GetSessionByGuid(sid, true);
                        if (_sessionPayload != null)
                            _redisClient.Save(_sessionPayload).ContinueWith(c => {
                                ExceptionHandler.Process(c.Exception);
                            },
                            TaskContinuationOptions.OnlyOnFaulted | 
                            TaskContinuationOptions.ExecuteSynchronously);
                    }
                }


                if (_sessionPayload != null)
                {
                    if (!this.IsAuthenticated)
                    {
                        this.Initialize("Guest", false);
                        string sessionID = "Anonymous" + Guid.NewGuid().ToString();
                        cookie = new HttpCookie(site.SessionCookieName, sessionID);
                        if (!string.IsNullOrWhiteSpace(site.SessionCookieDomain))
                            cookie.Domain = site.SessionCookieDomain.Trim();
                        cookie.HttpOnly = true;
                        cookie.Secure = SafeParseBoolString(CM.Content.Metadata.Get("Metadata/Settings.EnableSecureCookie").DefaultIfNullOrEmpty("no"), false);
                        httpContext.Response.Cookies.Clear();
                        httpContext.Response.Cookies.Add(cookie);

                        if (_sessionPayload.ExitReason.HasValue)
                            this.OnLogoffCompleted(_sessionPayload.UserID, _sessionPayload.Guid, _sessionPayload.ExitReason.Value);
                    }
                    else
                    {
                        _guidsToBeTouched[currentSessionID] = currentSessionID;
                        this.Initialize(_sessionPayload.Username, true);
                        this.DisplayName = string.Format("{0} {1}", _sessionPayload.Firstname, _sessionPayload.Surname);

                        if (_sessionPayload.Roles == null)
                        {
                            using (CodeProfiler.Step(1, "Init - GetRoleStringByUser"))
                            {
                                string roleString = this.GetRoleStringByUser(site, this.UserID).DefaultIfNullOrEmpty(",");
                                SessionPayload sessionPayload = new SessionPayload()
                                {
                                    Guid = _sessionPayload.Guid,
                                };
                                if (roleString != null)
                                    sessionPayload.Roles = roleString.Split(',');
                                else
                                    sessionPayload.Roles = new string[0];
                                _agentClient.UpdateSession(sessionPayload);
                            }
                        }
                    }
                }
                else
                {
                    this.Initialize("Guest", false);
                    _sessionPayload = new SessionPayload()
                    {
                        Guid = currentSessionID,
                        Roles = new string[] { "Anonymous" },
                        DomainID = site.DomainID,
                    };
                }

                {
                    ConcurrentDictionary<string, object> dic = null;
                    if (Interlocked.Increment(ref _touchLock) == 1)
                    {
                        long currentTicks = DateTime.UtcNow.Ticks;
                        if (currentTicks - _lastTouchTime > 10000000 * 25)
                        {
                            _lastTouchTime = currentTicks;
                            dic = Interlocked.Exchange(ref _guidsToBeTouched, new ConcurrentDictionary<string, object>());
                        }
                    }
                    Interlocked.Decrement(ref _touchLock);

                    if (dic != null && dic.Count > 0)
                    {
                        try
                        {
                            _agentClient.BatchKeepSessionAlive(dic.Keys.ToArray());
                        }
                        catch
                        {
                        }
                    }
                }

                if (_sessionPayload.IsAuthenticated != true)
                {

                    IPLocation ipLocation = IPLocation.GetByIP(httpContext.Request.GetRealUserAddress());
                    if (ipLocation != null && ipLocation.Found)
                    {
                        this.IpCountryID = ipLocation.CountryID;
                    }
                }


                if (!ignoreIpVerification && _sessionPayload != null && _sessionPayload.IsAuthenticated == true)
                {
                    // Force HTTPS for logged-in users
                    if (!httpContext.Request.IsHttps() &&
                        !httpContext.Request.IsAjaxRequest() &&
                        SiteManager.Current.HttpsPort > 0 &&
                        string.Equals(httpContext.Request.HttpMethod, "GET", StringComparison.InvariantCultureIgnoreCase) &&
                        !httpContext.Request.RawUrl.StartsWith("/Login/LoginResponse", StringComparison.InvariantCultureIgnoreCase))
                    {
                        string clientIP = httpContext.Request.GetRealUserAddress();
                        if (!clientIP.Equals("85.9.28.130") && !clientIP.Equals("85.9.7.222") &&
                            !clientIP.StartsWith("10.0.11.", StringComparison.InvariantCulture) &&
                            !clientIP.StartsWith("10.0.10.", StringComparison.InvariantCulture) &&
                            !clientIP.StartsWith("192.168.", StringComparison.InvariantCulture) &&
                            !(clientIP.CompareTo("172.16.0.0") > 0 && clientIP.CompareTo("172.31.255.255") < 0) &&
                            !clientIP.StartsWith("109.205.9", StringComparison.InvariantCulture))
                        {
                            string postfix = string.Empty;
                            if (SiteManager.Current.HttpsPort != 443)
                                postfix = string.Format(":{0}", SiteManager.Current.HttpsPort);

                            string url = string.Format("https://{0}{1}/{2}"
                                , httpContext.Request.Url.Host
                                , postfix
                                , httpContext.Request.Url.PathAndQuery.TrimStart('/')
                                );
                            httpContext.Response.Redirect(url, false);
                            return;
                        }
                    }


                    bool isInvalidSession = false;



                    string ip = httpContext.Request.GetRealUserAddress();
                    if (!ignoreIpVerification &&
                        !isInvalidSession &&
                        !this.IsExternal &&
                        !string.IsNullOrWhiteSpace(this.LoginIP) &&
                        !string.Equals(this.LoginIP, httpContext.Request.GetRealUserAddress(), StringComparison.InvariantCultureIgnoreCase) &&
                        !ip.StartsWith("10.0.", StringComparison.InvariantCulture) &&
                        !ip.StartsWith("109.205.", StringComparison.InvariantCulture) &&
                        !ip.StartsWith("78.133.", StringComparison.InvariantCulture) &&
                        !ip.StartsWith("192.168.", StringComparison.InvariantCulture) &&
                        !(ip.CompareTo("172.16.0.0") > 0 && ip.CompareTo("172.31.255.255") < 0) &&
                        !ip.Equals("85.9.28.130", StringComparison.InvariantCulture) &&
                        !ip.Equals("85.9.7.222", StringComparison.InvariantCulture))
                    {
                        Match m1 = ipRegex.Match(this.LoginIP);
                        Match m2 = ipRegex.Match(httpContext.Request.GetRealUserAddress());
                        if (m1.Success && m2.Success)
                        {
                            if (m1.Groups["a1"].Value != m2.Groups["a1"].Value ||
                                m1.Groups["a2"].Value != m2.Groups["a2"].Value)
                            {
                                isInvalidSession = true;
                                SessionPayload sessionPayload = new SessionPayload()
                                {
                                    Guid = _sessionPayload.Guid,
                                    IsAuthenticated = false,
                                    ExitReason = SessionExitReason.IPChanged
                                };

                                _agentClient.UpdateSession(sessionPayload);
                                OnLogoffCompleted(this.UserID, this.SessionID, SessionExitReason.IPChanged);
                            }
                        }
                    }

                    if (isInvalidSession)
                    {
                        _sessionPayload = new SessionPayload()
                        {
                            Guid = "Anonymous" + Guid.NewGuid().ToString(),
                            Roles = new string[] { "Anonymous" },
                            DomainID = site.DomainID,
                        };

                        cookie = new HttpCookie(site.SessionCookieName, _sessionPayload.Guid);
                        if (!string.IsNullOrWhiteSpace(site.SessionCookieDomain))
                            cookie.Domain = site.SessionCookieDomain.Trim();
                        cookie.HttpOnly = true;
                        cookie.Secure = SafeParseBoolString(CM.Content.Metadata.Get("Metadata/Settings.EnableSecureCookie").DefaultIfNullOrEmpty("no"), false);
                        httpContext.Response.Cookies.Remove(site.SessionCookieName);
                        httpContext.Response.Cookies.Add(cookie);
                    }
                }
            }
        }


        /// <summary>
        /// Result of the login
        /// </summary>
        public enum LoginResult
        {
            Undefined,
            /// <summary> Success </summary>
            Success,
            /// <summary> username or password does not match </summary>
            NoMatch,
            /// <summary> email address is not verified </summary>
            EmailNotVerified,
            /// <summary> user is blocked </summary>
            Blocked,
            /// <summary> too many failed attempts </summary>
            TooManyInvalidAttempts,
            /// <summary> country is blocked </summary>
            CountryBlocked,
            /// <summary>No password</summary>
            NoPassword,

			/// <summary>Password unsafe</summary>
            NeedChangePassword,

            /// <summary>
            /// requires captcha
            /// </summary>
            RequiresCaptcha,

            /// <summary>
            /// username or password does not match, requires captcha for next attempt
            /// </summary>
            NoMatch_RequiresCaptcha,

            /// <summary>
            /// captcha is incorrect
            /// </summary>
            CaptchaNotMatch,

            /// <summary>
            /// send a request to iocation, will get allow or deny
            /// </summary>
            IovationDeny,

            /// <summary>
            /// Rofus Registration status
            /// </summary>
            RofusRegistrationFailed,
            RofusRegisteredIndefinitely,
            RofusRegisteredTemporarily,
            NemIDNotProvided,


            RequiresSecondFactor,
            RequiresSecondFactor_FirstTime,
            SecondFactorAuthFailed,

            NotMatchDevice,
        }

        protected virtual void LogFailedLogin(cmUser user, NoteType type, string message)
        {
        }
        public static bool SafeParseBoolString(string text, bool defValue)
        {
            if (string.IsNullOrWhiteSpace(text))
                return defValue;

            text = text.Trim();

            if (Regex.IsMatch(text, @"(YES)|(ON)|(OK)|(TRUE)|(\1)", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant | RegexOptions.Compiled))
                return true;

            if (Regex.IsMatch(text, @"(NO)|(OFF)|(FALSE)|(\0)", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant | RegexOptions.Compiled))
                return false;

            return defValue;
        }
        /// <summary>
        /// Login the user and create the session
        /// </summary>
        /// <param name="cp">cp</param>
        /// <param name="site">site</param>
        /// <param name="CPR">CPR</param>
        /// <param name="loginMode">loginMode</param> 
        /// <returns>LoginResult</returns>
        public LoginResult LoginVIADK(CustomProfile cp,cmSite site, string CPR, LoginMode loginMode = LoginMode.Default)
        {
            string dkTempAccountRole = CM.Content.Metadata.Get("Metadata/Settings/DKLicense.TemporaryAccountRoleName").DefaultIfNullOrEmpty("Unverified Identity");
            string dkTempAccountExpireMsg = CM.Content.Metadata.Get("Metadata/ServerResponse.Login_Blocked_AccountExpire").DefaultIfNullOrEmpty("Your account is blocked!");
            bool isDKTempAccountEnbaled =  SafeParseBoolString(CM.Content.Metadata.Get("Metadata/Settings/DKLicense.EnabledTemporaryAccount").DefaultIfNullOrEmpty("no"), false);
            int dkTempAccountExpireDays = 30; 
            int.TryParse(CM.Content.Metadata.Get("Metadata/Settings/DKLicense.TemporaryAccountMaximumDays").DefaultIfNullOrEmpty("30"), out dkTempAccountExpireDays);

            if (string.IsNullOrWhiteSpace(CPR))
                return LoginResult.NoMatch; 

            using (DbManager dbManager = new DbManager())
            {
                UserAccessor ua = DataAccessor.CreateInstance<UserAccessor>(dbManager);
                cmUser user = null;
                using (CodeProfiler.Step(1, "Login - GetByUsernameOrEmail"))
                {
                    user = ua.GetByPersonalID(site.DomainID, CPR);
                }

                if (user == null)
                    return LoginResult.NoMatch;

                // if the user is not exported, export again now
                if (!user.IsExported)
                {
                    this.ExportUser(user.ID, user.Currency);
                }

                // if the user is blocked
                if (user.RecentLockTime.HasValue && (DateTime.Now - user.RecentLockTime.Value).TotalMinutes < 15)
                {
                    LogFailedLogin(user, NoteType.User, "Login is failed because there were too many failed attempts.");
                    return LoginResult.TooManyInvalidAttempts;
                }

                // blocked
                if (user.IsBlocked)
                {
                    LogFailedLogin(user, NoteType.User, "Login is failed because user is blocked.");
                    return LoginResult.Blocked;
                }

                if (isDKTempAccountEnbaled && cp.IsInRole(dkTempAccountRole) && DateTime.Now > cp.JoinTime.AddDays(dkTempAccountExpireDays))
                {
                    LogFailedLogin(user, NoteType.User, dkTempAccountExpireMsg);
                    return LoginResult.Blocked;
                }

                // country blocked
                if (this.IsCountryBlocked(user.CountryID)
                    || this.IsCountryBlocked(cp.IpCountryID))
                {
                    LogFailedLogin(user, NoteType.User, "Login is failed as IP country is blocked.");
                    return LoginResult.CountryBlocked;
                }

                string ip = null;
                if (HttpContext.Current != null && HttpContext.Current.Request != null)
                    ip = HttpContext.Current.Request.GetRealUserAddress();
                this.Initialize(user.Username, true);
                
                // create session in db
                this.CreateSession(site, user);
                this.OnLoginCompleted(user, this.SessionID, ip);

                return LoginResult.Success;
            }
        }

        /// <summary>
        /// Login the user and create the session
        /// </summary>
        /// <param name="username">username</param>
        /// <param name="password">password</param>
        /// <param name="securityToken">securityToken</param>
        /// <returns>LoginResult</returns>
        public LoginResult Login(string username, string password, string securityToken, LoginMode loginMode = LoginMode.Default)
        {
            cmUser outUser;
            SecondFactorAuthSetupCode outSecondFactorAuthSetupCode = null;
            string phoneNumber = string.Empty;
            return Login(username, password, securityToken, null, null, SecondFactorAuthType.None, loginMode, true, out outUser, out outSecondFactorAuthSetupCode, out phoneNumber);
        }            

        public LoginResult Login(string username, string password, string securityToken, string captcha, string secondFactorAuthCode, SecondFactorAuthType secondFactorAuthType, bool isSystem, out cmUser outUser, out SecondFactorAuthSetupCode outSecondFactorAuthSetupCode, out string phoneNumber)
        {
            return Login(username, password, securityToken, captcha, secondFactorAuthCode, secondFactorAuthType, LoginMode.Default, isSystem, out outUser, out outSecondFactorAuthSetupCode, out phoneNumber);
        }
        /// <summary>
        /// Login the user and create the session
        /// </summary>
        /// <param name="username">username</param>
        /// <param name="password">password</param>
        /// <param name="securityToken">securityToken</param>
        /// <param name="captcha">captcha</param>
        /// <param name="secondFactorAuthCode">secondFactorAuthCode</param>
        /// <param name="secondFactorAuthType">secondFactorAuthType</param>
        /// <param name="loginMode">userIDForOut</param>
        /// <param name="isSystem">isSystem</param>
        /// <param name="outUser">outUser</param>
        /// <param name="outSecondFactorAuthSetupCode">outSecondFactorAuthSetupCode</param>
        /// <returns>LoginResult</returns>
        public LoginResult Login(
            string username, 
            string password, 
            string securityToken, 
            string captcha, 
            string secondFactorAuthCode, 
            SecondFactorAuthType secondFactorAuthType,
            LoginMode loginMode, 
            bool isSystem, 
            out cmUser outUser,
            out SecondFactorAuthSetupCode outSecondFactorAuthSetupCode,
            out string phoneNumber)
        {
            outUser = null;
            outSecondFactorAuthSetupCode = null;
            phoneNumber = string.Empty;

            if (loginMode != LoginMode.ExternalLogin)
            {
                if (string.IsNullOrWhiteSpace(username) || string.IsNullOrWhiteSpace(password))
                    return LoginResult.NoMatch;                
            }
            else
            {
                if (string.IsNullOrWhiteSpace(username))
                    return LoginResult.NoMatch;
            }

            using (DbManager dbManager = new DbManager())
            {
                UserAccessor ua = DataAccessor.CreateInstance<UserAccessor>(dbManager);

                cmSite site = null;
                if (!string.IsNullOrWhiteSpace(securityToken))
                {
                    SiteAccessor da = DataAccessor.CreateInstance<SiteAccessor>(dbManager);
                    site = da.GetBySecurityToken(securityToken);
                    if (site == null)
                    {
                        return LoginResult.NoMatch;
                    }
                }
                else
                    site = SiteManager.Current;

                // find the user by username
                cmUser user = GetUser(username, site.DomainID, ua);

                if (user == null)
                    return LoginResult.NoMatch;

                outUser = user;

                // check if captcha is required for login
                if (user.Type == 0 && (IsCaptchaEnabledForLogin && user.FailedLoginAttempts >= _failedLogin_RequiresCaptcha_Attempts))
                {
                    if (string.IsNullOrWhiteSpace(captcha))
                        return LoginResult.RequiresCaptcha;

                    string captchaToCompare = this.Get("captcha");
                    this.Set("captcha", null);

                    if (!string.Equals(captcha.Trim(), captchaToCompare, StringComparison.InvariantCultureIgnoreCase))
                        return LoginResult.CaptchaNotMatch;
                }

                string passwordHash = null, storedPassword = user.Password;
                if (loginMode != LoginMode.ExternalLogin)
                {
                    passwordHash = PasswordHelper.CreateEncryptedPassword(user.PasswordEncMode/*site.PasswordEncryptionMode*/, password);
                }
                //if (loginMode == LoginMode.Default)
                //{
                //storedPassword = user.Password;
                //passwordHash = PasswordHelper.CreateEncryptedPassword(site.PasswordEncryptionMode, password);
                //}
                //else if (loginMode == LoginMode.CardDeck)
                //{
                //    storedPassword = user.AlternatePassword;
                //    passwordHash = PasswordHelper.DoubleEncryptPassword(password);
                //}                

                // if the user is not exported, export again now
                if (!user.IsExported)
                {
                    this.ExportUser(user.ID, user.Currency);
                }

                // if password is empty
                if (string.IsNullOrWhiteSpace(storedPassword))
                    return LoginResult.NoPassword;

                // if the user is blocked
                if (user.RecentLockTime.HasValue && (DateTime.Now - user.RecentLockTime.Value).TotalMinutes < 15)
                {
                    LogFailedLogin(user, NoteType.User, "Login is failed because there were too many failed attempts.");
                    return LoginResult.TooManyInvalidAttempts;
                }


                // if password is invalid
                if (loginMode != LoginMode.ExternalLogin)
                {
                    bool isValidated = true;
                    LoginResult tempResult = LoginResult.Undefined;

                    // verify password
                    if (!string.Equals(passwordHash, storedPassword, StringComparison.InvariantCultureIgnoreCase))
                    {
                        isValidated = false;
                        LogFailedLogin(user, NoteType.User, "Login is failed because of incorrect password.");
                    }
                    // second factor authentication
                    else if (IsSecondFactorAuthenticationEnabled)
                    {
                        bool skipSecondFactorAuth = SecondFactorAuthenticator.IsTrustedDevice() & user.IsSecondFactorVerified;

                        if (!skipSecondFactorAuth)
                        {
                            if (secondFactorAuthType == SecondFactorAuthType.NormalLogin)
                            {
                                if (user.SecondFactorType != secondFactorAuthType)
                                    ua.SetSecondFactorType(user.ID, (int)secondFactorAuthType);
                            }
                            else if (string.IsNullOrWhiteSpace(secondFactorAuthCode))
                            {
                                isValidated = false;
                                if (user.SecondFactorType == SecondFactorAuthType.None)
                                {
                                    tempResult = LoginResult.RequiresSecondFactor_FirstTime;
                                    outSecondFactorAuthSetupCode = SecondFactorAuthenticator.GenerateSetupCode(site, user, secondFactorAuthType);
                                    user.SecondFactorType = secondFactorAuthType;
                                    ua.SetSecondFactorType(user.ID, (int)secondFactorAuthType);
                                }
                                else
                                {
                                    tempResult = LoginResult.RequiresSecondFactor;
                                }
                            }
                            else
                            {
                                bool validAuthCode = false;
                                if (user.SecondFactorType == SecondFactorAuthType.GeneralAuthCode)
                                {
                                    List<string> newCodes;
                                    validAuthCode = SecondFactorAuthenticator.VerifyBackupCode(user, secondFactorAuthCode, out newCodes);
                                    if (validAuthCode && newCodes != null && newCodes.Count > 0)
                                    {
                                        // send Email
                                        this.SendSecondFactorBackupCodeEmail(user, newCodes);
                                    }
                                }
                                else
                                    validAuthCode = SecondFactorAuthenticator.ValidateAuthCode(user, secondFactorAuthCode);                                

                                if (!validAuthCode)
                                {
                                    isValidated = false;
                                    LogFailedLogin(user, NoteType.User, "Login is failed because of second factor authentication failed.");
                                    tempResult = LoginResult.SecondFactorAuthFailed;
                                }
                            }
                        }
                    }
                    if (!isValidated)
                    {
                        if (tempResult == LoginResult.Undefined || tempResult == LoginResult.SecondFactorAuthFailed)
                        {
                            LoginResult lr = IncreaseFailedLoginAttempts(outUser, ua);
                            if (lr != LoginResult.Undefined)
                            {
                                return lr;
                            }
                        }

                        if (tempResult != LoginResult.Undefined)
                            return tempResult;

                        return LoginResult.NoMatch;
                    }
                }                

                // blocked
                if (user.IsBlocked)
                {

                    LogFailedLogin(user, NoteType.User, "Login is failed because user is blocked.");
                    return LoginResult.Blocked;
                }

                // country blocked
                if (this.IsCountryBlocked(user.CountryID)
                    || this.IsCountryBlocked(CustomProfile.Current.IpCountryID))
                {
                    LogFailedLogin(user, NoteType.User, "Login is failed as IP country is blocked.");
                    return LoginResult.CountryBlocked;
                }

                // verify the email verification
                if (!user.IsEmailVerified && (DateTime.Now - user.Ins).TotalDays > this.NumberOfDaysForLoginWithoutEmailVerification)
                {
                    LogFailedLogin(user, NoteType.User, "Login is failed as email is not verified.");
                    return LoginResult.EmailNotVerified;
                }

                if (IsSecondStepsAuthenticationEnabled)
                {
                    HttpCookie cookie = HttpContext.Current.Request.Cookies[string.Format("_hvp_{0}", user.ID)];
                    if (cookie != null && cookie.Value.ToLowerInvariant() == "true")
                    {
                        cookie.Value = "false";
                        if (!string.IsNullOrWhiteSpace(SiteManager.Current.SessionCookieDomain))
                            cookie.Domain = SiteManager.Current.SessionCookieDomain;
                        cookie.Expires = DateTime.Now.AddDays(-1);
                        HttpContext.Current.Response.Cookies.Add(cookie);
                    } 
                    else
                    {
                        SessionAccessor sa = DataAccessor.CreateInstance<SessionAccessor>(dbManager);
                        cmSession session = sa.GetLatestSessionByUserID(user.ID);
                        /*if (session != null && !(session.Browser.Equals(HttpContext.Current.Request.UserAgent, StringComparison.InvariantCultureIgnoreCase) || session.IP.Equals(HttpContext.Current.Request.GetRealUserAddress(), StringComparison.InvariantCultureIgnoreCase)))*/
                        if (session != null && !session.IP.Equals(HttpContext.Current.Request.GetRealUserAddress(), StringComparison.InvariantCultureIgnoreCase))
                        {
                            phoneNumber = user.Mobile.Replace(user.Mobile.Substring(0, user.Mobile.Length - 2), "********");
                            return LoginResult.NotMatchDevice;
                        }
                    }
                }

                if (!isSystem) { 
                    try
                    {
                        if((CM.Content.Metadata.Get("Metadata/Settings.Password_GlobalExpiry_Enabled").ParseToBool(false)))
                        {
                            if (!string.IsNullOrWhiteSpace(CM.Content.Metadata.Get("Metadata/Settings.Password_GlobalExpiryTime")))
                            {
                                DateTime globalExpiryTime = Convert.ToDateTime(CM.Content.Metadata.Get("Metadata/Settings.Password_GlobalExpiryTime"));
                            
                                if (globalExpiryTime > (user.LastPasswordModified ?? user.Ins) && globalExpiryTime < DateTime.Now)
                                {
                                    LogFailedLogin(user, NoteType.User, "Login is failed as Password has to be changed.");
                                    return LoginResult.NeedChangePassword;
                                }
                            }
                        }
                    }
                    catch (Exception ex)
                    {
                        Logger.Exception(ex);
                    }
                }

                string ip = null;
                if (HttpContext.Current != null && HttpContext.Current.Request != null)
                    ip = HttpContext.Current.Request.GetRealUserAddress();
                this.Initialize(user.Username, true);

                // create session in db
                this.CreateSession(site, user);



                //SaveCurrentUserSession(this.UserID, this.SessionID);



                this.OnLoginCompleted(user, this.SessionID, ip);

                return LoginResult.Success;
            }
        }

        /// <summary>
        /// get user via username, email or personalID
        /// </summary>
        /// <param name="username">username</param>
        /// <param name="password">password</param>
        /// <param name="outUser">outUser</param>
        /// <returns>cmUser</returns>
        public cmUser GetUser(string username, int domainId, UserAccessor ua)
        {
            using (DbManager dbManager = new DbManager())
            {
                ua = ua == null ? DataAccessor.CreateInstance<UserAccessor>(dbManager) : ua;
                // find the user by username
                cmUser user = null;
                using (CodeProfiler.Step(1, "Login - GetByUsernameOrEmail"))
                {
                    user = ua.GetByUsernameOrEmail(domainId, username, username);
                }
                if (user == null && (CM.Content.Metadata.Get("Metadata/Settings.EnableLoginViaPersonalID").ParseToBool(false)))
                {
                    user = ua.GetByPersonalID(domainId, username);
                }
                
                return user;
            }
        }

        public LoginResult IncreaseFailedLoginAttempts(cmUser user, UserAccessor ua)
        {
            using (DbManager dbManager = new DbManager())
            {
                // too many failed attempts
                bool isBlocked = false;
                int failedLoginAttempts = 0;
                using (CodeProfiler.Step(1, "Login - IncreaseFailedLoginAttempts"))
                {
                    failedLoginAttempts = ua.IncreaseFailedLoginAttempts(user.ID, DateTime.Now, FailedLoginAttempts_LockUser);
                    isBlocked = (failedLoginAttempts >= FailedLoginAttempts_LockUser);
                }
                if (IsCaptchaEnabledForLogin & failedLoginAttempts >= _failedLogin_RequiresCaptcha_Attempts)
                {
                    return LoginResult.NoMatch_RequiresCaptcha;
                }
                if (user.Type == 0 && isBlocked)
                {
                    if (!user.IsBlocked)
                    {
                        this.SendNotificationEmail(user);
                    }
                    return LoginResult.TooManyInvalidAttempts;
                }
                return LoginResult.Undefined;
            }
        }
        /// <summary>
        /// verify if username and password is correct
        /// </summary>
        /// <param name="username">username</param>
        /// <param name="password">password</param>
        /// <param name="outUser">outUser</param>
        /// <returns>LoginResult</returns>
        public LoginResult VerifyUserPassword(string username, string password, out cmUser outUser)
        {
            outUser = null;
            if (string.IsNullOrWhiteSpace(username) || string.IsNullOrWhiteSpace(password))
                return LoginResult.NoMatch;
            using (DbManager dbManager = new DbManager())
            {
                UserAccessor ua = DataAccessor.CreateInstance<UserAccessor>(dbManager);
                // find the user by username
                outUser = GetUser(username, SiteManager.Current.DomainID, ua);
                
                if (outUser == null)
                    return LoginResult.NoMatch;
                // if the user is blocked
                if (outUser.RecentLockTime.HasValue && (DateTime.Now - outUser.RecentLockTime.Value).TotalMinutes < 15)
                {
                    LogFailedLogin(outUser, NoteType.User, "Login is failed because there were too many failed attempts.");
                    return LoginResult.TooManyInvalidAttempts;
                }
                string passwordHash = null, storedPassword = outUser.Password;
                passwordHash = PasswordHelper.CreateEncryptedPassword(SiteManager.Current.PasswordEncryptionMode, password);

                if (!string.Equals(passwordHash, storedPassword, StringComparison.InvariantCultureIgnoreCase))
                {
                    LoginResult lr = IncreaseFailedLoginAttempts(outUser, ua);
                    if(lr != LoginResult.Undefined)
                    {
                        return lr;
                    }
                    return LoginResult.NoMatch;
                }
                
                return LoginResult.Success;
            }
        }

        /// <summary>
        /// External login for 3rd-party
        /// </summary>
        /// <param name="site">site</param>
        /// <param name="userID">user id</param>
        /// <param name="ip">ip</param>
        /// <returns>LoginResult</returns>
        public LoginResult ExternalLogin(cmSite site, long userID, string ip)
        {
            using (DbManager dbManager = new DbManager())
            {
                UserAccessor ua = DataAccessor.CreateInstance<UserAccessor>(dbManager);

                // find the user by username
                cmUser user = null;
                using (CodeProfiler.Step(1, "ExternalLogin - Get User by ID"))
                {
                    user = ua.GetByID(userID);
                }
                if (user == null)
                    return LoginResult.NoMatch;

                // if the user is not exported, export again now
                if (!user.IsExported)
                {
                    this.ExportUser(user.ID, user.Currency);
                }

                // blocked
                if (user.IsBlocked)
                    return LoginResult.Blocked;

                // country blocked
                if (this.IsCountryBlocked(user.CountryID))
                    return LoginResult.CountryBlocked;

                // verify the email verification
                if (!user.IsEmailVerified && (DateTime.Now - user.Ins).TotalDays > 7)
                    return LoginResult.EmailNotVerified;


                this.Initialize(user.Username, true);



                using (CodeProfiler.Step(1, "ExternalLogin - insert session table"))
                {
                    SessionPayload sessionPayload = new SessionPayload()
                    {
                        UserID = userID,
                        DomainID = site.DomainID,
                        IP = ip,
                        UserAgent = HttpContext.Current.Request.UserAgent,
                        IsExternal = true,
                        MaxIdleSeconds = site.SessionTimeoutSeconds,
                    };

                    _agentClient.CreateSession(sessionPayload, true, true);
                }

                //SaveCurrentUserSession(this.UserID, this.SessionID);

                this.OnLoginCompleted(user, this.SessionID, ip);

                return LoginResult.Success;
            }
        }

        /// <summary>
        /// Logoff current profile
        /// </summary>
        public void Logoff()
        {
            Logoff(SessionExitReason.LoggedOff);
        }
        
        /// <summary>
        /// Logoff current profile
        /// </summary>
        /// <param name="exitReason">session exit reason</param>
        public void Logoff(SessionExitReason exitReason)
        {
            if (this.IsAuthenticated)
            {
                this.OnLogoffCompleted(this.UserID, this.SessionID, exitReason);

                //RedisSession.Remove(SessionID);

                cmSite site = SiteManager.Current;
                if (site != null)
                {
                    _sessionPayload.IsAuthenticated = false;
                    _sessionPayload.ExitReason = SessionExitReason.LoggedOff;
                    _sessionPayload = _agentClient.UpdateSession(_sessionPayload);
                    _sessionPayload = new SessionPayload()
                    {
                        Guid = "Anonymous" + Guid.NewGuid().ToString(),
                        Roles = new string[] { "Anonymous" },
                        DomainID = site.DomainID,
                    };

                    HttpCookie cookie = new HttpCookie(site.SessionCookieName, _sessionPayload.Guid);
                    if (!string.IsNullOrWhiteSpace(site.SessionCookieDomain))
                        cookie.Domain = site.SessionCookieDomain.Trim();
                    cookie.HttpOnly = true;
                    cookie.Secure = SafeParseBoolString(CM.Content.Metadata.Get("Metadata/Settings.EnableSecureCookie").DefaultIfNullOrEmpty("no"), false);
                    HttpContext.Current.Response.Cookies.Remove(site.SessionCookieName);
                    HttpContext.Current.Response.Cookies.Add(cookie);
                }
            }
        }

        /// <summary>
        /// Get role string bu user
        /// </summary>
        /// <param name="site"></param>
        /// <param name="userID">User ID</param>
        /// <returns></returns>
        protected virtual string GetRoleStringByUser(cmSite site, long userID)
        {
            return string.Empty;
        }



        /// <summary>
        /// Export the user to GmCore
        /// </summary>
        /// <param name="userID">userid</param>
        /// <param name="currency">currency</param>
        /// <returns>indicate if it is success</returns>
        protected virtual bool ExportUser(long userID, string currency)
        {
            return false;
        }


        /// <summary>
        /// Determine if the country blocked
        /// </summary>
        /// <param name="countryID">Country ID</param>
        /// <returns>true if this is blocked country</returns>
        protected virtual bool IsCountryBlocked(int countryID)
        {
            return false;
        }

        /// <summary>
        /// Send notification email to user
        /// </summary>
        /// <param name="user"></param>
        protected virtual void SendNotificationEmail(cmUser user)
        {
        }

        protected virtual void OnLoginCompleted(cmUser user, string sessionID, string ip)
        {
        }

        protected virtual void OnLogoffCompleted(long userID, string sessionID, SessionExitReason exitReason)
        {
        }

        protected virtual void UpdateLastAccessTime(string sessionID)
        {
        }

        protected virtual void SendSecondFactorBackupCodeEmail(cmUser user, List<string> backupCodes)
        {
        }
        /// <summary>
        /// Create session
        /// </summary>
        /// <param name="site">site</param>
        /// <param name="user">user</param>
        /// <param name="ip">ip address</param>
        private void CreateSession(cmSite site, cmUser user, string ip=null)
        {
            if (string.IsNullOrEmpty(ip))
                ip = HttpContext.Current.Request.GetRealUserAddress();



            _sessionPayload = new SessionPayload()
            {
                UserID = user.ID,
                IP = ip,
                //Roles = this.RoleString
                DomainID = site.DomainID,
                UserAgent = HttpContext.Current.Request.UserAgent,
                MaxIdleSeconds = site.SessionTimeoutSeconds,
            };

            string roleString = this.GetRoleStringByUser(site, user.ID);
            if (roleString != null)
                _sessionPayload.Roles = roleString.Split(',');
            else
                _sessionPayload.Roles = new string[0];
            
            CreateSessionResponse response = _agentClient.CreateSession(_sessionPayload, true, true);
            _sessionPayload = response.Session;

            /*
            using (CodeProfiler.Step(1, "CreateSession - insert session table"))
            {
                cmSession session = new cmSession()
                {
                    Guid = this.SessionID,
                    UserID = this.UserID,
                    IP = ip,
                    RoleString = this.RoleString,
                    DomainID = site.DomainID,
                    TimeZoneAddMinutes = 0,
                    Culture = HttpContext.Current.GetLanguage(),
                    Browser = HttpContext.Current.Request.UserAgent,
                    AffiliateMarker = this.AffiliateMarker,
                    IsAuthenticated = true,
                    Login = DateTime.Now,
                    Logout = null,
                    IsExpired = false,
                    CountryID = this.IpCountryID,
                    LocationID = 0,
                    Latitude = 0.0f,
                    Longitude = 0.0f,
                    UserLanguages = HttpContext.Current.Request.UserLanguages.ConvertToCommaSplitedString(),
                    LastAccess = DateTime.Now,
                    CookiesSupported = true,
                    IsExternal = false,
                    Ins = DateTime.Now,
                    SessionLimitSeconds = user.SessionLimitSeconds,
                };
                SessionAccessor.CreateSession(session);
            }
            */

            HttpCookie cookie = new HttpCookie(site.SessionCookieName, SessionID);

            if (!string.IsNullOrWhiteSpace(site.SessionCookieDomain))
                cookie.Domain = site.SessionCookieDomain.Trim();

            cookie.HttpOnly = true;
            cookie.Secure = SafeParseBoolString(CM.Content.Metadata.Get("Metadata/Settings.EnableSecureCookie").DefaultIfNullOrEmpty("no"), false);
            HttpContext.Current.Response.Cookies.Remove(site.SessionCookieName);
            HttpContext.Current.Response.Cookies.Add(cookie);
        }        

        /*
        /// <summary>
        /// Update memcached server
        /// </summary>
        public void SyncToMemorycahced()
        {
            if (HttpContext.Current != null &&
                HttpContext.Current.Request != null &&
                this.IsAuthenticated &&
                this.LastSyncTime > DateTime.MinValue )
            {
                if ((DateTime.Now - this.LastSyncTime).TotalMinutes >= 4)
                {
                    this.LastSyncTime = DateTime.Now;
                    this.UpdateLastAccessTime(this.SessionID);
                }
            }

            this.LastAccess = DateTime.Now;
            _redisSession.Save();
        }//
         * */

        /// <summary>
        /// Save the UserID == SessionID
        /// </summary>
        public static void SaveCurrentUserSession(long userID, string sessionID)
        {
            //RedisSession.SaveUserSession(userID, sessionID);
        }

        /*
        public static string GetUserSessionID(long userID)
        {
            Task<string> task = RedisSession.GetUserSession(userID);
            task.Wait();
            string sessionID = task.Result;

            if (string.IsNullOrEmpty(sessionID))
            {
                SessionAccessor sa = SessionAccessor.CreateInstance<SessionAccessor>();
                sessionID = sa.GetByUserID(userID);

                if (!string.IsNullOrEmpty(sessionID))
                {
                    SaveCurrentUserSession(userID, sessionID);
                }
            }

            return sessionID;
        }
        */

        protected virtual void UpdateRoleStringAsync(string guid, string roleString)
        {
        }

        [SettingsAllowAnonymous(true)]
        public string Passport
        {
            get
            {
                if (HttpRuntime.Cache["Passport"] != null)
                    return HttpRuntime.Cache["Passport"].ToString();
                return string.Empty;
            }
            set
            {
                HttpRuntime.Cache["Passport"] = value;
            }
        }
    }
}
