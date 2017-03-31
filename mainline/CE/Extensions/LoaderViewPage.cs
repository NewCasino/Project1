using System;
using System.Collections.Generic;
using System.Configuration;
using System.Diagnostics.CodeAnalysis;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Mvc;
using BLToolkit.DataAccess;
using CE.db;
using CE.db.Accessor;
using CE.Integration.GmGaming.Models;
using CE.Integration.TransferMoneyBetweenWallets;
using CE.Integration.VendorApi;
using CE.Integration.VendorApi.Models;
using CE.Utils;
using EveryMatrix.SessionAgent.Protocol;
using GamMatrixAPI;
using GmGamingAPI;

namespace CE.Extensions
{
    /// <summary>
    /// Override System.Web.Mvc.dll ViewPage and ViewPage&lt;T&gt;
    /// </summary>
    public class LoaderViewPage : ViewPage
    {
        #region Properties
        private Dictionary<string, object> _startupParams = new Dictionary<string, object>();
        private List<string> _supportedLanguages = new List<string>(0);

        public VendorID VendorID { get; internal set; }
        public ceDomainConfigEx Domain { get; internal set; }
        public SessionPayload UserSession { get; internal set; }
        public bool FunMode { get; set; }
        public bool UseGmGaming { get; internal set; }
        public string GameID { get; internal set; }
        public long CasinoGameID { get; internal set; }
        public long CasinoBaseGameID { get; internal set; }
        public string GameCode { get; internal set; }
        public string Slug { get; internal set; }
        public string TableID { get; internal set; }
        public string Language { get; set; }
        public string LaunchUrl { get; set; }
        public bool EnableLogging { get; internal set; }


        public List<string> SupportedLanguages
        {
            get { return _supportedLanguages; }
            set { _supportedLanguages = value; }
        }
        public Dictionary<string, object> StartupParams
        {
            get { return _startupParams; }
            set { _startupParams = value; }
        }
        #endregion


        protected override void OnPreInit(EventArgs e)
        {
            InitLoader();
            base.OnPreInit(e);
            if (UserSession != null && !FunMode)
            {               
                CashTransporter cashTransporter = new CashTransporter(UserSession, Domain.DomainID, VendorID);
                string language = GetLanguage();
                cashTransporter.TransferMoney(language);
            }
        }      

        public void InitLoader()
        {
            try
            {
                this.VendorID = (VendorID)ViewData["VendorID"];
                this.Domain = ViewData["Domain"] as ceDomainConfigEx;
                this.UserSession = ViewData["UserSession"] as SessionPayload;
                this.FunMode = (ViewData["FunMode"] == null) || (bool)ViewData["FunMode"];
                this.UseGmGaming = (bool)ViewData["UseGmGaming"];
                this.EnableLogging = (bool)ViewData["EnableLogging"];
                this.GameID = ViewData["GameID"] as string;
                this.GameCode = ViewData["GameCode"] as string;
                this.Slug = ViewData["Slug"] as string;
                this.TableID = ViewData["TableID"] as string;
                this.CasinoGameID = (long)ViewData["CasinoGameID"];
                this.CasinoBaseGameID = (long)ViewData["CasinoBaseGameID"];

                if (this.Domain == null)
                {
                    throw new Exception("Invalid Domain");
                }

                if (!string.IsNullOrEmpty(Request["cashierurl"]))
                {
                    this.Domain.CashierUrl = Request["cashierurl"];
                    this.Domain.MobileCashierUrl = Request["cashierurl"];
                }

                if (!string.IsNullOrEmpty(Request["casinolobbyurl"]))
                {
                    this.Domain.LobbyUrl = Request["casinolobbyurl"];
                    this.Domain.MobileLobbyUrl = Request["casinolobbyurl"];
                }

                this.Language = GetLanguage();

                if (EnableLogging)
                {
                    var userState = (UserSession == null) ? "NULL" : UserSession.Username + " | " + UserSession.UserID + (FunMode ? " | FunMode" : "");
                    StartupParams.Add("VendorID", VendorID);
                    StartupParams.Add("DomainID", Domain.DomainID);
                    StartupParams.Add("UserSession", userState);
                    StartupParams.Add("FunMode", FunMode);
                    StartupParams.Add("Language", Language);
                    StartupParams.Add("UseGmGaming", UseGmGaming);
                    StartupParams.Add("GameID", GameID);
                    StartupParams.Add("GameCode", GameCode);
                    StartupParams.Add("Slug", Slug);
                    StartupParams.Add("CasinoGameID", CasinoGameID);
                    StartupParams.Add("CasinoBaseGameID", CasinoBaseGameID);
                    StartupParams.Add("TableID", TableID);
                    GmLogger.Instance.Trace(StartupParams, "GameStarted at {0}, {1} {2}, User:{3}", new[] { VendorID.ToString(), GameID, GameCode, userState });
                }
            }
            catch (Exception ex)
            {
                if (EnableLogging)
                    GmLogger.Instance.ErrorException(ex, StartupParams, "InitLoader Exception {0}, {1}", new[] { VendorID.ToString(), GameID });
                throw;
            }
        }

        public string GetLanguage()
        {
            string lang = this.ViewData["Language"] as string ?? "en";
            return GetLanguage(lang);
        }

        public virtual string GetLanguage(string lang)
        {
            if (string.IsNullOrWhiteSpace(lang))
                return "en";

            string isoLang = lang.Truncate(2).ToLowerInvariant();
            if (SupportedLanguages.Count == 0)
                return isoLang;

            if (SupportedLanguages.Contains(isoLang, StringComparer.OrdinalIgnoreCase))
                return isoLang;

            return "en";
        }

        public string InjectScriptCode(string url)
        {
            string scriptUrl = Domain.GetCfg(url);
            if (!string.IsNullOrWhiteSpace(scriptUrl))
            {
                return string.Format("<script language='javascript' type='text/javascript' src='{0}' ></{1}",
                    scriptUrl, "script>");
            }
            return "";
        }

        public TokenResponse GetToken(List<NameValue> additionalParameters = null)
        {
            using (GmGamingRestClient client = new GmGamingRestClient())
            {
                TokenRequest tokenRequest = new TokenRequest()
                {
                    DomainId = UserSession.DomainID,
                    UserID = UserSession.UserID,
                    VendorID = VendorID,
                    IsMobile = PlatformHandler.IsMobile,
                    GameCode = GameCode,
                    Slug = Slug,
                    GameId = GameID,
                    CasinoGameId = CasinoGameID,
                    CasinoBaseGameId = CasinoBaseGameID,
                    TableId = TableID
                };
                if (additionalParameters != null)
                    tokenRequest.AdditionalParameters = additionalParameters;

                if (UserSession != null)
                {
                    tokenRequest.PlayerSession = new PlayerSession
                    {
                        SessionId = UserSession.Guid,
                        UserName = UserSession.Username,
                        FirstName = UserSession.Firstname,
                        LastName = UserSession.Surname,
                        CountryCode = UserSession.UserCountryCode,
                        IpCountryCode = UserSession.IpCountryCode,
                        IpAddess = UserSession.IP,
                        Birthday = UserSession.BirthDate,
                        AffiliateMarker = UserSession.AffiliateMarker,
                        Language = Language,
                        BrowserAgent = UserSession.UserAgent
                    };
                }

                return client.GetToken(tokenRequest, EnableLogging);
            }
        }

        protected void LogGmClientRequest(string sessionId, string responseParam, string responseParamName = null)
        {
            if (EnableLogging)
                GmLogger.Instance.Trace("{0}GetSessionRequest at Domain:{1}, User:{2} | {3} | {4}, {6}:{5}", VendorID.ToString(), UserSession.DomainID, UserSession.Username, UserSession.UserID, sessionId, responseParam, responseParamName ?? "Token");
        }
        protected override void OnError(EventArgs e)
        {
            if (EnableLogging)
                GmLogger.Instance.ErrorException(Server.GetLastError(), StartupParams, "Error in Loader {0}, {1}", new[] { VendorID.ToString(), GameID });
            base.OnError(e);
        }
    }

    public class LoaderViewPage<TModel> : LoaderViewPage where TModel : class
    {
        private ViewDataDictionary<TModel> _viewData;

        public new TModel Model
        {
            get
            {
                return ViewData.Model;
            }
        }

        [SuppressMessage("Microsoft.Usage", "CA2227:CollectionPropertiesShouldBeReadOnly")]
        public new ViewDataDictionary<TModel> ViewData
        {
            get
            {
                if (_viewData == null)
                {
                    SetViewData(new ViewDataDictionary<TModel>());
                }
                return _viewData;
            }
            set
            {
                SetViewData(value);
            }
        }

        protected override void SetViewData(ViewDataDictionary viewData)
        {
            _viewData = new ViewDataDictionary<TModel>(viewData);

            base.SetViewData(_viewData);
        }
    }
}
