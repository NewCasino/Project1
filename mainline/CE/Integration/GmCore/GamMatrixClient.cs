using System;
using System.Collections.Generic;
using System.Collections.Specialized;
using System.Configuration;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Runtime.Serialization.Formatters.Binary;
using System.Text;
using System.Threading.Tasks;
using System.Web;
using System.Web.Caching;
using System.Web.Script.Serialization;
using System.Xml;
using System.Xml.Linq;
using CE.db;
using CE.DomainConfig;
using CE.Utils;
using GamMatrixAPI;

public class GamMatrixClient : GmAPIRestClient
{
    private static readonly string DOMAIN_SESSION_CACHE_KEY_FORMAT = @"_domain_session_id_{0}";

    

    public T SingleRequest<T>(T request) where T : HandlerRequest
    {
        /*
        if (string.IsNullOrWhiteSpace(request.SESSION_ID))
            request.SESSION_ID = GamMatrixClient.GetSessionIDForCurrentOperator();
        if (CustomProfile.Current.IsAuthenticated && request.SESSION_USERID <= 0)
            request.SESSION_USERID = CustomProfile.Current.UserID;
            */
        return CheckResponse(base.SingleRequest(request)).Reply as T;
    }

    private ReplyResponse CheckResponse(ReplyResponse response)
    {
        if (!response.Success)
        {
            throw new GmException(response);
        }
        return response;
    }

    private string LoginSuperUser()
    {
        using (GmAPIRestClient client = new GmAPIRestClient())
        {
            var response = client.Login(new LoginRequest()
            {
                UserName = ConfigurationManager.AppSettings["GmCore.APIUsername"],
                PlainTextPassword = ConfigurationManager.AppSettings["GmCore.APIPassword"],
                SecurityToken = ConfigurationManager.AppSettings["GmCore.APISecurityToken"],
                Type = SessionType.System,
            });
            if (!response.Success)
            {
                throw new Exception(response.ErrorUserMessage);
            }
            return ((LoginRequest)response.Reply).UserProfile.SessionID;
        }
    }

    private void LogoffSuperUser(string sessionID)
    {
        using (GmAPIRestClient client = new GmAPIRestClient())
        {
            client.SingleRequest(new LogoutRequest()
            {
                SESSION_ID = sessionID,
                SESSION_USERID = int.Parse(ConfigurationManager.AppSettings["GmCore.APIUserID"]),
            });
        }
    }

    public static void NotifyGmCoreConfigurationChanged()
    {
        using (GamMatrixClient client = new GamMatrixClient())
        {
            client.SingleRequest<UpdateConfigNotificationRequest>( Constant.SystemDomainID
                , new UpdateConfigNotificationRequest() { Type = ConfigNotificationType.GameContributionProvider }
                );
        }
    }

    /// <summary>
    /// Get all currency rates
    /// </summary>
    /// <returns></returns>
    public static Dictionary<string, CurrencyExchangeRateRec> GetCurrencyRates(long domainID)
    {
        Dictionary<string, CurrencyExchangeRateRec> dic;
        string cacheKey = "__currency_rates_dictionary";
        dic = HttpRuntime.Cache[cacheKey] as Dictionary<string, CurrencyExchangeRateRec>;
        if (dic != null)
            return dic;

        lock (typeof(GetCurrencyRatesRequest))
        {
            dic = HttpRuntime.Cache[cacheKey] as Dictionary<string, CurrencyExchangeRateRec>;
            if (dic != null)
                return dic;

            dic = new Dictionary<string, CurrencyExchangeRateRec>(StringComparer.OrdinalIgnoreCase);
            using (GamMatrixClient client = new GamMatrixClient())
            {
                var list = client.SingleRequest<GetCurrencyRatesRequest>( Constant.SystemDomainID, new GetCurrencyRatesRequest() { }).Data;
                foreach (var item in list)
                {
                    dic[item.ISO4217_Alpha] = item;
                }
            }

            HttpRuntime.Cache.Insert(cacheKey
                , dic
                , null
                , DateTime.Now.AddHours(1)
                , Cache.NoSlidingExpiration
                );
        }
        return dic;
    }

    public static CurrencyData [] GetSupportedCurrencies()
    {
        const string CACHE_KEY = "__SupporttedCurrencies";
        CurrencyData[] currencies = HttpRuntime.Cache[CACHE_KEY] as CurrencyData[];
        if (currencies != null)
            return currencies;

        using (GamMatrixClient client = new GamMatrixClient())
        {
            GetSupportedCurrencyListRequest response = client.SingleRequest<GetSupportedCurrencyListRequest>( Constant.SystemDomainID
                , new GetSupportedCurrencyListRequest() );
            currencies = response.CurrencyData.ToArray();
        }
        
        HttpRuntime.Cache.Insert(CACHE_KEY
                , currencies
                , null
                , DateTime.Now.AddMinutes(15)
                , Cache.NoSlidingExpiration
                );
        return currencies;
    }

    public static decimal TransformCurrency(string sourceCurrency, string destCurrency, decimal amount)
    {
        if (string.Equals(sourceCurrency, destCurrency, StringComparison.OrdinalIgnoreCase))
            return amount;

        decimal transformed = amount;
        Dictionary<string, CurrencyExchangeRateRec> dic = GamMatrixClient.GetCurrencyRates(Constant.SystemDomainID);
        if (!string.Equals(sourceCurrency, "EUR", StringComparison.OrdinalIgnoreCase))
        {
            CurrencyExchangeRateRec rec = null;
            if (!dic.TryGetValue(sourceCurrency, out rec))
                throw new Exception("Unknown currency :" + sourceCurrency);
            transformed = amount / rec.MidRate;
        }

        if (!string.Equals(destCurrency, "EUR", StringComparison.OrdinalIgnoreCase))
        {
            CurrencyExchangeRateRec rec = null;
            if (!dic.TryGetValue(destCurrency, out rec))
                throw new Exception("Unknown currency :" + destCurrency);
            transformed = transformed * rec.MidRate;
        }
        return transformed;
    }




    #region operator special API
    [Serializable]
    public sealed class ApiParameters
    {
        public long SessionUserID { get; set; }
        public string SessionID { get; set; }
    }

    private ApiParameters RenewDomainParameters(long domainID)
    {
        var domains = DomainManager.GetDomains();
        var domain = domains.First(d => d.DomainID == domainID);
        using (GmAPIRestClient client = new GmAPIRestClient())
        {
            var response = client.Login(new LoginRequest()
            {
                UserName = domain.WcfApiUsername,
                PlainTextPassword = domain.WcfApiPassword,
                SecurityToken = domain.SecurityToken,
                Type = SessionType.User,
            });
            if (!response.Success)
            {
                throw new Exception(response.ErrorUserMessage);
            }
            ApiParameters apiParameters = new ApiParameters()
            {
                SessionUserID = ((LoginRequest)response.Reply).UserProfile.UserRec.ID,
                SessionID = ((LoginRequest)response.Reply).UserProfile.SessionID,
            };
            string filename = string.Format("{0}.sessionid", domainID);
            string cacheFilePath = Path.Combine(FileSystemUtility.GetWebSiteTempDirectory(), filename);
            try
            {
                using (FileStream fs = new FileStream(cacheFilePath
                    , FileMode.OpenOrCreate
                    , FileAccess.Write
                    , FileShare.ReadWrite | FileShare.Delete
                    ))
                {
                    fs.SetLength(0);
                    BinaryFormatter bf = new BinaryFormatter();
                    bf.Serialize(fs, apiParameters);
                    fs.Flush();
                }
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
            }

            string cacheKey = string.Format(DOMAIN_SESSION_CACHE_KEY_FORMAT, domainID);
            HttpRuntime.Cache[cacheKey] = apiParameters;
            return apiParameters;
        }
    }

    public ApiParameters GetApiParameters(long domainID, bool forceRegenerate)
    {
        ApiParameters apiParameters = null;
        if (!forceRegenerate)
        {
            string cacheKey = string.Format(DOMAIN_SESSION_CACHE_KEY_FORMAT, domainID);
            apiParameters = HttpRuntime.Cache[cacheKey] as ApiParameters;

            if (apiParameters == null)
            {
                if (domainID == Constant.SystemDomainID)
                {
                    apiParameters = new ApiParameters()
                    {
                        SessionID = LoginSuperUser(),
                        SessionUserID = int.Parse(ConfigurationManager.AppSettings["GmCore.APIUserID"]),
                    };
                }

                string filename = string.Format("{0}.sessionid", domainID);
                string cacheFilePath = Path.Combine(FileSystemUtility.GetWebSiteTempDirectory(), filename);
                if (File.Exists(cacheFilePath))
                {
                    using (FileStream fs = new FileStream(cacheFilePath
                    , FileMode.Open
                    , FileAccess.Read
                    , FileShare.ReadWrite | FileShare.Delete
                    ))
                    {
                        BinaryFormatter bf = new BinaryFormatter();
                        apiParameters = bf.Deserialize(fs) as ApiParameters;
                    }
                }
            }
        }

        if (apiParameters == null)
            apiParameters = RenewDomainParameters(domainID);

        return apiParameters;
    }

    public ApiParameters PrepareCommonParameters<T>(long domainID, T request, bool forceRegenerate) where T : HandlerRequest
    {
        ApiParameters apiParameters = GetApiParameters(domainID, forceRegenerate);

        try
        {
            request.SESSION_ID = apiParameters.SessionID;
            request.SESSION_USERID = apiParameters.SessionUserID;
            try
            {
                request.SESSION_USERIP = HttpContext.Current.Request.GetRealUserAddress();
            }
            catch
            {
            }
            return apiParameters;
        }
        catch (GmException gex)
        {
            if (string.Equals(gex.ReplyResponse.ErrorCode, "SYS_1010", StringComparison.InvariantCultureIgnoreCase))
            {
                apiParameters = RenewDomainParameters(domainID);
                request.SESSION_ID = apiParameters.SessionID;
                request.SESSION_USERID = apiParameters.SessionUserID;
                try
                {
                    request.SESSION_USERIP = HttpContext.Current.Request.GetRealUserAddress();
                }
                catch
                {
                }
                return apiParameters;
            }
            throw;
        }
    }


    public T SingleRequest<T>(long domainID, T request) where T : HandlerRequest
    {
        ApiParameters apiParameters = PrepareCommonParameters( domainID, request, false);
            
        try
        {
            return CheckResponse(base.SingleRequest(request)).Reply as T;
        }
        catch (GmException gex)
        {
            if (string.Equals(gex.ReplyResponse.ErrorCode, "SYS_1010", StringComparison.OrdinalIgnoreCase))
            {
                apiParameters = PrepareCommonParameters(domainID, request, true);
                return CheckResponse(base.SingleRequest(request)).Reply as T;
            }
            throw;
        }
        finally
        {
            if (domainID == Constant.SystemDomainID && apiParameters != null)
            {
                LogoffSuperUser(apiParameters.SessionID);
            }
        }
    }


    public List<HandlerRequest> ParallelMultiRequest(long domainID, List<HandlerRequest> requests)
    {
        string cacheKey = string.Format(DOMAIN_SESSION_CACHE_KEY_FORMAT, domainID);
        ApiParameters apiParameters = HttpRuntime.Cache[cacheKey] as ApiParameters;

        if (apiParameters == null)
        {
            if (domainID == Constant.SystemDomainID)
            {
                apiParameters = new ApiParameters()
                {
                    SessionID = LoginSuperUser(),
                    SessionUserID = int.Parse(ConfigurationManager.AppSettings["GmCore.APIUserID"]),
                };
            }

            string filename = string.Format("{0}.sessionid", domainID);
            string cacheFilePath = Path.Combine(FileSystemUtility.GetWebSiteTempDirectory(), filename);
            if (File.Exists(cacheFilePath))
            {
                using (FileStream fs = new FileStream(cacheFilePath
                , FileMode.Open
                , FileAccess.Read
                , FileShare.ReadWrite | FileShare.Delete
                ))
                {
                    BinaryFormatter bf = new BinaryFormatter();
                    apiParameters = bf.Deserialize(fs) as ApiParameters;
                }
            }
        }

        if (apiParameters == null)
            apiParameters = RenewDomainParameters(domainID);
        try
        {
            foreach( HandlerRequest request in requests)
            {
                request.SESSION_ID = apiParameters.SessionID;
                request.SESSION_USERID = apiParameters.SessionUserID;
                try
                {
                    request.SESSION_USERIP = HttpContext.Current.Request.GetRealUserAddress();
                }
                catch
                {
                }
            }
            List<ReplyResponse> replies = base.ParallelMultiRequest(requests);
            List<HandlerRequest> responses = new List<HandlerRequest>();
            foreach (ReplyResponse reply in replies)
            {
                if( reply.Success )
                    responses.Add(reply.Reply);
            }
            return responses;
        }
        finally
        {
            if (domainID == Constant.SystemDomainID && apiParameters != null)
            {
                LogoffSuperUser(apiParameters.SessionID);
            }
        }
    }
    #endregion

    //public static IPLocation GetIPLocation(string ip)
    //{
    //    try
    //    {
    //        string cacheKey = string.Format("GamMatrixClient.GetIPLocation({0})", ip);
    //        IPLocation ipLocation = HttpRuntime.Cache[cacheKey] as IPLocation;
    //        if (ipLocation != null)
    //            return ipLocation;

    //        using (GamMatrixClient client = new GamMatrixClient())
    //        {
    //            IP2LocationRequest response = client.SingleRequest<IP2LocationRequest>(new IP2LocationRequest()
    //            {
    //                UserIP = ip,
    //            });
    //            if (response.Data != null && response.Data.Count > 0)
    //            {
    //                ipLocation = new IPLocation()
    //                {
    //                    Found = true,
    //                    IP = ip,
    //                };
    //                double temp;
    //                if (double.TryParse(response.Data["Latitude"], out temp))
    //                    ipLocation.Latitude = temp;
    //                if (double.TryParse(response.Data["Longitude"], out temp))
    //                    ipLocation.Longitude = temp;

    //                string val;
    //                if (response.Data.TryGetValue("MetroCode", out val))
    //                    ipLocation.MetroCode = val;
    //                if (response.Data.TryGetValue("RegionCode", out val))
    //                    ipLocation.RegionCode = val;
    //                if (response.Data.TryGetValue("RegionName", out val))
    //                    ipLocation.RegionName = val;
    //                if (response.Data.TryGetValue("ZipCode", out val))
    //                    ipLocation.Zip = val;
    //                if (response.Data.TryGetValue("City", out val))
    //                    ipLocation.City = val;
    //                if (response.Data.TryGetValue("CountryCode", out val))
    //                    ipLocation.CountryCode = val;
    //                if (response.Data.TryGetValue("CountryName", out val))
    //                    ipLocation.CountryName = val;

    //                HttpRuntime.Cache.Insert(cacheKey, ipLocation, null, Cache.NoAbsoluteExpiration, new TimeSpan(0, 5, 0));

    //                return ipLocation;
    //            }
    //            return new IPLocation() { IP = ip, Found = false };
    //        }
    //    }
    //    catch(Exception ex)
    //    {
    //        ex.AppendToErrorLog();
    //        return new IPLocation() { IP = ip, Found = false };
    //    }
    //}
    #region API cross operators

    /// <summary>
    /// Get all NetEnt games
    /// </summary>
    /// <returns></returns>
    public static string[] GetNetEntGames(long domainID)
    {
        string filename = string.Format("GamMatrixClient.GetNetEntGames.{0}", domainID);
        string physicalPath = Path.Combine(FileSystemUtility.GetWebSiteTempDirectory(), filename);

        // try to get from cache
        string[] gameIDs = HttpRuntime.Cache[physicalPath] as string[];
        if (gameIDs != null)
            return gameIDs;

        // then check if it is avaliable in filecache
        if (File.Exists(physicalPath))
            gameIDs = ObjectHelper.BinaryDeserialize<string[]>(physicalPath, null);



        using (GamMatrixClient client = new GamMatrixClient())
        {
            NetEntAPIRequest request = new NetEntAPIRequest()
            {
                GetGameIds = true,
            };

            Func<NetEntAPIRequest, string, string[]> action = (NetEntAPIRequest req, string destPath) =>
            {
                try
                {
                    req = client.SingleRequest<NetEntAPIRequest>(domainID, req);

                    ObjectHelper.BinarySerialize<string[]>(req.GetGameIdsResponse.ToArray(), destPath);

                    HttpRuntime.Cache.Insert(destPath, req.GetGameIdsResponse, null, DateTime.Now.AddMinutes(10), Cache.NoSlidingExpiration);
                    return req.GetGameIdsResponse.ToArray();
                }
                catch (Exception ex)
                {
                    Logger.Exception(ex);
                }
                return new string[0];
            };

            Task<string[]> task = Task<string[]>.Factory.StartNew(() => action(request, physicalPath));

            // if it is null, wait for it
            if (gameIDs == null)
            {
                task.Wait();
                gameIDs = task.Result;
                //gameIDs = new string[0]; 
            }
            return gameIDs;
        }

    }

    /// <summary>
    /// Get the CTXM games
    /// </summary>
    /// <returns></returns>
    //public static GameType[] GetCTXMGames(long domainID)
    //{
    //    string filename = string.Format("GamMatrixClient.GetCTXMGames.{0}", domainID);
    //    string physicalPath = Path.Combine(FileSystemUtility.GetWebSiteTempDirectory(), filename);

    //    // try to get from cache
    //    GameType[] games = HttpRuntime.Cache[physicalPath] as GameType[];
    //    if (games != null)
    //        return games;

    //    // then check if it is avaliable in filecache
    //    if (File.Exists(physicalPath))
    //        games = ObjectHelper.BinaryDeserialize<GameType[]>(physicalPath, null);



    //    using (GamMatrixClient client = new GamMatrixClient())
    //    {
    //        CTXMAPIRequest request = new CTXMAPIRequest()
    //        {
    //            GetGameList = true,
    //            GetGameListLanguage = "en",
    //        };

    //        Func<CTXMAPIRequest, string, GameType[]> action = (CTXMAPIRequest req, string destPath) =>
    //        {
    //            try
    //            {
    //                req = client.SingleRequest<CTXMAPIRequest>(domainID, req);

    //                ObjectHelper.BinarySerialize<GameType[]>(req.GetGameListResponse.gamesField.ToArray(), destPath);

    //                HttpRuntime.Cache.Insert(destPath, req.GetGameListResponse.gamesField, null, DateTime.Now.AddMinutes(10), Cache.NoSlidingExpiration);
    //                return req.GetGameListResponse.gamesField.ToArray();
    //            }
    //            catch (Exception ex)
    //            {
    //                Logger.Exception(ex);
    //                return new GameType[0];
    //            }
    //        };

    //        Task<GameType[]> task = Task<GameType[]>.Factory.StartNew(() => action(request, physicalPath));

    //        // if it is null, wait for it
    //        if (games == null)
    //        {
    //            task.Wait();
    //            games = task.Result;
    //            //games = new GameType[0];
    //        }
    //        return games;
    //    }
    //}

    /// <summary>
    /// Get the CTXM games
    /// </summary>
    /// <returns></returns>
    public static Dictionary<int, string> GetGreenTubeGames(long domainID)
    {
        string filename = string.Format("GamMatrixClient.GetGreenTubeGames.{0}", domainID);
        string physicalPath = Path.Combine(FileSystemUtility.GetWebSiteTempDirectory(), filename);

        // try to get from cache
        Dictionary<int, string> games = HttpRuntime.Cache[physicalPath] as Dictionary<int, string>;
        if (games != null)
            return games;

        // then check if it is avaliable in filecache
        if (File.Exists(physicalPath))
            games = ObjectHelper.BinaryDeserialize<Dictionary<int, string>>(physicalPath, null);

        using (GamMatrixClient client = new GamMatrixClient())
        {
            GreenTubeAPIRequest request = new GreenTubeAPIRequest()
            {
                GetGameListRequest = new GreentubeGetGameListRequest()
                {
                    LanguageCode = "EN",
                }
            };

            Func<GreenTubeAPIRequest, string, Dictionary<int, string>> action = (GreenTubeAPIRequest req, string destPath) =>
            {
                Dictionary<int, string> dic = new Dictionary<int, string>();
                try
                {
                    req = client.SingleRequest<GreenTubeAPIRequest>(domainID, req);

                    if (req.GetGameListResponse.GameList != null &&
                        req.GetGameListResponse.GameList.Count > 0)
                    {
                        foreach (GameInfo game in req.GetGameListResponse.GameList)
                        {
                            dic[game.GameId] = game.GameName;
                        }

                        ObjectHelper.BinarySerialize<Dictionary<int, string>>(dic, destPath);
                        HttpRuntime.Cache.Insert(destPath, dic, null, DateTime.Now.AddMinutes(10), Cache.NoSlidingExpiration);
                    }
                    return dic;
                }
                catch (Exception ex)
                {
                    Logger.Exception(ex);
                    return dic;
                }
            };

            Task<Dictionary<int, string>> task = Task<Dictionary<int, string>>.Factory.StartNew(() => action(request, physicalPath));

            // if it is null, wait for it
            if (games == null)
            {
                task.Wait();
                games = task.Result;
            }
            return games;
        }
    }

    private static string GameListV2ByCE(string skinCode, string uri, string userName, string password)
    {
        Uri apiUri = new Uri(uri);

        string gameListV2MethodRequest = "gameListV2Request";
        string gameListV2MethodResponse = "gameListV2Response";

        XDocument xml = new XDocument(new XElement(gameListV2MethodRequest));
        xml.Element(gameListV2MethodRequest).Add(new XElement("skinCode", skinCode));

        string encodedCredentials = Convert.ToBase64String(ASCIIEncoding.ASCII.GetBytes(userName + ":" + password));

        NameValueCollection headers = new NameValueCollection
        {
            {"Content-Type", "application/xml"},
            {"Authorization", string.Format("Basic {0}", encodedCredentials)}
        };

        string response = HttpHelper.PostData(apiUri, xml.ToString(), headers);

        return response;
    }

    private static string GameListV3ByCE(string skinCode, string uri, string userName, string password)
    {
        Uri apiUri = new Uri(uri);

        string gameListV3MethodRequest = "gameListV3Request";
        string gameListV3MethodResponse = "gameListV3Response";

        XDocument xml = new XDocument(new XElement(gameListV3MethodRequest));
        xml.Element(gameListV3MethodRequest).Add(new XElement("skinCode", skinCode));

        string encodedCredentials = Convert.ToBase64String(ASCIIEncoding.ASCII.GetBytes(userName + ":" + password));

        NameValueCollection headers = new NameValueCollection
        {
            {"Content-Type", "application/xml"},
            {"Authorization", string.Format("Basic {0}", encodedCredentials)}
        };

        string response = HttpHelper.PostData(apiUri, xml.ToString(), headers);

        return response;
    }

    /// <summary>
    /// 
    /// </summary>
    /// <returns></returns>
    public static Dictionary<string, IGTIntegration.Game> GetIGTGames(long domainID, string skinCode = null, string uri = null, string userName = null, string password = null)
    {
        string filename = string.Format("GamMatrixClient.GetIGTGames.{0}", domainID);
        string physicalPath = Path.Combine(FileSystemUtility.GetWebSiteTempDirectory(), filename);

        // try to get from cache
        Dictionary<string, IGTIntegration.Game> games = HttpRuntime.Cache[physicalPath] as Dictionary<string, IGTIntegration.Game>;
        if (games != null)
            return games;

        // then check if it is avaliable in filecache
        if (File.Exists(physicalPath))
            games = ObjectHelper.BinaryDeserialize<Dictionary<string, IGTIntegration.Game>>(physicalPath, null);

        IGTAPIRequest request = new IGTAPIRequest()
        {
            GameListV2 = true,
        };

        Func<IGTAPIRequest, string, Dictionary<string, IGTIntegration.Game>> action = (IGTAPIRequest req, string destPath) =>
        {
            try
            {
                string xml;

                if (!string.IsNullOrWhiteSpace(userName) && !string.IsNullOrWhiteSpace(password) &&
                    !string.IsNullOrWhiteSpace(uri) && !string.IsNullOrWhiteSpace(skinCode))
                {
                    Logger.Information(string.Format("Tried to get IGT game list from CE by url:{0}", uri));
                    xml = uri.EndsWith("v3") ? GameListV3ByCE(skinCode, uri, userName, password) : GameListV2ByCE(skinCode, uri, userName, password);
                }
                else
                {
                    using (GamMatrixClient client = new GamMatrixClient())
                    {
                        req = client.SingleRequest<IGTAPIRequest>(domainID, req);
                    }

                    xml = req.GameListV2Response;
                }

                Dictionary<string, IGTIntegration.Game> igtGames =
                        new Dictionary<string, IGTIntegration.Game>(StringComparer.InvariantCultureIgnoreCase);

                #region XML
                /*
    string xml = @"<gameListV2Response>
<channels>
<channel code=""INT"">
    <game>
    <gameName>100,000 Pyramid</gameName>
    <gameDescription>SlotGame</gameDescription>
    <gameType>S</gameType>

    <url>/tc/game</url>
    <languageCodes>
        <languageCode value=""pl"" />
        <languageCode value=""hu"" />
        <languageCode value=""fi"" />
        <languageCode value=""ro"" />
        <languageCode value=""ja"" />
        <languageCode value=""es"" />

        <languageCode value=""en"" />
        <languageCode value=""sv"" />
        <languageCode value=""da"" />
        <languageCode value=""ru"" />
        <languageCode value=""de"" />
        <languageCode value=""it"" />
        <languageCode value=""el"" />
        <languageCode value=""pt"" />
        <languageCode value=""fr"" />

    </languageCodes>
    <softwareIds>
        <softwareId id=""200-1024-001"">
            <presentationTypes>
                <presentationType code=""FLSH"">
                <wndHeight>768</wndHeight>
                <wndWidth>1024</wndWidth>
                <currencies>

                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>0.15</maxBet>
                            </configuration>

                        </configurations>
                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>0.15</maxBet>

                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""NOK"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>

                            <maxBet>0.75</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""USD"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.01</denomAmount>

                            <minBet>0.01</minBet>
                            <maxBet>0.15</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""DKK"">
                        <configurations>
                            <configuration>

                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>0.75</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""SEK"">

                        <configurations>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>1.5</maxBet>
                            </configuration>
                        </configurations>

                    </currency>
                    <currency code=""ZAR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>0.75</maxBet>

                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""CZK"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>

                            <maxBet>1.5</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""CNY"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.05</denomAmount>

                            <minBet>0.05</minBet>
                            <maxBet>0.75</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""PLN"">
                        <configurations>
                            <configuration>

                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>0.75</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                </currencies>

                </presentationType>
            </presentationTypes>
        </softwareId>
    </softwareIds>
    </game>
    <game>
    <gameName>Power Blackjack</gameName>
    <gameDescription>TableGame-Blackjack</gameDescription>

    <gameType>T</gameType>
    <url>/game.do</url>
    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>
    <softwareIds>
        <softwareId id=""200-0078-001"">
            <presentationTypes>

                <presentationType code=""FLSH"">
                <wndHeight>690</wndHeight>
                <wndWidth>636</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>

                            <minBet>0.2</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>1000.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>100.0</denomAmount>
                            <minBet>100.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>

                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>

                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>100.0</denomAmount>
                            <minBet>100.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>

                            <minBet>0.5</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>1000.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>

                            <maxBet>1000.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>
        </softwareId>

    </softwareIds>
    </game>
    <game>
    <gameName>Elvis Multi-Strike</gameName>
    <gameDescription>SlotGame</gameDescription>
    <gameType>S</gameType>
    <url>/game.do</url>

    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>
    <softwareIds>
        <softwareId id=""200-0080-001"">
            <presentationTypes>
                <presentationType code=""FLSH"">
                <wndHeight>690</wndHeight>

                <wndWidth>636</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>

                            <maxBet>600.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>15.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>60.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>

                            <minBet>5.0</minBet>
                            <maxBet>1500.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>300.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>6.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>3000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>

                            <maxBet>150.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>3.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>30.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>

                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>60.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>3.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.02</denomAmount>

                            <minBet>0.02</minBet>
                            <maxBet>6.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>600.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>15.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>3000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>

                            <maxBet>150.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>30.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>1500.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>

                            <minBet>1.0</minBet>
                            <maxBet>300.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""USD"">
                        <configurations>
                            <configuration>

                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>6.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>

                            <maxBet>30.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>150.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>600.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>

                            <minBet>0.05</minBet>
                            <maxBet>15.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>3000.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.25</denomAmount>
                            <minBet>0.25</minBet>
                            <maxBet>75.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>1500.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>

                            <maxBet>300.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>3.0</maxBet>
                            </configuration>

                        </configurations>
                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>
        </softwareId>
    </softwareIds>
    </game>
    <game>

    <gameName>Cats</gameName>
    <gameDescription>SlotGame</gameDescription>
    <gameType>S</gameType>
    <url>/tc/game</url>
    <languageCodes>
        <languageCode value=""pl"" />
        <languageCode value=""hu"" />

        <languageCode value=""fi"" />
        <languageCode value=""ro"" />
        <languageCode value=""ja"" />
        <languageCode value=""es"" />
        <languageCode value=""en"" />
        <languageCode value=""sv"" />
        <languageCode value=""da"" />
        <languageCode value=""ru"" />
        <languageCode value=""de"" />

        <languageCode value=""it"" />
        <languageCode value=""el"" />
        <languageCode value=""pt"" />
        <languageCode value=""fr"" />
    </languageCodes>
    <softwareIds>
        <softwareId id=""200-1137-001"">
            <presentationTypes>
                <presentationType code=""FLSH"">

                <wndHeight>768</wndHeight>
                <wndWidth>1024</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.01</denomAmount>

                            <minBet>0.01</minBet>
                            <maxBet>0.3</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>

                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>0.3</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""USD"">

                        <configurations>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>0.3</maxBet>
                            </configuration>
                        </configurations>

                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>
        </softwareId>
    </softwareIds>
    </game>
    <game>
    <gameName>Wild Wolf</gameName>

    <gameDescription>SlotGame</gameDescription>
    <gameType>S</gameType>
    <url>/tc/game</url>
    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>
    <softwareIds>

        <softwareId id=""200-1140-001"">
            <presentationTypes>
                <presentationType code=""FLSH"">
                <wndHeight>768</wndHeight>
                <wndWidth>1024</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>

                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>0.4</maxBet>
                            </configuration>
                        </configurations>
                    </currency>

                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>0.4</maxBet>
                            </configuration>

                        </configurations>
                    </currency>
                    <currency code=""USD"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>0.4</maxBet>

                            </configuration>
                        </configurations>
                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>
        </softwareId>
        <softwareId id=""200-1140-011"">
            <presentationTypes>

                <presentationType code=""FLSH"">
                <wndHeight>768</wndHeight>
                <wndWidth>1024</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.01</denomAmount>

                            <minBet>0.01</minBet>
                            <maxBet>0.4</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>

                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>0.4</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""USD"">

                        <configurations>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>0.4</maxBet>
                            </configuration>
                        </configurations>

                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>
        </softwareId>
    </softwareIds>
    </game>
    <game>
    <gameName>Hi-Lo Classic</gameName>

    <gameDescription>NumbersGame</gameDescription>
    <gameType>S</gameType>
    <url>/game.do</url>
    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>
    <softwareIds>

        <softwareId id=""200-0055-002"">
            <presentationTypes>
                <presentationType code=""FLSH"">
                <wndHeight>690</wndHeight>
                <wndWidth>636</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>

                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>200.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>

                            <minBet>0.05</minBet>
                            <maxBet>5.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>20.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>

                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>

                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>20.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>200.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>

                            <minBet>0.05</minBet>
                            <maxBet>5.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>1000.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>

                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>

                        </configurations>
                    </currency>
                    <currency code=""USD"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>10.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>200.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>

                            <maxBet>5.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.25</denomAmount>
                            <minBet>0.25</minBet>
                            <maxBet>25.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>

                            <minBet>5.0</minBet>
                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>100.0</maxBet>

                            </configuration>
                        </configurations>
                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>
        </softwareId>
    </softwareIds>
    </game>

    <game>
    <gameName>White Orchid</gameName>
    <gameDescription>SlotGame</gameDescription>
    <gameType>S</gameType>
    <url>/game.do</url>
    <languageCodes>
        <languageCode value=""en"" />

    </languageCodes>
    <softwareIds>
        <softwareId id=""200-0114-001"">
            <presentationTypes>
                <presentationType code=""FLSH"">
                <wndHeight>690</wndHeight>
                <wndWidth>636</wndWidth>
                <currencies>

                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>800.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>20.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.2</denomAmount>

                            <minBet>0.2</minBet>
                            <maxBet>80.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>2000.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>400.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>8.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>

                            <maxBet>4000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>200.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>4.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>

                            <minBet>0.1</minBet>
                            <maxBet>40.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>

                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>80.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>

                            <maxBet>4.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>8.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>800.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>

                            <minBet>0.05</minBet>
                            <maxBet>20.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>4000.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>200.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>40.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>

                            <maxBet>2000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>400.0</maxBet>
                            </configuration>

                        </configurations>
                    </currency>
                    <currency code=""USD"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>8.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>40.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>200.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>

                            <maxBet>800.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>20.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>4000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.25</denomAmount>

                            <minBet>0.25</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>2000.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>400.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>4.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                </currencies>

                </presentationType>
            </presentationTypes>
        </softwareId>
    </softwareIds>
    </game>
    <game>
    <gameName>Multi-Hand Blackjack</gameName>
    <gameDescription>TableGame-Blackjack</gameDescription>

    <gameType>T</gameType>
    <url>/game.do</url>
    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>
    <softwareIds>
        <softwareId id=""200-0065-001"">
            <presentationTypes>

                <presentationType code=""FLSH"">
                <wndHeight>690</wndHeight>
                <wndWidth>636</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>

                            <minBet>0.2</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>1000.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>100.0</denomAmount>
                            <minBet>100.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>

                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>

                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>100.0</denomAmount>
                            <minBet>100.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>

                            <minBet>0.5</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>1000.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>

                            <maxBet>1000.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>
        </softwareId>

    </softwareIds>
    </game>
    <game>
    <gameName>Down the Hatch Hi-Lo</gameName>
    <gameDescription>NumbersGame</gameDescription>
    <gameType>S</gameType>
    <url>/game.do</url>

    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>
    <softwareIds>
        <softwareId id=""200-0054-002"">
            <presentationTypes>
                <presentationType code=""FLSH"">
                <wndHeight>690</wndHeight>

                <wndWidth>636</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>

                            <maxBet>200.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>5.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>20.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>

                            <minBet>5.0</minBet>
                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>100.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>

                            <maxBet>10.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>

                            <minBet>0.2</minBet>
                            <maxBet>20.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>200.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>5.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>

                            <maxBet>50.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>

                            <minBet>1.0</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""USD"">
                        <configurations>
                            <configuration>

                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>

                            <maxBet>50.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>200.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>5.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>

                            <minBet>10.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.25</denomAmount>
                            <minBet>0.25</minBet>
                            <maxBet>25.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                </currencies>

                </presentationType>
            </presentationTypes>
        </softwareId>
    </softwareIds>
    </game>
    <game>
    <gameName>Treasures of Troy</gameName>
    <gameDescription>SlotGame</gameDescription>

    <gameType>S</gameType>
    <url>/game.do</url>
    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>
    <softwareIds>
        <softwareId id=""200-0117-001"">
            <presentationTypes>

                <presentationType code=""FLSH"">
                <wndHeight>690</wndHeight>
                <wndWidth>636</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>2.0</denomAmount>

                            <minBet>2.0</minBet>
                            <maxBet>800.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>20.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>80.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>2000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>

                            <maxBet>400.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>8.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>4000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>

                            <minBet>0.5</minBet>
                            <maxBet>200.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>4.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>40.0</maxBet>
                            </configuration>
                        </configurations>

                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>80.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>4.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>8.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>

                            <maxBet>800.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>20.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>4000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>

                            <minBet>0.5</minBet>
                            <maxBet>200.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>40.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>2000.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>400.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""USD"">

                        <configurations>
                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>8.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>40.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>

                            <maxBet>200.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>800.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>20.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>

                            <minBet>10.0</minBet>
                            <maxBet>4000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.25</denomAmount>
                            <minBet>0.25</minBet>
                            <maxBet>100.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>2000.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>400.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>

                            <maxBet>4.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>
        </softwareId>

    </softwareIds>
    </game>
    <game>
    <gameName>Three Card Poker</gameName>
    <gameDescription>TableGame-ThreeCard</gameDescription>
    <gameType>T</gameType>
    <url>/game.do</url>

    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>
    <softwareIds>
        <softwareId id=""200-0071-001"">
            <presentationTypes>
                <presentationType code=""FLSH"">
                <wndHeight>690</wndHeight>

                <wndWidth>636</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>

                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>

                            <minBet>0.1</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>

                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>

                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>

                    <currency code=""USD"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>25.0</denomAmount>

                            <minBet>25.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>1000.0</maxBet>

                            </configuration>
                        </configurations>
                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>
        </softwareId>
    </softwareIds>
    </game>

    <game>
    <gameName>King Keno</gameName>
    <gameDescription>NumbersGame</gameDescription>
    <gameType>S</gameType>
    <url>/game.do</url>
    <languageCodes>
        <languageCode value=""en"" />

    </languageCodes>
    <softwareIds>
        <softwareId id=""200-0045-001"">
            <presentationTypes>
                <presentationType code=""FLSH"">
                <wndHeight>620</wndHeight>
                <wndWidth>640</wndWidth>
                <currencies>

                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>20.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>0.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.2</denomAmount>

                            <minBet>0.2</minBet>
                            <maxBet>2.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>50.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>

                            <maxBet>5.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>1.0</maxBet>
                            </configuration>

                        </configurations>
                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>2.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>20.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>0.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>

                            <maxBet>100.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>5.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>1.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>

                            <minBet>5.0</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>10.0</maxBet>

                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""USD"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>

                            <maxBet>1.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>5.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>20.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>

                            <minBet>0.05</minBet>
                            <maxBet>0.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>100.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.25</denomAmount>
                            <minBet>0.25</minBet>
                            <maxBet>2.5</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>

                            <maxBet>10.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>
        </softwareId>

    </softwareIds>
    </game>
    <game>
    <gameName>3 Wheel Roulette</gameName>
    <gameDescription>TableGame-Roulette</gameDescription>
    <gameType>T</gameType>
    <url>/game.do</url>

    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>
    <softwareIds>
        <softwareId id=""200-0084-001"">
            <presentationTypes>
                <presentationType code=""FLSH"">
                <wndHeight>690</wndHeight>

                <wndWidth>636</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>

                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>

                            <minBet>0.5</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>1000.0</maxBet>

                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>

                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>

                            <minBet>5.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>1000.0</maxBet>

                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""USD"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>

                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>

                            <minBet>1.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>

        </softwareId>
    </softwareIds>
    </game>
    <game>
    <gameName>Hi-Lo Techno</gameName>
    <gameDescription>NumbersGame</gameDescription>
    <gameType>S</gameType>

    <url>/game.do</url>
    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>
    <softwareIds>
        <softwareId id=""200-0056-002"">
            <presentationTypes>
                <presentationType code=""FLSH"">

                <wndHeight>690</wndHeight>
                <wndWidth>636</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>2.0</denomAmount>

                            <minBet>2.0</minBet>
                            <maxBet>200.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>5.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>20.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>

                            <maxBet>100.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>

                            <minBet>0.1</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>

                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>20.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>

                            <maxBet>200.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>5.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>

                            <minBet>0.5</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>10.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""USD"">

                        <configurations>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>

                            <maxBet>200.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>5.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.25</denomAmount>

                            <minBet>0.25</minBet>
                            <maxBet>25.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>500.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>
                        </configurations>

                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>
        </softwareId>
    </softwareIds>
    </game>
    <game>
    <gameName>Texas Hold em Bonus</gameName>

    <gameDescription>TableGame-Hold_em</gameDescription>
    <gameType>T</gameType>
    <url>/game.do</url>
    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>
    <softwareIds>

        <softwareId id=""200-0083-001"">
            <presentationTypes>
                <presentationType code=""FLSH"">
                <wndHeight>690</wndHeight>
                <wndWidth>636</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>

                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>

                            <minBet>5.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>1000.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>100.0</denomAmount>
                            <minBet>100.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>

                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                        </configurations>
                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>1000.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>100.0</denomAmount>
                            <minBet>100.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>

                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>

                            <minBet>1.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>

        </softwareId>
    </softwareIds>
    </game>
    <game>
    <gameName>Kitty Glitter</gameName>
    <gameDescription>SlotGame</gameDescription>
    <gameType>S</gameType>

    <url>/tc/game</url>
    <languageCodes>
        <languageCode value=""pl"" />
        <languageCode value=""hu"" />
        <languageCode value=""fi"" />
        <languageCode value=""ro"" />
        <languageCode value=""ja"" />
        <languageCode value=""es"" />

        <languageCode value=""en"" />
        <languageCode value=""sv"" />
        <languageCode value=""da"" />
        <languageCode value=""ru"" />
        <languageCode value=""de"" />
        <languageCode value=""it"" />
        <languageCode value=""el"" />
        <languageCode value=""pt"" />
        <languageCode value=""fr"" />

    </languageCodes>
    <softwareIds>
        <softwareId id=""200-1127-001"">
            <presentationTypes>
                <presentationType code=""FLSH"">
                <wndHeight>768</wndHeight>
                <wndWidth>1024</wndWidth>
                <currencies>

                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>1.5</maxBet>
                            </configuration>

                        </configurations>
                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>1.5</maxBet>

                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""USD"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>

                            <maxBet>1.5</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>
        </softwareId>

    </softwareIds>
    </game>
    <game>
    <gameName>Caribbean Stud Poker</gameName>
    <gameDescription>TableGame-Other</gameDescription>
    <gameType>T</gameType>
    <url>/game.do</url>

    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>
    <softwareIds>
        <softwareId id=""200-0021-001"">
            <presentationTypes>
                <presentationType code=""FLSH"">
                <wndHeight>620</wndHeight>

                <wndWidth>640</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>

                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>

                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>

                            <minBet>1.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>

        </softwareId>
    </softwareIds>
    </game>
    <game>
    <gameName>Cluedo - Who Won It?</gameName>
    <gameDescription>SlotGame</gameDescription>
    <gameType>S</gameType>

    <url>/game.do</url>
    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>
    <softwareIds>
        <softwareId id=""200-0063-001"">
            <presentationTypes>
                <presentationType code=""FLSH"">

                <wndHeight>690</wndHeight>
                <wndWidth>636</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>

                            <minBet>0.2</minBet>
                            <maxBet>15.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>75.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>0.75</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>1875.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>

                            <maxBet>7.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>150.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>20.0</denomAmount>
                            <minBet>20.0</minBet>
                            <maxBet>1500.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>

                            <minBet>0.05</minBet>
                            <maxBet>3.75</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>375.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>1.5</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>750.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>

                            <maxBet>37.5</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.01</denomAmount>

                            <minBet>0.01</minBet>
                            <maxBet>0.75</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>1.5</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>3.75</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>20.0</denomAmount>
                            <minBet>20.0</minBet>
                            <maxBet>1500.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>

                            <maxBet>7.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>375.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>1875.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.2</denomAmount>

                            <minBet>0.2</minBet>
                            <maxBet>15.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>150.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>750.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>37.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>

                            <maxBet>75.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""USD"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.1</denomAmount>

                            <minBet>0.1</minBet>
                            <maxBet>7.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>150.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>3.75</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>75.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>

                            <maxBet>0.75</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>1.5</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>20.0</denomAmount>
                            <minBet>20.0</minBet>
                            <maxBet>1500.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>

                            <minBet>0.5</minBet>
                            <maxBet>37.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>1875.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>750.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.25</denomAmount>
                            <minBet>0.25</minBet>
                            <maxBet>18.75</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>

                            <maxBet>375.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>
        </softwareId>

    </softwareIds>
    </game>
    <game>
    <gameName>Double Bonus Spin Roulette</gameName>
    <gameDescription>TableGame-Roulette</gameDescription>
    <gameType>T</gameType>
    <url>/game.do</url>

    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>
    <softwareIds>
        <softwareId id=""200-0073-001"">
            <presentationTypes>
                <presentationType code=""FLSH"">
                <wndHeight>690</wndHeight>

                <wndWidth>636</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>

                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>

                            <minBet>0.5</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>1000.0</maxBet>

                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>

                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>

                            <minBet>5.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>1000.0</maxBet>

                            </configuration>
                        </configurations>
                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>
        </softwareId>
    </softwareIds>
    </game>

    <game>
    <gameName>Blackjack</gameName>
    <gameDescription>TableGame-Blackjack</gameDescription>
    <gameType>T</gameType>
    <url>/game.do</url>
    <languageCodes>
        <languageCode value=""en"" />

    </languageCodes>
    <softwareIds>
        <softwareId id=""200-0067-001"">
            <presentationTypes>
                <presentationType code=""FLSH"">
                <wndHeight>690</wndHeight>
                <wndWidth>636</wndWidth>
                <currencies>

                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>25.0</denomAmount>

                            <minBet>25.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>1000.0</maxBet>

                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>

                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>

                            <minBet>1.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""USD"">
                        <configurations>
                            <configuration>

                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>

                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>

                </currencies>
                </presentationType>
            </presentationTypes>
        </softwareId>
    </softwareIds>
    </game>
    <game>
    <gameName>Capt. Quid's Treasure Quest</gameName>

    <gameDescription>SlotGame</gameDescription>
    <gameType>S</gameType>
    <url>/tc/game</url>
    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>
    <softwareIds>

        <softwareId id=""200-1095-001"">
            <presentationTypes>
                <presentationType code=""FLSH"">
                <wndHeight>768</wndHeight>
                <wndWidth>1024</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>

                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>0.15</maxBet>
                            </configuration>
                        </configurations>
                    </currency>

                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>0.15</maxBet>
                            </configuration>

                        </configurations>
                    </currency>
                    <currency code=""USD"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>0.15</maxBet>

                            </configuration>
                        </configurations>
                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>
        </softwareId>
    </softwareIds>
    </game>

    <game>
    <gameName>Wipeout</gameName>
    <gameDescription>SlotGame</gameDescription>
    <gameType>S</gameType>
    <url>/tc/game</url>
    <languageCodes>
        <languageCode value=""pl"" />

        <languageCode value=""hu"" />
        <languageCode value=""fi"" />
        <languageCode value=""ro"" />
        <languageCode value=""ja"" />
        <languageCode value=""es"" />
        <languageCode value=""en"" />
        <languageCode value=""sv"" />
        <languageCode value=""da"" />
        <languageCode value=""ru"" />

        <languageCode value=""de"" />
        <languageCode value=""it"" />
        <languageCode value=""el"" />
        <languageCode value=""pt"" />
        <languageCode value=""fr"" />
    </languageCodes>
    <softwareIds>
        <softwareId id=""200-1139-001"">
            <presentationTypes>

                <presentationType code=""FLSH"">
                <wndHeight>768</wndHeight>
                <wndWidth>1024</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.01</denomAmount>

                            <minBet>0.01</minBet>
                            <maxBet>0.1</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>

                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>0.1</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""USD"">

                        <configurations>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>0.1</maxBet>
                            </configuration>
                        </configurations>

                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>
        </softwareId>
    </softwareIds>
    </game>
    <game>
    <gameName>Jeopardy!</gameName>

    <gameDescription>SlotGame</gameDescription>
    <gameType>S</gameType>
    <url>/game.do</url>
    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>
    <softwareIds>

        <softwareId id=""200-0022-001"">
            <presentationTypes>
                <presentationType code=""FLSH"">
                <wndHeight>690</wndHeight>
                <wndWidth>636</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>

                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>90.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>

                            <minBet>0.05</minBet>
                            <maxBet>2.25</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>9.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>225.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>45.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>

                            <maxBet>0.9</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>22.5</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>0.45</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>

                            <minBet>0.1</minBet>
                            <maxBet>4.5</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>

                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>9.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>

                            <maxBet>0.45</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>0.9</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>90.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>

                            <minBet>0.05</minBet>
                            <maxBet>2.25</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>22.5</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>4.5</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>225.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>

                            <maxBet>45.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""USD"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.02</denomAmount>

                            <minBet>0.02</minBet>
                            <maxBet>0.9</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>4.5</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>22.5</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>90.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>

                            <maxBet>2.25</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.25</denomAmount>
                            <minBet>0.25</minBet>
                            <maxBet>11.25</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>225.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>

                            <minBet>1.0</minBet>
                            <maxBet>45.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>0.45</maxBet>

                            </configuration>
                        </configurations>
                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>
        </softwareId>
    </softwareIds>
    </game>

    <game>
    <gameName>Battleship: Search and Destroy</gameName>
    <gameDescription>SlotGame</gameDescription>
    <gameType>S</gameType>
    <url>/game.do</url>
    <languageCodes>
        <languageCode value=""en"" />

    </languageCodes>
    <softwareIds>
        <softwareId id=""200-0110-001"">
            <presentationTypes>
                <presentationType code=""FLSH"">
                <wndHeight>690</wndHeight>
                <wndWidth>636</wndWidth>
                <currencies>

                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>250.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>6.25</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.2</denomAmount>

                            <minBet>0.2</minBet>
                            <maxBet>25.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>625.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>125.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>2.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>

                            <maxBet>1250.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>62.5</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>1.25</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>

                            <minBet>0.1</minBet>
                            <maxBet>12.5</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>

                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>25.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>

                            <maxBet>1.25</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>2.5</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>250.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>

                            <minBet>0.05</minBet>
                            <maxBet>6.25</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>1250.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>62.5</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>12.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>

                            <maxBet>625.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>125.0</maxBet>
                            </configuration>

                        </configurations>
                    </currency>
                    <currency code=""USD"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>2.5</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>12.5</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>62.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>

                            <maxBet>250.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>6.25</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>1250.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.25</denomAmount>

                            <minBet>0.25</minBet>
                            <maxBet>31.25</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>625.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>125.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>1.25</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                </currencies>

                </presentationType>
            </presentationTypes>
        </softwareId>
    </softwareIds>
    </game>
    <game>
    <gameName>Cleopatra</gameName>
    <gameDescription>SlotGame</gameDescription>

    <gameType>S</gameType>
    <url>/game.do</url>
    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>
    <softwareIds>
        <softwareId id=""200-0077-001"">
            <presentationTypes>

                <presentationType code=""FLSH"">
                <wndHeight>690</wndHeight>
                <wndWidth>636</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>2.0</denomAmount>

                            <minBet>2.0</minBet>
                            <maxBet>200.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>5.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>20.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>

                            <maxBet>100.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>2.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>

                            <minBet>0.5</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>1.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>
                        </configurations>

                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>20.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>1.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>2.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>

                            <maxBet>200.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>5.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>

                            <minBet>0.5</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>10.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""USD"">

                        <configurations>
                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>2.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>

                            <maxBet>50.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>200.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>5.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>

                            <minBet>10.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.25</denomAmount>
                            <minBet>0.25</minBet>
                            <maxBet>25.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>

                            <maxBet>1.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>
        </softwareId>

    </softwareIds>
    </game>
    <game>
    <gameName>Wheel of Fortune Triple Action Frenzy</gameName>
    <gameDescription>SlotGame</gameDescription>
    <gameType>S</gameType>
    <url>/game.do</url>

    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>
    <softwareIds>
        <softwareId id=""200-0075-001"">
            <presentationTypes>
                <presentationType code=""FLSH"">
                <wndHeight>690</wndHeight>

                <wndWidth>636</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>

                            <maxBet>90.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>2.25</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>9.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>

                            <minBet>5.0</minBet>
                            <maxBet>225.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>45.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>0.9</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>450.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>

                            <maxBet>22.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>0.45</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>4.5</maxBet>
                            </configuration>
                        </configurations>
                    </currency>

                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>9.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>0.45</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.02</denomAmount>

                            <minBet>0.02</minBet>
                            <maxBet>0.9</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>90.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>2.25</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>450.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>

                            <maxBet>22.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>4.5</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>225.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>

                            <minBet>1.0</minBet>
                            <maxBet>45.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""USD"">
                        <configurations>
                            <configuration>

                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>0.9</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>

                            <maxBet>4.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>22.5</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>90.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>

                            <minBet>0.05</minBet>
                            <maxBet>2.25</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>450.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.25</denomAmount>
                            <minBet>0.25</minBet>
                            <maxBet>11.25</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>225.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>

                            <maxBet>45.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>0.45</maxBet>
                            </configuration>

                        </configurations>
                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>
        </softwareId>
    </softwareIds>
    </game>
    <game>

    <gameName>Wheel of Fortune Hollywood</gameName>
    <gameDescription>SlotGame</gameDescription>
    <gameType>S</gameType>
    <url>/game.do</url>
    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>

    <softwareIds>
        <softwareId id=""200-0020-001"">
            <presentationTypes>
                <presentationType code=""FLSH"">
                <wndHeight>720</wndHeight>
                <wndWidth>640</wndWidth>
                <currencies>
                    <currency code=""GBP"">

                        <configurations>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>90.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>2.25</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>

                            <maxBet>9.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>225.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>45.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.02</denomAmount>

                            <minBet>0.02</minBet>
                            <maxBet>0.9</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>450.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>22.5</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>0.45</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>

                            <maxBet>4.5</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>

                            <minBet>0.2</minBet>
                            <maxBet>9.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>0.45</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>0.9</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>90.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>

                            <maxBet>2.25</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>450.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>22.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>

                            <minBet>0.1</minBet>
                            <maxBet>4.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>225.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>45.0</maxBet>
                            </configuration>
                        </configurations>

                    </currency>
                    <currency code=""USD"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>0.9</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>4.5</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>22.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>

                            <maxBet>90.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>2.25</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>450.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.25</denomAmount>

                            <minBet>0.25</minBet>
                            <maxBet>11.25</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>225.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>45.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>0.45</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                </currencies>

                </presentationType>
            </presentationTypes>
        </softwareId>
    </softwareIds>
    </game>
    <game>
    <gameName>Goal! Three 2 Win</gameName>
    <gameDescription>NumbersGame</gameDescription>

    <gameType>S</gameType>
    <url>/game.do</url>
    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>
    <softwareIds>
        <softwareId id=""200-0032-101"">
            <presentationTypes>

                <presentationType code=""FLSH"">
                <wndHeight>690</wndHeight>
                <wndWidth>636</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.05</denomAmount>

                            <minBet>0.05</minBet>
                            <maxBet>0.05</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>0.2</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>1.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>0.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>

                            <maxBet>0.1</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>

                            <minBet>0.2</minBet>
                            <maxBet>0.2</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>0.05</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>0.5</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>0.1</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>

                            <maxBet>1.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""USD"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.1</denomAmount>

                            <minBet>0.1</minBet>
                            <maxBet>0.1</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>0.5</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>0.05</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.25</denomAmount>
                            <minBet>0.25</minBet>
                            <maxBet>0.25</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>

                            <maxBet>1.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>
        </softwareId>

    </softwareIds>
    </game>
    <game>
    <gameName>Multi-Hand Blackjack with 1000x Bonus</gameName>
    <gameDescription>TableGame-Blackjack</gameDescription>
    <gameType>T</gameType>
    <url>/game.do</url>

    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>
    <softwareIds>
        <softwareId id=""200-0035-001"">
            <presentationTypes>
                <presentationType code=""FLSH"">
                <wndHeight>620</wndHeight>

                <wndWidth>640</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>

                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>20.0</denomAmount>
                            <minBet>20.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.2</denomAmount>

                            <minBet>0.2</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>50.0</denomAmount>
                            <minBet>50.0</minBet>
                            <maxBet>1000.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>

                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>

                            <minBet>0.1</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>

                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>

                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>20.0</denomAmount>

                            <minBet>20.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>1000.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>50.0</denomAmount>
                            <minBet>50.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>

                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>

                </currencies>
                </presentationType>
            </presentationTypes>
        </softwareId>
    </softwareIds>
    </game>
    <game>
    <gameName>Lucky Draw Joker Poker</gameName>

    <gameDescription>VideoPoker</gameDescription>
    <gameType>S</gameType>
    <url>/game.do</url>
    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>
    <softwareIds>

        <softwareId id=""200-0005-401"">
            <presentationTypes>
                <presentationType code=""FLSH"">
                <wndHeight>740</wndHeight>
                <wndWidth>636</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>

                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>40.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>20.0</denomAmount>

                            <minBet>20.0</minBet>
                            <maxBet>400.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>1.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>4.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>

                            <maxBet>20.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>200.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>25.0</denomAmount>

                            <minBet>25.0</minBet>
                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>2.0</maxBet>

                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>

                            <maxBet>4.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>40.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>1.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>

                            <minBet>10.0</minBet>
                            <maxBet>200.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>20.0</denomAmount>
                            <minBet>20.0</minBet>
                            <maxBet>400.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>2.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>

                            <maxBet>100.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>500.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>20.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>

                    <currency code=""USD"">
                        <configurations>
                            <configuration>
                            <denomAmount>20.0</denomAmount>
                            <minBet>20.0</minBet>
                            <maxBet>400.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>2.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>

                            <minBet>0.5</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>40.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>1.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>

                            <maxBet>200.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.25</denomAmount>
                            <minBet>0.25</minBet>
                            <maxBet>5.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>

                            <minBet>1.0</minBet>
                            <maxBet>20.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>

        </softwareId>
    </softwareIds>
    </game>
    <game>
    <gameName>Baccarat</gameName>
    <gameDescription>TableGame-Other</gameDescription>
    <gameType>T</gameType>

    <url>/game.do</url>
    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>
    <softwareIds>
        <softwareId id=""200-0012-001"">
            <presentationTypes>
                <presentationType code=""FLSH"">

                <wndHeight>620</wndHeight>
                <wndWidth>640</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>2.0</denomAmount>

                            <minBet>2.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>20.0</denomAmount>
                            <minBet>20.0</minBet>
                            <maxBet>1000.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>50.0</denomAmount>
                            <minBet>50.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>

                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>100.0</denomAmount>
                            <minBet>100.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>

                            <minBet>10.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>1000.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                        </configurations>

                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>1000.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>100.0</denomAmount>
                            <minBet>100.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>

                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>20.0</denomAmount>
                            <minBet>20.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>50.0</denomAmount>

                            <minBet>50.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>1000.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                </currencies>

                </presentationType>
            </presentationTypes>
        </softwareId>
    </softwareIds>
    </game>
    <game>
    <gameName>Underground Hi-Lo</gameName>
    <gameDescription>NumbersGame</gameDescription>

    <gameType>S</gameType>
    <url>/game.do</url>
    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>
    <softwareIds>
        <softwareId id=""200-0034-001"">
            <presentationTypes>

                <presentationType code=""FLSH"">
                <wndHeight>690</wndHeight>
                <wndWidth>636</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>2.0</denomAmount>

                            <minBet>2.0</minBet>
                            <maxBet>200.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>5.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>20.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>

                            <maxBet>100.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>

                            <minBet>0.1</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>

                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>20.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>

                            <maxBet>200.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>5.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>

                            <minBet>0.5</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>10.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""USD"">

                        <configurations>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>

                            <maxBet>200.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>5.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.25</denomAmount>

                            <minBet>0.25</minBet>
                            <maxBet>25.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>500.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>
                        </configurations>

                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>
        </softwareId>
    </softwareIds>
    </game>
    <game>
    <gameName>Krazy Keno Superball</gameName>

    <gameDescription>NumbersGame</gameDescription>
    <gameType>S</gameType>
    <url>/game.do</url>
    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>
    <softwareIds>

        <softwareId id=""200-0006-001"">
            <presentationTypes>
                <presentationType code=""FLSH"">
                <wndHeight>740</wndHeight>
                <wndWidth>636</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>

                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>8.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>20.0</denomAmount>

                            <minBet>20.0</minBet>
                            <maxBet>80.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>0.2</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>0.8</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>20.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>

                            <maxBet>4.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>40.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>2.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>25.0</denomAmount>

                            <minBet>25.0</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>0.4</maxBet>

                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>

                            <maxBet>0.8</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>8.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>0.2</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>

                            <minBet>10.0</minBet>
                            <maxBet>40.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>20.0</denomAmount>
                            <minBet>20.0</minBet>
                            <maxBet>80.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>2.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>0.4</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>

                            <maxBet>20.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>4.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>

                    <currency code=""USD"">
                        <configurations>
                            <configuration>
                            <denomAmount>20.0</denomAmount>
                            <minBet>20.0</minBet>
                            <maxBet>80.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>0.4</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>

                            <minBet>0.5</minBet>
                            <maxBet>2.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>8.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>0.2</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>

                            <maxBet>40.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.25</denomAmount>
                            <minBet>0.25</minBet>
                            <maxBet>1.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>20.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>

                            <minBet>1.0</minBet>
                            <maxBet>4.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>

        </softwareId>
    </softwareIds>
    </game>
    <game>
    <gameName>Craps</gameName>
    <gameDescription>TableGame-Other</gameDescription>
    <gameType>T</gameType>

    <url>/game.do</url>
    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>
    <softwareIds>
        <softwareId id=""200-0013-003"">
            <presentationTypes>
                <presentationType code=""FLSH"">

                <wndHeight>620</wndHeight>
                <wndWidth>640</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>2.0</denomAmount>

                            <minBet>2.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>20.0</denomAmount>
                            <minBet>20.0</minBet>
                            <maxBet>1000.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>50.0</denomAmount>
                            <minBet>50.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>

                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>100.0</denomAmount>
                            <minBet>100.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>

                            <minBet>10.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>1000.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                        </configurations>

                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>1000.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>100.0</denomAmount>
                            <minBet>100.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>

                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>20.0</denomAmount>
                            <minBet>20.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>50.0</denomAmount>

                            <minBet>50.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>1000.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                </currencies>

                </presentationType>
            </presentationTypes>
        </softwareId>
    </softwareIds>
    </game>
    <game>
    <gameName>Roulette - Classic</gameName>
    <gameDescription>TableGame-Roulette</gameDescription>

    <gameType>T</gameType>
    <url>/game.do</url>
    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>
    <softwareIds>
        <softwareId id=""200-0011-101"">
            <presentationTypes>

                <presentationType code=""FLSH"">
                <wndHeight>620</wndHeight>
                <wndWidth>640</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>2.0</denomAmount>

                            <minBet>2.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>20.0</denomAmount>
                            <minBet>20.0</minBet>
                            <maxBet>1000.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>50.0</denomAmount>
                            <minBet>50.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>

                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>100.0</denomAmount>
                            <minBet>100.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>

                            <minBet>10.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>1000.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                        </configurations>

                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>1000.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>100.0</denomAmount>
                            <minBet>100.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>

                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>20.0</denomAmount>
                            <minBet>20.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>50.0</denomAmount>

                            <minBet>50.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>1000.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                </currencies>

                </presentationType>
            </presentationTypes>
        </softwareId>
    </softwareIds>
    </game>
    <game>
    <gameName>Monopoly On a Roll</gameName>
    <gameDescription>NumbersGame</gameDescription>

    <gameType>T</gameType>
    <url>/game.do</url>
    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>
    <softwareIds>
        <softwareId id=""200-0044-001"">
            <presentationTypes>

                <presentationType code=""FLSH"">
                <wndHeight>690</wndHeight>
                <wndWidth>636</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>2.0</denomAmount>

                            <minBet>2.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>1000.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>50.0</denomAmount>
                            <minBet>50.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>

                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>100.0</denomAmount>
                            <minBet>100.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>

                            <minBet>10.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>1000.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                        </configurations>

                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>1000.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>100.0</denomAmount>
                            <minBet>100.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>

                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>50.0</denomAmount>

                            <minBet>50.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>1000.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                </currencies>

                </presentationType>
            </presentationTypes>
        </softwareId>
    </softwareIds>
    </game>
    <game>
    <gameName>Da Vinci Diamonds</gameName>
    <gameDescription>SlotGame</gameDescription>

    <gameType>S</gameType>
    <url>/tc/game</url>
    <languageCodes>
        <languageCode value=""pl"" />
        <languageCode value=""hu"" />
        <languageCode value=""fi"" />
        <languageCode value=""ro"" />
        <languageCode value=""ja"" />

        <languageCode value=""es"" />
        <languageCode value=""en"" />
        <languageCode value=""sv"" />
        <languageCode value=""da"" />
        <languageCode value=""ru"" />
        <languageCode value=""de"" />
        <languageCode value=""it"" />
        <languageCode value=""el"" />
        <languageCode value=""pt"" />

        <languageCode value=""fr"" />
    </languageCodes>
    <softwareIds>
        <softwareId id=""200-1100-001"">
            <presentationTypes>
                <presentationType code=""FLSH"">
                <wndHeight>768</wndHeight>
                <wndWidth>1024</wndWidth>

                <currencies>
                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>0.2</maxBet>

                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>

                            <maxBet>0.2</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""USD"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.01</denomAmount>

                            <minBet>0.01</minBet>
                            <maxBet>0.2</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>

        </softwareId>
    </softwareIds>
    </game>
    <game>
    <gameName>Arabian Riches</gameName>
    <gameDescription>SlotGame</gameDescription>
    <gameType>S</gameType>

    <url>/game.do</url>
    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>
    <softwareIds>
        <softwareId id=""200-0004-001"">
            <presentationTypes>
                <presentationType code=""FLSH"">

                <wndHeight>740</wndHeight>
                <wndWidth>636</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>

                            <minBet>0.2</minBet>
                            <maxBet>0.6</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>3.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>100.0</denomAmount>
                            <minBet>100.0</minBet>
                            <maxBet>300.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>0.03</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>

                            <maxBet>75.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>0.3</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>6.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>20.0</denomAmount>

                            <minBet>20.0</minBet>
                            <maxBet>60.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>0.15</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>50.0</denomAmount>
                            <minBet>50.0</minBet>
                            <maxBet>150.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>15.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>

                            <maxBet>0.06</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>30.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>1.5</maxBet>
                            </configuration>
                        </configurations>
                    </currency>

                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>0.03</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>100.0</denomAmount>
                            <minBet>100.0</minBet>
                            <maxBet>300.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.02</denomAmount>

                            <minBet>0.02</minBet>
                            <maxBet>0.06</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>0.15</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>20.0</denomAmount>
                            <minBet>20.0</minBet>
                            <maxBet>60.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>0.3</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>

                            <maxBet>15.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>75.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>0.6</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>

                            <minBet>2.0</minBet>
                            <maxBet>6.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>30.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>1.5</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>50.0</denomAmount>
                            <minBet>50.0</minBet>
                            <maxBet>150.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>

                            <maxBet>3.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""USD"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.1</denomAmount>

                            <minBet>0.1</minBet>
                            <maxBet>0.3</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>6.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>0.15</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>3.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>

                            <maxBet>0.03</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>0.06</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>20.0</denomAmount>
                            <minBet>20.0</minBet>
                            <maxBet>60.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>

                            <minBet>0.5</minBet>
                            <maxBet>1.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>100.0</denomAmount>
                            <minBet>100.0</minBet>
                            <maxBet>300.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>75.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>30.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.25</denomAmount>
                            <minBet>0.25</minBet>

                            <maxBet>0.75</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>15.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>50.0</denomAmount>
                            <minBet>50.0</minBet>
                            <maxBet>150.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>

                </currencies>
                </presentationType>
            </presentationTypes>
        </softwareId>
    </softwareIds>
    </game>
    <game>
    <gameName>Super Hoot Loot</gameName>

    <gameDescription>SlotGame</gameDescription>
    <gameType>S</gameType>
    <url>/game.do</url>
    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>
    <softwareIds>

        <softwareId id=""200-0107-001"">
            <presentationTypes>
                <presentationType code=""FLSH"">
                <wndHeight>690</wndHeight>
                <wndWidth>636</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>

                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>400.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>

                            <minBet>0.05</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>40.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>200.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>

                            <maxBet>4.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>2000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.01</denomAmount>

                            <minBet>0.01</minBet>
                            <maxBet>2.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>20.0</maxBet>

                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>

                            <maxBet>40.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>2.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>4.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>

                            <minBet>2.0</minBet>
                            <maxBet>400.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>10.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>2000.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>

                            <maxBet>20.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>200.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>

                    <currency code=""USD"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>4.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>20.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>

                            <minBet>0.5</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>400.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>2000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.25</denomAmount>
                            <minBet>0.25</minBet>

                            <maxBet>50.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>200.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.01</denomAmount>

                            <minBet>0.01</minBet>
                            <maxBet>2.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>

        </softwareId>
    </softwareIds>
    </game>
    <game>
    <gameName>Bananarama Match 3</gameName>
    <gameDescription>NumbersGame</gameDescription>
    <gameType>S</gameType>

    <url>/game.do</url>
    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>
    <softwareIds>
        <softwareId id=""200-0029-101"">
            <presentationTypes>
                <presentationType code=""FLSH"">

                <wndHeight>690</wndHeight>
                <wndWidth>636</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.05</denomAmount>

                            <minBet>0.05</minBet>
                            <maxBet>0.05</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>0.2</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>1.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>0.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>

                            <maxBet>0.1</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>

                            <minBet>0.2</minBet>
                            <maxBet>0.2</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>0.05</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>0.5</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>0.1</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>

                            <maxBet>1.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""USD"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.1</denomAmount>

                            <minBet>0.1</minBet>
                            <maxBet>0.1</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>0.5</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>0.05</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.25</denomAmount>
                            <minBet>0.25</minBet>
                            <maxBet>0.25</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>

                            <maxBet>1.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>
        </softwareId>

    </softwareIds>
    </game>
    <game>
    <gameName>Roulette with 2 Zeros - Classic</gameName>
    <gameDescription>TableGame-Roulette</gameDescription>
    <gameType>T</gameType>
    <url>/game.do</url>

    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>
    <softwareIds>
        <softwareId id=""200-0011-001"">
            <presentationTypes>
                <presentationType code=""FLSH"">
                <wndHeight>620</wndHeight>

                <wndWidth>640</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>

                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>20.0</denomAmount>
                            <minBet>20.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>50.0</denomAmount>

                            <minBet>50.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>1000.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>100.0</denomAmount>
                            <minBet>100.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>

                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>

                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>100.0</denomAmount>
                            <minBet>100.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>

                            <minBet>2.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>1000.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>20.0</denomAmount>
                            <minBet>20.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>50.0</denomAmount>
                            <minBet>50.0</minBet>

                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>

                            <minBet>1.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>

        </softwareId>
    </softwareIds>
    </game>
    <game>
    <gameName>Da Vinci Diamonds</gameName>
    <gameDescription>SlotGame</gameDescription>
    <gameType>S</gameType>

    <url>/game.do</url>
    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>
    <softwareIds>
        <softwareId id=""200-0100-001"">
            <presentationTypes>
                <presentationType code=""FLSH"">

                <wndHeight>690</wndHeight>
                <wndWidth>636</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>2.0</denomAmount>

                            <minBet>2.0</minBet>
                            <maxBet>200.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>5.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>20.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>

                            <maxBet>100.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>2.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>

                            <minBet>0.5</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>1.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>
                        </configurations>

                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>20.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>1.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>2.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>

                            <maxBet>200.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>5.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>

                            <minBet>0.5</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>10.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""USD"">

                        <configurations>
                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>2.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>

                            <maxBet>50.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>200.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>5.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>

                            <minBet>10.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.25</denomAmount>
                            <minBet>0.25</minBet>
                            <maxBet>25.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>

                            <maxBet>1.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>
        </softwareId>

    </softwareIds>
    </game>
    <game>
    <gameName>Krazy Hi-Lo</gameName>
    <gameDescription>NumbersGame</gameDescription>
    <gameType>S</gameType>
    <url>/game.do</url>

    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>
    <softwareIds>
        <softwareId id=""200-0030-001"">
            <presentationTypes>
                <presentationType code=""FLSH"">
                <wndHeight>690</wndHeight>

                <wndWidth>636</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>

                            <maxBet>200.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>5.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>20.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>

                            <minBet>5.0</minBet>
                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>100.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>

                            <maxBet>10.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>

                            <minBet>0.2</minBet>
                            <maxBet>20.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>200.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>5.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>

                            <maxBet>50.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>

                            <minBet>1.0</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""USD"">
                        <configurations>
                            <configuration>

                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>

                            <maxBet>50.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>200.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>5.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>

                            <minBet>10.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.25</denomAmount>
                            <minBet>0.25</minBet>
                            <maxBet>25.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                </currencies>

                </presentationType>
            </presentationTypes>
        </softwareId>
    </softwareIds>
    </game>
    <game>
    <gameName>Three Card 2nd Chance</gameName>
    <gameDescription>TableGame-ThreeCard</gameDescription>

    <gameType>T</gameType>
    <url>/game.do</url>
    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>
    <softwareIds>
        <softwareId id=""200-0101-001"">
            <presentationTypes>

                <presentationType code=""FLSH"">
                <wndHeight>690</wndHeight>
                <wndWidth>636</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>5.0</denomAmount>

                            <minBet>5.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>1000.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>100.0</denomAmount>
                            <minBet>100.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>

                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                        </configurations>
                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>100.0</denomAmount>
                            <minBet>100.0</minBet>
                            <maxBet>1000.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>

                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>

                </currencies>
                </presentationType>
            </presentationTypes>
        </softwareId>
    </softwareIds>
    </game>
    <game>
    <gameName>Lil' Lady</gameName>

    <gameDescription>SlotGame</gameDescription>
    <gameType>S</gameType>
    <url>/game.do</url>
    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>
    <softwareIds>

        <softwareId id=""200-0104-001"">
            <presentationTypes>
                <presentationType code=""FLSH"">
                <wndHeight>690</wndHeight>
                <wndWidth>636</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>

                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>400.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>

                            <minBet>0.05</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>40.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>200.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>

                            <maxBet>4.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>2000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.01</denomAmount>

                            <minBet>0.01</minBet>
                            <maxBet>2.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>20.0</maxBet>

                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>

                            <maxBet>40.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>2.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>4.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>

                            <minBet>2.0</minBet>
                            <maxBet>400.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>10.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>2000.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>

                            <maxBet>20.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>200.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>

                    <currency code=""USD"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>4.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>20.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>

                            <minBet>0.5</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>400.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>2000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.25</denomAmount>
                            <minBet>0.25</minBet>

                            <maxBet>50.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>200.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.01</denomAmount>

                            <minBet>0.01</minBet>
                            <maxBet>2.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>

        </softwareId>
    </softwareIds>
    </game>
    <game>
    <gameName>Mels Hi-Lo Golf</gameName>
    <gameDescription>NumbersGame</gameDescription>
    <gameType>S</gameType>

    <url>/game.do</url>
    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>
    <softwareIds>
        <softwareId id=""200-0047-002"">
            <presentationTypes>
                <presentationType code=""FLSH"">

                <wndHeight>690</wndHeight>
                <wndWidth>636</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>2.0</denomAmount>

                            <minBet>2.0</minBet>
                            <maxBet>200.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>5.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>20.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>

                            <maxBet>100.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>

                            <minBet>0.1</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>

                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>20.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>

                            <maxBet>200.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>5.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>

                            <minBet>0.5</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>10.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""USD"">

                        <configurations>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>

                            <maxBet>200.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>5.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.25</denomAmount>

                            <minBet>0.25</minBet>
                            <maxBet>25.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>500.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>
                        </configurations>

                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>
        </softwareId>
    </softwareIds>
    </game>
    <game>
    <gameName>Enchanted Unicorn</gameName>

    <gameDescription>SlotGame</gameDescription>
    <gameType>S</gameType>
    <url>/game.do</url>
    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>
    <softwareIds>

        <softwareId id=""200-0081-001"">
            <presentationTypes>
                <presentationType code=""FLSH"">
                <wndHeight>690</wndHeight>
                <wndWidth>636</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>

                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>200.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>

                            <minBet>0.05</minBet>
                            <maxBet>5.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>20.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>

                            <maxBet>2.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>1.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>

                            <minBet>0.1</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>

                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>20.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>

                            <maxBet>1.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>2.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>200.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>

                            <minBet>0.05</minBet>
                            <maxBet>5.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>50.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>

                            <maxBet>100.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""USD"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.02</denomAmount>

                            <minBet>0.02</minBet>
                            <maxBet>2.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>10.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>200.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>

                            <maxBet>5.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.25</denomAmount>
                            <minBet>0.25</minBet>
                            <maxBet>25.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>

                            <minBet>1.0</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>1.0</maxBet>

                            </configuration>
                        </configurations>
                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>
        </softwareId>
    </softwareIds>
    </game>

    <game>
    <gameName>Cleopatra II</gameName>
    <gameDescription>SlotGame</gameDescription>
    <gameType>S</gameType>
    <url>/game.do</url>
    <languageCodes>
        <languageCode value=""en"" />

    </languageCodes>
    <softwareIds>
        <softwareId id=""200-0094-001"">
            <presentationTypes>
                <presentationType code=""FLSH"">
                <wndHeight>690</wndHeight>
                <wndWidth>636</wndWidth>
                <currencies>

                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>200.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>5.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.2</denomAmount>

                            <minBet>0.2</minBet>
                            <maxBet>20.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>500.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>2.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>

                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>1.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>

                            <minBet>0.1</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>

                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>20.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>

                            <maxBet>1.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>2.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>200.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>

                            <minBet>0.05</minBet>
                            <maxBet>5.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>1000.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>

                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>

                        </configurations>
                    </currency>
                    <currency code=""USD"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>2.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>

                            <maxBet>200.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>5.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.25</denomAmount>

                            <minBet>0.25</minBet>
                            <maxBet>25.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>500.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>1.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                </currencies>

                </presentationType>
            </presentationTypes>
        </softwareId>
    </softwareIds>
    </game>
    <game>
    <gameName>Vacation USA</gameName>
    <gameDescription>SlotGame</gameDescription>

    <gameType>S</gameType>
    <url>/game.do</url>
    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>
    <softwareIds>
        <softwareId id=""200-0017-001"">
            <presentationTypes>

                <presentationType code=""FLSH"">
                <wndHeight>740</wndHeight>
                <wndWidth>636</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>

                            <minBet>0.2</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>50.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>0.5</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>1250.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>

                            <maxBet>5.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>20.0</denomAmount>
                            <minBet>20.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>

                            <minBet>0.05</minBet>
                            <maxBet>2.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>250.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>1.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>

                            <maxBet>25.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.01</denomAmount>

                            <minBet>0.01</minBet>
                            <maxBet>0.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>1.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>2.5</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>20.0</denomAmount>
                            <minBet>20.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>

                            <maxBet>5.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>250.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>1250.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.2</denomAmount>

                            <minBet>0.2</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>100.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>25.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>

                            <maxBet>50.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""USD"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.1</denomAmount>

                            <minBet>0.1</minBet>
                            <maxBet>5.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>100.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>2.5</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>

                            <maxBet>0.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>1.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>20.0</denomAmount>
                            <minBet>20.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>

                            <minBet>0.5</minBet>
                            <maxBet>25.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>1250.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.25</denomAmount>
                            <minBet>0.25</minBet>
                            <maxBet>12.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>

                            <maxBet>250.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>
        </softwareId>

    </softwareIds>
    </game>
    <game>
    <gameName>Miss Hi-Lo Club</gameName>
    <gameDescription>NumbersGame</gameDescription>
    <gameType>S</gameType>
    <url>/game.do</url>

    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>
    <softwareIds>
        <softwareId id=""200-0027-001"">
            <presentationTypes>
                <presentationType code=""FLSH"">
                <wndHeight>690</wndHeight>

                <wndWidth>636</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>

                            <maxBet>200.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>20.0</denomAmount>
                            <minBet>20.0</minBet>
                            <maxBet>2000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>5.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.2</denomAmount>

                            <minBet>0.2</minBet>
                            <maxBet>20.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>50.0</denomAmount>
                            <minBet>50.0</minBet>
                            <maxBet>5000.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>

                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>2500.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>

                            <minBet>0.1</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>

                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>20.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>

                            <maxBet>200.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>5.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>20.0</denomAmount>

                            <minBet>20.0</minBet>
                            <maxBet>2000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>50.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>50.0</denomAmount>
                            <minBet>50.0</minBet>
                            <maxBet>5000.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>

                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>2500.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>

                    <currency code=""USD"">
                        <configurations>
                            <configuration>
                            <denomAmount>20.0</denomAmount>
                            <minBet>20.0</minBet>
                            <maxBet>2000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>

                            <minBet>0.5</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>200.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>5.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>2500.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>

                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.25</denomAmount>
                            <minBet>0.25</minBet>
                            <maxBet>25.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>50.0</denomAmount>

                            <minBet>50.0</minBet>
                            <maxBet>5000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>100.0</maxBet>

                            </configuration>
                        </configurations>
                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>
        </softwareId>
    </softwareIds>
    </game>

    <game>
    <gameName>Capt. Quid's Treasure Quest</gameName>
    <gameDescription>SlotGame</gameDescription>
    <gameType>S</gameType>
    <url>/game.do</url>
    <languageCodes>
        <languageCode value=""en"" />

    </languageCodes>
    <softwareIds>
        <softwareId id=""200-0095-001"">
            <presentationTypes>
                <presentationType code=""FLSH"">
                <wndHeight>690</wndHeight>
                <wndWidth>636</wndWidth>
                <currencies>

                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>150.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>3.75</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.2</denomAmount>

                            <minBet>0.2</minBet>
                            <maxBet>15.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>375.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>75.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>1.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>

                            <maxBet>750.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>37.5</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>0.75</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>

                            <minBet>0.1</minBet>
                            <maxBet>7.5</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>

                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>15.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>

                            <maxBet>0.75</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>1.5</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>150.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>

                            <minBet>0.05</minBet>
                            <maxBet>3.75</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>750.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>37.5</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>7.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>

                            <maxBet>375.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>75.0</maxBet>
                            </configuration>

                        </configurations>
                    </currency>
                    <currency code=""USD"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>1.5</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>7.5</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>37.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>

                            <maxBet>150.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>3.75</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>750.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.25</denomAmount>

                            <minBet>0.25</minBet>
                            <maxBet>18.75</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>375.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>75.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>0.75</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                </currencies>

                </presentationType>
            </presentationTypes>
        </softwareId>
    </softwareIds>
    </game>
    <game>
    <gameName>Monopoly Pass Go</gameName>
    <gameDescription>SlotGame</gameDescription>

    <gameType>S</gameType>
    <url>/game.do</url>
    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>
    <softwareIds>
        <softwareId id=""200-0059-001"">
            <presentationTypes>

                <presentationType code=""FLSH"">
                <wndHeight>690</wndHeight>
                <wndWidth>636</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>

                            <minBet>0.2</minBet>
                            <maxBet>9.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>45.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>1125.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>0.45</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>

                            <maxBet>4.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>90.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>20.0</denomAmount>
                            <minBet>20.0</minBet>
                            <maxBet>900.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>

                            <minBet>0.05</minBet>
                            <maxBet>2.25</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>50.0</denomAmount>
                            <minBet>50.0</minBet>
                            <maxBet>2250.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>225.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>0.9</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>

                            <maxBet>450.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>22.5</maxBet>
                            </configuration>

                        </configurations>
                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>0.45</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>0.9</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>2.25</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>20.0</denomAmount>
                            <minBet>20.0</minBet>

                            <maxBet>900.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>4.5</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>225.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>25.0</denomAmount>

                            <minBet>25.0</minBet>
                            <maxBet>1125.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>9.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>90.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>450.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>

                            <maxBet>22.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>50.0</denomAmount>
                            <minBet>50.0</minBet>
                            <maxBet>2250.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>45.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>

                    <currency code=""USD"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>4.5</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>90.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>

                            <minBet>0.05</minBet>
                            <maxBet>2.25</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>45.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>0.45</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>0.9</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>20.0</denomAmount>
                            <minBet>20.0</minBet>

                            <maxBet>900.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>22.5</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>1125.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>

                            <minBet>10.0</minBet>
                            <maxBet>450.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.25</denomAmount>
                            <minBet>0.25</minBet>
                            <maxBet>11.25</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>225.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>50.0</denomAmount>
                            <minBet>50.0</minBet>
                            <maxBet>2250.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                </currencies>

                </presentationType>
            </presentationTypes>
        </softwareId>
    </softwareIds>
    </game>
    <game>
    <gameName>Double Bonus Spin Roulette - Classic</gameName>
    <gameDescription>TableGame-Roulette</gameDescription>

    <gameType>T</gameType>
    <url>/game.do</url>
    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>
    <softwareIds>
        <softwareId id=""200-0039-001"">
            <presentationTypes>

                <presentationType code=""FLSH"">
                <wndHeight>620</wndHeight>
                <wndWidth>640</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>2.0</denomAmount>

                            <minBet>2.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>20.0</denomAmount>
                            <minBet>20.0</minBet>
                            <maxBet>1000.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>50.0</denomAmount>
                            <minBet>50.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>

                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>100.0</denomAmount>
                            <minBet>100.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>

                            <minBet>10.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>1000.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""EUR"">

                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>100.0</denomAmount>
                            <minBet>100.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>

                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>20.0</denomAmount>
                            <minBet>20.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>

                            <minBet>0.5</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>50.0</denomAmount>
                            <minBet>50.0</minBet>
                            <maxBet>1000.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>

                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                        </configurations>
                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>
        </softwareId>
    </softwareIds>
    </game>
    <game>

    <gameName>Transformers: Ultimate Payback</gameName>
    <gameDescription>SlotGame</gameDescription>
    <gameType>S</gameType>
    <url>/game.do</url>
    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>

    <softwareIds>
        <softwareId id=""200-0112-001"">
            <presentationTypes>
                <presentationType code=""FLSH"">
                <wndHeight>690</wndHeight>
                <wndWidth>636</wndWidth>
                <currencies>
                    <currency code=""GBP"">

                        <configurations>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>250.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>6.25</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>

                            <maxBet>25.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>625.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>125.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.02</denomAmount>

                            <minBet>0.02</minBet>
                            <maxBet>2.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>1250.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>62.5</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>1.25</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>

                            <maxBet>12.5</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>

                            <minBet>0.2</minBet>
                            <maxBet>25.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>1.25</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>2.5</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>250.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>

                            <maxBet>6.25</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>1250.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>62.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>

                            <minBet>0.1</minBet>
                            <maxBet>12.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>625.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>125.0</maxBet>
                            </configuration>
                        </configurations>

                    </currency>
                    <currency code=""USD"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>2.5</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>12.5</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>62.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>

                            <maxBet>250.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>6.25</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>1250.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.25</denomAmount>

                            <minBet>0.25</minBet>
                            <maxBet>31.25</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>625.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>125.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>1.25</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                </currencies>

                </presentationType>
            </presentationTypes>
        </softwareId>
    </softwareIds>
    </game>
    <game>
    <gameName>Star Trek</gameName>
    <gameDescription>SlotGame</gameDescription>

    <gameType>S</gameType>
    <url>/tc/game</url>
    <languageCodes>
        <languageCode value=""pl"" />
        <languageCode value=""hu"" />
        <languageCode value=""fi"" />
        <languageCode value=""ro"" />
        <languageCode value=""ja"" />

        <languageCode value=""es"" />
        <languageCode value=""en"" />
        <languageCode value=""sv"" />
        <languageCode value=""da"" />
        <languageCode value=""ru"" />
        <languageCode value=""de"" />
        <languageCode value=""it"" />
        <languageCode value=""el"" />
        <languageCode value=""pt"" />

        <languageCode value=""fr"" />
    </languageCodes>
    <softwareIds>
        <softwareId id=""200-1144-001"">
            <presentationTypes>
                <presentationType code=""FLSH"">
                <wndHeight>768</wndHeight>
                <wndWidth>1024</wndWidth>

                <currencies>
                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>0.3</maxBet>

                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>

                            <maxBet>0.3</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""USD"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.01</denomAmount>

                            <minBet>0.01</minBet>
                            <maxBet>0.3</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>

        </softwareId>
    </softwareIds>
    </game>
    <game>
    <gameName>Ten Play Bonus</gameName>
    <gameDescription>VideoPoker</gameDescription>
    <gameType>S</gameType>

    <url>/game.do</url>
    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>
    <softwareIds>
        <softwareId id=""200-0008-101"">
            <presentationTypes>
                <presentationType code=""FLSH"">

                <wndHeight>740</wndHeight>
                <wndWidth>636</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>2.0</denomAmount>

                            <minBet>2.0</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>2.5</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>250.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>

                            <maxBet>50.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>500.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>25.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>

                            <minBet>0.1</minBet>
                            <maxBet>5.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>

                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>

                            <maxBet>100.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>2.5</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>

                            <minBet>0.5</minBet>
                            <maxBet>25.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>5.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>250.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""USD"">

                        <configurations>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>5.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>25.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>

                            <maxBet>100.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>2.5</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.25</denomAmount>

                            <minBet>0.25</minBet>
                            <maxBet>12.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>250.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>
                        </configurations>

                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>
        </softwareId>
    </softwareIds>
    </game>
    <game>
    <gameName>Vegas Blackjack with 20+ Bonus</gameName>

    <gameDescription>TableGame-Blackjack</gameDescription>
    <gameType>T</gameType>
    <url>/game.do</url>
    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>
    <softwareIds>

        <softwareId id=""200-0106-001"">
            <presentationTypes>
                <presentationType code=""FLSH"">
                <wndHeight>690</wndHeight>
                <wndWidth>636</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>

                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>

                            <minBet>5.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>1000.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>100.0</denomAmount>
                            <minBet>100.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>

                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                        </configurations>
                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>1000.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>100.0</denomAmount>
                            <minBet>100.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>

                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>

                            <minBet>1.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>

        </softwareId>
    </softwareIds>
    </game>
    <game>
    <gameName>Five Times Pay</gameName>
    <gameDescription>SlotGame</gameDescription>
    <gameType>S</gameType>

    <url>/game.do</url>
    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>
    <softwareIds>
        <softwareId id=""200-0092-001"">
            <presentationTypes>
                <presentationType code=""FLSH"">

                <wndHeight>690</wndHeight>
                <wndWidth>636</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>2.0</denomAmount>

                            <minBet>2.0</minBet>
                            <maxBet>6.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>20.0</denomAmount>
                            <minBet>20.0</minBet>
                            <maxBet>60.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>0.15</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>0.6</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>

                            <maxBet>15.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>3.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>0.06</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>

                            <minBet>10.0</minBet>
                            <maxBet>30.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>1.5</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>0.03</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>0.3</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""EUR"">

                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>0.6</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>0.03</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>

                            <maxBet>0.06</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>6.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>0.15</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>

                            <minBet>10.0</minBet>
                            <maxBet>30.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>20.0</denomAmount>
                            <minBet>20.0</minBet>
                            <maxBet>60.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>1.5</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>0.3</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>

                            <maxBet>15.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>3.0</maxBet>
                            </configuration>

                        </configurations>
                    </currency>
                    <currency code=""USD"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>0.06</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>20.0</denomAmount>
                            <minBet>20.0</minBet>
                            <maxBet>60.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>0.3</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>

                            <maxBet>1.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>6.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>0.15</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>

                            <minBet>10.0</minBet>
                            <maxBet>30.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.25</denomAmount>
                            <minBet>0.25</minBet>
                            <maxBet>0.75</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>15.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>3.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>

                            <maxBet>0.03</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>
        </softwareId>

    </softwareIds>
    </game>
    <game>
    <gameName>3-Reel Hold-Up</gameName>
    <gameDescription>SlotGame</gameDescription>
    <gameType>S</gameType>
    <url>/game.do</url>

    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>
    <softwareIds>
        <softwareId id=""200-0007-002"">
            <presentationTypes>
                <presentationType code=""FLSH"">
                <wndHeight>740</wndHeight>

                <wndWidth>636</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>

                            <maxBet>3.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>15.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>0.15</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>25.0</denomAmount>

                            <minBet>25.0</minBet>
                            <maxBet>375.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>1.5</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>30.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>20.0</denomAmount>
                            <minBet>20.0</minBet>
                            <maxBet>300.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>

                            <maxBet>0.75</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>50.0</denomAmount>
                            <minBet>50.0</minBet>
                            <maxBet>750.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>75.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.02</denomAmount>

                            <minBet>0.02</minBet>
                            <maxBet>0.3</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>150.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>7.5</maxBet>
                            </configuration>
                        </configurations>

                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>0.15</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>0.3</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>0.75</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>20.0</denomAmount>
                            <minBet>20.0</minBet>

                            <maxBet>300.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>1.5</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>75.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>25.0</denomAmount>

                            <minBet>25.0</minBet>
                            <maxBet>375.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>3.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>30.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>150.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>

                            <maxBet>7.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>50.0</denomAmount>
                            <minBet>50.0</minBet>
                            <maxBet>750.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>15.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>

                    <currency code=""USD"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>1.5</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>30.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>

                            <minBet>0.05</minBet>
                            <maxBet>0.75</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>15.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>0.15</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>0.3</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>20.0</denomAmount>
                            <minBet>20.0</minBet>

                            <maxBet>300.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>7.5</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>375.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>

                            <minBet>10.0</minBet>
                            <maxBet>150.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.25</denomAmount>
                            <minBet>0.25</minBet>
                            <maxBet>3.75</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>75.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>50.0</denomAmount>
                            <minBet>50.0</minBet>
                            <maxBet>750.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                </currencies>

                </presentationType>
            </presentationTypes>
        </softwareId>
    </softwareIds>
    </game>
    <game>
    <gameName>Triple Fortune Dragon</gameName>
    <gameDescription>SlotGame</gameDescription>

    <gameType>S</gameType>
    <url>/game.do</url>
    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>
    <softwareIds>
        <softwareId id=""200-0105-001"">
            <presentationTypes>

                <presentationType code=""FLSH"">
                <wndHeight>690</wndHeight>
                <wndWidth>636</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>2.0</denomAmount>

                            <minBet>2.0</minBet>
                            <maxBet>250.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>6.25</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>25.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>625.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>

                            <maxBet>125.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>2.5</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>1250.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>

                            <minBet>0.5</minBet>
                            <maxBet>62.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>1.25</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>12.5</maxBet>
                            </configuration>
                        </configurations>

                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>25.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>1.25</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>2.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>

                            <maxBet>250.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>6.25</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>1250.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>

                            <minBet>0.5</minBet>
                            <maxBet>62.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>12.5</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>625.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>125.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""USD"">

                        <configurations>
                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>2.5</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>12.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>

                            <maxBet>62.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>250.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>6.25</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>

                            <minBet>10.0</minBet>
                            <maxBet>1250.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.25</denomAmount>
                            <minBet>0.25</minBet>
                            <maxBet>31.25</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>625.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>125.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>

                            <maxBet>1.25</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>
        </softwareId>

    </softwareIds>
    </game>
    <game>
    <gameName>Ten Play Joker Poker</gameName>
    <gameDescription>VideoPoker</gameDescription>
    <gameType>S</gameType>
    <url>/game.do</url>

    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>
    <softwareIds>
        <softwareId id=""200-0008-401"">
            <presentationTypes>
                <presentationType code=""FLSH"">
                <wndHeight>740</wndHeight>

                <wndWidth>636</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>

                            <maxBet>100.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>2.5</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>

                            <minBet>5.0</minBet>
                            <maxBet>250.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>50.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>25.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>

                            <maxBet>5.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>

                            <minBet>0.2</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>100.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>2.5</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>

                            <maxBet>25.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>5.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>250.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>

                            <minBet>1.0</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""USD"">
                        <configurations>
                            <configuration>

                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>5.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>

                            <maxBet>25.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>2.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>

                            <minBet>10.0</minBet>
                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.25</denomAmount>
                            <minBet>0.25</minBet>
                            <maxBet>12.5</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>250.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                </currencies>

                </presentationType>
            </presentationTypes>
        </softwareId>
    </softwareIds>
    </game>
    <game>
    <gameName>Bitten</gameName>
    <gameDescription>SlotGame</gameDescription>

    <gameType>S</gameType>
    <url>/game.do</url>
    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>
    <softwareIds>
        <softwareId id=""200-0130-001"">
            <presentationTypes>

                <presentationType code=""FLSH"">
                <wndHeight>690</wndHeight>
                <wndWidth>636</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>2.0</denomAmount>

                            <minBet>2.0</minBet>
                            <maxBet>200.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>5.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>20.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>

                            <maxBet>100.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>2.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.01</denomAmount>

                            <minBet>0.01</minBet>
                            <maxBet>1.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>10.0</maxBet>

                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>

                            <maxBet>20.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>1.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>2.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>

                            <minBet>2.0</minBet>
                            <maxBet>200.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>5.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>

                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>

                        </configurations>
                    </currency>
                    <currency code=""USD"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>2.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>

                            <maxBet>200.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>5.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.25</denomAmount>

                            <minBet>0.25</minBet>
                            <maxBet>25.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>500.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>1.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                </currencies>

                </presentationType>
            </presentationTypes>
        </softwareId>
    </softwareIds>
    </game>
    <game>
    <gameName>Roulette with Section Bets - Classic</gameName>
    <gameDescription>TableGame-Roulette</gameDescription>

    <gameType>T</gameType>
    <url>/game.do</url>
    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>
    <softwareIds>
        <softwareId id=""200-0011-201"">
            <presentationTypes>

                <presentationType code=""FLSH"">
                <wndHeight>620</wndHeight>
                <wndWidth>640</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>2.0</denomAmount>

                            <minBet>2.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>20.0</denomAmount>
                            <minBet>20.0</minBet>
                            <maxBet>1000.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>50.0</denomAmount>
                            <minBet>50.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>

                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>100.0</denomAmount>
                            <minBet>100.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>

                            <minBet>10.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>1000.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""EUR"">

                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>100.0</denomAmount>
                            <minBet>100.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>

                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>20.0</denomAmount>
                            <minBet>20.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>

                            <minBet>0.5</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>50.0</denomAmount>
                            <minBet>50.0</minBet>
                            <maxBet>1000.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>

                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                        </configurations>
                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>
        </softwareId>
    </softwareIds>
    </game>
    <game>

    <gameName>Dungeons and Dragons - Crystal Caverns</gameName>
    <gameDescription>SlotGame</gameDescription>
    <gameType>S</gameType>
    <url>/game.do</url>
    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>

    <softwareIds>
        <softwareId id=""200-0115-001"">
            <presentationTypes>
                <presentationType code=""FLSH"">
                <wndHeight>690</wndHeight>
                <wndWidth>636</wndWidth>
                <currencies>
                    <currency code=""GBP"">

                        <configurations>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>200.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>5.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>

                            <maxBet>20.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>500.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.02</denomAmount>

                            <minBet>0.02</minBet>
                            <maxBet>2.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>1000.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>1.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>

                            <maxBet>10.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>

                            <minBet>0.2</minBet>
                            <maxBet>20.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>1.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>2.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>200.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>

                            <maxBet>5.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>

                            <minBet>0.1</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>500.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>
                        </configurations>

                    </currency>
                    <currency code=""USD"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>2.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>

                            <maxBet>200.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>5.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.25</denomAmount>

                            <minBet>0.25</minBet>
                            <maxBet>25.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>500.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>1.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                </currencies>

                </presentationType>
            </presentationTypes>
        </softwareId>
    </softwareIds>
    </game>
    <game>
    <gameName>Double Diamond</gameName>
    <gameDescription>SlotGame</gameDescription>

    <gameType>S</gameType>
    <url>/game.do</url>
    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>
    <softwareIds>
        <softwareId id=""200-0090-001"">
            <presentationTypes>

                <presentationType code=""FLSH"">
                <wndHeight>690</wndHeight>
                <wndWidth>636</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>

                            <minBet>0.2</minBet>
                            <maxBet>0.6</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>3.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>100.0</denomAmount>
                            <minBet>100.0</minBet>
                            <maxBet>300.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>0.03</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>

                            <maxBet>75.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>0.3</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>6.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>20.0</denomAmount>

                            <minBet>20.0</minBet>
                            <maxBet>60.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>0.15</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>50.0</denomAmount>
                            <minBet>50.0</minBet>
                            <maxBet>150.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>15.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>

                            <maxBet>0.06</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>30.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>1.5</maxBet>
                            </configuration>
                        </configurations>
                    </currency>

                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>0.03</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>100.0</denomAmount>
                            <minBet>100.0</minBet>
                            <maxBet>300.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.02</denomAmount>

                            <minBet>0.02</minBet>
                            <maxBet>0.06</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>0.15</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>20.0</denomAmount>
                            <minBet>20.0</minBet>
                            <maxBet>60.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>0.3</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>

                            <maxBet>15.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>75.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>0.6</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>

                            <minBet>2.0</minBet>
                            <maxBet>6.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>30.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>1.5</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>50.0</denomAmount>
                            <minBet>50.0</minBet>
                            <maxBet>150.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>

                            <maxBet>3.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""USD"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.1</denomAmount>

                            <minBet>0.1</minBet>
                            <maxBet>0.3</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>6.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>0.15</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>3.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>

                            <maxBet>0.03</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>0.06</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>20.0</denomAmount>
                            <minBet>20.0</minBet>
                            <maxBet>60.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>

                            <minBet>0.5</minBet>
                            <maxBet>1.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>100.0</denomAmount>
                            <minBet>100.0</minBet>
                            <maxBet>300.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>75.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>30.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.25</denomAmount>
                            <minBet>0.25</minBet>

                            <maxBet>0.75</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>15.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>50.0</denomAmount>
                            <minBet>50.0</minBet>
                            <maxBet>150.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>

                </currencies>
                </presentationType>
            </presentationTypes>
        </softwareId>
    </softwareIds>
    </game>
    <game>
    <gameName>King Arthurs Hi-Lo</gameName>

    <gameDescription>NumbersGame</gameDescription>
    <gameType>S</gameType>
    <url>/game.do</url>
    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>
    <softwareIds>

        <softwareId id=""200-0028-001"">
            <presentationTypes>
                <presentationType code=""FLSH"">
                <wndHeight>690</wndHeight>
                <wndWidth>636</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>

                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>200.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>20.0</denomAmount>

                            <minBet>20.0</minBet>
                            <maxBet>2000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>5.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>20.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>50.0</denomAmount>
                            <minBet>50.0</minBet>
                            <maxBet>5000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>

                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>

                            <minBet>0.5</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>2500.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>
                        </configurations>

                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>20.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>200.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>5.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>

                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>20.0</denomAmount>
                            <minBet>20.0</minBet>
                            <maxBet>2000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>50.0</denomAmount>

                            <minBet>50.0</minBet>
                            <maxBet>5000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>10.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>2500.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>

                            <maxBet>100.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""USD"">
                        <configurations>
                            <configuration>
                            <denomAmount>20.0</denomAmount>

                            <minBet>20.0</minBet>
                            <maxBet>2000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>10.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>200.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>

                            <maxBet>5.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>2500.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.25</denomAmount>

                            <minBet>0.25</minBet>
                            <maxBet>25.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>500.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>50.0</denomAmount>
                            <minBet>50.0</minBet>
                            <maxBet>5000.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                </currencies>

                </presentationType>
            </presentationTypes>
        </softwareId>
    </softwareIds>
    </game>
    <game>
    <gameName>Bingo-Keno</gameName>
    <gameDescription>VideoPoker</gameDescription>

    <gameType>S</gameType>
    <url>/game.do</url>
    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>
    <softwareIds>
        <softwareId id=""200-0010-001"">
            <presentationTypes>

                <presentationType code=""FLSH"">
                <wndHeight>620</wndHeight>
                <wndWidth>640</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.05</denomAmount>

                            <minBet>0.05</minBet>
                            <maxBet>0.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>2.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>5.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>

                            <maxBet>1.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>

                            <minBet>0.2</minBet>
                            <maxBet>2.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>0.5</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>5.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>1.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>

                            <maxBet>10.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""USD"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.1</denomAmount>

                            <minBet>0.1</minBet>
                            <maxBet>1.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>5.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>0.5</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.25</denomAmount>
                            <minBet>0.25</minBet>
                            <maxBet>2.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>

                            <maxBet>10.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>
        </softwareId>

    </softwareIds>
    </game>
    <game>
    <gameName>Blackjack with Hot Streak Bonus</gameName>
    <gameDescription>TableGame-Blackjack</gameDescription>
    <gameType>T</gameType>
    <url>/game.do</url>

    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>
    <softwareIds>
        <softwareId id=""200-0070-001"">
            <presentationTypes>
                <presentationType code=""FLSH"">
                <wndHeight>690</wndHeight>

                <wndWidth>636</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>

                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>

                            <minBet>0.1</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>

                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>

                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>

                    <currency code=""USD"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>25.0</denomAmount>

                            <minBet>25.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>1000.0</maxBet>

                            </configuration>
                        </configurations>
                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>
        </softwareId>
    </softwareIds>
    </game>

    <game>
    <gameName>Phantom Belle Joker Poker</gameName>
    <gameDescription>VideoPoker</gameDescription>
    <gameType>S</gameType>
    <url>/game.do</url>
    <languageCodes>
        <languageCode value=""en"" />

    </languageCodes>
    <softwareIds>
        <softwareId id=""200-0001-403"">
            <presentationTypes>
                <presentationType code=""FLSH"">
                <wndHeight>740</wndHeight>
                <wndWidth>636</wndWidth>
                <currencies>

                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>1.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>5.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>100.0</denomAmount>

                            <minBet>100.0</minBet>
                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>125.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>0.5</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>20.0</denomAmount>
                            <minBet>20.0</minBet>

                            <maxBet>100.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>0.25</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>50.0</denomAmount>
                            <minBet>50.0</minBet>
                            <maxBet>250.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>

                            <minBet>5.0</minBet>
                            <maxBet>25.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>50.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>2.5</maxBet>
                            </configuration>
                        </configurations>

                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>100.0</denomAmount>
                            <minBet>100.0</minBet>
                            <maxBet>500.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>0.25</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>20.0</denomAmount>
                            <minBet>20.0</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>

                            <maxBet>0.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>25.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>125.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.2</denomAmount>

                            <minBet>0.2</minBet>
                            <maxBet>1.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>10.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>2.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>50.0</denomAmount>
                            <minBet>50.0</minBet>

                            <maxBet>250.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>5.0</maxBet>
                            </configuration>

                        </configurations>
                    </currency>
                    <currency code=""USD"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>0.5</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>0.25</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>

                            <maxBet>5.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>20.0</denomAmount>
                            <minBet>20.0</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>2.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>100.0</denomAmount>

                            <minBet>100.0</minBet>
                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>125.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.25</denomAmount>
                            <minBet>0.25</minBet>
                            <maxBet>1.25</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>

                            <maxBet>25.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>50.0</denomAmount>
                            <minBet>50.0</minBet>
                            <maxBet>250.0</maxBet>
                            </configuration>

                        </configurations>
                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>
        </softwareId>
    </softwareIds>
    </game>
    <game>

    <gameName>Double Attack Blackjack</gameName>
    <gameDescription>TableGame-Blackjack</gameDescription>
    <gameType>T</gameType>
    <url>/game.do</url>
    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>

    <softwareIds>
        <softwareId id=""200-0099-001"">
            <presentationTypes>
                <presentationType code=""FLSH"">
                <wndHeight>690</wndHeight>
                <wndWidth>636</wndWidth>
                <currencies>
                    <currency code=""GBP"">

                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>

                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>100.0</denomAmount>
                            <minBet>100.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>25.0</denomAmount>

                            <minBet>25.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>1000.0</maxBet>

                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>

                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>100.0</denomAmount>
                            <minBet>100.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>

                            <minBet>0.1</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>1000.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                </currencies>

                </presentationType>
            </presentationTypes>
        </softwareId>
    </softwareIds>
    </game>
    <game>
    <gameName>Monopoly Multiplier</gameName>
    <gameDescription>SlotGame</gameDescription>

    <gameType>S</gameType>
    <url>/tc/game</url>
    <languageCodes>
        <languageCode value=""fi"" />
        <languageCode value=""it"" />
        <languageCode value=""es"" />
        <languageCode value=""en"" />
        <languageCode value=""sv"" />

        <languageCode value=""da"" />
        <languageCode value=""fr"" />
    </languageCodes>
    <softwareIds>
        <softwareId id=""200-1131-001"">
            <presentationTypes>
                <presentationType code=""FLSH"">
                <wndHeight>768</wndHeight>

                <wndWidth>1024</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>

                            <maxBet>2.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.01</denomAmount>

                            <minBet>0.01</minBet>
                            <maxBet>2.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""USD"">
                        <configurations>
                            <configuration>

                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>2.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                </currencies>

                </presentationType>
            </presentationTypes>
        </softwareId>
    </softwareIds>
    </game>
    <game>
    <gameName>Top Hat 21</gameName>
    <gameDescription>TableGame-Blackjack</gameDescription>

    <gameType>S</gameType>
    <url>/game.do</url>
    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>
    <softwareIds>
        <softwareId id=""200-0009-001"">
            <presentationTypes>

                <presentationType code=""FLSH"">
                <wndHeight>740</wndHeight>
                <wndWidth>636</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>2.0</denomAmount>

                            <minBet>2.0</minBet>
                            <maxBet>20.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>20.0</denomAmount>
                            <minBet>20.0</minBet>
                            <maxBet>200.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>0.5</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>2.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>50.0</denomAmount>
                            <minBet>50.0</minBet>

                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>

                            <minBet>10.0</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>5.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>250.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>1.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""EUR"">

                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>2.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>20.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>

                            <maxBet>0.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>20.0</denomAmount>
                            <minBet>20.0</minBet>
                            <maxBet>200.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>

                            <minBet>0.5</minBet>
                            <maxBet>5.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>50.0</denomAmount>
                            <minBet>50.0</minBet>
                            <maxBet>500.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>1.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>

                            <maxBet>250.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>

                        </configurations>
                    </currency>
                    <currency code=""USD"">
                        <configurations>
                            <configuration>
                            <denomAmount>20.0</denomAmount>
                            <minBet>20.0</minBet>
                            <maxBet>200.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>1.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>5.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>

                            <maxBet>20.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>0.5</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>250.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>

                            <minBet>10.0</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.25</denomAmount>
                            <minBet>0.25</minBet>
                            <maxBet>2.5</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>50.0</denomAmount>
                            <minBet>50.0</minBet>
                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>

                            <maxBet>10.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>
        </softwareId>

    </softwareIds>
    </game>
    <game>
    <gameName>Multiplier</gameName>
    <gameDescription>NumbersGame</gameDescription>
    <gameType>S</gameType>
    <url>/game.do</url>

    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>
    <softwareIds>
        <softwareId id=""200-0057-001"">
            <presentationTypes>
                <presentationType code=""FLSH"">
                <wndHeight>620</wndHeight>

                <wndWidth>640</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>

                            <maxBet>25000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>250.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>2500.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>

                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>250.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>2500.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>

                            <minBet>1.0</minBet>
                            <maxBet>25000.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""USD"">
                        <configurations>
                            <configuration>

                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>2500.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>

                            <maxBet>25000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>250.0</maxBet>
                            </configuration>

                        </configurations>
                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>
        </softwareId>
    </softwareIds>
    </game>
    <game>

    <gameName>Phantom Belle Jacks or Better</gameName>
    <gameDescription>VideoPoker</gameDescription>
    <gameType>S</gameType>
    <url>/game.do</url>
    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>

    <softwareIds>
        <softwareId id=""200-0001-003"">
            <presentationTypes>
                <presentationType code=""FLSH"">
                <wndHeight>740</wndHeight>
                <wndWidth>636</wndWidth>
                <currencies>
                    <currency code=""GBP"">

                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>1.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>5.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>100.0</denomAmount>
                            <minBet>100.0</minBet>

                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>125.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>0.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>

                            <minBet>2.0</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>20.0</denomAmount>
                            <minBet>20.0</minBet>
                            <maxBet>100.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>0.25</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>50.0</denomAmount>
                            <minBet>50.0</minBet>
                            <maxBet>250.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>

                            <maxBet>25.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>2.5</maxBet>
                            </configuration>
                        </configurations>
                    </currency>

                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>100.0</denomAmount>
                            <minBet>100.0</minBet>
                            <maxBet>500.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>0.25</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>20.0</denomAmount>

                            <minBet>20.0</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>0.5</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>25.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>125.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>

                            <maxBet>1.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>

                            <minBet>0.5</minBet>
                            <maxBet>2.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>50.0</denomAmount>
                            <minBet>50.0</minBet>
                            <maxBet>250.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>5.0</maxBet>
                            </configuration>
                        </configurations>

                    </currency>
                    <currency code=""USD"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>0.5</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>0.25</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>

                            <maxBet>5.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>20.0</denomAmount>
                            <minBet>20.0</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>2.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>100.0</denomAmount>

                            <minBet>100.0</minBet>
                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>125.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.25</denomAmount>
                            <minBet>0.25</minBet>
                            <maxBet>1.25</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>

                            <maxBet>25.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>50.0</denomAmount>
                            <minBet>50.0</minBet>
                            <maxBet>250.0</maxBet>
                            </configuration>

                        </configurations>
                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>
        </softwareId>
    </softwareIds>
    </game>
    <game>

    <gameName>21 + 3 Blackjack</gameName>
    <gameDescription>TableGame-Blackjack</gameDescription>
    <gameType>T</gameType>
    <url>/game.do</url>
    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>

    <softwareIds>
        <softwareId id=""200-0067-101"">
            <presentationTypes>
                <presentationType code=""FLSH"">
                <wndHeight>690</wndHeight>
                <wndWidth>636</wndWidth>
                <currencies>
                    <currency code=""GBP"">

                        <configurations>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>

                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                        </configurations>
                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>1000.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>

                            <maxBet>1000.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""USD"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.1</denomAmount>

                            <minBet>0.1</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>1000.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                </currencies>

                </presentationType>
            </presentationTypes>
        </softwareId>
    </softwareIds>
    </game>
    <game>
    <gameName>Texas Tea</gameName>
    <gameDescription>SlotGame</gameDescription>

    <gameType>S</gameType>
    <url>/game.do</url>
    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>
    <softwareIds>
        <softwareId id=""200-0088-001"">
            <presentationTypes>

                <presentationType code=""FLSH"">
                <wndHeight>690</wndHeight>
                <wndWidth>636</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>2.0</denomAmount>

                            <minBet>2.0</minBet>
                            <maxBet>90.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>2.25</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>9.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>225.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>

                            <maxBet>45.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>0.9</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>450.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>

                            <minBet>0.5</minBet>
                            <maxBet>22.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>0.45</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>4.5</maxBet>
                            </configuration>
                        </configurations>

                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>9.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>0.45</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>0.9</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>

                            <maxBet>90.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>2.25</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>450.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>

                            <minBet>0.5</minBet>
                            <maxBet>22.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>4.5</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>225.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>45.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""USD"">

                        <configurations>
                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>0.9</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>4.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>

                            <maxBet>22.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>90.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>2.25</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>

                            <minBet>10.0</minBet>
                            <maxBet>450.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.25</denomAmount>
                            <minBet>0.25</minBet>
                            <maxBet>11.25</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>225.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>45.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>

                            <maxBet>0.45</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>
        </softwareId>

    </softwareIds>
    </game>
    <game>
    <gameName>Triple Bonus Spin Roulette</gameName>
    <gameDescription>TableGame-Roulette</gameDescription>
    <gameType>T</gameType>
    <url>/tc/game</url>

    <languageCodes>
        <languageCode value=""pl"" />
        <languageCode value=""hu"" />
        <languageCode value=""fi"" />
        <languageCode value=""ro"" />
        <languageCode value=""ja"" />
        <languageCode value=""es"" />
        <languageCode value=""en"" />
        <languageCode value=""sv"" />

        <languageCode value=""da"" />
        <languageCode value=""ru"" />
        <languageCode value=""de"" />
        <languageCode value=""it"" />
        <languageCode value=""el"" />
        <languageCode value=""pt"" />
        <languageCode value=""fr"" />
    </languageCodes>
    <softwareIds>

        <softwareId id=""200-1134-001"">
            <presentationTypes>
                <presentationType code=""FLSH"">
                <wndHeight>768</wndHeight>
                <wndWidth>1024</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>

                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>300.0</maxBet>
                            <minSideBet>1.0</minSideBet>
                            <maxSideBet>20.0</maxSideBet>

                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>

                            <maxBet>300.0</maxBet>
                            <minSideBet>1.0</minSideBet>
                            <maxSideBet>20.0</maxSideBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""USD"">

                        <configurations>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>300.0</maxBet>
                            <minSideBet>1.0</minSideBet>
                            <maxSideBet>20.0</maxSideBet>

                            </configuration>
                        </configurations>
                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>
        </softwareId>
    </softwareIds>
    </game>

    <game>
    <gameName>5 of 6 Hi-Lo Line-Up</gameName>
    <gameDescription>NumbersGame</gameDescription>
    <gameType>S</gameType>
    <url>/game.do</url>
    <languageCodes>
        <languageCode value=""en"" />

    </languageCodes>
    <softwareIds>
        <softwareId id=""200-0031-001"">
            <presentationTypes>
                <presentationType code=""FLSH"">
                <wndHeight>690</wndHeight>
                <wndWidth>636</wndWidth>
                <currencies>

                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>200.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>5.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.2</denomAmount>

                            <minBet>0.2</minBet>
                            <maxBet>20.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>500.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>

                            <maxBet>50.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>

                        </configurations>
                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>20.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>200.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>5.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>

                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>

                            <minBet>5.0</minBet>
                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>100.0</maxBet>

                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""USD"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>

                            <maxBet>10.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>200.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>

                            <minBet>0.05</minBet>
                            <maxBet>5.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>1000.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.25</denomAmount>
                            <minBet>0.25</minBet>
                            <maxBet>25.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>

                            <maxBet>100.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>
        </softwareId>

    </softwareIds>
    </game>
    <game>
    <gameName>Wolf Run</gameName>
    <gameDescription>SlotGame</gameDescription>
    <gameType>S</gameType>
    <url>/game.do</url>

    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>
    <softwareIds>
        <softwareId id=""200-0096-001"">
            <presentationTypes>
                <presentationType code=""FLSH"">
                <wndHeight>690</wndHeight>

                <wndWidth>636</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>

                            <maxBet>400.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>40.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>

                            <minBet>5.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>200.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>4.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>2000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>

                            <maxBet>100.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>2.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>20.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>

                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>40.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>2.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.02</denomAmount>

                            <minBet>0.02</minBet>
                            <maxBet>4.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>400.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>2000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>

                            <maxBet>100.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>20.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>

                            <minBet>1.0</minBet>
                            <maxBet>200.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""USD"">
                        <configurations>
                            <configuration>

                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>4.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>

                            <maxBet>20.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>400.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>

                            <minBet>0.05</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>2000.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.25</denomAmount>
                            <minBet>0.25</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>

                            <maxBet>200.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>2.0</maxBet>
                            </configuration>

                        </configurations>
                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>
        </softwareId>
    </softwareIds>
    </game>
    <game>

    <gameName>Roulette</gameName>
    <gameDescription>TableGame-Roulette</gameDescription>
    <gameType>T</gameType>
    <url>/game.do</url>
    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>

    <softwareIds>
        <softwareId id=""200-0064-001"">
            <presentationTypes>
                <presentationType code=""FLSH"">
                <wndHeight>690</wndHeight>
                <wndWidth>636</wndWidth>
                <currencies>
                    <currency code=""GBP"">

                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>

                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>100.0</denomAmount>
                            <minBet>100.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>25.0</denomAmount>

                            <minBet>25.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>1000.0</maxBet>

                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>

                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>100.0</denomAmount>
                            <minBet>100.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>

                            <minBet>0.1</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>1000.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""USD"">

                        <configurations>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>100.0</denomAmount>
                            <minBet>100.0</minBet>

                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>

                            <minBet>1.0</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>

        </softwareId>
    </softwareIds>
    </game>
    <game>
    <gameName>Banana-Rama Deluxe</gameName>
    <gameDescription>SlotGame</gameDescription>
    <gameType>S</gameType>

    <url>/game.do</url>
    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>
    <softwareIds>
        <softwareId id=""200-0003-001"">
            <presentationTypes>
                <presentationType code=""FLSH"">

                <wndHeight>740</wndHeight>
                <wndWidth>636</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>

                            <minBet>0.2</minBet>
                            <maxBet>5.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>25.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>625.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>0.25</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>

                            <maxBet>2.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>20.0</denomAmount>
                            <minBet>20.0</minBet>
                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>

                            <minBet>0.05</minBet>
                            <maxBet>1.25</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>125.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>0.5</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>250.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>

                            <maxBet>12.5</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.01</denomAmount>

                            <minBet>0.01</minBet>
                            <maxBet>0.25</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>0.5</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>1.25</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>20.0</denomAmount>
                            <minBet>20.0</minBet>
                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>

                            <maxBet>2.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>125.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>625.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.2</denomAmount>

                            <minBet>0.2</minBet>
                            <maxBet>5.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>50.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>250.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>12.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>

                            <maxBet>25.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""USD"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.1</denomAmount>

                            <minBet>0.1</minBet>
                            <maxBet>2.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>50.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>1.25</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>25.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>

                            <maxBet>0.25</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>0.5</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>20.0</denomAmount>
                            <minBet>20.0</minBet>
                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>

                            <minBet>0.5</minBet>
                            <maxBet>12.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>625.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>250.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.25</denomAmount>
                            <minBet>0.25</minBet>
                            <maxBet>6.25</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>

                            <maxBet>125.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>
        </softwareId>

    </softwareIds>
    </game>
    <game>
    <gameName>Roulette with Hot Streak Bonus</gameName>
    <gameDescription>TableGame-Roulette</gameDescription>
    <gameType>T</gameType>
    <url>/game.do</url>

    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>
    <softwareIds>
        <softwareId id=""200-0069-001"">
            <presentationTypes>
                <presentationType code=""FLSH"">
                <wndHeight>690</wndHeight>

                <wndWidth>636</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>

                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>

                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>

                            <minBet>1.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>

        </softwareId>
    </softwareIds>
    </game>
    <game>
    <gameName>Rainbow Riches Win Big Shindig</gameName>
    <gameDescription>SlotGame</gameDescription>
    <gameType>S</gameType>

    <url>/game.do</url>
    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>
    <softwareIds>
        <softwareId id=""200-0116-001"">
            <presentationTypes>
                <presentationType code=""FLSH"">

                <wndHeight>690</wndHeight>
                <wndWidth>636</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>2.0</denomAmount>

                            <minBet>2.0</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>2.5</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>250.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>

                            <maxBet>50.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>1.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>

                            <minBet>0.5</minBet>
                            <maxBet>25.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>0.5</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>5.0</maxBet>
                            </configuration>
                        </configurations>

                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>10.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>0.5</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>1.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>

                            <maxBet>100.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>2.5</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>

                            <minBet>0.5</minBet>
                            <maxBet>25.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>5.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>250.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""USD"">

                        <configurations>
                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>1.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>5.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>

                            <maxBet>25.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>2.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>

                            <minBet>10.0</minBet>
                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.25</denomAmount>
                            <minBet>0.25</minBet>
                            <maxBet>12.5</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>250.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>

                            <maxBet>0.5</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>
        </softwareId>

    </softwareIds>
    </game>
    <game>
    <gameName>Lucky Draw Bonus</gameName>
    <gameDescription>VideoPoker</gameDescription>
    <gameType>S</gameType>
    <url>/game.do</url>

    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>
    <softwareIds>
        <softwareId id=""200-0005-101"">
            <presentationTypes>
                <presentationType code=""FLSH"">
                <wndHeight>740</wndHeight>

                <wndWidth>636</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>

                            <maxBet>40.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>20.0</denomAmount>
                            <minBet>20.0</minBet>
                            <maxBet>400.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>1.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.2</denomAmount>

                            <minBet>0.2</minBet>
                            <maxBet>4.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>100.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>20.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>200.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>

                            <maxBet>10.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>500.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>2.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>

                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>4.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>40.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>

                            <minBet>0.05</minBet>
                            <maxBet>1.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>200.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>20.0</denomAmount>
                            <minBet>20.0</minBet>
                            <maxBet>400.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>

                            <maxBet>2.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>

                            <minBet>1.0</minBet>
                            <maxBet>20.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""USD"">
                        <configurations>
                            <configuration>

                            <denomAmount>20.0</denomAmount>
                            <minBet>20.0</minBet>
                            <maxBet>400.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>

                            <maxBet>2.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>40.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>

                            <minBet>0.05</minBet>
                            <maxBet>1.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>500.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>200.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.25</denomAmount>
                            <minBet>0.25</minBet>
                            <maxBet>5.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>

                            <maxBet>100.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>20.0</maxBet>
                            </configuration>

                        </configurations>
                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>
        </softwareId>
    </softwareIds>
    </game>
    <game>

    <gameName>Monopoly Here and Now</gameName>
    <gameDescription>SlotGame</gameDescription>
    <gameType>S</gameType>
    <url>/game.do</url>
    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>

    <softwareIds>
        <softwareId id=""200-0076-001"">
            <presentationTypes>
                <presentationType code=""FLSH"">
                <wndHeight>690</wndHeight>
                <wndWidth>636</wndWidth>
                <currencies>
                    <currency code=""GBP"">

                        <configurations>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>200.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>5.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>

                            <maxBet>20.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>500.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.02</denomAmount>

                            <minBet>0.02</minBet>
                            <maxBet>2.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>1000.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>1.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>

                            <maxBet>10.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>

                            <minBet>0.2</minBet>
                            <maxBet>20.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>1.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>2.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>200.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>

                            <maxBet>5.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>

                            <minBet>0.1</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>500.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>
                        </configurations>

                    </currency>
                    <currency code=""USD"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>2.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>

                            <maxBet>200.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>5.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.25</denomAmount>

                            <minBet>0.25</minBet>
                            <maxBet>25.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>500.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>1.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                </currencies>

                </presentationType>
            </presentationTypes>
        </softwareId>
    </softwareIds>
    </game>
    <game>
    <gameName>Three Card Poker - Classic</gameName>
    <gameDescription>TableGame-ThreeCard</gameDescription>

    <gameType>T</gameType>
    <url>/game.do</url>
    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>
    <softwareIds>
        <softwareId id=""200-0023-001"">
            <presentationTypes>

                <presentationType code=""FLSH"">
                <wndHeight>620</wndHeight>
                <wndWidth>640</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>2.0</denomAmount>

                            <minBet>2.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>20.0</denomAmount>
                            <minBet>20.0</minBet>
                            <maxBet>1000.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>50.0</denomAmount>
                            <minBet>50.0</minBet>

                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>

                            <minBet>10.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>1000.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""EUR"">

                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>

                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>20.0</denomAmount>
                            <minBet>20.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>

                            <minBet>0.5</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>50.0</denomAmount>
                            <minBet>50.0</minBet>
                            <maxBet>1000.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>

                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                        </configurations>
                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>
        </softwareId>
    </softwareIds>
    </game>
    <game>

    <gameName>Dungeons and Dragons - Fortress of Fortunes</gameName>
    <gameDescription>SlotGame</gameDescription>
    <gameType>S</gameType>
    <url>/game.do</url>
    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>

    <softwareIds>
        <softwareId id=""200-0111-001"">
            <presentationTypes>
                <presentationType code=""FLSH"">
                <wndHeight>690</wndHeight>
                <wndWidth>636</wndWidth>
                <currencies>
                    <currency code=""GBP"">

                        <configurations>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>200.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>5.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>

                            <maxBet>20.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>500.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.02</denomAmount>

                            <minBet>0.02</minBet>
                            <maxBet>2.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>1000.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>1.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>

                            <maxBet>10.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>

                            <minBet>0.2</minBet>
                            <maxBet>20.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>1.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>2.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>200.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>

                            <maxBet>5.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>

                            <minBet>0.1</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>500.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>
                        </configurations>

                    </currency>
                    <currency code=""USD"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>2.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>

                            <maxBet>200.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>5.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.25</denomAmount>

                            <minBet>0.25</minBet>
                            <maxBet>25.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>500.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>1.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                </currencies>

                </presentationType>
            </presentationTypes>
        </softwareId>
    </softwareIds>
    </game>
    <game>
    <gameName>MegaJackpots Monopoly Pass Go</gameName>
    <gameDescription>SlotGame</gameDescription>

    <gameType>S</gameType>
    <url>/game.do</url>
    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>
    <softwareIds>
        <softwareId id=""200-0085-001"">
            <presentationTypes>

                <presentationType code=""FLSH"">
                <wndHeight>800</wndHeight>
                <wndWidth>636</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>20.0</denomAmount>

                            <minBet>20.0</minBet>
                            <maxBet>900.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>2.25</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>9.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>225.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>

                            <maxBet>45.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>450.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>22.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>

                            <minBet>0.1</minBet>
                            <maxBet>4.5</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>

                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>9.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>

                            <maxBet>2.25</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>450.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>20.0</denomAmount>
                            <minBet>20.0</minBet>
                            <maxBet>900.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>

                            <minBet>0.5</minBet>
                            <maxBet>22.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>4.5</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>225.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>45.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""USD"">

                        <configurations>
                            <configuration>
                            <denomAmount>20.0</denomAmount>
                            <minBet>20.0</minBet>
                            <maxBet>900.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>4.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>

                            <maxBet>22.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>2.25</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>450.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.25</denomAmount>

                            <minBet>0.25</minBet>
                            <maxBet>11.25</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>225.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>45.0</maxBet>
                            </configuration>
                        </configurations>

                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>
        </softwareId>
    </softwareIds>
    </game>
    <game>
    <gameName>Table Blackjack</gameName>

    <gameDescription>TableGame-Blackjack</gameDescription>
    <gameType>T</gameType>
    <url>/game.do</url>
    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>
    <softwareIds>

        <softwareId id=""200-0014-101"">
            <presentationTypes>
                <presentationType code=""FLSH"">
                <wndHeight>620</wndHeight>
                <wndWidth>640</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>

                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>20.0</denomAmount>

                            <minBet>20.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>1000.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>50.0</denomAmount>
                            <minBet>50.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>

                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>100.0</denomAmount>
                            <minBet>100.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>

                            <minBet>0.5</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>1000.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                        </configurations>

                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>1000.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>100.0</denomAmount>
                            <minBet>100.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>

                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>20.0</denomAmount>
                            <minBet>20.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>50.0</denomAmount>

                            <minBet>50.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>1000.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>

                            <maxBet>1000.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>
        </softwareId>

    </softwareIds>
    </game>
    <game>
    <gameName>Texas Hold em Shootout</gameName>
    <gameDescription>TableGame-Hold_em</gameDescription>
    <gameType>T</gameType>
    <url>/game.do</url>

    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>
    <softwareIds>
        <softwareId id=""200-0068-001"">
            <presentationTypes>
                <presentationType code=""FLSH"">
                <wndHeight>690</wndHeight>

                <wndWidth>636</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>

                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>

                            <minBet>0.1</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>

                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>

                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>

                </currencies>
                </presentationType>
            </presentationTypes>
        </softwareId>
    </softwareIds>
    </game>
    <game>
    <gameName>Phantom Belle Bonus</gameName>

    <gameDescription>VideoPoker</gameDescription>
    <gameType>S</gameType>
    <url>/game.do</url>
    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>
    <softwareIds>

        <softwareId id=""200-0001-103"">
            <presentationTypes>
                <presentationType code=""FLSH"">
                <wndHeight>740</wndHeight>
                <wndWidth>636</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>

                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>1.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>

                            <minBet>1.0</minBet>
                            <maxBet>5.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>100.0</denomAmount>
                            <minBet>100.0</minBet>
                            <maxBet>500.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>125.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>0.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>

                            <maxBet>10.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>20.0</denomAmount>
                            <minBet>20.0</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>0.25</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>50.0</denomAmount>

                            <minBet>50.0</minBet>
                            <maxBet>250.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>25.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>2.5</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""EUR"">

                        <configurations>
                            <configuration>
                            <denomAmount>100.0</denomAmount>
                            <minBet>100.0</minBet>
                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>0.25</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>20.0</denomAmount>
                            <minBet>20.0</minBet>

                            <maxBet>100.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>0.5</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>25.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>25.0</denomAmount>

                            <minBet>25.0</minBet>
                            <maxBet>125.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>1.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>

                            <maxBet>2.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>50.0</denomAmount>
                            <minBet>50.0</minBet>
                            <maxBet>250.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>5.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>

                    <currency code=""USD"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>0.5</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>

                            <minBet>0.05</minBet>
                            <maxBet>0.25</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>5.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>20.0</denomAmount>
                            <minBet>20.0</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>2.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>100.0</denomAmount>
                            <minBet>100.0</minBet>

                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>125.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.25</denomAmount>

                            <minBet>0.25</minBet>
                            <maxBet>1.25</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>25.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>50.0</denomAmount>
                            <minBet>50.0</minBet>
                            <maxBet>250.0</maxBet>
                            </configuration>
                        </configurations>

                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>
        </softwareId>
    </softwareIds>
    </game>
    <game>
    <gameName>ELVIS - A Little More Action</gameName>

    <gameDescription>SlotGame</gameDescription>
    <gameType>S</gameType>
    <url>/game.do</url>
    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>
    <softwareIds>

        <softwareId id=""200-0103-001"">
            <presentationTypes>
                <presentationType code=""FLSH"">
                <wndHeight>690</wndHeight>
                <wndWidth>636</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>

                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>

                            <minBet>0.05</minBet>
                            <maxBet>12.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>50.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>1250.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>250.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>

                            <maxBet>5.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>125.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>2.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>

                            <minBet>0.1</minBet>
                            <maxBet>25.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>

                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>

                            <maxBet>2.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>5.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>

                            <minBet>0.05</minBet>
                            <maxBet>12.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>125.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>25.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>1250.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>

                            <maxBet>250.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""USD"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.02</denomAmount>

                            <minBet>0.02</minBet>
                            <maxBet>5.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>25.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>125.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>

                            <maxBet>12.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.25</denomAmount>
                            <minBet>0.25</minBet>
                            <maxBet>62.5</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>1250.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>

                            <minBet>1.0</minBet>
                            <maxBet>250.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>2.5</maxBet>

                            </configuration>
                        </configurations>
                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>
        </softwareId>
    </softwareIds>
    </game>

    <game>
    <gameName>Wan Doy Pairs Poker</gameName>
    <gameDescription>TableGame-Other</gameDescription>
    <gameType>T</gameType>
    <url>/game.do</url>
    <languageCodes>
        <languageCode value=""en"" />

    </languageCodes>
    <softwareIds>
        <softwareId id=""200-0062-001"">
            <presentationTypes>
                <presentationType code=""FLSH"">
                <wndHeight>690</wndHeight>
                <wndWidth>636</wndWidth>
                <currencies>

                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>

                            <minBet>1.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>1000.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                        </configurations>

                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>1000.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>

                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                        </configurations>
                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>
        </softwareId>
    </softwareIds>
    </game>
    <game>

    <gameName>50,000 Pyramid</gameName>
    <gameDescription>SlotGame</gameDescription>
    <gameType>S</gameType>
    <url>/game.do</url>
    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>

    <softwareIds>
        <softwareId id=""200-0024-001"">
            <presentationTypes>
                <presentationType code=""FLSH"">
                <wndHeight>690</wndHeight>
                <wndWidth>636</wndWidth>
                <currencies>
                    <currency code=""GBP"">

                        <configurations>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>150.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>3.75</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>

                            <maxBet>15.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>75.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>1.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>

                            <minBet>0.5</minBet>
                            <maxBet>37.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>0.75</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>7.5</maxBet>
                            </configuration>
                        </configurations>

                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>15.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>0.75</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>1.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>

                            <maxBet>150.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>3.75</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>37.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>

                            <minBet>0.1</minBet>
                            <maxBet>7.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>375.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>75.0</maxBet>
                            </configuration>
                        </configurations>

                    </currency>
                    <currency code=""USD"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>1.5</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>7.5</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>37.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>

                            <maxBet>150.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>3.75</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.25</denomAmount>
                            <minBet>0.25</minBet>
                            <maxBet>18.75</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>

                            <minBet>5.0</minBet>
                            <maxBet>375.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>75.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>0.75</maxBet>
                            </configuration>
                        </configurations>

                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>
        </softwareId>
    </softwareIds>
    </game>
    <game>
    <gameName>Roulette!</gameName>

    <gameDescription>TableGame-Roulette</gameDescription>
    <gameType>T</gameType>
    <url>/tc/game</url>
    <languageCodes>
        <languageCode value=""pl"" />
        <languageCode value=""hu"" />
        <languageCode value=""fi"" />

        <languageCode value=""ro"" />
        <languageCode value=""ja"" />
        <languageCode value=""es"" />
        <languageCode value=""en"" />
        <languageCode value=""sv"" />
        <languageCode value=""da"" />
        <languageCode value=""ru"" />
        <languageCode value=""de"" />
        <languageCode value=""it"" />

        <languageCode value=""el"" />
        <languageCode value=""pt"" />
        <languageCode value=""fr"" />
    </languageCodes>
    <softwareIds>
        <softwareId id=""200-1133-001"">
            <presentationTypes>
                <presentationType code=""FLSH"">
                <wndHeight>768</wndHeight>

                <wndWidth>1024</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>

                            <maxBet>3000.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>
        </softwareId>

    </softwareIds>
    </game>
    <game>
    <gameName>Vegas, Baby!</gameName>
    <gameDescription>SlotGame</gameDescription>
    <gameType>S</gameType>
    <url>/game.do</url>

    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>
    <softwareIds>
        <softwareId id=""200-0102-001"">
            <presentationTypes>
                <presentationType code=""FLSH"">
                <wndHeight>690</wndHeight>

                <wndWidth>636</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>

                            <maxBet>200.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>5.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>20.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>

                            <minBet>5.0</minBet>
                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>100.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>2.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>

                            <maxBet>50.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>1.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>

                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>20.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>1.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.02</denomAmount>

                            <minBet>0.02</minBet>
                            <maxBet>2.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>200.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>5.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>

                            <maxBet>50.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>

                            <minBet>1.0</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""USD"">
                        <configurations>
                            <configuration>

                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>2.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>

                            <maxBet>10.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>200.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>

                            <minBet>0.05</minBet>
                            <maxBet>5.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>1000.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.25</denomAmount>
                            <minBet>0.25</minBet>
                            <maxBet>25.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>

                            <maxBet>100.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>1.0</maxBet>
                            </configuration>

                        </configurations>
                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>
        </softwareId>
    </softwareIds>
    </game>
    <game>

    <gameName>Ten Play Jacks or Better</gameName>
    <gameDescription>VideoPoker</gameDescription>
    <gameType>S</gameType>
    <url>/game.do</url>
    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>

    <softwareIds>
        <softwareId id=""200-0008-001"">
            <presentationTypes>
                <presentationType code=""FLSH"">
                <wndHeight>740</wndHeight>
                <wndWidth>636</wndWidth>
                <currencies>
                    <currency code=""GBP"">

                        <configurations>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>2.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>

                            <maxBet>10.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>250.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>

                            <minBet>10.0</minBet>
                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>25.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>5.0</maxBet>
                            </configuration>
                        </configurations>

                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>10.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>2.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>

                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>25.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>5.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>

                            <minBet>5.0</minBet>
                            <maxBet>250.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>50.0</maxBet>

                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""USD"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>

                            <maxBet>5.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>25.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>

                            <minBet>0.05</minBet>
                            <maxBet>2.5</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>500.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.25</denomAmount>
                            <minBet>0.25</minBet>
                            <maxBet>12.5</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>250.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>

                            <maxBet>50.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>
        </softwareId>

    </softwareIds>
    </game>
    <game>
    <gameName>MegaJackpots Cleopatra</gameName>
    <gameDescription>SlotGame</gameDescription>
    <gameType>S</gameType>
    <url>/game.do</url>

    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>
    <softwareIds>
        <softwareId id=""200-0109-001"">
            <presentationTypes>
                <presentationType code=""FLSH"">
                <wndHeight>800</wndHeight>

                <wndWidth>636</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>

                            <maxBet>5.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>20.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>

                            <minBet>1.0</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>2.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>

                            <maxBet>1.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>

                        </configurations>
                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>20.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>1.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>2.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>

                            <maxBet>5.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>

                            <minBet>0.1</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>500.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>
                        </configurations>

                    </currency>
                    <currency code=""USD"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>2.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>

                            <maxBet>5.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.25</denomAmount>
                            <minBet>0.25</minBet>
                            <maxBet>25.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>

                            <minBet>5.0</minBet>
                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>100.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>1.0</maxBet>
                            </configuration>
                        </configurations>

                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>
        </softwareId>
    </softwareIds>
    </game>
    <game>
    <gameName>Lucky Draw Jacks or Better</gameName>

    <gameDescription>VideoPoker</gameDescription>
    <gameType>S</gameType>
    <url>/game.do</url>
    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>
    <softwareIds>

        <softwareId id=""200-0005-001"">
            <presentationTypes>
                <presentationType code=""FLSH"">
                <wndHeight>740</wndHeight>
                <wndWidth>636</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>

                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>40.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>20.0</denomAmount>

                            <minBet>20.0</minBet>
                            <maxBet>400.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>1.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>4.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>

                            <maxBet>20.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>200.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>25.0</denomAmount>

                            <minBet>25.0</minBet>
                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>2.0</maxBet>

                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>

                            <maxBet>4.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>40.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>1.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>

                            <minBet>10.0</minBet>
                            <maxBet>200.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>20.0</denomAmount>
                            <minBet>20.0</minBet>
                            <maxBet>400.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>2.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>

                            <maxBet>100.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>500.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>20.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>

                    <currency code=""USD"">
                        <configurations>
                            <configuration>
                            <denomAmount>20.0</denomAmount>
                            <minBet>20.0</minBet>
                            <maxBet>400.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>2.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>

                            <minBet>0.5</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>
                            <maxBet>40.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>
                            <maxBet>1.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>

                            <maxBet>200.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.25</denomAmount>
                            <minBet>0.25</minBet>
                            <maxBet>5.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>

                            <minBet>1.0</minBet>
                            <maxBet>20.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>

        </softwareId>
    </softwareIds>
    </game>
    <game>
    <gameName>Monty's Millions</gameName>
    <gameDescription>SlotGame</gameDescription>
    <gameType>S</gameType>

    <url>/tc/game</url>
    <languageCodes>
        <languageCode value=""pl"" />
        <languageCode value=""hu"" />
        <languageCode value=""fi"" />
        <languageCode value=""ro"" />
        <languageCode value=""ja"" />
        <languageCode value=""es"" />

        <languageCode value=""en"" />
        <languageCode value=""sv"" />
        <languageCode value=""da"" />
        <languageCode value=""ru"" />
        <languageCode value=""de"" />
        <languageCode value=""it"" />
        <languageCode value=""el"" />
        <languageCode value=""pt"" />
        <languageCode value=""fr"" />

    </languageCodes>
    <softwareIds>
        <softwareId id=""200-1128-001"">
            <presentationTypes>
                <presentationType code=""FLSH"">
                <wndHeight>768</wndHeight>
                <wndWidth>1024</wndWidth>
                <currencies>

                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>2.0</maxBet>
                            </configuration>

                        </configurations>
                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>2.0</maxBet>

                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""USD"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>

                            <maxBet>2.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>
        </softwareId>

    </softwareIds>
    </game>
    <game>
    <gameName>Multi-Hand Three Card Poker - Classic</gameName>
    <gameDescription>TableGame-ThreeCard</gameDescription>
    <gameType>T</gameType>
    <url>/game.do</url>

    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>
    <softwareIds>
        <softwareId id=""200-0060-001"">
            <presentationTypes>
                <presentationType code=""FLSH"">
                <wndHeight>690</wndHeight>

                <wndWidth>636</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>2.0</denomAmount>
                            <minBet>2.0</minBet>

                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>20.0</denomAmount>
                            <minBet>20.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>50.0</denomAmount>

                            <minBet>50.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>1000.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>100.0</denomAmount>
                            <minBet>100.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>

                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>

                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>100.0</denomAmount>
                            <minBet>100.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>2.0</denomAmount>

                            <minBet>2.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>1000.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>20.0</denomAmount>
                            <minBet>20.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>50.0</denomAmount>
                            <minBet>50.0</minBet>

                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>25.0</denomAmount>
                            <minBet>25.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>

                            <minBet>1.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>

        </softwareId>
    </softwareIds>
    </game>
    <game>
    <gameName>Noah's Ark</gameName>
    <gameDescription>SlotGame</gameDescription>
    <gameType>S</gameType>

    <url>/tc/game</url>
    <languageCodes>
        <languageCode value=""pl"" />
        <languageCode value=""hu"" />
        <languageCode value=""fi"" />
        <languageCode value=""ro"" />
        <languageCode value=""ja"" />
        <languageCode value=""es"" />

        <languageCode value=""en"" />
        <languageCode value=""sv"" />
        <languageCode value=""da"" />
        <languageCode value=""ru"" />
        <languageCode value=""de"" />
        <languageCode value=""it"" />
        <languageCode value=""el"" />
        <languageCode value=""pt"" />
        <languageCode value=""fr"" />

    </languageCodes>
    <softwareIds>
        <softwareId id=""200-1129-001"">
            <presentationTypes>
                <presentationType code=""FLSH"">
                <wndHeight>768</wndHeight>
                <wndWidth>1024</wndWidth>
                <currencies>

                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>1.5</maxBet>
                            </configuration>

                        </configurations>
                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>1.5</maxBet>

                            </configuration>
                        </configurations>
                    </currency>
                    <currency code=""USD"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>

                            <maxBet>1.5</maxBet>
                            </configuration>
                        </configurations>
                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>
        </softwareId>

    </softwareIds>
    </game>
    <game>
    <gameName>MegaJackpots Cluedo</gameName>
    <gameDescription>SlotGame</gameDescription>
    <gameType>S</gameType>
    <url>/game.do</url>

    <languageCodes>
        <languageCode value=""en"" />
    </languageCodes>
    <softwareIds>
        <softwareId id=""200-0087-001"">
            <presentationTypes>
                <presentationType code=""FLSH"">
                <wndHeight>800</wndHeight>

                <wndWidth>636</wndWidth>
                <currencies>
                    <currency code=""GBP"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>

                            <maxBet>5.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>20.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>

                            <minBet>1.0</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>2.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>

                            <maxBet>1.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>

                        </configurations>
                    </currency>
                    <currency code=""EUR"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.2</denomAmount>
                            <minBet>0.2</minBet>
                            <maxBet>20.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>1.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>2.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>

                            <maxBet>5.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>

                            <minBet>0.1</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>
                            <minBet>5.0</minBet>
                            <maxBet>500.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>100.0</maxBet>
                            </configuration>
                        </configurations>

                    </currency>
                    <currency code=""USD"">
                        <configurations>
                            <configuration>
                            <denomAmount>0.02</denomAmount>
                            <minBet>0.02</minBet>
                            <maxBet>2.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.1</denomAmount>
                            <minBet>0.1</minBet>
                            <maxBet>10.0</maxBet>
                            </configuration>
                            <configuration>

                            <denomAmount>0.5</denomAmount>
                            <minBet>0.5</minBet>
                            <maxBet>50.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>0.05</denomAmount>
                            <minBet>0.05</minBet>

                            <maxBet>5.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>10.0</denomAmount>
                            <minBet>10.0</minBet>
                            <maxBet>1000.0</maxBet>
                            </configuration>

                            <configuration>
                            <denomAmount>0.25</denomAmount>
                            <minBet>0.25</minBet>
                            <maxBet>25.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>5.0</denomAmount>

                            <minBet>5.0</minBet>
                            <maxBet>500.0</maxBet>
                            </configuration>
                            <configuration>
                            <denomAmount>1.0</denomAmount>
                            <minBet>1.0</minBet>
                            <maxBet>100.0</maxBet>

                            </configuration>
                            <configuration>
                            <denomAmount>0.01</denomAmount>
                            <minBet>0.01</minBet>
                            <maxBet>1.0</maxBet>
                            </configuration>
                        </configurations>

                    </currency>
                </currencies>
                </presentationType>
            </presentationTypes>
        </softwareId>
    </softwareIds>
    </game>
</channel>
</channels>

<status>SUCCESS</status>
</gameListV2Response>

";
    //*/
                #endregion

                string gameListResponse = uri.EndsWith("v3") ? "gameListV3Response" : "gameListV2Response";
                XmlDocument xmlDoc = new XmlDocument();
                xmlDoc.LoadXml(xml);
                XmlNode statusNode = xmlDoc.SelectSingleNode(string.Format("/{0}/status/text()", gameListResponse));
                if (statusNode == null ||
                    !string.Equals(statusNode.Value, "SUCCESS", StringComparison.InvariantCultureIgnoreCase))
                    return igtGames;

                XmlNodeList channelNodes = xmlDoc.SelectNodes(string.Format("/{0}/channels/channel", gameListResponse));
                foreach (XmlNode channelNode in channelNodes)
                {
                    XmlNodeList gameNodes = channelNode.SelectNodes("game");


                    foreach (XmlNode gameNode in gameNodes)
                    {
                        string gameName = null, description = null, url = null;
                        XmlNode textNode = gameNode.SelectSingleNode("gameName/text()");
                        if (textNode != null) gameName = textNode.Value;
                        textNode = gameNode.SelectSingleNode("gameDescription/text()");
                        if (textNode != null) description = textNode.Value;
                        textNode = gameNode.SelectSingleNode("url/text()");
                        if (textNode != null) url = textNode.Value;

                        List<string> languages = new List<string>();
                        XmlNodeList languagesNodes = gameNode.SelectNodes("languageCodes/languageCode[@value]");
                        foreach (XmlNode languageNode in languagesNodes)
                        {
                            languages.Add(languageNode.Attributes["value"].Value.ToLowerInvariant());
                        }

                        XmlNodeList softwareIdNodes = gameNode.SelectNodes("softwareIds/softwareId[@id]");

                        foreach (XmlNode softwareIdNode in softwareIdNodes)
                        {
                            string softwareId = softwareIdNode.Attributes["id"].Value;
                            XmlNode presentationNode = softwareIdNode.SelectSingleNode("presentationTypes/presentationType[@code]");
                            if (presentationNode != null)
                            {
                                int width = 0, height = 0;
                                string type = presentationNode.Attributes["code"].Value;
                                textNode = presentationNode.SelectSingleNode("wndWidth/text()");
                                if (textNode != null)
                                    int.TryParse(textNode.Value, NumberStyles.Integer, CultureInfo.InvariantCulture, out width);
                                textNode = presentationNode.SelectSingleNode("wndHeight/text()");
                                if (textNode != null)
                                    int.TryParse(textNode.Value, NumberStyles.Integer, CultureInfo.InvariantCulture, out height);


                                Dictionary<string, List<IGTIntegration.Configuration>> configurations
                                    = new Dictionary<string, List<IGTIntegration.Configuration>>(StringComparer.InvariantCultureIgnoreCase);
                                XmlNodeList currencyNodes = presentationNode.SelectNodes("currencies/currency[@code]");
                                foreach (XmlNode currencyNode in currencyNodes)
                                {
                                    List<IGTIntegration.Configuration> currencyConfigs = new List<IGTIntegration.Configuration>();

                                    string currency = currencyNode.Attributes["code"].Value.ToUpperInvariant();

                                    if (string.Equals(currency, "FPY", StringComparison.InvariantCultureIgnoreCase))
                                        continue;

                                    XmlNodeList configurationNodes = currencyNode.SelectNodes("configurations/configuration");
                                    foreach (XmlNode configurationNode in configurationNodes)
                                    {
                                        XmlNode denomNode = configurationNode.SelectSingleNode("denomAmount");
                                        XmlNode minBetNode = configurationNode.SelectSingleNode("minBet");
                                        XmlNode maxBetNode = configurationNode.SelectSingleNode("maxBet");
                                        if (denomNode != null && minBetNode != null && maxBetNode != null)
                                        {
                                            decimal denom = 0.00M, minBet = 0.00M, maxBet = 0.00M;
                                            if (decimal.TryParse(denomNode.InnerText, NumberStyles.AllowDecimalPoint, CultureInfo.InvariantCulture, out denom) &&
                                                decimal.TryParse(minBetNode.InnerText, NumberStyles.AllowDecimalPoint, CultureInfo.InvariantCulture, out minBet) &&
                                                decimal.TryParse(maxBetNode.InnerText, NumberStyles.AllowDecimalPoint, CultureInfo.InvariantCulture, out maxBet))
                                            {
                                                IGTIntegration.Configuration config = new IGTIntegration.Configuration()
                                                {
                                                    DenomAmount = denom,
                                                    MinBet = minBet,
                                                    MaxBet = maxBet,
                                                };
                                                currencyConfigs.Add(config);
                                            }
                                        }
                                    }

                                    configurations[currency] = currencyConfigs;
                                }

                                IGTIntegration.Game game = new IGTIntegration.Game(
                                    channelNode.Attributes["code"].Value
                                    , presentationNode.Attributes["code"].Value
                                    , configurations
                                    )
                                {
                                    SoftwareID = softwareId,
                                    Title = gameName,
                                    Description = description,
                                    Url = url,
                                    Width = width,
                                    Height = height,
                                    LanguageCodes = languages.ToArray(),
                                };
                                igtGames[softwareId] = game;
                            }
                        }
                    }
                }

                ObjectHelper.BinarySerialize<Dictionary<string, IGTIntegration.Game>>(igtGames, destPath);

                HttpRuntime.Cache.Insert(destPath, igtGames, null, DateTime.Now.AddHours(6), Cache.NoSlidingExpiration);
                Logger.Information(string.Format("Number of received IGT games: {0}", igtGames.Count));
                return igtGames;
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return new Dictionary<string, IGTIntegration.Game>();
            }
        };

        Task<Dictionary<string, IGTIntegration.Game>> task = Task<Dictionary<string, IGTIntegration.Game>>.Factory.StartNew(() => action(request, physicalPath));

        // if it is null, wait for it
        if (games == null)
        {
            task.Wait();
            games = task.Result;
            //games = new Dictionary<string, IGTIntegration.Game>();
        }
        return games;

    }


    /// <summary>
    /// 
    /// </summary>
    /// <param name="domain"></param>
    /// <returns>id - name</returns>
    public static Dictionary<string, string> GetBetSoftGames(ceDomainConfig domain)
    {
        string url;
        if (domain != null)
            url = string.Format(domain.GetCfg(BetSoft.CasinoGameListURL), domain.GetCfg(BetSoft.BankID));
        else
            url = ConfigurationManager.AppSettings["SystemBetSoftGameListUrl"] as string;
        string filename = string.Format("GamMatrixClient.GetBetSoftGames.{0}", url.GetHashCode());
        string physicalPath = Path.Combine(FileSystemUtility.GetWebSiteTempDirectory(), filename);


        // try to get from cache
        Dictionary<string, string> cached = HttpRuntime.Cache[physicalPath] as Dictionary<string, string>;
        if (cached != null)
            return cached;

        // then check if it is avaliable in filecache
        if (File.Exists(physicalPath))
            cached = ObjectHelper.BinaryDeserialize<Dictionary<string, string>>(physicalPath, null);


        Func<string, Dictionary<string, string>> action = (string gameListUrl) =>
        {
            Dictionary<string, string> dic = new Dictionary<string, string>();
            try
            {

                XElement root = XElement.Load(url);

                IEnumerable<XElement> games = root.Descendants("GAME");
                foreach (XElement game in games)
                {
                    if (game.Attribute("ID") != null &&
                        game.Attribute("NAME") != null)
                    {
                        dic[game.Attribute("ID").Value] = game.Attribute("NAME").Value;
                    }
                }

                ObjectHelper.BinarySerialize<Dictionary<string, string>>(dic, physicalPath);

                HttpRuntime.Cache.Insert(physicalPath, dic, null, DateTime.Now.AddMinutes(10), Cache.NoSlidingExpiration);
                return dic;
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return dic;
            }
        };


        Task<Dictionary<string, string>> task = Task<Dictionary<string, string>>.Factory.StartNew(() => action(url));

        // if it is null, wait for it
        if (cached == null)
        {
            task.Wait();
            cached = task.Result;
        }
        return cached;
    }



    public static Dictionary<string, BallyIntegration.Game> GetBallyGames(long domainID)
    {
        //string filename = string.Format("GamMatrixClient.GetBallyGames.{0}", domainID);
        //string physicalPath = Path.Combine(FileSystemUtility.GetWebSiteTempDirectory(), filename);

        //// try to get from cache
        //Dictionary<string, BallyIntegration.Game> games = HttpRuntime.Cache[physicalPath] as Dictionary<string, BallyIntegration.Game>;
        //if (games != null)
        //    return games;

        //// then check if it is avaliable in filecache
        //if (File.Exists(physicalPath))
        //    games = ObjectHelper.BinaryDeserialize<Dictionary<string, BallyIntegration.Game>>(physicalPath, null);

        //using (GamMatrixClient client = new GamMatrixClient())
        //{
        //    BallyGetGamesListRequest request = new BallyGetGamesListRequest()
        //    {
        //        PageSize = 500,
        //        PageNumber = 0
        //    };

        //    Func<BallyGetGamesListRequest, string, Dictionary<string, BallyIntegration.Game>> action = (BallyGetGamesListRequest req, string destPath) =>
        //    {
        //        try
        //        {
        //            req = client.SingleRequest<BallyGetGamesListRequest>(domainID, req);

        //            JavaScriptSerializer ser = new JavaScriptSerializer();
        //            BallyIntegration.GamesWrapper gamesWrapper = ser.Deserialize<BallyIntegration.GamesWrapper>(req.Games);

        //            if (gamesWrapper.Games.TotalCount > req.PageSize)
        //            {
        //                req.PageSize = gamesWrapper.Games.TotalCount;
        //                req = client.SingleRequest<BallyGetGamesListRequest>(domainID, req);

        //                gamesWrapper = ser.Deserialize<BallyIntegration.GamesWrapper>(req.Games);
        //            }

        //            games = new Dictionary<string, BallyIntegration.Game>();
        //            foreach (BallyIntegration.Game game in gamesWrapper.Games.Items)
        //            {
        //                games.Add(game.SoftwareID, game);
        //            }

        //            ObjectHelper.BinarySerialize<Dictionary<string, BallyIntegration.Game>>(games, destPath);
        //            HttpRuntime.Cache.Insert(destPath, games, null, DateTime.Now.AddMinutes(30), Cache.NoSlidingExpiration);
        //            return games;
        //        }
        //        catch (Exception ex)
        //        {
        //            Logger.Exception(ex);
        //        }
        //        return new Dictionary<string, BallyIntegration.Game>();
        //    };

        //    Task<Dictionary<string, BallyIntegration.Game>> task = Task<Dictionary<string, BallyIntegration.Game>>.Factory.StartNew(() => action(request, physicalPath));

        //    // if it is null, wait for it
        //    if (games == null)
        //    {
        //        task.Wait();
        //        games = task.Result;
        //        //gameIDs = new string[0]; 
        //    }
        //}

        //return games;
        return null;
    }



    #endregion
}

