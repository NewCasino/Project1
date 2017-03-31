using System;
using System.Collections.Generic;
using System.Configuration;
using System.Linq;
using System.Web.Mvc;
using BLToolkit.Data;
using BLToolkit.DataAccess;
using CM.Content;
using CM.db;
using CM.db.Accessor;
using CM.Sites;
using CM.State;
using CM.Web;
using GamMatrixAPI;
using GmCore;

namespace GamMatrix.CMS.Controllers.System
{

    [HandleError]
    [ControllerExtraInfo(DefaultAction = "Index")]
    [SystemAuthorize(Roles = "CMS System Admin")]
    public class OperatorMgtController : ControllerEx
    {
        [HttpGet]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public ActionResult Index()
        {
            try
            {
                return View("Index");
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                throw;
            }
        }

        [HttpGet]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public JsonResult GetOperators()
        {
            try
            {
                using (GamMatrixClient client = GamMatrixClient.Get())
                {
                    UserProfileData userProfile = LoginAsSuperUser();

                    // get all domains
                    GetDomainListRequest getDomainListRequest = client.SingleRequest<GetDomainListRequest>(new GetDomainListRequest()
                    {
                        SESSION_ID = userProfile.SessionID,
                        SESSION_USERID = userProfile.UserRec.ID,
                    });


                    var sites = SiteManager.GetSites();
                    return this.Json(new
                    {
                        success = true,
                        operators = sites.Select(o => new
                        {
                            ID = o.ID
                            ,
                            DistinctName = o.DistinctName
                            ,
                            SecurityToken = o.SecurityToken
                            ,
                            ApiUsername = o.ApiUsername
                            ,
                            DefaultCulture = o.DefaultCulture
                            ,
                            DefaultTheme = o.DefaultTheme
                            ,
                            EmailHost = o.EmailHost
                            ,
                            TemplateDomainDistinctName = o.TemplateDomainDistinctName
                            ,
                            PasswordEncryptionMode = o.PasswordEncryptionMode
                            ,
                            SessionCookieName = o.SessionCookieName
                            ,
                            SessionCookieDomain = o.SessionCookieDomainInDatabase
                            ,
                            SessionTimeoutSeconds = o.SessionTimeoutSeconds
                            ,
                            SessionID = GamMatrixClient.GetSessionID(o, false)
                            ,
                            HttpPort = o.HttpPort
                            ,
                            HttpsPort = o.HttpsPort
                            ,
                            UseRemoteStylesheet = o.UseRemoteStylesheet
                            ,
                            StaticFileServerDomainName = o.StaticFileServerDomainName
                            ,
                            ChangeHistoryUrl = Url.RouteUrl("HistoryViewer", new
                            {
                                @action = "Dialog",
                                @distinctName = o.DistinctName.DefaultEncrypt(),
                                @relativePath = string.Format("/.config/operator/{0}.setting", o.DistinctName).DefaultEncrypt(),
                                @searchPattner = "",
                            }).SafeHtmlEncode()
                        }).ToArray()
                    }
                    , JsonRequestBehavior.AllowGet);

                }
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false, @error = ex.Message }, JsonRequestBehavior.AllowGet); 
            }
        }

        private UserProfileData LoginAsSuperUser()
        {
            using (GamMatrixClient client = GamMatrixClient.Get() )
            {
                // login with super user
                var loginResponse = client.Login(new LoginRequest()
                {
                    UserName = ConfigurationManager.AppSettings["GmCore.SuperAdminLogin"].DefaultIfNullOrEmpty("a"),
                    PlainTextPassword = ConfigurationManager.AppSettings["GmCore.SuperAdminPwd"].DefaultIfNullOrEmpty("a"),
                    SecurityToken = ConfigurationManager.AppSettings["GmCore.SuperAdminSecToken"].DefaultIfNullOrEmpty("sys"),
                    Type = SessionType.System,
                });

                if (!loginResponse.Success)
                    throw new Exception(loginResponse.ErrorSysMessage);

                return ((LoginRequest)loginResponse.Reply).UserProfile;
            }
        }

        [HttpPost]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public JsonResult Save(int id
            , PasswordEncryptionMode passwordEncryptionMode
            , string templateDomainDistinctName
            , string defaultTheme
            , string defaultCulture
            , string emailHost
            , string sessionCookieName
            , string sessionCookieDomain
            , string staticFileServerDomainName
            , int? sessionTimeoutSeconds
            , int? httpPort
            , int? httpsPort
            , bool? useRemoteStylesheet            
            )
        {
            SiteAccessor da = DataAccessor.CreateInstance<SiteAccessor>();
            cmSite site = da.GetBySiteID(id);
            if (site == null)
                throw new Exception("Invalid parameter [id].");

            string relativePath = string.Format("/.config/operator/{0}.setting", site.DistinctName);
            string name = site.DistinctName;
            Revisions.BackupIfNotExists<cmSite>(site, site, relativePath, name);

            // update the domain configration
            SqlQuery<cmSite> query = new SqlQuery<cmSite>();
            site.DefaultCulture = defaultCulture.DefaultIfNullOrEmpty("en");
            site.DefaultTheme = defaultTheme;
            site.TemplateDomainDistinctName = templateDomainDistinctName;
            site.HttpPort = (httpPort.HasValue && httpPort.Value > 0) ? httpPort.Value : 80;
            site.HttpsPort = (httpsPort.HasValue && httpsPort.Value > 0) ? httpsPort.Value : 0;
            site.SessionTimeoutSeconds = (sessionTimeoutSeconds.HasValue && sessionTimeoutSeconds.Value > 0) ? sessionTimeoutSeconds.Value : 0;
            site.UseRemoteStylesheet = useRemoteStylesheet.HasValue && useRemoteStylesheet.Value;
            site.StaticFileServerDomainName = staticFileServerDomainName; 
            query.Update(site);

            da.UpdateDomain(site.DomainID
                , sessionCookieName
                , sessionCookieDomain.ToLowerInvariant()
                , emailHost
                , (int)passwordEncryptionMode
                );

            site = da.GetBySiteID(id);
            Revisions.Backup<cmSite>(site, site, relativePath, name);

            site.ReloadCache(Request.RequestContext, CacheManager.CacheType.DomainCache);

            return this.Json(new { success = true  });
        }

        [HttpPost]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public JsonResult CreateSite( bool isNewOperator
            , string title
            , string distinctName
            , string apiUsername
            , string securityToken
            , string hostname
            , int? existingDomainID            
            )
        {
            try
            {
                if (isNewOperator)
                {
                    using (DbManager dbManager = new DbManager())
                    {
                        using (GamMatrixClient client = GamMatrixClient.Get())
                        {
                            UserProfileData userProfile = LoginAsSuperUser();

                            // begin the transaction
                            dbManager.BeginTransaction();
                            try
                            {
                                SiteAccessor da = DataAccessor.CreateInstance<SiteAccessor>(dbManager);
                                int domainID = da.CreateDomain(title, distinctName, apiUsername, securityToken, CustomProfile.Current.UserID);

                                cmSite site = new cmSite()
                                {
                                    DistinctName = distinctName,
                                    DisplayName = title,
                                    DomainID = domainID,
                                    DefaultUrl = "/Home",
                                    DefaultCulture = "en",
                                };
                                SqlQuery<cmSite> query = new SqlQuery<cmSite>(dbManager);
                                query.Insert(site);

                                List<HandlerRequest> requests = new List<HandlerRequest>();

                                // create the domain in GmCore
                                requests.Add(new RegisterDomainRequest()
                                {
                                    SESSION_ID = userProfile.SessionID,
                                    SESSION_USERID = userProfile.UserRec.ID,
                                    Record = new DomainRec()
                                    {
                                        Name = title,
                                        Description = "No description",
                                        Type = DomainType.Ordinary,
                                        ActiveStatus = ActiveStatus.Active,
                                        DomainID = domainID,
                                        SecurityToken = securityToken,
                                        Hostname = hostname,
                                    }
                                });

                                // switch to the new domain
                                requests.Add(new SwitchDomainRequest()
                                {
                                    SESSION_ID = userProfile.SessionID,
                                    SESSION_USERID = userProfile.UserRec.ID,
                                    DomainID = domainID
                                });

                                // register the API User
                                requests.Add(new RegisterUserRequest()
                                {
                                    SESSION_ID = userProfile.SessionID,
                                    SESSION_USERID = userProfile.UserRec.ID,
                                    Record = new UserRec()
                                    {
                                        DisplayName = "CMS System",
                                        Type = UserType.Ordinary,
                                        UserName = "_Api_Cms",
                                        Password = securityToken,
                                        ActiveStatus = ActiveStatus.Active,
                                        Email = "wj@gammatrix.com"
                                    },
                                    SkipValidation = true,
                                });

                                requests.Add(new RegisterUserRequest()
                                {
                                    SESSION_ID = userProfile.SessionID,
                                    SESSION_USERID = userProfile.UserRec.ID,
                                    Record = new UserRec()
                                    {
                                        DisplayName = "Casino Engine",
                                        Type = UserType.Ordinary,
                                        UserName = "_Api_CE",
                                        Password = securityToken,
                                        ActiveStatus = ActiveStatus.Active,
                                        Email = "wj@everymatrix.com"
                                    },
                                    SkipValidation = true,
                                });

                                client.MultiRequest<HandlerRequest>(requests);

                                dbManager.CommitTransaction();
                            }
                            catch
                            {
                                // commit even failed
                                dbManager.CommitTransaction();
                                //dbManager.RollbackTransaction();
                                throw;
                            }

                            try
                            {
                                // logoff the sesson 
                                client.SingleRequest<LogoutRequest>(new LogoutRequest()
                                {
                                    SESSION_ID = userProfile.SessionID,
                                    SESSION_USERID = userProfile.UserRec.ID,
                                });
                            }
                            catch
                            {
                            }
                        }
                    }
                }// if new operatior
                else if (existingDomainID.HasValue)
                {
                    cmSite site = new cmSite()
                    {
                        DistinctName = distinctName,
                        DisplayName = title,
                        DefaultUrl = "/Home",
                        DefaultCulture = "en",
                        DomainID = existingDomainID.Value
                    };
                    SqlQuery<cmSite> query = new SqlQuery<cmSite>();
                    query.Insert(site);
                }

                // reload the cache from db
                //DomainManager.ReloadConfigrarion(false);
                SiteManager.Current.ReloadCache(Request.RequestContext, CacheManager.CacheType.DomainCache);

                return this.Json(new { success = true });
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { success = false, @error = ex.Message });
            }
           
        }
    }



}
