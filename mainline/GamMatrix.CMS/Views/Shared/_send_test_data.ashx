<%@ WebHandler Language="C#" Class="_send_test_data" %>

using System;
using System.IO;
using System.Text;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Xml.Linq;
using System.Threading;
using System.Web;
using System.Web.Script.Serialization;
using CM.db;
using CM.Content;
using CM.Sites;
using CM.State;
using Finance;
using GamMatrixAPI;
using GmCore;
using CasinoEngine;
using System.Text.RegularExpressions;
using System.Net;
using EveryMatrix.SessionAgent;
using EveryMatrix.SessionAgent.Protocol;
using System.Configuration;
using CM.db.Accessor;
using System.Globalization;

public class _send_test_data : IHttpHandler
{
    private HttpContext context;
    
    public void ProcessRequest (HttpContext context) 
    {
        try
        {
            //json format
            //Newtonsoft.Json.JsonConvert.SerializeObject(object);
            
            //xml format
            //byte[] postData = ObjectHelper.XmlSerialize(object);
            //byte[] postData = new byte[]{};

            this.context = context;
            ProfileCommon.Current.Init(context);

            /*if (!ProfileCommon.Current.IsAuthenticated)
            {
                context.Response.Write("Not logged In");
                context.Response.ContentType = "text/plain";
                return;
            }*/

            string method = context.Request.QueryString["method"];
            if (!string.IsNullOrEmpty(method))
            {
                switch (method.ToLowerInvariant())
                {
                    //casino games
                    case "getcasinogames":  //get Casino Games
                        GetCasinoGames();
                        break;
                    case "checkcasinogames":
                        CheckCasinoGames();
                        break;
                    case "getcasinocategory": //get Casino Game Categories
                        GetCasinoCategory();
                        break;
                    case "getlivecasinogames":
                        GetLiveCasinoGames();
                        break;
                    case "getglobalbetgames":
                        GetGlobalbetGames();
                        break;
                    case "getminigames":
                        GetMiniGames();
                        break;
                    case "clearfeedtype":
                        ClearFeedType();
                        break;
                    case "clearlivecasinogamescache":
                        ClearLiveCasinoGamesCache();
                        break;
                    
                    //payment methods
                    case "wallet":
                        GetWallet();  //parameter: userid?
                        break;
                    case "paymentlist":
                        GetPaymentList();
                        break;
                    case "depositlimit":
                        GetDepositLimit();  //parameter: payment
                        break;
                    case "transparameter":
                        GetTransParameter();    // parameter: _sid
                        break;
                    case "getbonus":    //parameter: userid
                        GetBonus();
                        break;
                    case "txtnation":
                        GetTxtNation();  //parameter: transid
                        break;
                        
                    case "checkisrofusselfexcluded":
                        CheckIsRofusSelfExcluded(); //parameter: cpr
                        break;
                   
                    //system level
                    case "reloadsitecache":
                        ReloadSiteCache();  // parameter: type=reload?
                        break;
                    case "reloadroutetable":
                        ReloadRouteTable();     //parameter: site?, start?, length?
                        break;
                    case "encrypassword":
                        EncryPassword();    //parameter: mode?, password
                        break;
                    case "health":
                        Health();
                        break;
                    
                    case "getpassport":
                        GetPassport(); //parameter: userid
                        break;
                    case "getcontract":
                        GetContract(); //parameter: userid
                        break;
                    case "sportsagent":
                        SportsAgent();
                        break;
                        case "twostepsauth":
                        TwoStepsAuth(); //parameter: username, domainid
                        break;
                    default:
                        break;
                }

                /*using (System.Net.WebClient client = new System.Net.WebClient())
                    {
                        client.Headers.Add("Content-Type", "application/x-wwww-form-urlencoded");
                        client.UploadData(string.Format("http://{0}/_receive_request.ashx", context.Request.Url.Host), "POST", postData);
                    }*/
            }
        }
        catch (Exception ex)
        {
            context.Response.ContentType = "text/plain";
            context.Response.Write(ex.Message);
            return;
        }
    }
 
    public bool IsReusable {
        get {
            return false;
        }
    }

    private void GetWallet()
    {
        int userId = ProfileCommon.Current.UserID;
        if (!string.IsNullOrEmpty(context.Request.QueryString["userid"]))
        {
            int.TryParse(context.Request.QueryString["userid"], out userId);
        }
        GetUserAccountsRequest request = new GetUserAccountsRequest()
        {
            UserID = userId,
            NoBalance = false,
        };
        GamMatrixClient gmclient = new GamMatrixClient();
        GetUserAccountsRequest resp = gmclient.SingleRequest<GetUserAccountsRequest>(request);
        List<AccountData> list = new List<AccountData>();

        if (resp != null && resp.Data.Count > 0)
        {
            list = resp.Data.Where(a => a.Record.Type == AccountType.Ordinary).ToList();
        }

        context.Response.ContentType = "text/plain";
        context.Response.Write(Newtonsoft.Json.JsonConvert.SerializeObject(list));

        /*byte[] postData = ObjectHelper.XmlSerialize(list);

        using (StreamReader sr = new StreamReader(new MemoryStream(postData)))
        {
            context.Response.ContentType = "text/xml";
            context.Response.Write(sr.ReadToEnd());
            return;
        }*/
    }

    private void GetPaymentList()
    {
        PaymentMethod[] paymentMethods = PaymentMethodManager.GetPaymentMethods().ToArray();

        context.Response.ContentType = "text/xml";
        context.Response.Write("<Root>");
        if (paymentMethods != null && paymentMethods.Count() > 0)
        {
            context.Response.Write(Encoding.UTF8.GetString(ObjectHelper.XmlSerialize(paymentMethods)));
        }
        context.Response.Write(Encoding.UTF8.GetString(ObjectHelper.XmlSerialize(ProfileCommon.Current)));
        context.Response.Write("</Root>");
    }

    private void CheckIsRofusSelfExcluded()
    {
        /*string dkApiHost = GamMatrix.CMS.Integration.OAuth.DkLicenseClient.GmCoreUrl + "/api/dkuser";
            string domainID = CM.Sites.SiteManager.Current.DomainID.ToString();
            string dkKey = Settings.DKLicenseKey;
            context.Response.Write("dkApiHost: " + dkApiHost);
            context.Response.Write("domainID: " + domainID);
            context.Response.Write("dkKey: " + dkKey);*/
        
        string cpr = context.Request.QueryString["cpr"];
        GamMatrix.CMS.Integration.OAuth.CheckIsRofusSelfExcludedResponse rofusResponse = GamMatrix.CMS.Integration.OAuth.DkLicenseClient.CheckIsRofusSelfExcluded(cpr);
        byte[] postData = ObjectHelper.XmlSerialize(rofusResponse);

        using (StreamReader sr = new StreamReader(new MemoryStream(postData)))
        {
            context.Response.ContentType = "text/xml";
            context.Response.Write(sr.ReadToEnd());
            return;
        }
    }

    private void GetCasinoGames()
    {
        var StartTick = DateTime.Now.Ticks;
        //display all games
        Dictionary<string, Game> games = CasinoEngineClient.GetGames(useCache:false);

        context.Response.ContentType = "text/xml";
        context.Response.Write("<Root>");
        if (games != null && games.Count > 0)
        {
            context.Response.Write(Encoding.UTF8.GetString(ObjectHelper.XmlSerialize(games)));
        }
        decimal elapsedSeconds = (DateTime.Now.Ticks - StartTick) / 10000000.000M;
        context.Response.Write(string.Format("<SpendTime>{0:f2}s</SpendTime>", elapsedSeconds));
        context.Response.Write(string.Format("<ServerName>{0}</ServerName>", context.Server.MachineName));
        context.Response.Write("</Root>");
    }
    
    private void CheckCasinoGames()
    {
        cmSite site = SiteManager.Current;
        Dictionary<string, Game> cached = new Dictionary<string, Game>();
        context.Response.ContentType = "text/html";
        try
        {
            string path = Path.Combine(System.Web.Hosting.HostingEnvironment.MapPath("~/App_Data/")
                        , ".casino"
                        , site.DomainID.ToString(CultureInfo.InvariantCulture)
                        , "games.json"
                        );
            string json = FileSystemUtility.ReadWithoutLock(path);
            if (!string.IsNullOrWhiteSpace(json))
            {
                cached = Newtonsoft.Json.JsonConvert.DeserializeObject<Dictionary<string, Game>>(json);
                context.Response.Write("OK");
            }
        }
        catch (Exception e)
        {
            context.Response.Write(e.Message);
        }
    }
    
    private void GetCasinoCategory()
    {
        //display all games
        List<GameCategory> categories = GameMgr.GetCategories();

        context.Response.ContentType = "text/xml";
        context.Response.Write("<Root>");
        if (categories != null && categories.Count > 0)
        {
            context.Response.Write(Encoding.UTF8.GetString(ObjectHelper.XmlSerialize(categories)));
        }

        context.Response.Write("</Root>");
    }

    private void GetLiveCasinoGames()
    {
        var games = CasinoEngine.GameMgr.GetLiveCasinoTables(SiteManager.Current).ToList();
        byte[] postData = ObjectHelper.XmlSerialize(games);

        using (StreamReader sr = new StreamReader(new MemoryStream(postData)))
        {
            context.Response.ContentType = "text/xml";
            context.Response.Write(sr.ReadToEnd());
            return;
        }

        /*context.Response.ContentType = "text/plain";
        foreach (var game in games)
        {
        }*/
    }

    private void GetDepositLimit()
    {
        string payment = context.Request.QueryString["payment"];
        PaymentMethod[] paymentMethods = PaymentMethodManager.GetPaymentMethods().ToArray();
        var query = paymentMethods.Where(p => p.IsAvailable &&
            p.SupportDeposit &&
            DomainConfigAgent.IsVendorEnabled(p));

        int countryID = -1;
        //string currency = "EUR";

        if (countryID > 0)
            query = query.Where(p => p.SupportedCountries.Exists(countryID));

        //if (!string.IsNullOrWhiteSpace(currency))
        //    query = query.Where(p => p.SupportedCurrencies.Exists(currency));
        if (ProfileCommon.Current.IsAuthenticated)
        {
            if (Regex.IsMatch(Metadata.Get("Metadata/Settings/Deposit.AstroPayCard_Ignore_DenyDepositCardRole").DefaultIfNullOrWhiteSpace("NO"), @"(YES)|(ON)|(OK)|(TRUE)|(\1)", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant | RegexOptions.Compiled))
            {
                query = query.Where(p => !ProfileCommon.Current.IsInRole(p.DenyAccessRoleNames)
                    || (p.UniqueName == "AstroPayCard" && !ProfileCommon.Current.IsInRole(p.DenyAccessRoleNames.Where(r => !r.Equals("Deny Card Deposit", StringComparison.InvariantCultureIgnoreCase)).ToArray())));
            }
            else
            {
                query = query.Where(p => !ProfileCommon.Current.IsInRole(p.DenyAccessRoleNames));
            }
        }

        paymentMethods = query.Where(p => p.RepulsivePaymentMethods == null ||
            p.RepulsivePaymentMethods.Count == 0 ||
            !p.RepulsivePaymentMethods.Exists(p2 => query.FirstOrDefault(p3 => p3.UniqueName == p2) != null)
            ).ToArray();

        var paymentMethod = paymentMethods.Where(p => p.UniqueName == payment).FirstOrDefault();
        if (paymentMethod != null)
        {
            byte[] postData = ObjectHelper.XmlSerialize(paymentMethod);

            using (StreamReader sr = new StreamReader(new MemoryStream(postData)))
            {
                context.Response.ContentType = "text/xml";
                context.Response.Write(sr.ReadToEnd());
                return;
            }
        }
        else
        {
            context.Response.ContentType = "text/plain";
            context.Response.Write("can't find the payment method.");
            return;
        }
        
    }

    private void GetMiniGames()
    {
        try
        {
            string[] paths = Metadata.GetChildrenPaths("/Metadata/Casino/MiniGames");
            List<MiniGame> _MiniGames = new List<MiniGame>();
            if (paths != null && paths.Length > 0)
            {
                List<GameRef> allMiniGames = new List<GameRef>();
                try
                {
                    allMiniGames = GameMgr.GetAllMiniGame();
                }
                catch { }

                Dictionary<string, LiveCasinoTable> allLiveTables = CasinoEngineClient.GetLiveCasinoTables();

                string gameID;
                string tableID;

                MiniGame miniGame;
                GameRef gameRef;
                int w = 0, h = 0;
                foreach (string path in paths)
                {
                    gameID = Metadata.Get(path + ".ID").Trim();
                    tableID = Metadata.Get(path + ".TableID").Trim();

                    if (!string.IsNullOrWhiteSpace(tableID))
                    {
                        if (!allLiveTables.Keys.Contains(tableID))
                            continue;

                        miniGame = new MiniGame();
                        miniGame.ID = miniGame.TableID = tableID;
                        miniGame.IsLiveCasino = true;
                        miniGame.Image = Metadata.Get(path + ".Image").Trim();
                        miniGame.Name = path.Substring(path.LastIndexOf("/") + 1).ToLowerInvariant();
                        miniGame.Title = allLiveTables[tableID].Name;

                        int.TryParse(Metadata.Get(path + ".Width").DefaultIfNullOrWhiteSpace("0").Trim(), out w);
                        miniGame.Width = w;
                        int.TryParse(Metadata.Get(path + ".Height").DefaultIfNullOrWhiteSpace("h").Trim(), out h);
                        miniGame.Height = h;

                        _MiniGames.Add(miniGame);
                    }
                    else if (!string.IsNullOrWhiteSpace(gameID) && allMiniGames.Exists(p => p.ID.Equals(gameID, StringComparison.OrdinalIgnoreCase)))
                    {
                        gameRef = allMiniGames.First(p => p.ID.Equals(gameID, StringComparison.OrdinalIgnoreCase));
                        if (!ProfileCommon.Current.IsAuthenticated)
                        {
                            if (!gameRef.Game.IsFunModeEnabled || !gameRef.Game.IsAnonymousFunModeEnabled)
                                continue;
                        }
                        else
                        {
                            if (!gameRef.Game.IsRealMoneyModeEnabled)
                                continue;
                        }

                        miniGame = new MiniGame();
                        miniGame.ID = miniGame.GameID = gameID;
                        miniGame.Image = Metadata.Get(path + ".Image").Trim();
                        miniGame.Name = path.Substring(path.LastIndexOf("/") + 1).ToLowerInvariant();
                        miniGame.Title = gameRef.Name;

                        _MiniGames.Add(miniGame);
                    }
                }
            }

            if (_MiniGames.Count > 0)
            {
                byte[] postData = ObjectHelper.XmlSerialize(_MiniGames);

                using (StreamReader sr = new StreamReader(new MemoryStream(postData)))
                {
                    context.Response.ContentType = "text/xml";
                    context.Response.Write(sr.ReadToEnd());
                    return;
                }
            }
            else
            {
                context.Response.ContentType = "text/plain";
                context.Response.Write("no mini games");
                return;
            }
        }
        catch (Exception ex)
        {
            context.Response.ContentType = "text/plain";
            context.Response.Write(ex.Message);
            return;
        }
        
    }

    private void GetTransParameter()
    {
        string sid = context.Request.QueryString["_sid"];

        context.Response.ContentType = "text/xml";
        context.Response.Write("<Root>");
        
        PrepareTransRequest prepareTransRequest = cmTransParameter.ReadObject<PrepareTransRequest>(sid, "PrepareTransRequest");
        if (prepareTransRequest != null)
        {
            context.Response.Write(Encoding.UTF8.GetString(ObjectHelper.XmlSerialize(prepareTransRequest)));
        }

        ProcessAsyncTransRequest processAsyncTransRequest = cmTransParameter.ReadObject<ProcessAsyncTransRequest>(sid, "ProcessAsyncTransRequestBefore");
        if (processAsyncTransRequest != null)
        {
            context.Response.Write(Encoding.UTF8.GetString(ObjectHelper.XmlSerialize(processAsyncTransRequest)));
        }

        ProcessTransRequest processTransRequest = cmTransParameter.ReadObject<ProcessTransRequest>(sid, "ProcessTransRequest");
        if (processTransRequest != null)
        {
            context.Response.Write(Encoding.UTF8.GetString(ObjectHelper.XmlSerialize(processTransRequest)));
        }

        context.Response.Write("</Root>");
    }

    private void ReloadSiteCache()
    {
        context.Response.ContentType = "text/html";
        string reloadType = context.Request.QueryString["type"];
        if (!string.IsNullOrEmpty(reloadType) && reloadType.Equals("reload", StringComparison.InvariantCultureIgnoreCase))
        {
            try
            {
                SiteManager.ReloadSiteHostCache();
                context.Response.Write("OK");
            } 
            catch (Exception ex)
            {
                //string ALL_SITES_CACHE_FILE = "~/App_Data/sites_cache.dat";
                //string ALL_HOSTS_CACHE_FILE = "~/App_Data/hosts_cache.dat";
                string HOST_SITE_MAP_CACHE_FILE = "~/App_Data/hosts_sites_cache.dat";
                context.Response.Write(System.Web.Hosting.HostingEnvironment.MapPath(HOST_SITE_MAP_CACHE_FILE));
                context.Response.Write(ex.Message);
            }
        }
        else
        {
            System.Collections.Specialized.NameValueCollection servers = System.Configuration.ConfigurationManager.GetSection("servers") as System.Collections.Specialized.NameValueCollection;
            if (servers != null && servers.Count > 0)
            {
                foreach (string serverName in servers.Keys)
                {
                    string url = string.Format("http://{0}/_send_test_data.ashx?method=ReloadSiteCache&type=reload"
                            , servers[serverName]
                            );
                    try
                    {
                        HttpWebRequest request = HttpWebRequest.Create(url) as HttpWebRequest;
                        request.KeepAlive = false;
                        request.Method = "POST";
                        request.ProtocolVersion = Version.Parse("1.0");
                        request.AutomaticDecompression = DecompressionMethods.GZip | DecompressionMethods.Deflate;
                        request.Accept = "text/plain";

                        using (Stream stream = request.GetRequestStream())
                        using (StreamWriter writer = new StreamWriter(stream))
                        {
                            //writer.Write(json);
                            writer.Flush();
                        }

                        HttpWebResponse response = request.GetResponse() as HttpWebResponse;
                        string respText = string.Empty;
                        using (Stream stream = response.GetResponseStream())
                        {
                            using (StreamReader sr = new StreamReader(stream))
                            {
                                respText = sr.ReadToEnd();
                            }
                        }
                        response.Close();

                        bool success = string.Compare(respText, "OK", true) == 0;
                        context.Response.Write(string.Format("{0}: {1}<br />", servers[serverName], respText));
                    }
                    catch (Exception ex)
                    {
                        context.Response.Write(string.Format("{0}, this url is {1}<br/>", ex.Message, url));
                    }
                }
            }
        }
    }

    private void ReloadRouteTable()
    {
        context.Response.ContentType = "text/plain";
        string sitename = context.Request.QueryString["site"];

        if (!string.IsNullOrEmpty(sitename))
        {
            try
            {
                if (sitename.Equals("shared", StringComparison.InvariantCultureIgnoreCase))
                {
                    cmSite sharedSite = SiteManager.GetSiteByDistinctName("Shared");
                    SiteManager.ReloadConfigration(sharedSite);
                    context.Response.Write(sharedSite.DistinctName + " is ok\n");

                    sharedSite = SiteManager.GetSiteByDistinctName("MobileShared");
                    SiteManager.ReloadConfigration(sharedSite);
                    context.Response.Write(sharedSite.DistinctName + " is ok\n");

                    sharedSite = SiteManager.GetSiteByDistinctName("System");
                    SiteManager.ReloadConfigration(sharedSite);
                    context.Response.Write(sharedSite.DistinctName + " is ok\n");
                } 
                else 
                {
                    cmSite site = SiteManager.GetSiteByDistinctName(sitename);
                    SiteRouteInfo siteRouteInfo = SiteManager.ReloadConfigration(site);

                    context.Response.Write(site.DistinctName + " is ok\n");
                    context.Response.Write(Newtonsoft.Json.JsonConvert.SerializeObject(siteRouteInfo.RouteCollection));
                }
            }
            catch (Exception ex)
            {
                context.Response.Write(ex.Message);
            }
        }
        else
        {
            try
            {
                int startIndex = 0;
                int length = 20;
                if (!string.IsNullOrEmpty(context.Request.QueryString["start"]))
                {
                    int.TryParse(context.Request.QueryString["start"], out startIndex);
                }

                if (!string.IsNullOrEmpty(context.Request.QueryString["length"]))
                {
                    int.TryParse(context.Request.QueryString["length"], out length);
                }

                List<cmSite> sites = SiteManager.GetSites().Where(f => !(f.DistinctName.Equals("Shared", StringComparison.InvariantCultureIgnoreCase) || f.DistinctName.Equals("MoblieShared", StringComparison.InvariantCultureIgnoreCase))).ToList();
                
                int count = 0;
                foreach (var site in sites)
                {
                    count++;
                    if (count < startIndex - 1) continue;
                    if (count > (startIndex - 1)+ length) break;

                    SiteManager.ReloadConfigration(site);
                    context.Response.Write(site.DistinctName + " is ok\n");
                }
                
                context.Response.Write(string.Format(@"finished: {0}-{1}/{2}", startIndex + 1, count, sites.Count));
            }
            catch (Exception ex)
            {
                context.Response.Write(ex.Message + "\n");
            }
        }
    }

    private void EncryPassword() 
    {
        PasswordEncryptionMode mode = PasswordEncryptionMode.MD5;
        string passwordMode = context.Request.QueryString["mode"];
        if (!string.IsNullOrEmpty(passwordMode))
        {
            switch (passwordMode)
            {
                case "sha1":
                    mode = PasswordEncryptionMode.SHA1_IntraGame;
                    break;
                case "sha2":
                    //mode = PasswordEncryptionMode.SHA2_512;
                    break;
                default:
                    break;
            } 
        }

        string password = context.Request.QueryString["password"];
        context.Response.Write(PasswordHelper.CreateEncryptedPassword(mode, password));
        context.Response.ContentType = "text/plain";
    }

    private void GetPassport()
    {
        long userid = -1L;
        if (!string.IsNullOrEmpty(context.Request.QueryString["userid"]))
        {
            long.TryParse(context.Request.QueryString["userid"], out userid);
            CM.db.Accessor.UserAccessor ua = CM.db.Accessor.UserAccessor.CreateInstance<CM.db.Accessor.UserAccessor>();
            cmUser user = ua.GetByID(userid);
            var passport = GamMatrixClient.GetUserImageRequest(user.ID, user.PassportID);
            if (passport != null && passport.Image != null)
            {
                context.Response.Clear();
                context.Response.ContentType = passport.Image.ImageContentType;
                context.Response.AddHeader("Content-Disposition", "attachment;  filename=" + HttpUtility.UrlEncode(passport.Image.ImageFileName, Encoding.UTF8));
                context.Response.BinaryWrite(passport.Image.ImageFile);
                context.Response.Flush();
                context.Response.End();
            }
            else
            {
                context.Response.Clear();
                context.Response.ContentType = "text/plain";
                context.Response.Write("can't download the file.");
                context.Response.Flush();
                context.Response.End();
            }
        }
        else
        {
            context.Response.Clear();
            context.Response.ContentType = "text/plain";
            context.Response.Write("can't download the file.");
            context.Response.Flush();
            context.Response.End();
        }
        
    }

    private void GetContract()
    {
        long userid = -1L;
        if (!string.IsNullOrEmpty(context.Request.QueryString["userid"]))
        {
            long.TryParse(context.Request.QueryString["userid"], out userid);
            var contractRequest = GamMatrixClient.GetUserLicenseLTContractValidityRequest(userid);

            context.Response.ContentType = "text/xml";
            context.Response.Write("<Root>");

            if (contractRequest != null)
            {
                context.Response.Write(Encoding.UTF8.GetString(ObjectHelper.XmlSerialize(contractRequest)));
            }
            context.Response.Write("</Root>");
        } 
        else 
        {
            context.Response.Clear();
            context.Response.ContentType = "text/plain";
            context.Response.Write("can't find the user.");
            context.Response.Flush();
            context.Response.End();
        }
    }

    private void GetBonus() 
    {
        int userid = -1;
        if (!string.IsNullOrEmpty(context.Request.QueryString["userid"]))
        {
            int.TryParse(context.Request.QueryString["userid"], out userid);
        }
        try
        {
            VendorID vendorID;
            if (!Enum.TryParse<VendorID>(context.Request.QueryString["vendor"], out vendorID))
                vendorID = VendorID.CasinoWallet;
        
       
            GamMatrixClient client = new GamMatrixClient();
            var accounts = GamMatrixClient.GetUserGammingAccounts(userid);
            var account = accounts.First(a => a.Record.VendorID == VendorID.CasinoWallet);

            
            byte[] buffer;
            byte[] bufferABD = null;
            if (vendorID == VendorID.CasinoWallet)
            {
                GetUserAvailableCasinoBonusDetailsRequest request = new GetUserAvailableCasinoBonusDetailsRequest()
                {
                    AccountID = account.ID,
                };

                request = client.SingleRequest<GetUserAvailableCasinoBonusDetailsRequest>(request);
                buffer = ObjectHelper.XmlSerialize(request);
            }
            else
            {
                GetUserAvailableBonusDetailsRequest request = new GetUserAvailableBonusDetailsRequest()
                {
                    VendorID = vendorID,
                    UserID = userid,
                };

                request = client.SingleRequest<GetUserAvailableBonusDetailsRequest>(request);
                buffer = ObjectHelper.XmlSerialize(request);
            }

            if (Settings.IsOMSeamlessWalletEnabled)
            {
                GetUserAvailableBonusDetailsRequest requestABD = new GetUserAvailableBonusDetailsRequest()
                {
                    UserID = userid,
                    VendorID = VendorID.OddsMatrix
                };

                requestABD = client.SingleRequest<GetUserAvailableBonusDetailsRequest>(requestABD);
                bufferABD = ObjectHelper.XmlSerialize(requestABD);
            }
            context.Response.Write("<Root>");
            context.Response.Write(Encoding.UTF8.GetString(buffer));
            
            if (bufferABD != null && bufferABD.Length > 0)
            {
                context.Response.Write(Encoding.UTF8.GetString(bufferABD));
            }
            context.Response.Write("</Root>");
            context.Response.ContentType = "text/xml";
        }
        catch (Exception ex)
        {
            context.Response.Write(ex.Message);
            context.Response.ContentType = "text/plain";
        }
    }

    private void GetGlobalbetGames()
    {
        List<GameRef> globalbetGames = GameMgr.GetAllGames().Where(f => f.VendorID == VendorID.Globalbet || f.VendorID == VendorID.Kiron).ToList();
        context.Response.ContentType = "text/xml";
        context.Response.Write("<Root>");
        context.Response.Write(Encoding.UTF8.GetString(ObjectHelper.XmlSerialize(globalbetGames)));

        context.Response.Write("</Root>");
    }

    private void SportsAgent() 
    {
        context.Response.ContentType = "text/plain";
        try 
        {
            
            AgentClient _agentClient = new AgentClient(
            ConfigurationManager.AppSettings["SessionAgent.ZooKeeperConnectionString"],
            ConfigurationManager.AppSettings["SessionAgent.ClusterName"],
            ConfigurationManager.AppSettings["SessionAgent.UseProtoBuf"] == "1"
            );

            string currentSession = context.Request["currentSession"];
            SessionPayload sess = _agentClient.GetSessionByGuid(currentSession);
            if (sess != null)
            {
                context.Response.Write("IsAuthenticated: " + sess.IsAuthenticated);
            } 
            else 
            {
                context.Response.Write("can't find the record");
            }
        }
        catch(Exception e)
        {
            context.Response.Write(e.Message);
        }
    }

    private void Health()
    {
        context.Response.ContentType = "text/xml";
        context.Response.Write("<Root>");
        
        //check the database connection
        DateTime startTime = DateTime.Now;
        long startTick = startTime.Ticks;
        string spendTime = string.Empty;
        bool status = true;
        string message = string.Empty;
        string result = string.Empty;
        string template = @"<Connection><Connection_Type>{0}</Connection_Type><Status>{1}</Status><Message>{2}</Message><SpendTime>{3}</SpendTime><StartTime>{4}</StartTime></Connection>";
        try
        {
            using (BLToolkit.Data.DbManager dbManager = new BLToolkit.Data.DbManager())
            {
                if (!(dbManager.Connection.State == System.Data.ConnectionState.Open || dbManager.Connection.State == System.Data.ConnectionState.Fetching || dbManager.Connection.State == System.Data.ConnectionState.Executing))
                {
                    status = false;
                    message = string.Format("connection state is {0}", dbManager.Connection.State.ToString());
                }
            }
        }
        catch (Exception ex)
        {
            status = false;
            message = ex.Message;
        }
        spendTime = string.Format("{0:f2}s", ((DateTime.Now.Ticks - startTick) / 10000000.00M));

        result = string.Format(template, "Connect to database", status, message, spendTime, startTime.ToString("yyyy-MM-dd hh:mm:ss"));
        context.Response.Write(result);
        
        //check gmcore
        startTime = DateTime.Now;
        startTick = startTime.Ticks;
        spendTime = string.Empty;
        status = true;
        message = string.Empty;
        try
        {
            using (System.Net.Sockets.TcpClient tc = new System.Net.Sockets.TcpClient())
            {
                string host = System.Configuration.ConfigurationManager.AppSettings["GmCore.RestURL"].ToString().Replace("https://", "").Replace("http://", "").Split('/')[0];
                tc.Connect(host, 80);
                if (!tc.Connected)
                {
                    status = false;
                    message = "can't connect to gmcore";
                }
            };
        }
        catch (Exception ex)
        {
            status = false;
            message = ex.Message;
        }
        spendTime = string.Format("{0:f2}s", ((DateTime.Now.Ticks - startTick) / 10000000.00M));

        result = string.Format(template, "Connect to gmcore", status, message, spendTime, startTime.ToString("yyyy-MM-dd hh:mm:ss"));
        context.Response.Write(result);
        
        context.Response.Write("</Root>");
    }

    private void ClearFeedType()
    {
        context.Response.ContentType = "text/html";
        string reloadType = context.Request.QueryString["type"];
        if (!string.IsNullOrEmpty(reloadType) && reloadType.Equals("reload", StringComparison.InvariantCultureIgnoreCase))
        {
            var sites = SiteManager.GetSites();
            using (BLToolkit.Data.DbManager dbManager = new BLToolkit.Data.DbManager())
            {
                CM.db.Accessor.SiteAccessor da = BLToolkit.DataAccess.DataAccessor.CreateInstance<CM.db.Accessor.SiteAccessor>(dbManager);
                foreach (var site in sites)
                {
                    try
                    {
                        if (!Directory.Exists(System.Web.Hosting.HostingEnvironment.MapPath(string.Format("~/Views/{0}/.config", site.DistinctName)))) continue;
                        
                        string cacheKey = string.Format("{0}_FeedType", site.DistinctName);
                        FeedsType cached = (FeedsType)da.GetFeedType(site.DomainID);
                        string relativePath = string.Format("~/Views/{0}/.config/ce_feeds_type.setting", site.DistinctName);
                        string filePath = System.Web.Hosting.HostingEnvironment.MapPath(relativePath);
                        cached = ObjectHelper.BinaryDeserialize<FeedsType>(filePath, cached);

                        HttpRuntime.Cache.Insert(cacheKey
                                , cached
                                , new System.Web.Caching.CacheDependency(filePath)
                                , System.Web.Caching.Cache.NoAbsoluteExpiration
                                , System.Web.Caching.Cache.NoSlidingExpiration
                                );
                    }
                    catch (Exception ex)
                    {
                        context.Response.Write(ex.Message + "\n");
                    }
                    
                }

                context.Response.Write("OK");
            }
        }
        else
        {
            System.Collections.Specialized.NameValueCollection servers = System.Configuration.ConfigurationManager.GetSection("servers") as System.Collections.Specialized.NameValueCollection;
            if (servers != null && servers.Count > 0)
            {
                foreach (string serverName in servers.Keys)
                {
                    string url = string.Format("http://{0}/_send_test_data.ashx?method=clearfeedtype&type=reload"
                            , servers[serverName]
                            );
                    try
                    {
                        HttpWebRequest request = HttpWebRequest.Create(url) as HttpWebRequest;
                        request.KeepAlive = false;
                        request.Method = "POST";
                        request.ProtocolVersion = Version.Parse("1.0");
                        request.AutomaticDecompression = DecompressionMethods.GZip | DecompressionMethods.Deflate;
                        request.Accept = "text/plain";

                        using (Stream stream = request.GetRequestStream())
                        using (StreamWriter writer = new StreamWriter(stream))
                        {
                            //writer.Write(json);
                            writer.Flush();
                        }

                        HttpWebResponse response = request.GetResponse() as HttpWebResponse;
                        string respText = string.Empty;
                        using (Stream stream = response.GetResponseStream())
                        {
                            using (StreamReader sr = new StreamReader(stream))
                            {
                                respText = sr.ReadToEnd();
                            }
                        }
                        response.Close();

                        bool success = string.Compare(respText, "OK", true) == 0;
                        context.Response.Write(string.Format("{0}: {1}<br />", servers[serverName], respText));
                    }
                    catch (Exception ex)
                    {
                        context.Response.Write(string.Format("{0}, this url is {1}<br/>", ex.Message, url));
                    }
                }
            }
        }
    }

    private static Platform GetUserPlatform()
    {
        try
        {
            string userAgent = HttpContext.Current.Request.UserAgent;
            if (Regex.IsMatch(userAgent, @"\biPad\b", RegexOptions.Compiled | RegexOptions.CultureInvariant))
                return Platform.iPad;

            if (Regex.IsMatch(userAgent, @"\biPhone\b", RegexOptions.Compiled | RegexOptions.CultureInvariant))
                return Platform.iPhone;

            if (Regex.IsMatch(userAgent, @"\bAndroid\b", RegexOptions.Compiled | RegexOptions.CultureInvariant))
                return Platform.Android;

            if (Regex.IsMatch(userAgent, @"\bWindows(\s+)Phone(\s+)OS(\s+)7", RegexOptions.Compiled | RegexOptions.CultureInvariant))
                return Platform.WM7;

            if (Regex.IsMatch(userAgent, @"\bWindows(\s+)Phone(\s+)8", RegexOptions.Compiled | RegexOptions.CultureInvariant))
                return Platform.WP8;
        }
        catch
        {
        }
        return Platform.PC;
    }

    private static string GetCacheKey(string prefix, string userIPCountryCode, string userCountryCode, Platform platform)
    {
        return string.Format(CultureInfo.InvariantCulture
            , "{0}_{1}_{2}_{3}_{4}_{5}"
            , prefix
            , SiteManager.Current.ID
            , GetCountryKey(userIPCountryCode, userCountryCode)
            , platform
            , CustomProfile.Current.IsAuthenticated
            , MultilingualMgr.GetCurrentCulture()
            );
    }

    private static string GetCountryKey(string code1, string code2)
    {
        if (string.Compare(code1, code2, true) > 0)
            return string.Format(CultureInfo.InvariantCulture, "{0}|{1}", code1, code2);

        return string.Format(CultureInfo.InvariantCulture, "{0}|{1}", code2, code1);
    }

    private static bool IsAvailableGame(Game game
            , string userIPCountryCode
            , string userCountryCode
            , Platform platform
            )
    {
        if (game == null)
            return false;
        if (!game.Platforms.Contains(platform))
            return false;
        if (game.RestrictedTerritories == null ||
            game.RestrictedTerritories.Length == 0)
        {
            return true;
        }

        if (!string.IsNullOrWhiteSpace(userCountryCode))
        {
            if (game.RestrictedTerritories.FirstOrDefault(t =>
                string.Equals(userCountryCode, t, StringComparison.InvariantCultureIgnoreCase)) != null)
            {
                return false;
            }
        }
        if (!string.IsNullOrWhiteSpace(userIPCountryCode))
        {
            if (game.RestrictedTerritories.FirstOrDefault(t =>
                string.Equals(userIPCountryCode, t, StringComparison.InvariantCultureIgnoreCase)) != null)
            {
                return false;
            }
        }
        return true;
    }
    
    private void ClearLiveCasinoGamesCache()
    {
        /*context.Response.ContentType = "text/html";
        string reloadType = context.Request.QueryString["type"];
        if (!string.IsNullOrEmpty(reloadType) && reloadType.Equals("reload", StringComparison.InvariantCultureIgnoreCase))
        {
            cmSite site = SiteManager.Current;
            string TABLE_CATEGORY_XML_PATH = @"~/Views/{0}/.config/live_casino_category.xml";
            string userIPCountryCode = CountryManager.GetAllCountries().First(c => CustomProfile.Current.IpCountryID == c.InternalID).ISO_3166_Alpha2Code;
            string userCountryCode = null;
            Platform platform = GetUserPlatform();

            string cacheKey = GetCacheKey("GameMgr.GetLiveCasinoTables", userIPCountryCode, userCountryCode, platform);

            List<KeyValuePair<string, List<LiveCasinoTable>>> cache = new List<KeyValuePair<string, List<LiveCasinoTable>>>();

            Dictionary<string, LiveCasinoTable> allTables = CasinoEngineClient.GetLiveCasinoTables()
                .Where(t => IsAvailableGame(t.Value, userIPCountryCode, userCountryCode, platform))
                .ToDictionary(t => t.Key, t => t.Value);
            
            var needToUpdateCacheKey = string.Format("{0}_NeedToUpdateTables", site.DistinctName);
            HttpRuntime.Cache.Remove(needToUpdateCacheKey);

            if (allTables.Count == 0)
                return;

            List<string> dependedFiles = new List<string>();
            string physicalPath = System.Web.Hosting.HostingEnvironment.MapPath(string.Format(CultureInfo.InvariantCulture, TABLE_CATEGORY_XML_PATH, site.DistinctName));
            dependedFiles.Add(physicalPath);

            if (!global::System.IO.File.Exists(physicalPath))
            {
                if (!string.IsNullOrWhiteSpace(site.TemplateDomainDistinctName))
                {
                    physicalPath = System.Web.Hosting.HostingEnvironment.MapPath(
                        string.Format(CultureInfo.InvariantCulture, TABLE_CATEGORY_XML_PATH, site.TemplateDomainDistinctName)
                        );
                    dependedFiles.Add(physicalPath);
                }
            }
            else
            {
                XDocument doc = XDocument.Load(physicalPath);
                IEnumerable<XElement> nodes = doc.Root.Elements("node");
                foreach (XElement node in nodes)
                {
                    if (node.Attribute("type").Value != "category")
                        continue;
                    string cat = node.Attribute("id").Value;

                    List<LiveCasinoTable> list = new List<LiveCasinoTable>();

                    IEnumerable<XElement> children = node.Elements("node");
                    foreach (XElement child in children)
                    {
                        string tableID = child.Attribute("id").Value;
                        LiveCasinoTable table;
                        if (allTables.TryGetValue(tableID, out table))
                        {
                            list.Add(table);
                        }
                    }

                    if (list.Count > 0)
                    {
                        cache.Add(new KeyValuePair<string, List<LiveCasinoTable>>(cat, list));
                    }
                }
            }


            if (cache.Count >= 0)
            {
                HttpRuntime.Cache.Insert(cacheKey
                    , cache
                    , new CacheDependencyEx(dependedFiles.ToArray(), false)
                    , DateTime.Now.AddMinutes(2)
                    , Cache.NoSlidingExpiration
                    );
            }
        }
        else
        {
            System.Collections.Specialized.NameValueCollection servers = System.Configuration.ConfigurationManager.GetSection("servers") as System.Collections.Specialized.NameValueCollection;
            if (servers != null && servers.Count > 0)
            {
                foreach (string serverName in servers.Keys)
                {
                    string url = string.Format("http://{0}/_send_test_data.ashx?method=clearlivecasinogamescache&type=reload"
                            , servers[serverName]
                            );
                    try
                    {
                        HttpWebRequest request = HttpWebRequest.Create(url) as HttpWebRequest;
                        request.KeepAlive = false;
                        request.Method = "POST";
                        request.ProtocolVersion = Version.Parse("1.0");
                        request.AutomaticDecompression = DecompressionMethods.GZip | DecompressionMethods.Deflate;
                        request.Accept = "text/plain";

                        using (Stream stream = request.GetRequestStream())
                        using (StreamWriter writer = new StreamWriter(stream))
                        {
                            //writer.Write(json);
                            writer.Flush();
                        }

                        HttpWebResponse response = request.GetResponse() as HttpWebResponse;
                        string respText = string.Empty;
                        using (Stream stream = response.GetResponseStream())
                        {
                            using (StreamReader sr = new StreamReader(stream))
                            {
                                respText = sr.ReadToEnd();
                            }
                        }
                        response.Close();

                        bool success = string.Compare(respText, "OK", true) == 0;
                        context.Response.Write(string.Format("{0}: {1}<br />", servers[serverName], respText));
                    }
                    catch (Exception ex)
                    {
                        context.Response.Write(string.Format("{0}, this url is {1}<br/>", ex.Message, url));
                    }
                }
            }
        }*/
    }

    private void TwoStepsAuth() 
    {
        string username = context.Request.QueryString["username"];
        int domainid = int.Parse(context.Request.QueryString["domainid"]);
        int secondFactorType = 1;
        string result = string.Empty;
        string message = "operation failed!";
            if (!string.IsNullOrWhiteSpace(username))
            {
                try
                {
                    using (BLToolkit.Data.DbManager dbManager = new BLToolkit.Data.DbManager())
                    {
                        UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
                        cmUser user = CustomProfile.Current.AsCustomProfile().GetUser(username, domainid, ua);
                        if (user != null)
                        {
                            TwoFactorAuth.SecondFactorAuthenticator.ResetSecondFactorAuth(user.ID);
                            TwoFactorAuth.SecondFactorAuthenticator.SetSecondFactorType(user.ID, secondFactorType);

                            TwoFactorAuth.SecondFactorAuthSetupCode setupCode = TwoFactorAuth.SecondFactorAuthenticator.GenerateSetupCode(SiteManager.Current, user, user.SecondFactorType);

                            if (setupCode.AuthType == TwoFactorAuth.SecondFactorAuthType.GeneralAuthCode)
                            {
                                //TwoFactorAuth.SendSecondFactorBackupCodeEmail(user, setupCode.BackupCodes, true);
                                bool isNewGeneration = true;
                                Email mail = new Email();
                                if (isNewGeneration)
                                    mail.LoadFromMetadata("SecondFactorNewGenerationBackupCode", user.Language);
                                else
                                    mail.LoadFromMetadata("SecondFactorBackupCode", user.Language);

                                mail.ReplaceDirectory["USERNAME"] = user.Username;
                                mail.ReplaceDirectory["FIRSTNAME"] = user.FirstName;

                                StringBuilder sb = new StringBuilder();
                                if (setupCode.BackupCodes != null && setupCode.BackupCodes.Count > 0)
                                {
                                    for (int i = 0; i < setupCode.BackupCodes.Count; i++)
                                    {
                                        mail.ReplaceDirectory["BACKUPCODE" + (i + 1)] = setupCode.BackupCodes[i];

                                        sb.AppendFormat("<li>{0}</li>", setupCode.BackupCodes[i]);
                                    }
                                }
                                mail.ReplaceDirectory["BACKUPCODELIST"] = sb.ToString();

                                mail.Send(user.Email);
                            }
                            else
                            {
                                //TwoFactorAuth.SendSecondFactorAuthCodeEmail(user, setupCode);
                                Email mail = new Email();
                                mail.LoadFromMetadata("SecondFactorAuthCode", user.Language);
                                mail.ReplaceDirectory["USERNAME"] = user.Username;
                                mail.ReplaceDirectory["FIRSTNAME"] = user.FirstName;
                                mail.ReplaceDirectory["QRCODEIMAGEURL"] = setupCode.QrCodeImageUrl;
                                mail.ReplaceDirectory["AUTHKEY"] = setupCode.SetupCode;

                                mail.Send(user.Email);
                            }
                            result = "changed";
                        }
                    }
                }
                catch (Exception ex)
                {
                    result = ex.Message;
                }
            }

        context.Response.Write(result);
        context.Response.ContentType = "text/plain";
    }

    private void GetTxtNation()
    {
        long transid = long.Parse(context.Request.QueryString["transid"]);
        var paymentMethodName = VendorID.TxtNation.ToString();

        var sid = string.Empty;

        var request = new GamMatrixAPI.GetTxtNationSidRequest
        {
            TxtNationTransID = transid
        };

        using (GamMatrixClient client = new GamMatrixClient())
        {
            request = client.SingleRequest<GetTxtNationSidRequest>(request);
        }

        context.Response.ContentType = "text/xml";
        context.Response.Write("<Root>");
        context.Response.Write(Encoding.UTF8.GetString(ObjectHelper.XmlSerialize(request)));

        context.Response.Write("</Root>");
    }


}

public class MiniGame
{
    public string Name { get; set; }
    public string ID { get; set; }
    public string GameID { get; set; }
    public string Title { get; set; }
    public string Image { get; set; }
    public string TableID { get; set; }
    public bool IsLiveCasino { get; set; }
    public int Width { get; set; }
    public int Height { get; set; }
}