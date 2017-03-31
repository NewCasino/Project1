using System;
using System.Collections.Generic;
using System.Configuration;

using System.Linq;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;
using System.Web;
using System.Web.Caching;
using System.Web.Mvc;
using BLToolkit.Data;

using CE.db;
using CE.db.Accessor;
using CE.Extensions;
using CE.Models;
using CE.Utils;
using EveryMatrix.SessionAgent;
using EveryMatrix.SessionAgent.Protocol;
using GamMatrixAPI;
using System.Web.Routing;

namespace CasinoEngine.Controllers
{
    public class LoaderController : Controller
    {

        private static AgentClient _agentClient = new AgentClient(
            ConfigurationManager.AppSettings["SessionAgent.ZooKeeperConnectionString"],
            ConfigurationManager.AppSettings["SessionAgent.ClusterName"],
            ConfigurationManager.AppSettings["SessionAgent.UseProtoBuf"] == "1"
            );


        private string GetVendorRestrictedCountries(long domainID, VendorID vendor)
        {
            string cacheKey = string.Format("LoaderController.GetVendorRestrictedCountries.{0}", domainID);
            Dictionary<VendorID, string> dic = HttpRuntime.Cache[cacheKey] as Dictionary<VendorID, string>;
            if (dic == null)
            {
                CasinoVendorAccessor cva = CasinoVendorAccessor.CreateInstance<CasinoVendorAccessor>();
                dic = cva.GetRestrictedTerritoriesDictionary(domainID);
                HttpRuntime.Cache.Insert(cacheKey, dic, null, DateTime.Now.AddMinutes(5), Cache.NoSlidingExpiration);
            }

            string restrictedCountries = null;
            dic.TryGetValue(vendor, out restrictedCountries);
            return restrictedCountries;
        }

        private static string Encrypt(string toEncrypt, string key, bool useHashing)
        {
            try
            {
                byte[] keyArray;
                byte[] toEncryptArray = UTF8Encoding.UTF8.GetBytes(toEncrypt);

                if (useHashing)
                {
                    MD5CryptoServiceProvider hashmd5 = new MD5CryptoServiceProvider();
                    keyArray = hashmd5.ComputeHash(UTF8Encoding.UTF8.GetBytes(key));
                }
                else
                    keyArray = UTF8Encoding.UTF8.GetBytes(key);

                TripleDESCryptoServiceProvider tdes = new TripleDESCryptoServiceProvider();

                tdes.Key = keyArray;
                tdes.Mode = CipherMode.ECB;
                tdes.Padding = PaddingMode.PKCS7;

                ICryptoTransform cTransform = tdes.CreateEncryptor();
                byte[] resultArray = cTransform.TransformFinalBlock(toEncryptArray, 0, toEncryptArray.Length);

                return Convert.ToBase64String(resultArray, 0, resultArray.Length);
            }
            catch (Exception ex)
            {
                return HttpUtility.UrlEncode(ex.ToString());
            }
        }

        private static string Decrypt(string toDecrypt, string key, bool useHashing)
        {
            try
            {
                byte[] keyArray;
                byte[] toEncryptArray = Convert.FromBase64String(toDecrypt);

                if (useHashing)
                {
                    MD5CryptoServiceProvider hashmd5 = new MD5CryptoServiceProvider();
                    keyArray = hashmd5.ComputeHash(UTF8Encoding.UTF8.GetBytes(key));
                }
                else
                    keyArray = UTF8Encoding.UTF8.GetBytes(key);

                TripleDESCryptoServiceProvider tdes = new TripleDESCryptoServiceProvider();
                tdes.Key = keyArray;
                tdes.Mode = CipherMode.ECB;
                tdes.Padding = PaddingMode.PKCS7;

                ICryptoTransform cTransform = tdes.CreateDecryptor();
                byte[] resultArray = cTransform.TransformFinalBlock(toEncryptArray, 0, toEncryptArray.Length);

                return UTF8Encoding.UTF8.GetString(resultArray);

            }
            catch (Exception ex)
            {
                return HttpUtility.UrlEncode(ex.ToString());
            }

        }

        private bool CheckFunMode(bool? funMode, string _sid)
        {
            if (!funMode.HasValue)
            {
                return string.IsNullOrEmpty(_sid);
            }
            else if (string.IsNullOrEmpty(_sid))
            {
                return true;
            }
            else
            {
                return funMode.Value;
            }
        }

        public ActionResult RealityCheckConfig(long domainId, string id, string realityCheckTimeout)
        {
            int limit = 0;
            if (!string.IsNullOrEmpty(realityCheckTimeout) && Int32.TryParse(realityCheckTimeout, out limit))
            {
                ViewData["RealityCheckTimeout"] = limit;
            }

            List<ceDomainConfigEx> domains = DomainManager.GetDomains();
            ceDomainConfigEx domain = domains.FirstOrDefault(d => d.DomainID == domainId);
            if (domain == null)
            {
                this.ViewData["ErrorMessage"] = "Invalid Url Parameter(s)!";
                return this.View("Error");
            }
            DomainManager.CurrentDomainID = domainId;
            ViewData["Domain"] = domain;

            int vendorId = Int32.Parse(id);

            if (vendorId == (int)VendorID.NetEnt)
            {
                return View("NetEntRealityCheckConfig");
            }

            if (vendorId == (int)VendorID.Realistic)
            {
                return View("RealisticRealityCheckConfig");
            }

            if (vendorId == (int) VendorID.Microgaming)
            {
                return View("MicrogamingRealityCheckConfig");
            }
            else if(vendorId == (int)VendorID.QuickSpin)
            {
                return View("QuickSpinRealityCheckConfig");
            }
            else if (vendorId == (int)VendorID.PlaynGO)
            {
                return View("PlaynGORealityCheckConfig");
            }


            this.ViewData["ErrorMessage"] = String.Format("Invalid Url Parameter(s)!. Unknown vendor '{0}'", vendorId);
            return this.View("Error");
        }


        public ActionResult LobbyResolver(long domainId, string id)
        {
            List<ceDomainConfigEx> domains = DomainManager.GetDomains();
            ceDomainConfigEx domain = domains.FirstOrDefault(d => d.DomainID == domainId);
            if (domain == null)
            {
                this.ViewData["ErrorMessage"] = "Invalid Url Parameter(s)!";
                return this.View("Error");
            }
            
            DomainManager.CurrentDomainID = domainId;
            ViewData["Domain"] = domain;

            return View("LobbyResolver");
        }

        
        // GET: /Loader/
        public ActionResult Start(long domainID, string id, string _sid, string _sid64, string language, bool? funMode, string tableID)
        {
            string userAgentInfo = Request.GetRealUserAddress() + Request.UserAgent;
            if (!string.IsNullOrEmpty(_sid))
            {
                string sid64 = Encrypt(_sid, userAgentInfo, true);
                sid64 = Regex.Replace(sid64, @"(\+|\/|\=)", (Match match) =>
                {
                    switch (match.Value)
                    {
                        case "+": return ".";
                        case "/": return "_";
                        case "=": return "-";
                        default: throw new NotSupportedException();
                    }
                }, RegexOptions.Compiled);

                RouteValueDictionary routeParams = new RouteValueDictionary();
                foreach (string key in Request.QueryString.Keys)
                    routeParams.Add(key, Request.QueryString[key]);

                routeParams["_sid64"] = sid64;
                routeParams["_sid"] = "";

                return RedirectToAction("Start", routeParams);
            }
            else
            {
                if (!string.IsNullOrEmpty(_sid64))
                {
                    _sid64 = Regex.Replace(_sid64, @"(\.|_|\-)", (Match match) =>
                    {
                        switch (match.Value)
                        {
                            case ".": return "+";
                            case "_": return "/";
                            case "-": return "=";
                            default: throw new NotSupportedException();
                        }
                    }, RegexOptions.Compiled);

                    _sid = Decrypt(_sid64, userAgentInfo, true);
                }
            }

            funMode = CheckFunMode(funMode, _sid); 

            //------- Domain Validation
            List<ceDomainConfigEx> domains = DomainManager.GetDomains();
            ceDomainConfigEx domain = domains.FirstOrDefault(d => d.DomainID == domainID);
            if (domain == null)
            {
                this.ViewData["ErrorMessage"] = "Invalid Url Parameter(s)!";
                return this.View("Error");
            }
            DomainManager.CurrentDomainID = domainID;

            //------- Game Validation
            Dictionary<string, ceCasinoGameBaseEx> games = CacheManager.GetGameDictionary(domain.DomainID);
            ceCasinoGameBaseEx game;
            if (!games.TryGetValue(id, out game))
            {
                throw new CeException("Game [{0}] is not available!", id);
            }
            if (!GlobalConstant.AllVendors.Contains(game.VendorID))
                throw new Exception("Unsupported VendorID!");


            //------- Country and IP restrictions Validation
            string vendorRestrictedCountries = GetVendorRestrictedCountries(domainID, game.VendorID);
            
            IPLocation ipLocation = IPLocation.GetByIP(Request.GetRealUserAddress());
            if (ipLocation.Found)
            {
                if (!string.IsNullOrWhiteSpace(game.RestrictedTerritories))
                {
                    if (game.RestrictedTerritories.IndexOf(ipLocation.CountryCode, StringComparison.InvariantCultureIgnoreCase) >= 0)
                    {
                        Logger.FailureAudit(string.Format("Accessing from {0}({1}) to game [{2}] is denied by game rules [{3}]."
                            , Request.GetRealUserAddress()
                            , ipLocation.CountryCode
                            , game.GameName
                            , game.RestrictedTerritories
                            )
                            );
                        return this.View("Error_RestrictedCountries");
                    }
                }
                if (!string.IsNullOrWhiteSpace(vendorRestrictedCountries))
                {
                    if (vendorRestrictedCountries.IndexOf(ipLocation.CountryCode, StringComparison.InvariantCultureIgnoreCase) >= 0)
                    {
                        Logger.FailureAudit(string.Format("Accessing from {0}({1}) to game [{2}] is denied by vendor rules [{3}]."
                            , Request.GetRealUserAddress()
                            , ipLocation.CountryCode
                            , game.GameName
                            , vendorRestrictedCountries
                            )
                            );
                        return this.View("Error_RestrictedCountries");
                    }
                }
            }

            SessionPayload session = null;
            if (!string.IsNullOrWhiteSpace(_sid))
            {
                {
                    session = _agentClient.GetSessionByGuid(_sid);
                    if (session == null ||
                        session.IsAuthenticated != true ||
                        session.DomainID != domain.DomainID)
                    {
                        return this.View("Error_InvalidSession");
                    }
                }                

                if (!funMode.Value && session != null && session.IsEmailVerified != true)
                {
                    return this.View("Error_Inactive");
                }

                if (session != null && session.Roles != null)
                {
                    bool isExist = session.Roles.FirstOrDefault(r => string.Equals(r, "Withdraw only", StringComparison.InvariantCultureIgnoreCase)) != null;
                    if (isExist)
                    {
                        return this.View("Error_WithdrawOnly");
                    }
                }

                // verify the restricted countries
                if (!string.IsNullOrWhiteSpace(game.RestrictedTerritories) && !string.IsNullOrEmpty(session.UserCountryCode))
                {
                    if (game.RestrictedTerritories.IndexOf(session.UserCountryCode, StringComparison.InvariantCultureIgnoreCase) >= 0)
                    {
                        Logger.FailureAudit(string.Format("Accessing from {0}({1} - {2}) to game [{3}] is denied by game rules [{4}]."
                            , session.UserID
                            , session.Username
                            , session.UserCountryCode
                            , game.GameName
                            , game.RestrictedTerritories
                            )
                            );
                        return this.View("Error_RestrictedCountries");
                    }
                }
                if (!string.IsNullOrWhiteSpace(vendorRestrictedCountries) && !string.IsNullOrEmpty(session.UserCountryCode))
                {
                    if (vendorRestrictedCountries.IndexOf(session.UserCountryCode, StringComparison.InvariantCultureIgnoreCase) >= 0)
                    {
                        Logger.FailureAudit(string.Format("Accessing from {0}({1} - {2}) to game [{3}] is denied by vendor rules [{4}]."
                            , session.UserID
                            , session.Username
                            , session.UserCountryCode
                            , game.GameName
                            , vendorRestrictedCountries
                            )
                            );
                        return this.View("Error_RestrictedCountries");
                    }
                }
                if (game.AgeLimit)
                {
                    if (session.BirthDate.AddYears(21) > DateTime.UtcNow.Date)
                    {
                        return this.View("Error_AgeLimit");
                    }
                }
            }
            else if (!game.FunMode && !game.AnonymousFunMode)
            {
                return this.View("Error_InvalidSession");
            }


            //------- If All OK start game
            this.ViewData["UserSession"] = session;
            this.ViewData["Domain"] = domain;
            this.ViewData["VendorID"] = game.VendorID;
            this.ViewData["GameID"] = game.GameID;
            this.ViewData["CasinoBaseGameID"] = game.ID;
            this.ViewData["Slug"] = game.Slug;
            this.ViewData["CasinoGameID"] = game.CasinoGameId;
            this.ViewData["GameCode"] = game.GameCode;
            this.ViewData["Language"] = language;
            this.ViewData["FunMode"] = funMode.Value;
            this.ViewData["TableID"] = tableID;


            Dictionary<int, ceCasinoVendor> vendors = CacheManager.GetVendorDictionary(domain.DomainID);
            this.ViewData["UseGmGaming"] = (vendors.ContainsKey((int) game.VendorID)) &&
                                            vendors[(int) game.VendorID].EnableGmGamingAPI;
            this.ViewData["EnableLogging"] = (vendors.ContainsKey((int)game.VendorID)) &&
                                            vendors[(int) game.VendorID].EnableLogging;

            switch (game.VendorID)
            {
                case VendorID.NetEnt:
                    {
                        if (funMode.Value)
                        {
                            this.ViewData["_sid64"] = null;
                        }
                        else
                        {
                            this.ViewData["_sid64"] = _sid64;
                        }

                        if (game.GameCategories.IndexOf(",LIVEDEALER,", StringComparison.InvariantCultureIgnoreCase) >= 0)
                            return View("NetEntLiveDealer", game);

                        bool inclusionEnabled = ConfigurationManager.AppSettings["Netent.Launch.Inclusion.Enabled"].SafeParseToBool(false);
                        if (inclusionEnabled)
                        {
                            return View("NetEnt_Inclusion", game);
                        }
                        else
                        {
                            if (game.GameID.EndsWith("_mobile_html_sw", StringComparison.InvariantCultureIgnoreCase))
                                return View("NetEntMobile", game);

                            return View("NetEnt", game);
                        }
                    }
                case VendorID.Microgaming:
                    {
                        if (game.GameID.StartsWith("Nano", StringComparison.InvariantCultureIgnoreCase) ||
                            game.GameID.StartsWith("Mini", StringComparison.InvariantCultureIgnoreCase))
                        {
                            return View("MicrogamingNano", game);
                        }
                        if (game.GameCode.StartsWith("MGS_LG-", StringComparison.InvariantCultureIgnoreCase))
                        {
                            return View("MicrogamingLiveDealer", game);
                        }
                        return View("Microgaming", game);
                    }
                case VendorID.GreenTube:
                    {
                        if (domain.Name.Equals("energycasino", StringComparison.OrdinalIgnoreCase) ||
                            Request.Url.Host.EndsWith("energycasino.com", StringComparison.InvariantCultureIgnoreCase))
                            return View("GreenTube_EnergyCasino", game);
                        else
                            return View("GreenTube", game);
                    }
                case VendorID.ISoftBet:
                    if (game.GameID.EndsWith("_html", StringComparison.InvariantCultureIgnoreCase)
                        || game.GameID.EndsWith("_html5", StringComparison.InvariantCultureIgnoreCase))
                        return View("ISoftBetNew", game);

                    return View("ISoftBetNew", game);
                default:
                    return View(game.VendorID.ToString(), game);
            }
        }

        public ActionResult Help(long domainID, string id, string language)
        {
            List<ceDomainConfigEx> domains = DomainManager.GetDomains();
            ceDomainConfigEx domain = domains.FirstOrDefault(d => d.DomainID == domainID);
            if (domain == null)
            {
                this.ViewData["ErrorMessage"] = "Invalid Url Parameter(s)!";
                return this.View("Error");
            }
            Dictionary<string, ceCasinoGameBaseEx> games = CacheManager.GetGameDictionary(domain.DomainID);
            ceCasinoGameBaseEx game;
            if (!games.TryGetValue(id, out game))
            {
                this.ViewData["ErrorMessage"] = "Error, cannot find the game!";
                return this.View("Error");
            }

            if (game.VendorID == VendorID.NetEnt)
            {
                this.ViewData["Domain"] = domain;
                this.ViewData["Language"] = language;
                return this.View("NetEntHelp", game);
            }
            return null;
        }


        public ActionResult MicrogamingNanoXpro(long domainID, string id, string _sid)
        {
            List<ceDomainConfigEx> domains = DomainManager.GetDomains();
            ceDomainConfigEx domain = domains.FirstOrDefault(d => d.DomainID == domainID);
            if (domain == null)
            {
                this.ViewData["ErrorMessage"] = "Invalid Url Parameter(s)!";
                return this.View("Error");
            }

            Dictionary<string, ceCasinoGameBaseEx> games = CacheManager.GetGameDictionary(domainID);
            ceCasinoGameBaseEx game;
            if (!games.TryGetValue(id, out game))
            {
                this.ViewData["ErrorMessage"] = "Error, cannot find the game!";
                return this.View("Error");
            }

            SessionPayload session = null;
            if (!string.IsNullOrWhiteSpace(_sid))
            {
                using (DbManager db = new DbManager())
                {
                    session = _agentClient.GetSessionByGuid(_sid);
                    if (session == null ||
                        session.IsAuthenticated != true ||
                        session.DomainID != domainID)
                    {
                        this.ViewData["ErrorMessage"] = "Error, invalid session id!";
                        return this.View("Error");
                    }
                }
            }            

            
            MicrogamingNanoGameSessionInfo info = null;
            if (session != null)
            {
                string cacheKey = string.Format("MG_NANO_GAME_SESSION_{0}_{1}", domainID, session.Guid);
                info = HttpRuntime.Cache[cacheKey] as MicrogamingNanoGameSessionInfo;

                this.ViewData["HandlerUrl"] = this.Url.Action("SaveMicrogamingNanoGameSession"
                    , new { @domainID = domainID, @id = id, @_sid = session.Guid }
                    );
            }

            this.ViewData["UserSession"] = session;
            this.ViewData["Domain"] = domain;
            this.ViewData["MicrogamingNanoGameSessionInfo"] = info;
            this.ViewData["UserSession"] = session;
            this.ViewData["VendorID"] = game.VendorID;
            this.ViewData["GameID"] = game.GameID;
            this.ViewData["CasinoBaseGameID"] = game.ID;
            this.ViewData["CasinoGameID"] = game.CasinoGameId;
            this.ViewData["GameCode"] = game.GameCode;

            Dictionary<int, ceCasinoVendor> vendors = CacheManager.GetVendorDictionary(domain.DomainID);
            this.ViewData["UseGmGaming"] = (vendors.ContainsKey((int) game.VendorID)) &&
                                            vendors[(int) game.VendorID].EnableGmGamingAPI;
            this.ViewData["EnableLogging"] = (vendors.ContainsKey((int)game.VendorID)) &&
                                            vendors[(int) game.VendorID].EnableLogging;
            return this.View("MicrogamingNanoXpro", game);
        }

        public JsonResult SaveMicrogamingNanoGameSession(long domainID, long id, string _sid
            , decimal balance
            , string userType
            , string lcid
            , string sessionId
            , string token
            )
        {
            string cacheKey = string.Format("MG_NANO_GAME_SESSION_{0}_{1}", domainID, _sid);

            MicrogamingNanoGameSessionInfo info = new MicrogamingNanoGameSessionInfo()
            {
                Balance = balance,
                UserType = userType,
                LocalConnectionID = lcid,
                SessionId = sessionId,
                Token = token,
            };
            HttpRuntime.Cache[cacheKey] = info;

            return this.Json(new { @success = true }, JsonRequestBehavior.AllowGet);
        }

        /*
A code defining the reason for going back to the lobby.
“0” = A normal game termination (the player selected to go to the lobby using the lobby button in the game)
“1” = The game was started from a bookmark; a login (real or for fun) is required to obtain a web session and play the game.
“2” = The game has been inactive for too long and requires pin code authentication. Note: This feature will not be available in first release of mobile games.
“4” = Play for real promotion has been displayed in-game, and the player wants to register and play for real money.
“5” = The player ran out of money when playing a game, and want to deposit more money.
“6” = The device is confirmed not supported.
“9” = An error occurred in the game and the player chose to go to the lobby.
         */
        public ActionResult Return(long domainID, VendorID id, string gameId, string reason)
        {
            List<ceDomainConfigEx> domains = DomainManager.GetDomains();
            ceDomainConfigEx domain = domains.FirstOrDefault(d => d.DomainID == domainID);
            if (domain == null)
                throw new HttpException(404, "Invalid URL");

            switch (id)
            {
                case VendorID.NetEnt:
                    {
                        string postfix = string.Format("#{0}", reason);
                        if (reason == "5")
                            return this.Redirect(domain.MobileCashierUrl + postfix);
                        if (reason == "10")
                            return this.Redirect(domain.MobileAccountHistoryUrl + postfix);

                        return this.Redirect(domain.MobileLobbyUrl + postfix);
                    }

                default:
                    throw new NotSupportedException();
            }
        }
    }
}
