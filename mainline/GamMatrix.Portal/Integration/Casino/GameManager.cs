using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;
using System.Web;
using System.Web.Caching;
using System.Web.Hosting;
using System.Xml.Serialization;
using CM.Content;
using CM.db;
using CM.db.Accessor;
using CM.Sites;
using CM.State;
using Finance;
using GamMatrix.Infrastructure;
using GamMatrixAPI;
using GmCore;

namespace Casino
{
    /// <summary>
    /// Summary description for GameManager
    /// </summary>
    public static class GameManager
    {
        public const string CATEGORIES_FILE = @"~/Views/{0}/Metadata/Casino/Categories/.data.xml";
        public const string CATEGORY_METADATA = @"/Metadata/Casino/Categories/{0}";
        public const string METADATA_PATH = @"/Metadata/Casino/Games/{0}";
        private const string CACHE_KEY = @"Casino.GameManager_AllCasinoCache_{0}";


        private static ConcurrentDictionary<VendorID, ConcurrentDictionary<string, Game>> GetAllGames(cmSite site)
        {
            string cacheKey = string.Format(CACHE_KEY, site.DistinctName);
            ConcurrentDictionary<VendorID, ConcurrentDictionary<string, Game>> allGames
                = HttpRuntime.Cache[cacheKey] as ConcurrentDictionary<VendorID, ConcurrentDictionary<string, Game>>;
            if (allGames == null)
            {
                lock (typeof(GameManager))
                {
                    allGames = HttpRuntime.Cache[cacheKey] as ConcurrentDictionary<VendorID, ConcurrentDictionary<string, Game>>;
                    if (allGames == null)
                    {
                        allGames = new ConcurrentDictionary<VendorID, ConcurrentDictionary<string, Game>>();
                        HttpRuntime.Cache[cacheKey] = allGames;
                    }
                }
            }
            return allGames;
        }

        public static void ClearCache(cmSite site)
        {
            string cacheKey = string.Format(CACHE_KEY, site.DistinctName);
            HttpRuntime.Cache.Remove(cacheKey);
        }

        /// <summary>
        /// Get the casino games for special vendor
        /// </summary>
        /// <param name="vendorID"></param>
        /// <param name="site"></param>
        /// <returns></returns>
        public static ConcurrentDictionary<string, Game> GetGames(VendorID vendorID, cmSite site = null)
        {
            if (site == null)
                site = SiteManager.Current;
            ConcurrentDictionary<VendorID, ConcurrentDictionary<string, Game>> allGames = GetAllGames(site);
            ConcurrentDictionary<string, Game> games = null;
            if (allGames.TryGetValue(vendorID, out games))
                return games;

            games = new ConcurrentDictionary<string, Game>();

            string[] paths = Metadata.GetChildrenPaths(site, string.Format(Casino.GameManager.METADATA_PATH, vendorID.ToString()));

            foreach (string path in paths)
            {
                Game game = new Game(path, site);
                games[game.ID] = game;
            }
            allGames[vendorID] = games;
            return games;
        }


        /// <summary>
        /// Get Game object by GameID
        /// </summary>
        /// <param name="gameID"></param>
        /// <param name="site"></param>
        /// <returns></returns>
        public static Game GetGame(this GameID gameID, cmSite site = null)
        {
            if (gameID == null)
                throw new ArgumentNullException("gameID");
            Game game = null;
            var games = GetGames(gameID.VendorID, site);
            games.TryGetValue(gameID.ID, out game);
            return game;
        }

        /// <summary>
        /// Get the parameters for NetEnt games
        /// </summary>
        /// <param name="gameid"></param>
        /// <param name="language"></param>
        /// <returns></returns>
        public static Dictionary<string, string> GetNetEntGameParameters(string gameid, string language = null
            , string sessionID = null
            , long sessionUserID = 0
            )
        {
            if (string.IsNullOrWhiteSpace(language))
                language = MultilingualMgr.GetCurrentCulture();

            if (language == "bg")
                language = "en";

            using (GamMatrixClient client = GamMatrixClient.Get() )
            {
                NetEntAPIRequest request = new NetEntAPIRequest()
                {
                    SESSION_ID = sessionID,
                    SESSION_USERID = sessionUserID,
                    GetGameInfo = true,
                    GetGameInfoGameID = gameid,
                    GetGameInfoLanguage = MultilingualMgr.ConvertToISO639(language),
                };
                request = client.SingleRequest<NetEntAPIRequest>(request);
                Dictionary<string, string> ret = new Dictionary<string, string>();

                for (int i = 0; i < request.GetGameInfoResponse.Count - 1; i += 2)
                {
                    ret[request.GetGameInfoResponse[i]] = request.GetGameInfoResponse[i + 1];
                }
                return ret;
            }
        }


        public static void ClearCategoryCache(cmSite site)
        {
            string cacheKey = string.Format("casino_games_categories_{0}", site.DistinctName);
            HttpRuntime.Cache.Remove(cacheKey);
        }


        /// <summary>
        /// Load the categories
        /// </summary>
        /// <param name="site"></param>
        /// <param name="useCache"></param>
        /// <returns></returns>
        public static List<GameCategory> GetCategories(cmSite site = null, bool useCache = true)
        {
            if (site == null)
                site = SiteManager.Current;

            List<GameCategory> categories = null;
            string cacheKey = string.Format("casino_games_categories_{0}", site.DistinctName);
            if (useCache)
            {
                categories = HttpRuntime.Cache[cacheKey] as List<GameCategory>;
                if (categories != null)
                    return categories;
            }

            List<string> dependedFiles = new List<string>();
            
            string path = HostingEnvironment.MapPath(string.Format(CATEGORIES_FILE, site.DistinctName));
            dependedFiles.Add(path);
            XmlSerializer xs = new XmlSerializer(typeof(List<GameCategory>));
            if (File.Exists(path))
            {
                try
                {
                    using (FileStream fs = new FileStream(path
                        , FileMode.Open
                        , FileAccess.Read
                        , FileShare.Delete | FileShare.ReadWrite))
                    {
                        categories = (List<GameCategory>)xs.Deserialize(fs);
                    }
                }
                catch
                {
                }
            }

            if (categories == null && !string.IsNullOrWhiteSpace(site.TemplateDomainDistinctName))
            {
                path = HostingEnvironment.MapPath(string.Format(CATEGORIES_FILE, site.TemplateDomainDistinctName));
                dependedFiles.Add(path);
                if (File.Exists(path))
                {
                    try
                    {
                        using (FileStream fs = new FileStream(path
                        , FileMode.Open
                        , FileAccess.Read
                        , FileShare.Delete | FileShare.ReadWrite))
                        {
                            categories = (List<GameCategory>)xs.Deserialize(fs);
                        }
                    }
                    catch
                    {
                    }
                }
            }
            if (categories == null)
                categories = new List<GameCategory>();
            HttpRuntime.Cache.Insert(cacheKey
                , categories
                , new CacheDependencyEx(dependedFiles.ToArray(), false)
                , DateTime.Now.AddHours(1)
                , Cache.NoSlidingExpiration
                );
            return categories;
        }

        /// <summary>
        /// Save the categories to file
        /// </summary>
        /// <param name="site"></param>
        /// <param name="categories"></param>
        /// <returns></returns>
        public static void SaveCategories(cmSite site, List<GameCategory> categories)
        {
            if (site == null)
                site = SiteManager.Current;

            string path = HostingEnvironment.MapPath(string.Format(CATEGORIES_FILE, site.DistinctName));
            XmlSerializer xs = new XmlSerializer(typeof(List<GameCategory>));

            FileSystemUtility.EnsureDirectoryExist(path);
            using (FileStream fs = new FileStream(path
                , FileMode.OpenOrCreate
                , FileAccess.Write
                , FileShare.Delete | FileShare.ReadWrite))
            {
                fs.SetLength(0);
                xs.Serialize(fs, categories);
            }
        }




        public static string GetNetEntSessionID()
        {
            if (!CustomProfile.Current.IsAuthenticated)
                return string.Empty;

            using (GamMatrixClient client = GamMatrixClient.Get() )
            {
                NetEntAPIRequest request;
                string cacheKey = string.Format("{0}_casino_netent_session_id", CustomProfile.Current.UserID);

                // use the cached session if still valid
                string sessionID = HttpRuntime.Cache[cacheKey] as string;
                if (!string.IsNullOrWhiteSpace(sessionID))
                {
                    request = new NetEntAPIRequest()
                    {
                        IsUserSessionAlive = true,
                        IsUserSessionAliveSessionID = sessionID,
                    };
                    request = client.SingleRequest<NetEntAPIRequest>(request);
                    if (request.IsUserSessionAliveResponse)
                        return sessionID;
                }

                // generate a new session id
                request = new NetEntAPIRequest()
                {
                    LoginUserDetailed = true,
                    UserID = CustomProfile.Current.UserID
                };
                request = client.SingleRequest<NetEntAPIRequest>(request);
                sessionID = request.LoginUserDetailedResponse;

                HttpRuntime.Cache[cacheKey] = sessionID;
                return sessionID;
            }
        }


        public static string CreateMicrogamingToken()
        {
            if (!CustomProfile.Current.IsAuthenticated)
                return string.Empty;

            using (GamMatrixClient client = GamMatrixClient.Get() )
            {
                VanguardGetSessionRequest request = new VanguardGetSessionRequest()
                {
                    UserID = CustomProfile.Current.UserID,
                    // GameCode = 
                };
                request = client.SingleRequest<VanguardGetSessionRequest>(request);
                return request.Token;
            }
        }

        public static string CreateCTXMTicket()
        {
            if (!CustomProfile.Current.IsAuthenticated)
                return string.Empty;

            using (GamMatrixClient client = GamMatrixClient.Get() )
            {
                //CTXMGetSessionRequest request = new CTXMGetSessionRequest()
                //{
                //    UserID = CustomProfile.Current.UserID
                //};
                //request = client.SingleRequest<CTXMGetSessionRequest>(request);
                //return request.Ticket;
                return null;
            }
        }


        /// <summary>
        /// Get last winners
        /// </summary>
        /// <returns></returns>
        public static List<Winner> GetLastWinners()
        {
            string cacheKey = string.Format( "_casino_last_winners_{0}", SiteManager.Current.DistinctName);
            List<Winner> winners = HttpRuntime.Cache[cacheKey] as List<Winner>;
            if (winners != null)
                return winners;

            /////////////////////////////////////////////////////////////
            // start NetEnt
            using (GamMatrixClient client = GamMatrixClient.Get() )
            {
                NetEntAPIRequest request = new NetEntAPIRequest()
                {
                    GetCurrentOverview = true,
                };
                request = client.SingleRequest<NetEntAPIRequest>(request);
                var query = from record in request.GetCurrentOverviewResponse.winnersField
                            where record.playerMoneyWinAmountField.amountField.HasValue && record.playerMoneyWinAmountField.amountField.Value > 0.00M
                            group record by new { record.winUserNameField, record.winGameIdField, record.playerMoneyWinAmountField.amountCurrencyISOCodeField } into grouping
                            select new Winner()
                            {
                                Username = grouping.Key.winUserNameField,
                                GameID = new GameID( VendorID.NetEnt, grouping.Key.winGameIdField),
                                Currency = grouping.Key.amountCurrencyISOCodeField,
                                Amount = grouping.Sum( p => p.playerMoneyWinAmountField.amountField.Value)
                            };
                List<Winner> list1 = query.ToList();

                List<CountryInfo> countries = CountryManager.GetAllCountries();
                List<KeyValuePair<long, string>> domain2UsernameMap = new List<KeyValuePair<long, string>>();
                foreach (Winner winner in list1)
                {
                    Match m = Regex.Match(winner.Username, @"^(?<DomainID>\d+)\~(?<Username>.+)$", RegexOptions.Compiled | RegexOptions.ECMAScript);
                    if (m.Success)
                    {
                        winner.DomainID = long.Parse(m.Groups["DomainID"].Value);
                        winner.Username = m.Groups["Username"].Value;
                        domain2UsernameMap.Add( new KeyValuePair<long,string>( winner.DomainID, winner.Username));
                        
                    }
                }
                List<cmUser> users = UserAccessor.GetUsersByUsername(domain2UsernameMap);
                foreach (Winner winner in list1)
                {
                    cmUser user = users.FirstOrDefault(u => string.Equals(winner.Username, u.Username, StringComparison.OrdinalIgnoreCase) && winner.DomainID == u.DomainID);
                    if (user != null)
                    {
                        winner.DisplayName = string.Format("{0}.{1}"
                            , (user.FirstName ?? string.Empty).Truncate(1).ToUpper()
                            , (user.Surname ?? string.Empty).Truncate(1).ToUpper()
                            );
                        winner.Firstname = user.FirstName;
                        winner.Surname = user.Surname;
                        winner.CountryInfo = countries.FirstOrDefault(c => c.InternalID == user.CountryID);
                    }
                }
                winners = list1;
            }
            // end NetEnt

            string path = HostingEnvironment.MapPath( string.Format("~/App_Data/_casino_last_winners_{0}.xml", SiteManager.Current.DistinctName));

            if (winners != null && winners.Count > 0)
            {
                using (FileStream fs = new FileStream(path, FileMode.OpenOrCreate, FileAccess.Write, FileShare.ReadWrite))
                {
                    fs.SetLength(0);
                    XmlSerializer xs = new XmlSerializer(winners.GetType());
                    xs.Serialize(fs, winners);
                    fs.Flush();
                    fs.Close();
                }
            }
            else if( File.Exists(path) )
            {
                using (FileStream fs = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.ReadWrite))
                {
                    XmlSerializer xs = new XmlSerializer(winners.GetType());
                    winners = xs.Deserialize(fs) as List<Winner>;
                    fs.Close();
                }
            }

            if (winners != null && winners.Count > 0)
                HttpRuntime.Cache.Insert(cacheKey, winners, null, DateTime.Now.AddMinutes(15), Cache.NoSlidingExpiration);

            return winners ?? new List<Winner>();
        }// GetLastWinners


        /// <summary>
        /// GetJackpots
        /// </summary>
        /// <returns></returns>
        public static List<JackpotInfo> GetJackpots(string currency)
        {
            currency =  currency.DefaultIfNullOrEmpty("EUR");
            string cacheKey = string.Format("_casino_jackpots_{0}_{1}", currency, SiteManager.Current.DistinctName);
            List<JackpotInfo> jackpots = HttpRuntime.Cache[cacheKey] as List<JackpotInfo>;
            if (jackpots != null)
                return jackpots;

            ////////////////////////////////////////////////////////
            // NetEnt
            using (GamMatrixClient client = GamMatrixClient.Get() )
            {
                NetEntAPIRequest request = new NetEntAPIRequest()
                {
                    GetCurrentOverview = true,
                };
                request = client.SingleRequest<NetEntAPIRequest>(request);

                if (request.GetCurrentOverviewResponse != null &&
                    request.GetCurrentOverviewResponse.jackpotsField != null)
                {
                    List<JackpotInfo> list1 = new List<JackpotInfo>();
                    foreach (JackpotOverviewData jackpotOverviewData in request.GetCurrentOverviewResponse.jackpotsField)
                    {
                        if ( jackpotOverviewData == null ||
                             jackpotOverviewData.currentJackpotValueField == null ||
                            !jackpotOverviewData.currentJackpotValueField.amountField.HasValue ||
                             jackpotOverviewData.currentJackpotValueField.amountField.Value <= 0.00M )
                            continue;
                        JackpotInfo jackpot = new JackpotInfo()
                        {
                            ID = jackpotOverviewData.jackpotNameField,
                            Currency = currency,
                            Amount = MoneyHelper.TransformCurrency( jackpotOverviewData.currentJackpotValueField.amountCurrencyISOCodeField
                             , currency
                             , jackpotOverviewData.currentJackpotValueField.amountField.Value
                             ),
                        };
                        list1.Add(jackpot);
                        switch (jackpotOverviewData.jackpotNameField.ToLowerInvariant())
                        {
                            case "arabian": jackpot.Games.Add(new GameID(VendorID.NetEnt, "arabian")); break;
                            case "bingo": jackpot.Games.Add(new GameID(VendorID.NetEnt, "bingo")); break;
                            case "cashbomb": jackpot.Games.Add(new GameID(VendorID.NetEnt, "cashbomb")); break;
                            case "cstud": jackpot.Games.Add(new GameID(VendorID.NetEnt, "cstudflash")); break;
                            case "fishyfortune": jackpot.Games.Add(new GameID(VendorID.NetEnt, "fishyfortune")); break;
                            case "frog1": jackpot.Games.Add(new GameID(VendorID.NetEnt, "frog")); break;
                            case "frog2": jackpot.Games.Add(new GameID(VendorID.NetEnt, "frog")); break;
                            case "frog3": jackpot.Games.Add(new GameID(VendorID.NetEnt, "frog")); break;
                            case "goldrush": jackpot.Games.Add(new GameID(VendorID.NetEnt, "goldrushflash")); break;
                            case "hrscratchticketjp": jackpot.Games.Add(new GameID(VendorID.NetEnt, "hrscratchticketjp")); break;
                            case "hrscratchticketjpb": jackpot.Games.Add(new GameID(VendorID.NetEnt, "hrscratchticketjp")); break;
                            case "keno": jackpot.Games.Add(new GameID(VendorID.NetEnt, "kenobnjp")); break;
                            case "vault": jackpot.Games.Add(new GameID(VendorID.NetEnt, "vault")); break;
                            case "wonder1": jackpot.Games.Add(new GameID(VendorID.NetEnt, "tiki")); jackpot.Games.Add(new GameID(VendorID.NetEnt, "ice")); jackpot.Games.Add(new GameID(VendorID.NetEnt, "geisha")); break;
                            case "wonder2": jackpot.Games.Add(new GameID(VendorID.NetEnt, "tiki")); jackpot.Games.Add(new GameID(VendorID.NetEnt, "ice")); jackpot.Games.Add(new GameID(VendorID.NetEnt, "geisha")); break;
                            case "megajoker": jackpot.Games.Add(new GameID(VendorID.NetEnt, "megajoker")); break;
                            case "horserace": jackpot.Games.Add(new GameID(VendorID.NetEnt, "horserace")); break;
                            //case "megajackpot1": jackpot.Games.Add(new GameID(VendorID.NetEnt, "megajackpot")); break;
                            //case "megajackpot2": jackpot.Games.Add(new GameID(VendorID.NetEnt, "megajackpot")); break;
                            //case "megajackpot3": jackpot.Games.Add(new GameID(VendorID.NetEnt, "megajackpot")); break;
                            case "hog_small": jackpot.Games.Add(new GameID(VendorID.NetEnt, "hallofgods")); break;
                            case "hog_medium": jackpot.Games.Add(new GameID(VendorID.NetEnt, "hallofgods")); break;
                            case "hog_large": jackpot.Games.Add(new GameID(VendorID.NetEnt, "hallofgods")); break;
                            case "simsalabim1": jackpot.Games.Add(new GameID(VendorID.NetEnt, "simsalabim")); break;
                            case "simsalabim2": jackpot.Games.Add(new GameID(VendorID.NetEnt, "simsalabim")); break;
                        } // switch
                    }// foreach
                    jackpots = list1.OrderByDescending( j => j.Amount ).ToList();
                } // if            
            }// using

            if( jackpots != null && jackpots.Count > 0 ) 
                HttpRuntime.Cache.Insert(cacheKey, jackpots, null, DateTime.Now.AddMinutes(30), Cache.NoSlidingExpiration);


            return jackpots ?? new List<JackpotInfo>();
        }

        public static List<GameID> GetMostPopularGames()
        {
            /*string[] gameIDs = new string[] { "bloodsuckers", "eldorado", "piggyriches", "reelsteal", 
                "deadoralive", "jackhammer", "excalibur", "lrroulette2adv"};*/
            string[] gameIDs = {};
            string strGameIDs = Metadata.Get("/Metadata/Casino/MostPopularGames.Games");
            if (!string.IsNullOrEmpty(strGameIDs))
            {
                gameIDs = strGameIDs.Split(new char[]{','}, StringSplitOptions.RemoveEmptyEntries);
            }
            return gameIDs.Length>0 ? gameIDs.Select(g => new GameID { VendorID = VendorID.NetEnt, ID = g }).ToList() : new List<GameID>();
        }

        /// <summary>
        /// Get total jackpot amount
        /// </summary>
        /// <param name="currency"></param>
        /// <returns></returns>
        public static decimal GetTotalJackpotAmount(string currency)
        {
            List<JackpotInfo> jackpots = GetJackpots(currency);
            return jackpots.Where(j => j.Games.Count > 0).Sum(j => j.Amount);
        }


    }
}