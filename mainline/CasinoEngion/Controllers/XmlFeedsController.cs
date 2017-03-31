using System;
using System.Collections.Generic;
using System.Configuration;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Net.Mail;
using System.Text;
using System.Threading.Tasks;
using System.Web;
using System.Web.Mvc;
using System.Text.RegularExpressions;

using BLToolkit.DataAccess;

using CE.db;
using CE.db.Accessor;
using CE.DomainConfig;
using CE.Integration.Metadata;
using CE.Integration.Recommendation;
using CE.Utils;
using GamMatrixAPI;
using CasinoEngine.Models;
using Newtonsoft.Json;
using System.Xml.Serialization;
using EveryMatrix.SessionAgent.Protocol;
using EveryMatrix.SessionAgent;

namespace CasinoEngine.Controllers
{

    public partial class XmlFeedsController : ServiceControllerBase
    {
        private const string VENDORS_CACHE_KEY_FORMAT = "{0}{1}";

        private const string JACKPOT_LIST_CACHE_KEY_FORMAT = "{0}{1}{2}";
        private const string TOP_WINNERS_CACHE_KEY_FORMAT = "{0}{1}_{2}_{3}_{4}_{5}_{6}_{7}_{8}";
        private const string RECENT_WINNERS_CACHE_KEY_FORMAT = "{0}{1}_{2}";

        private const string CONTENT_PROVIDERS_CACHE_KEY_FORMAT = "{0}{1}";

        private static AgentClient _agentClient = new AgentClient(
    ConfigurationManager.AppSettings["SessionAgent.ZooKeeperConnectionString"],
    ConfigurationManager.AppSettings["SessionAgent.ClusterName"],
    ConfigurationManager.AppSettings["SessionAgent.UseProtoBuf"] == "1"
    );
        private bool HasIntersection(string commaSeperatedStr1, string commaSeperatedStr2)
        {
            if (string.IsNullOrWhiteSpace(commaSeperatedStr2) || string.IsNullOrWhiteSpace(commaSeperatedStr1))
                return false;

            List<string> list = commaSeperatedStr1.Split(',')
                            .Where(c => !string.IsNullOrWhiteSpace(c))
                            .Select(c => c.Trim().ToUpperInvariant())
                            .ToList();

            string[] items = commaSeperatedStr2.Split(',');
            foreach (string item in items)
            {
                if (string.IsNullOrWhiteSpace(item))
                    continue;
                if (list.Contains(item, StringComparer.InvariantCultureIgnoreCase))
                    return true;
            }
            return false;
        }

        private string GetLoaderUrl(ceDomainConfig domain, long gameID, string slug, VendorID gamingVendor)
        {
            string protocol = string.Empty;

            #region protocol for vendor
            switch (gamingVendor)
            {
                case VendorID.BetSoft:
                    protocol = domain.GetCfg(BetSoft.CELaunchUrlProtocol);
                    break;
                case VendorID.CTXM:
                    protocol = domain.GetCfg(CTXM.CELaunchUrlProtocol);
                    break;
                case VendorID.GreenTube:
                    protocol = domain.GetCfg(GreenTube.CELaunchUrlProtocol);
                    break;
                case VendorID.PokerKlas:
                    protocol = domain.GetCfg(PokerKlas.CELaunchUrlProtocol);
                    break;
                case VendorID.IGT:
                    protocol = domain.GetCfg(IGT.CELaunchUrlProtocol);
                    break;
                case VendorID.Microgaming:
                    protocol = domain.GetCfg(Microgaming.CELaunchUrlProtocol);
                    break;
                case VendorID.NetEnt:
                    protocol = domain.GetCfg(NetEnt.CELaunchUrlProtocol);
                    break;
                case VendorID.PlaynGO:
                    protocol = domain.GetCfg(PlaynGO.CELaunchUrlProtocol);
                    break;
                case VendorID.Sheriff:
                    protocol = domain.GetCfg(Sheriff.CELaunchUrlProtocol);
                    break;
                case VendorID.OMI:
                    protocol = domain.GetCfg(OMI.CELaunchUrlProtocol);
                    break;
                case VendorID.EvolutionGaming:
                    protocol = domain.GetCfg(EvolutionGaming.CELaunchUrlProtocol);
                    break;
                case VendorID.NYXGaming:
                    protocol = domain.GetCfg(NYXGaming.CELaunchUrlProtocol);
                    break;
                case VendorID.BallyGaming:
                    protocol = domain.GetCfg(BallyGaming.CELaunchUrlProtocol);
                    break;
                case VendorID.Norske:
                    protocol = domain.GetCfg(Norske.CELaunchUrlProtocol);
                    break;
                case VendorID.Realistic:
                    protocol = domain.GetCfg(Realistic.CELaunchUrlProtocol);
                    break;
                case VendorID.QuickSpin:
                    protocol = domain.GetCfg(QuickSpin.CELaunchUrlProtocol);
                    break;
                case VendorID.Parlay:
                    protocol = domain.GetCfg(Parlay.CELaunchUrlProtocol);
                    break;
                case VendorID.Genii:
                    protocol = domain.GetCfg(Genii.CELaunchUrlProtocol);
                    break;
                case VendorID.CandleBets:
                    protocol = domain.GetCfg(CandleBets.CELaunchUrlProtocol);
                    break;

            }
            #endregion protocol for vendor

            if (string.IsNullOrWhiteSpace(protocol))
                protocol = ConfigurationManager.AppSettings["LaunchUrlProtocol"].DefaultIfNullOrWhiteSpace("http");

            return string.Format("{0}{1}/Loader/Start/{2}/{3}"
                    , string.Equals(protocol, "https", StringComparison.InvariantCultureIgnoreCase) ? "https://" : "http://"
                    , domain.GameLoaderDomain
                    , domain.DomainID
                    , slug.DefaultIfNullOrEmpty(gameID.ToString())
                    );
        }

        private string GetHelpUrl(ceDomainConfig domain, ceCasinoGameBaseEx game)
        {
            var gameInformation = CasinoGame.GetGameInformation(domain, game.ID, "en");
            if (!string.IsNullOrWhiteSpace(gameInformation))
            {
                string protocol = string.Equals(ConfigurationManager.AppSettings["ProductionMode"], "off", StringComparison.InvariantCultureIgnoreCase)
                    ? "http://" : "https://";
                return string.Format("{0}{1}{2}"
                        , protocol
                        , domain.GameLoaderDomain
                        , this.Url.RouteUrl("Game", new { @action = "Information", @domainID = domain.DomainID, @id = game.Slug.DefaultIfNullOrEmpty(game.ID.ToString(CultureInfo.InvariantCulture)) })
                        );

            }

            if (game.VendorID == VendorID.NetEnt)
            {
                string protocol = string.Equals(ConfigurationManager.AppSettings["ProductionMode"], "off", StringComparison.InvariantCultureIgnoreCase)
                ? "http://" : "https://";
                return string.Format("{0}{1}{2}"
                        , protocol
                        , domain.GameLoaderDomain
                        , this.Url.RouteUrl("Game", new { @action = "Information", @domainID = domain.DomainID, @id = game.Slug.DefaultIfNullOrEmpty(game.ID.ToString(CultureInfo.InvariantCulture)) })
                        );
            }

            return string.Empty;

            //string protocol = string.Equals(ConfigurationManager.AppSettings["ProductionMode"], "off", StringComparison.InvariantCultureIgnoreCase)
            //    ? "http://" : "https://";
            //return string.Format("{0}{1}{2}"
            //        , protocol
            //        , domain.GameLoaderDomain
            //        , this.Url.RouteUrl("Loader", new { @action = "Help", @domainID = domain.DomainID, @id = slug.DefaultIfNullOrEmpty(gameID.ToString()) })
            //        );
        }

        private Dictionary<long, long> GetGamePopularity(ceDomainConfigEx domain, bool allowCache = true)
        {
            string cacheKey = string.Format("{0}_{1}_{2}_{3}.cache"
                , domain.PopularityExcludeOtherOperators ? domain.DomainID.ToString() : string.Empty
                , DateTime.Now.ToString("yyyyMMdd")
                , domain.PopularityDaysBack
                , domain.PopularityCalculationMethod
                );
            string filename = Path.Combine(FileSystemUtility.GetWebSiteTempDirectory()
                , string.Format("Game_Popularity_{0}.cache", domain.DomainID)
                );

            Func<Dictionary<long, long>> func = () =>
            {
                try
                {
                    Dictionary<long, long> data = new Dictionary<long, long>();
                    long? domainID = null;
                    if (domain.PopularityExcludeOtherOperators)
                        domainID = domain.DomainID;

                    List<dwGamePopularity> list = DwAccessor.GetGamePopularity(domainID, domain.PopularityDaysBack, domain.PopularityCalculationMethod == PopularityCalculationMethod.ByTimes);

                    //List<ceCasinoGameBaseEx> games = CasinoGameAccessor.GetDomainGames(Constant.SystemDomainID);
                    List<ceCasinoGameBaseEx> games = CacheManager.GetGameList(Constant.SystemDomainID, false, false, allowCache);
                    foreach (dwGamePopularity popularity in list)
                    {
                        VendorID vendor = (VendorID)popularity.VendorID;
                        switch (vendor)
                        {
                            case VendorID.NetEnt:
                                {
                                    if (!popularity.GameCode.EndsWith("_sw", StringComparison.InvariantCultureIgnoreCase))
                                        popularity.GameCode = popularity.GameCode + "_sw";
                                    break;
                                }

                            default:
                                break;
                        }
                        ceCasinoGameBaseEx game = games.FirstOrDefault(g => g.VendorID == vendor && string.Equals(g.GameCode, popularity.GameCode, StringComparison.InvariantCultureIgnoreCase));
                        if (game != null)
                        {
                            data[game.ID] = popularity.Popularity;
                        }
                    }

                    ObjectHelper.BinarySerialize<Dictionary<long, long>>(data, filename);
                    return data;
                }
                catch (Exception ex)
                {
                    Logger.Exception(ex);
                    throw;
                }
            };


            Dictionary<long, long> dic = null;
            if (!DelayUpdateCache<Dictionary<long, long>>.TryGetValue(cacheKey, out dic, func, 3600 * 24))
            {
                dic = ObjectHelper.BinaryDeserialize<Dictionary<long, long>>(filename, null);
                if (dic == null)
                {
                    dic = new Dictionary<long, long>();
                }
            }
            return dic;
        }

      //  , string countryCode
        private Dictionary<long, List<dwGamePopularity>> GetGamePopularityV2(ceDomainConfigEx domain, bool allowCache = true, int gameType = 0)
        {

            string cacheKey = string.Format("{0}_{1}_{2}_{3}V2.cache"
                , domain.PopularityExcludeOtherOperators ? domain.DomainID.ToString() : string.Empty
                , DateTime.Now.ToString("yyyyMMdd")
                , domain.PopularityDaysBack
                , domain.PopularityCalculationMethod
                );
            string filename = Path.Combine(FileSystemUtility.GetWebSiteTempDirectory()
                , string.Format("Game_Popularity_V2_{0}.cache", domain.DomainID)
                );

            Func<Dictionary<long, List<dwGamePopularity>>> func = () =>
            {
                try
                {
                    Dictionary<long, List<dwGamePopularity>> data = new Dictionary<long, List<dwGamePopularity>>();
                    long? domainID = null;
                    if (domain.PopularityExcludeOtherOperators)
                        domainID = domain.DomainID;
                    List<dwGamePopularity> list = new List<dwGamePopularity>();
                    DateTime endTime = DateTime.Now.AddDays(-1);
                    endTime = endTime.AddHours(23 - endTime.Hour).AddMinutes(59 - endTime.Minute).AddSeconds(59 - endTime.Second);
                    DateTime startTime = endTime.AddDays(-1 * Math.Abs(domain.PopularityDaysBack) - 1);
                    startTime = startTime.AddHours(-1 * startTime.Hour).AddMinutes(-1 * startTime.Hour).AddSeconds(-1 * startTime.Second);

                    list = DwAccessor.GetMostPopularGames(
                        startTime,
                        endTime,
                        domainID.ToString(),
                        (domain.PopularityCalculationMethod == PopularityCalculationMethod.ByTimes)
                        );
                    //List<ceCasinoGameBaseEx> games = CasinoGameAccessor.GetDomainGames(Constant.SystemDomainID);
                    List<ceCasinoGameBaseEx> games = CacheManager.GetGameList(Constant.SystemDomainID, false, false, allowCache);

                    Dictionary<string, List<dwGamePopularity>> dicPopularity = new Dictionary<string, List<dwGamePopularity>>();
                    foreach (dwGamePopularity popularity in list)
                    {
                        switch ((VendorID)popularity.VendorID)
                        {
                            case VendorID.NetEnt:
                                {
                                    if (!popularity.GameCode.EndsWith("_sw", StringComparison.InvariantCultureIgnoreCase))
                                        popularity.GameCode = popularity.GameCode + "_sw";
                                    break;
                                }

                            default:
                                break;
                        }

                        if (!dicPopularity.ContainsKey(popularity.GameCode))
                            dicPopularity[popularity.GameCode] = new List<dwGamePopularity>();

                        dicPopularity[popularity.GameCode].Add(popularity);
                    }

                    foreach (string gameCode in dicPopularity.Keys)
                    {
                        if (dicPopularity[gameCode].Count > 0)
                        {
                            VendorID vendor = (VendorID)dicPopularity[gameCode][0].VendorID;

                            ceCasinoGameBaseEx game = games.FirstOrDefault(g => g.VendorID == vendor && string.Equals(g.GameCode, gameCode, StringComparison.InvariantCultureIgnoreCase));
                            if (game != null)
                            {
                                data[game.ID] = dicPopularity[gameCode];
                            }
                        }
                    }

                    ObjectHelper.BinarySerialize<Dictionary<long, List<dwGamePopularity>>>(data, filename);
                    return data;
                }
                catch (Exception ex)
                {
                    Logger.Exception(ex);
                    throw;
                }
            };


            Dictionary<long, List<dwGamePopularity>> dic = null;
            if (!allowCache)
            {

                dic = func();

            }
            else
            {
                if (!DelayUpdateCache<Dictionary<long, List<dwGamePopularity>>>.TryGetValue(cacheKey, out dic, func, 3600 * 24))
                {
                    dic = ObjectHelper.BinaryDeserialize<Dictionary<long, List<dwGamePopularity>>>(filename, null);
                    if (dic == null)
                    {
                        dic = new Dictionary<long, List<dwGamePopularity>>();
                    }
                }
            }
            return dic;
        }



        #region JackpotList

        [HttpGet]
        public ContentResult JackpotList(string apiUsername, string ver)
        {
            if (string.IsNullOrWhiteSpace(apiUsername))
                return WrapResponse(ResultCode.Error_InvalidParameter, "Operator is NULL!");

            var domains = DomainManager.GetApiUsername_DomainDictionary();
            ceDomainConfigEx domain;
            if (!domains.TryGetValue(apiUsername.Trim(), out domain))
                return WrapResponse(ResultCode.Error_InvalidParameter, "Operator is invalid!");

            if (!IsWhitelistedIPAddress(domain, Request.GetRealUserAddress()))
                return WrapResponse(ResultCode.Error_BlockedIPAddress, string.Format("IP Address [{0}] is denied!", Request.GetRealUserAddress()));

            DomainManager.CurrentDomainID = domain.DomainID;
            try
            {
                string cacheKey = string.Format(JACKPOT_LIST_CACHE_KEY_FORMAT, Constant.JackpotListCachePrefix, domain.DomainID, ver);
                StringBuilderCache cache = HttpRuntime.Cache[cacheKey] as StringBuilderCache;
                if (cache == null || cache.IsExpried)
                {
                    cache = new StringBuilderCache(GetJackpotListXml(domain, ver));
                    CacheManager.AddCache(cacheKey, cache);
                }
                return WrapResponse(ResultCode.Success, string.Empty, cache.Value);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return WrapResponse(ResultCode.Error_SystemFailure, ex.Message);
            }
        }
        private StringBuilder GetJackpotListXml(ceDomainConfigEx domain, string ver)
        {
            CasinoVendorAccessor cva = CasinoVendorAccessor.CreateInstance<CasinoVendorAccessor>();
            List<VendorID> enabledVendors = cva.GetEnabledVendors(domain.DomainID);

            //List<ceCasinoGameBaseEx> games = CasinoGameAccessor.GetDomainGames(domain.DomainID, true, true);
            List<ceCasinoGameBaseEx> games = CacheManager.GetGameList(domain.DomainID);

            List<ceCasinoJackpotBaseEx> jackpots = CasinoJackpotAccessor.SearchJackpots(domain.DomainID);

            StringBuilder data = new StringBuilder();

            data.AppendLine("<jackpots>");
            foreach (ceCasinoJackpotBaseEx jackpot in jackpots)
            {
                if (!enabledVendors.Contains(jackpot.VendorID))
                    continue;

                var customVendorConfigs = JsonConvert.DeserializeObject<List<CustomVendorJackpotConfig>>(jackpot.CustomVendorConfig);

                string customUrl = null;
                CustomVendorJackpotConfig currentDomainCustomConfig = null;

                if (customVendorConfigs != null && customVendorConfigs.Count > 0)
                {
                    currentDomainCustomConfig = customVendorConfigs.SingleOrDefault(x => x.OperatorId == domain.DomainID);

                    if (currentDomainCustomConfig != null)
                    {
                        customUrl = currentDomainCustomConfig.Url;
                    }
                }

                Dictionary<string, Jackpot.JackpotInfo> jackpotInfoDic = null;
                switch (jackpot.VendorID)
                {
                    case VendorID.NetEnt:
                        jackpotInfoDic = Jackpot.JackpotFeeds.GetNetEntJackpots(DomainManager.CurrentDomainID);
                        break;

                    case VendorID.CTXM:
                        jackpotInfoDic = Jackpot.JackpotFeeds.GetCTXMJackpots(DomainManager.CurrentDomainID);
                        break;

                    case VendorID.Microgaming:
                        jackpotInfoDic = Jackpot.JackpotFeeds.GetMicrogamingJackpots(customUrl);
                        break;

                    case VendorID.PlaynGO:
                        jackpotInfoDic = Jackpot.JackpotFeeds.GetPlaynGOJackpots(domain.DomainID, customUrl);
                        break;

                    case VendorID.IGT:
                        jackpotInfoDic = Jackpot.JackpotFeeds.GetIGTJackpots(domain.DomainID, customUrl);
                        break;

                    case VendorID.BetSoft:
                        jackpotInfoDic = Jackpot.JackpotFeeds.GetBetSoftJackpots(domain, customUrl);
                        break;

                    case VendorID.Sheriff:
                        jackpotInfoDic = Jackpot.JackpotFeeds.GetSheriffJackpots(domain);
                        break;

                    case VendorID.OMI:
                        jackpotInfoDic = Jackpot.JackpotFeeds.GetOMIJackpots(domain);
                        break;

                    default:
                        continue;
                }

                Jackpot.JackpotInfo jackpotInfo = null;

                var mappedJackpotId = currentDomainCustomConfig != null ? currentDomainCustomConfig.MappedJackpotID : jackpot.MappedJackpotID;

                if (!jackpotInfoDic.TryGetValue(mappedJackpotId, out jackpotInfo)
                    || jackpotInfo.Amounts == null)
                {
                    continue;
                }

                data.AppendLine("\t<jackpot>");
                data.AppendFormat("\t\t<name>{0}</name>\n", jackpot.Name.SafeHtmlEncode());
                data.AppendFormat("\t\t<vendor>{0}</vendor>\n", jackpot.VendorID.ToString().SafeHtmlEncode());


                if (string.Equals(ver, "2", StringComparison.InvariantCultureIgnoreCase))
                    data.AppendLine("\t\t<amounts>");


                foreach (KeyValuePair<string, decimal> item in jackpotInfo.Amounts)
                {
                    data.AppendFormat("\t\t<amount currency=\"{0}\">{1:f2}</amount>\n"
                        , item.Key.SafeHtmlEncode()
                        , item.Value
                        );
                }


                if (string.Equals(ver, "2", StringComparison.InvariantCultureIgnoreCase))
                    data.AppendLine("\t\t</amounts>");

                data.AppendLine("\t\t<games>");
                string[] gameIDs = (jackpot.GameIDs ?? string.Empty).Split(',');
                string[] hiddenGameIDs = (jackpot.HiddenGameIDs ?? string.Empty).Split(',');
                foreach (string gameID in gameIDs)
                {
                    if (games.Exists(g => g.ID.ToString() == gameID))
                    {
                        data.AppendFormat("\t\t\t<game><id>{0}</id><hidden>{1}</hidden></game>\n", gameID, hiddenGameIDs.Contains(gameID).ToString().ToLower());

                        // Start Check Netent Jackpot alert
                        if (jackpot.VendorID == VendorID.NetEnt)
                        {
                            ceCasinoGameBaseEx game = games.FirstOrDefault(g => g.ID.ToString() == gameID);
                            CheckNetentJackpot(jackpot, jackpotInfo, game);
                        }
                        // End Check Netent Jackpot alert
                    }
                }

                data.AppendLine("\t\t</games>");

                data.AppendLine("\t</jackpot>");
            }

            data.AppendLine("</jackpots>");
            return data;
        }

        #region Netent Jackpot alert
        private decimal _Netent_Jackpot_Alert_Threshold_Amount = -1;
        private Dictionary<string, string> _Netent_Jackpot_Alert_Game_IDs = null;
        private void CheckNetentJackpot(ceCasinoJackpotBaseEx jackpot, Jackpot.JackpotInfo jackpotInfo, ceCasinoGameBaseEx game)
        {
            if (jackpot.VendorID != VendorID.NetEnt)
                return;

            #region
            if (_Netent_Jackpot_Alert_Threshold_Amount < 0)
            {
                decimal.TryParse(ConfigurationManager.AppSettings["Netent.Jackpot.Alert.Threshold.Amount"].DefaultIfNullOrWhiteSpace("0"), out _Netent_Jackpot_Alert_Threshold_Amount);
                if (_Netent_Jackpot_Alert_Threshold_Amount < 0)
                    _Netent_Jackpot_Alert_Threshold_Amount = 0;
            }

            if (_Netent_Jackpot_Alert_Threshold_Amount == 0)
                return;

            if (_Netent_Jackpot_Alert_Game_IDs == null)
            {
                _Netent_Jackpot_Alert_Game_IDs = new Dictionary<string, string>();
                foreach (string id in ConfigurationManager.AppSettings["Netent.Jackpot.Alert.Game.IDs"].DefaultIfNullOrWhiteSpace(",").Split(new char[] { ',' }, StringSplitOptions.RemoveEmptyEntries))
                {
                    _Netent_Jackpot_Alert_Game_IDs[id] = id;
                }
            }
            if (_Netent_Jackpot_Alert_Game_IDs.Count == 0)
                return;
            #endregion

            string cacheKey = "CE.Netent.Jackpot.Alert.PrevAmounts";
            Dictionary<string, decimal> dicPrevAmounts = HttpRuntime.Cache[cacheKey] as Dictionary<string, decimal>;
            if (dicPrevAmounts == null)
                dicPrevAmounts = new Dictionary<string, decimal>();

            decimal prevAmount = 0.00m;
            if (dicPrevAmounts.ContainsKey(game.GameID))
                prevAmount = dicPrevAmounts[game.GameID];
            else
                dicPrevAmounts[game.GameID] = 0.00m;

            //Dictionary<string, string> amountLimitVendorGameID = new Dictionary<string, string>();
            //amountLimitVendorGameID["megajackpot_sw"] = "Mega Fortune";
            //amountLimitVendorGameID["hallofgods_sw"] = "Hall of Gods";
            //amountLimitVendorGameID["arabian_sw"] = "Arabian Nights ";

            //amountLimitVendorGameID["ice_sw"] = "Icy Wonders ";

            if (jackpotInfo.Amounts.ContainsKey("EUR"))
            {
                if (_Netent_Jackpot_Alert_Game_IDs.ContainsKey(game.GameID))
                {
                    if (jackpotInfo.Amounts["EUR"] >= _Netent_Jackpot_Alert_Threshold_Amount && prevAmount < _Netent_Jackpot_Alert_Threshold_Amount)
                    {
                        Task t = new Task(() => SendAlertEmail(game.GameName, string.Format("EUR {0}", jackpotInfo.Amounts["EUR"])));
                        t.Start();
                    }
                    dicPrevAmounts[game.GameID] = jackpotInfo.Amounts["EUR"];
                }
            }
            CacheManager.AddCache(cacheKey, dicPrevAmounts);
        }


        private void SendAlertEmail(string gameName, string amountCurreny)
        {
            string smtp = ConfigurationManager.AppSettings["Email.SMTP"].DefaultIfNullOrWhiteSpace("10.0.10.7");
            int port = 25;
            int.TryParse(ConfigurationManager.AppSettings["Email.Port"].DefaultIfNullOrWhiteSpace("25"), out port);

            using (MailMessage message = new MailMessage())
            {
                //message.ReplyToList.Add(new MailAddress("bz@everymatrix.com"));
                message.Subject = "Netent Global Jackpot";
                message.SubjectEncoding = Encoding.UTF8;
                message.From = new MailAddress("noreply@everymatrix.com");

                foreach (string email in ConfigurationManager.AppSettings["Netent.Jackpot.Alert.Emails"].DefaultIfNullOrWhiteSpace(",").Split(new char[] { ',' }, StringSplitOptions.RemoveEmptyEntries))
                {
                    message.To.Add(email);
                }
                if (message.To.Count == 0)
                    return;
                message.BodyEncoding = Encoding.UTF8;
                message.IsBodyHtml = true;
                message.Body = string.Format(@"Game: {0}<br/>Jackpot value: {1}<br/>Time: {2}",
                    gameName,
                    amountCurreny,
                    DateTime.Now.ToShortDateString()
                    );

                SmtpClient client = new SmtpClient(smtp, port);
                client.Send(message);
            }
        }
        #endregion Netent Jackpot alert

        #endregion

        #region TopWinners


        [HttpGet]
        public ContentResult TopWinners(string apiUsername
            , int? maxRecords
            , int? daysBack
            , bool? excludeOtherOperators
            , string vendors
            , decimal? minAmount
            , string channel
            )
        {
            if (string.IsNullOrWhiteSpace(apiUsername))
                return WrapResponse(ResultCode.Error_InvalidParameter, "Operator is NULL!");

            var domains = DomainManager.GetApiUsername_DomainDictionary();
            ceDomainConfigEx domain;
            if (!domains.TryGetValue(apiUsername.Trim(), out domain))
                return WrapResponse(ResultCode.Error_InvalidParameter, "Operator is invalid!");

            if (!IsWhitelistedIPAddress(domain, Request.GetRealUserAddress()))
                return WrapResponse(ResultCode.Error_BlockedIPAddress, string.Format("IP Address [{0}] is denied!", Request.GetRealUserAddress()));

            DomainManager.CurrentDomainID = domain.DomainID;

            // prepare default value
            if (!maxRecords.HasValue || maxRecords.Value <= 0)
                maxRecords = domain.TopWinnersMaxRecords;
            if (!daysBack.HasValue || daysBack.Value <= 0)
                daysBack = domain.TopWinnersDaysBack;
            if (!excludeOtherOperators.HasValue)
                excludeOtherOperators = domain.TopWinnersExcludeOtherOperators;
            if (!minAmount.HasValue)
                minAmount = domain.TopWinnersMinAmount;

            VendorID[] vendorIDs = null;
            if (!string.IsNullOrWhiteSpace(vendors))
            {
                vendorIDs = vendors.Split(',').Where(v => !string.IsNullOrWhiteSpace(v))
                    .Select(v => (VendorID)Enum.Parse(typeof(VendorID), v)).ToArray();
            }

            long[] operators = null;
            if (excludeOtherOperators.Value)
                operators = new long[1] { domain.DomainID };

            try
            {
                bool isMobile = string.Equals(channel, "mobile", StringComparison.InvariantCultureIgnoreCase);
                string cacheKey = string.Format(TOP_WINNERS_CACHE_KEY_FORMAT
                    , Constant.TopWinnersCachePrefix
                    , domain.DomainID
                    , maxRecords.Value
                    , daysBack.Value
                    , excludeOtherOperators.Value
                    , vendors
                    , minAmount.Value
                    , DateTime.Now.DayOfYear
                    , isMobile
                    );
                string filename = Path.Combine(FileSystemUtility.GetWebSiteTempDirectory()
                    , string.Format("Top_Winners_{0}_{1}.cache", domain.DomainID, isMobile)
                    );

                Func<StringBuilder> func = () =>
                    {
                        try
                        {
                            if (vendorIDs == null)
                            {
                                CasinoVendorAccessor cva = CasinoVendorAccessor.CreateInstance<CasinoVendorAccessor>();
                                vendorIDs = cva.GetEnabledVendors(domain.DomainID).ToArray();
                            }

                            List<dwWinner> winners = DwAccessor.GetCasinoGameTopWinners(minAmount.Value
                                , daysBack.Value
                                , maxRecords.Value * 2
                                , isMobile
                                , vendorIDs
                                , operators
                                );

                            //List<ceCasinoGameBaseEx> games = CasinoGameAccessor.GetDomainGames(domain.DomainID, true, true);
                            List<ceCasinoGameBaseEx> games = CacheManager.GetGameList(domain.DomainID);

                            StringBuilder data = new StringBuilder();
                            data.AppendLine("<winners>");
                            int count = 0;
                            foreach (dwWinner winner in winners)
                            {
                                ceCasinoGameBaseEx game = null;

                                string gameCode = winner.GameCode;
                                if ((VendorID)winner.VendorID == VendorID.NetEnt &&
                                    !string.IsNullOrWhiteSpace(gameCode) &&
                                    !gameCode.EndsWith("_sw"))
                                {
                                    gameCode += "_sw";
                                }

                                game = games.FirstOrDefault(g => g.VendorID == (VendorID)winner.VendorID &&
                                           string.Equals(g.GameCode, gameCode, StringComparison.InvariantCultureIgnoreCase));

                                if (game != null)
                                {
                                    data.AppendLine("\t<winner>");

                                    data.AppendFormat("\t\t<vendor>{0}</vendor>\n", Enum.GetName(typeof(VendorID), winner.VendorID).SafeHtmlEncode());
                                    data.AppendFormat("\t\t<currency>{0}</currency>\n", winner.Currency.SafeHtmlEncode());
                                    data.AppendFormat("\t\t<amount>{0:f2}</amount>\n", winner.Amount);
                                    data.AppendFormat("\t\t<username>{0:f2}</username>\n", domain.DomainID == winner.DomainID ? winner.Username : string.Empty);
                                    data.AppendFormat("\t\t<displayName>{0}.{1}</displayName>\n", winner.Firstname.SafeHtmlEncode(), winner.Surname.Truncate(1).SafeHtmlEncode());
                                    data.AppendFormat("\t\t<countryCode>{0}</countryCode>\n", winner.CountryCode.SafeHtmlEncode());

                                    data.AppendFormat("\t\t<game><id>{0}</id><shortName>{1}</shortName><name>{2}</name><url>{3}</url></game>\n"
                                        , game.ID
                                        , game.ShortName.SafeHtmlEncode()
                                        , game.GameName.SafeHtmlEncode()
                                        , GetLoaderUrl(domain, game.ID, game.Slug, game.VendorID).SafeHtmlEncode()
                                        );
                                    data.AppendLine("\t</winner>");
                                    count++;
                                }

                                if (count >= maxRecords.Value)
                                {
                                    break;
                                }
                            }


                            data.AppendLine("</winners>");
                            ObjectHelper.BinarySerialize<StringBuilder>(data, filename);
                            return data;
                        }
                        catch (Exception ex)
                        {
                            Logger.Exception(ex);
                            throw;
                        }
                    };

                StringBuilder sb;
                if (!DelayUpdateCache<StringBuilder>.TryGetValue(cacheKey, out sb, func, 3600 * 10))
                {
                    sb = ObjectHelper.BinaryDeserialize<StringBuilder>(filename, null);
                    if (sb == null)
                    {
                        sb = new StringBuilder();
                        sb.AppendLine("<winners></winners>");
                    }
                }
                return WrapResponse(ResultCode.Success, string.Empty, sb);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return WrapResponse(ResultCode.Error_SystemFailure, ex.Message);
            }
        }
        #endregion


        private List<dwGamePopularity> GetDummyData(long domainID, List<ceCasinoGameBaseEx> games) {
            List<dwGamePopularity> lst = new List<dwGamePopularity>();
            for (long i = 0; i < 30; i++) {
                try
                {
                    dwGamePopularity item = new dwGamePopularity();
                    item.CountryCode = "CN";
                    item.GameCode = games[int.Parse(i.ToString())].GameCode;
                    item.GameType = "0";
                    item.Popularity = i * 31;
                    item.VendorID = (int)VendorID.AstroPay;
                    lst.Add(item);
                } catch { }
            }
            return lst;
        }

        #region GamePopularity
        [HttpGet]
        public ContentResult GamePopularity(
            string apiUsername ,
            string domainIDs , 
            bool allowCache = true
            )
        {
            try
            {
                ceDomainConfigEx domain;

                if (string.IsNullOrWhiteSpace(apiUsername))
                    return WrapResponse(ResultCode.Error_InvalidParameter, "Operator is NULL!");
                var domains = DomainManager.GetApiUsername_DomainDictionary();
                if (!domains.TryGetValue(apiUsername.Trim(), out domain))
                    return WrapResponse(ResultCode.Error_InvalidParameter, "Operator is invalid!");
                if (!IsWhitelistedIPAddress(domain, Request.GetRealUserAddress()))
                    return WrapResponse(ResultCode.Error_BlockedIPAddress, string.Format("IP Address [{0}] is denied!", Request.GetRealUserAddress()));

                DomainManager.CurrentDomainID = domain.DomainID;
                //List<ceCasinoGameBaseEx> games = CasinoGameAccessor.GetDomainGames(domain.DomainID, true, true);
                List<ceCasinoGameBaseEx> games = CacheManager.GetGameList(domain.DomainID);
                double lastDayNum = domain.PopularityDaysBack;
                bool isGameRounds = (domain.PopularityCalculationMethod == PopularityCalculationMethod.ByTimes);
                LocationAccessor la = LocationAccessor.CreateInstance<LocationAccessor>();
                Dictionary<string, int> dic = la.GetCountryCode2IdDictionary();
                DateTime betEndTime = DateTime.Now;
                DateTime betFromTime = DateTime.Now.AddDays((double)lastDayNum * -1);

                if (string.IsNullOrEmpty(domainIDs))
                {
                    domainIDs = domain.DomainID.ToString();
                }
                // GetPopularityXML
                StringBuilderCache cache = GetPopularityXML(apiUsername, domainIDs,
                    allowCache,
                    games
                    );
                return WrapResponse(ResultCode.Success, string.Empty, cache.Value);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return WrapResponse(ResultCode.Error_SystemFailure, ex.Message);
            }
        }

        public class PopularitySearchHistory {
            public DateTime BetFromTime { get; set; }
            public DateTime BetEndTime { get; set; }
            public string DomainID { get; set; }
            public bool IsGameRounds { get; set; }
            public List<dwGamePopularity> Result { get; set; }
        }

        private PopularitySearchHistory TryGetPopularityFromHistories(List<PopularitySearchHistory> list,
            DateTime betFromTime,
            DateTime betEndTime,
            string domainID,
            bool isGameRounds) { 
            PopularitySearchHistory result = list.FirstOrDefault(o => o.BetEndTime == betEndTime 
            && o.BetFromTime == betFromTime
            && o.DomainID == domainID
            && o.IsGameRounds == isGameRounds);
            if (result == null) {
                result = new PopularitySearchHistory();
                result.BetEndTime = betEndTime;
                result.BetFromTime = betFromTime;
                result.DomainID = domainID;
                result.IsGameRounds = isGameRounds;
                result.Result = DwAccessor.GetMostPopularGames(betFromTime, betEndTime, domainID, isGameRounds); 
            } 
            return result; 
        }
        private Dictionary<long , List<dwGamePopularity>>  GetAllPopularity(  bool allowCache = false)
        {
            string cacheKey = "Game_Domain_Popularity_ALL.cache" ;
            string filename = Path.Combine(FileSystemUtility.GetWebSiteTempDirectory(), cacheKey);
            Dictionary<long, List<dwGamePopularity>> allPopularity = new Dictionary<long, List<dwGamePopularity>>(); 
            Func<Dictionary<long, List<dwGamePopularity>>> func = () =>
            {
                var domains = DomainManager.GetApiUsername_DomainDictionary();
                DateTime betEndTime = DateTime.Now;
                List<PopularitySearchHistory> list = new List<PopularitySearchHistory>();
                PopularitySearchHistory hisItem = new PopularitySearchHistory();
                foreach (var domainItem in domains)
                {
                    bool isGameRounds = (domainItem.Value.PopularityCalculationMethod == PopularityCalculationMethod.ByTimes);
                    bool isPopularityExcludeOtherOperators = domainItem.Value.PopularityExcludeOtherOperators;
                    long domainID = domainItem.Value.DomainID;
                    DateTime betFromTime = betEndTime.AddDays((double)domainItem.Value.PopularityDaysBack * -1);
                    List<dwGamePopularity> popularityList = new List<dwGamePopularity>();
                    if (isPopularityExcludeOtherOperators)
                    {
                        hisItem = TryGetPopularityFromHistories(list, betFromTime, betEndTime, domainID.ToString(), isGameRounds);
                        list = TryAddItem(list, hisItem);
                        if (hisItem != null && hisItem.Result != null) {
                            popularityList = hisItem.Result;
                        }
                    }
                    else
                    {
                        foreach (var domain in domains)
                        {
                            hisItem = TryGetPopularityFromHistories(list, betFromTime, betEndTime, domain.Value.DomainID.ToString(), isGameRounds);
                            list = TryAddItem(list,hisItem);
                            if (hisItem != null && hisItem.Result!=null) 
                                popularityList.AddRange(hisItem.Result);
                        }
                    }
                    allPopularity.Add(domainID, popularityList);
                }
                ObjectHelper.BinarySerialize<Dictionary<long, List<dwGamePopularity>>>(allPopularity, filename);
                return allPopularity;
            };
            if (!allowCache)
            {
                func();
            }
            else
            {
                if (!DelayUpdateCache<Dictionary<long, List<dwGamePopularity>>>.TryGetValue(cacheKey, out allPopularity, func, 3600 * 24))
                {
                    allPopularity = ObjectHelper.BinaryDeserialize<Dictionary<long, List<dwGamePopularity>>>(filename, allPopularity);
                }
            }
            if (allPopularity == null)
            {
                allPopularity = new Dictionary<long, List<dwGamePopularity>>();
            }
            return allPopularity;
             
        }

        private List<PopularitySearchHistory> TryAddItem(List<PopularitySearchHistory> list, PopularitySearchHistory hisItem)
        {
            PopularitySearchHistory result = list.FirstOrDefault(o => o.BetEndTime == hisItem.BetEndTime
               && o.BetFromTime == hisItem.BetFromTime
               && o.DomainID == hisItem.DomainID
               && o.IsGameRounds == hisItem.IsGameRounds);
            if (result == null) {
                list.Add(hisItem);
            }
            return list;
        }

 

        private StringBuilderCache GetPopularityXML(string apiUsername,string domainIDStr, 
            bool allowCache, 
            List<ceCasinoGameBaseEx> games 
            )
        {

            string cacheKey = string.Format(GAME_POPULARITY_CACHE_KEY_FORMAT, "GAMEPOPULARITY", domainIDStr , DateTime.Now.ToString("yyyyMMdd"));
            StringBuilderCache cache = HttpRuntime.Cache[cacheKey] as StringBuilderCache;
            var domains = DomainManager.GetApiUsername_DomainDictionary();
            ceDomainConfigEx domain = new ceDomainConfigEx();
            domains.TryGetValue(apiUsername, out domain);
            if (cache == null || cache.IsExpried || !allowCache)
            {
                List<ceCasinoGamePopularity> list = new List<ceCasinoGamePopularity>();
                long domainID = 0;
                long.TryParse(domainIDStr, out domainID);
                Dictionary<long, List<dwGamePopularity>> allPopularityList = GetAllPopularity(allowCache);
                List<dwGamePopularity> popularityList = new List<dwGamePopularity>();
                foreach (var item in allPopularityList) {
                    if (item.Key == domainID)
                        popularityList = item.Value;
                } 
                if (popularityList.Count > 0)
                {
                    List<dwGamePopularity> popularity = new List<dwGamePopularity>();
                    foreach (ceCasinoGameBaseEx game in games)
                    {
                        popularity = popularityList.Where(p => p.GameCode.Equals(game.GameCode, StringComparison.InvariantCultureIgnoreCase)).ToList();

                        if ((popularity != null && popularity.Count > 0 && game != null))
                        { 
                            {
                                decimal _sum = 0M, _temp = 0M; 
                                if (popularity.Where(p => p.GameType.Equals("0", StringComparison.InvariantCultureIgnoreCase)).ToList().Count > 0)
                                { 
                                    foreach (dwGamePopularity p in popularity.Where(p => p.GameType.Equals("0", StringComparison.InvariantCultureIgnoreCase)))
                                    {
                                        _temp = p.Popularity * game.PopularityCoefficient; 
                                        list.Add(new ceCasinoGamePopularity()
                                        {
                                            GameID = game.ID,
                                            Platform = "desktop",
                                            CountryCode = p.CountryCode.ToLower(),
                                            Popularity = _temp,
                                        });
                                        _sum += _temp;
                                    }
                                    if (_sum > 0)
                                    { 
                                        list.Add(new ceCasinoGamePopularity()
                                        {
                                            GameID = game.ID,
                                            Platform = "desktop",
                                            CountryCode = "all",
                                            Popularity = _sum,
                                        });
                                    } 
                                }
                                if (popularity.Where(p => p.GameType.Equals("1", StringComparison.InvariantCultureIgnoreCase)).ToList().Count > 0)
                                { 
                                    _sum = 0M;
                                    foreach (dwGamePopularity p in popularity.Where(p => p.GameType.Equals("1", StringComparison.InvariantCultureIgnoreCase)))
                                    {
                                        _temp = p.Popularity * game.PopularityCoefficient; 
                                        list.Add(new ceCasinoGamePopularity()
                                        {
                                            GameID = game.ID,
                                            Platform = "mobile",
                                            CountryCode = p.CountryCode.ToLower(),
                                            Popularity = _temp,
                                        });
                                        _sum += _temp;
                                    }
                                    if (_sum > 0)
                                    { 
                                        list.Add(new ceCasinoGamePopularity()
                                        {
                                            GameID = game.ID,
                                            Platform = "mobile",
                                            CountryCode = "all",
                                            Popularity = _sum,
                                        });
                                    } 
                                } 
                            } 
                        }

                    }

                    if (domain.PopularityNotByCountry)
                    {
                        list = list.Where(i => i.CountryCode == "all").ToList();
                    }
                    else
                    {
                        Dictionary<string, PopularityConfigurationByCountry> configurationByCountry = domain.GetPopularityConfigurationByCountry();
                        foreach (string countryCode in configurationByCountry.Keys)
                        {
                            PopularityConfigurationByCountry configuration = configurationByCountry[countryCode];

                            //parse the desktop manual placed games
                            for (int index = configuration.DesktopPlaced.Count - 1; index >= 0; index--)
                            {
                                long gameID = configuration.DesktopPlaced[index];
                                ceCasinoGamePopularity item = list.FirstOrDefault(i => i.GameID == gameID && i.Platform == "desktop" && i.CountryCode == countryCode.ToLowerInvariant());
                                if (item != null)
                                {
                                    item.Popularity = list.Where(i => i.Platform == "desktop" && i.CountryCode == countryCode.ToLowerInvariant()).Max(i => i.Popularity) + 1;
                                }
                            }

                            //parse the mobile manual placed games
                            for (int index = configuration.MobilePlaced.Count - 1; index >= 0; index--)
                            {
                                long gameID = configuration.MobilePlaced[index];
                                ceCasinoGamePopularity item = list.FirstOrDefault(i => i.GameID == gameID && i.Platform == "mobile" && i.CountryCode == countryCode.ToLowerInvariant());
                                if (item != null)
                                {
                                    item.Popularity = list.Where(i => i.Platform == "mobile" && i.CountryCode == countryCode.ToLowerInvariant()).Max(i => i.Popularity) + 1;
                                }
                            }

                            List<ceCasinoGamePopularity> excludeItems;

                            //exclude the desktop games
                            if (countryCode == "all")
                                excludeItems = list.Where(i => configuration.DesktopExcluded.Contains(i.GameID) && i.Platform == "desktop").ToList();
                            else
                                excludeItems = list.Where(i => configuration.DesktopExcluded.Contains(i.GameID) && i.Platform == "desktop" && i.CountryCode == countryCode.ToLowerInvariant()).ToList();
                            foreach (ceCasinoGamePopularity item in excludeItems)
                                list.Remove(item);

                            //exclude the mobile games
                            if (countryCode == "all")
                                excludeItems = list.Where(i => configuration.MobileExcluded.Contains(i.GameID) && i.Platform == "mobile").ToList();
                            else
                                excludeItems = list.Where(i => configuration.MobileExcluded.Contains(i.GameID) && i.Platform == "mobile" && i.CountryCode == countryCode.ToLowerInvariant()).ToList();
                            foreach (ceCasinoGamePopularity item in excludeItems)
                                list.Remove(item);
                        }
                    }

                    StringBuilder data = new StringBuilder();
                    data.AppendLine("<gameList>");

                    List<long> gameIDs = list.Select(i => i.GameID).Distinct().ToList();
                    foreach (long gameID in gameIDs)
                    {
                        data.AppendLine("<game>");
                        data.AppendFormat("\t\t<id>{0}</id>\n", gameID);
                        data.Append("\t\t<popularity>\n");

                        StringBuilder _sp = new StringBuilder();
                        List<ceCasinoGamePopularity> desktopItems = list.Where(i => i.GameID == gameID && i.Platform == "desktop").ToList();

                        if (desktopItems.Any())
                        {
                            _sp.Append("\t\t<desktop>\n");

                            foreach (ceCasinoGamePopularity item in desktopItems.Where(i => i.CountryCode!= "all"))
                            {
                                _sp.AppendFormat("\t\t<{0}>{1}</{0}>", item.CountryCode, item.Popularity);
                            }

                            ceCasinoGamePopularity allItem = desktopItems.FirstOrDefault(i => i.CountryCode == "all");
                            if (allItem != null)
                                _sp.AppendFormat("\t\t<{0}>{1}</{0}>", "all", allItem.Popularity);

                            _sp.Append("\t\t</desktop>\n");
                        }

                        List<ceCasinoGamePopularity> mobileItems = list.Where(i => i.GameID == gameID && i.Platform == "mobile").ToList();
                        if (mobileItems.Any())
                        {
                            _sp.Append("\t\t<mobile>\n");

                            foreach (ceCasinoGamePopularity item in mobileItems.Where(i => i.CountryCode != "all"))
                            {
                                _sp.AppendFormat("\t\t<{0}>{1}</{0}>", item.CountryCode, item.Popularity);
                            }

                            ceCasinoGamePopularity allItem = mobileItems.FirstOrDefault(i => i.CountryCode == "all");
                            if (allItem != null)
                                _sp.AppendFormat("\t\t<{0}>{1}</{0}>", "all", allItem.Popularity);

                            _sp.Append("\t\t</mobile>\n");
                        }

                        data.Append(_sp);
                        
                        data.Append("\t\t</popularity>\n");
                        data.AppendLine("</game>");
                    }

                    data.AppendLine("</gameList>");

                    cache = new StringBuilderCache(data, 36000);
                }
                else
                {
                    StringBuilder data = new StringBuilder();
                    data.AppendLine("<gameList>");
                    data.AppendLine("</gameList>");
                    cache = new StringBuilderCache(data, 30);
                }
                CacheManager.ClearCache(cacheKey);
                CacheManager.AddCache(cacheKey, cache);
            }
            return cache;
        }
        #endregion

        #region GetPlayerBiggestWinGames
        [HttpGet]
        public ContentResult PlayerBiggestWinGames(string apiUsername, string _sid, int? recordCount)
        {
            if (string.IsNullOrWhiteSpace(apiUsername))
                return WrapResponse(ResultCode.Error_InvalidParameter, "Operator is NULL!");
            var domains = DomainManager.GetApiUsername_DomainDictionary();
            ceDomainConfigEx domain;
            if (!domains.TryGetValue(apiUsername.Trim(), out domain))
                return WrapResponse(ResultCode.Error_InvalidParameter, "Operator is invalid!");
            if (!IsWhitelistedIPAddress(domain, Request.GetRealUserAddress()))
                return WrapResponse(ResultCode.Error_BlockedIPAddress, string.Format("IP Address [{0}] is denied!", Request.GetRealUserAddress()));

            DomainManager.CurrentDomainID = domain.DomainID;

            if (string.IsNullOrWhiteSpace(_sid))
                return WrapResponse(ResultCode.Error_InvalidParameter, "Session ID cannot be empty!");

            SessionPayload sessionPayload = _agentClient.GetSessionByGuid(_sid);
            if (sessionPayload == null || sessionPayload.IsAuthenticated != true)
                return WrapResponse(ResultCode.Error_InvalidSession, "Session ID is not available!");

            long userId = 0;
            long domainID = 0;
            int lastDayNum = domain.PlayerBiggestWinGamesLastDayNum;
            bool uniqueGame = !domain.PlayerBiggestWinGamesIsDuplicated;
            decimal minWinEURAmounts = domain.PlayerBiggestWinGamesMinWinEURAmounts;

            if (recordCount == null)
            {
                recordCount = 40;
            }

            userId = sessionPayload.UserID;
            domainID = domain.DomainID;

            DateTime betEndTime = DateTime.Now;
            DateTime betFromTime = DateTime.Now.AddDays((double)lastDayNum * -1);
            //List<ceCasinoGameBaseEx> games = CasinoGameAccessor.GetDomainGames(domain.DomainID, true, true);
            List<ceCasinoGameBaseEx> games = CacheManager.GetGameList(domain.DomainID);
            try
            {

                string cacheKey = string.Format(GAME_LIST_CACHE_KEY_FORMAT
                    , Constant.GameListCachePrefix
                    , domainID.ToString()
                    , "USER"
                    , "PLAYED"
                    , "BIGGESTGAMES"
                    , userId.ToString()
                    , lastDayNum.ToString()
                    , uniqueGame.ToString()
                    , recordCount.ToString()
                    );

                StringBuilderCache cache = HttpRuntime.Cache[cacheKey] as StringBuilderCache;

                if (cache == null || cache.IsExpried)
                {
                    StringBuilder data = new StringBuilder();
                    List<ceCasinoGameWins> mostPlayedGames = DwAccessor.GetBiggestPlayerWinGames(
                        domainID,
                        userId,
                        betFromTime,
                        betEndTime,
                        recordCount.Value,
                        minWinEURAmounts,
                        uniqueGame
                    );

                    string xmlCode = XmlSerialize(mostPlayedGames);
                    data.Append(xmlCode);
                    cache = new StringBuilderCache(data, 36000);
                    CacheManager.AddCache(cacheKey, cache);
                }
                return WrapResponse(ResultCode.Success, string.Empty, cache.Value);

            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return WrapResponse(ResultCode.Error_SystemFailure, ex.Message);
            }




        }
        #endregion

        #region GetMostPlayedGames
        [HttpGet]
        public ContentResult MostPlayedGames(string apiUsername, int? recordCount, string _sid)
        {
            if (string.IsNullOrWhiteSpace(apiUsername))
                return WrapResponse(ResultCode.Error_InvalidParameter, "Operator is NULL!");

            if (string.IsNullOrWhiteSpace(_sid))
                return WrapResponse(ResultCode.Error_InvalidParameter, "Session ID cannot be empty!");

            SessionPayload sessionPayload = _agentClient.GetSessionByGuid(_sid);

            if (sessionPayload == null || sessionPayload.IsAuthenticated != true)
                return WrapResponse(ResultCode.Error_InvalidSession, "Session ID is not available!");

            var domains = DomainManager.GetApiUsername_DomainDictionary();
            ceDomainConfigEx domain;
            if (!domains.TryGetValue(apiUsername.Trim(), out domain))
                return WrapResponse(ResultCode.Error_InvalidParameter, "Operator is invalid!");
            if (!IsWhitelistedIPAddress(domain, Request.GetRealUserAddress()))
                return WrapResponse(ResultCode.Error_BlockedIPAddress, string.Format("IP Address [{0}] is denied!", Request.GetRealUserAddress()));


            long domainID = 0;
            long userId = sessionPayload.UserID;
            double lastDayNum = domain.MostPlayedGamesLastDayNum;   // load from configuration
            int minRoundCounts = domain.MostPlayedGamesMinRoundCounts;   // load from configuration 
            DomainManager.CurrentDomainID = domain.DomainID;
            domainID = domain.DomainID;



            if (recordCount == null)
            {
                recordCount = 40;
            }
            DateTime betEndTime = DateTime.Now;
            DateTime betFromTime = DateTime.Now.AddDays(lastDayNum * -1);
            try
            {

                string cacheKey = string.Format(GAME_LIST_CACHE_KEY_FORMAT
                    , Constant.GameListCachePrefix
                    , domainID.ToString()
                    , "USER"
                    , "MOSTPLAYED"
                    , "GAMES"
                    , userId.ToString()
                    , lastDayNum.ToString()
                    , minRoundCounts.ToString()
                    , recordCount.ToString()
                    );

                StringBuilderCache cache = HttpRuntime.Cache[cacheKey] as StringBuilderCache;

                if (cache == null || cache.IsExpried)
                {
                    StringBuilder data = new StringBuilder();
                    List<ceCasinoGameRounds> mostPlayedGames = DwAccessor.GetMostPlayedGames(domainID,
                        userId,
                      betFromTime,
                      betEndTime,
                      recordCount.Value,
                      minRoundCounts
                        );

                    string xmlCode = XmlSerialize(mostPlayedGames);
                    data.Append(xmlCode);
                    cache = new StringBuilderCache(data, 36000);
                    CacheManager.AddCache(cacheKey, cache);
                }
                return WrapResponse(ResultCode.Success, string.Empty, cache.Value);

            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return WrapResponse(ResultCode.Error_SystemFailure, ex.Message);
            }
        }
        #endregion

        private string XmlSerialize<T>(T obj)
        {
            string xmlString = string.Empty;
            XmlSerializer xmlSerializer = new XmlSerializer(typeof(T));
            using (MemoryStream ms = new MemoryStream())
            {
                xmlSerializer.Serialize(ms, obj);
                xmlString = Encoding.UTF8.GetString(ms.ToArray());
            }
            return xmlString.Replace("<?xml version=\"1.0\"?>", "");
        }

        #region LastPlayedGames
        [HttpGet]
        public ContentResult LastPlayedGames(string apiUsername, string _sid)
        {


            if (string.IsNullOrWhiteSpace(apiUsername))
                return WrapResponse(ResultCode.Error_InvalidParameter, "Operator is NULL!");
            var domains = DomainManager.GetApiUsername_DomainDictionary();
            ceDomainConfigEx domain;
            if (!domains.TryGetValue(apiUsername.Trim(), out domain))
                return WrapResponse(ResultCode.Error_InvalidParameter, "Operator is invalid!");
            if (!IsWhitelistedIPAddress(domain, Request.GetRealUserAddress()))
                return WrapResponse(ResultCode.Error_BlockedIPAddress, string.Format("IP Address [{0}] is denied!", Request.GetRealUserAddress()));


            if (string.IsNullOrWhiteSpace(_sid))
                return WrapResponse(ResultCode.Error_InvalidParameter, "Session ID cannot be empty!");

            SessionPayload sessionPayload = _agentClient.GetSessionByGuid(_sid);
            if (sessionPayload == null || sessionPayload.IsAuthenticated != true)
                return WrapResponse(ResultCode.Error_InvalidSession, "Session ID is not available!");


            long domainID = 0;
            long userId = 0;
            int recordCount = domain.LastPlayedGamesMaxRecords;
            bool uniqueGame = !domain.LastPlayedGamesIsDuplicated;
            double lastDayNum = domain.LastPlayedGamesLastDayNum;


            userId = sessionPayload.UserID;

            DomainManager.CurrentDomainID = domain.DomainID;
            domainID = domain.DomainID;


            DateTime betEndTime = DateTime.Now;
            DateTime betFromTime = DateTime.Now.AddDays((double)lastDayNum * -1);
            try
            {

                string cacheKey = string.Format(GAME_LIST_CACHE_KEY_FORMAT
                    , Constant.GameListCachePrefix
                    , domainID
                    , "USER"
                    , "PLAYED"
                    , "GAMES"
                    , userId.ToString()
                    , lastDayNum.ToString()
                    , uniqueGame.ToString()
                    , recordCount.ToString()
                    );

                StringBuilderCache cache = HttpRuntime.Cache[cacheKey] as StringBuilderCache;

                if (cache == null || cache.IsExpried)
                {
                    StringBuilder data = new StringBuilder();
                    List<ceCasinoGameTranStatus> lastPlayedGames = DwAccessor.GetLastPlayedGames(
                        domainID,
                        userId,
                        betFromTime,
                        betEndTime,
                        recordCount,
                        uniqueGame
                    );
                    string xmlCode = XmlSerialize(lastPlayedGames);
                    data.Append(xmlCode);
                    cache = new StringBuilderCache(data, 36000);
                    CacheManager.AddCache(cacheKey, cache);
                }
                return WrapResponse(ResultCode.Success, string.Empty, cache.Value);

            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return WrapResponse(ResultCode.Error_SystemFailure, ex.Message);
            }




        }
        #endregion


        #region RecentWinners


        [HttpGet]
        public ContentResult RecentWinners(string apiUsername, string channel)
        {
            if (string.IsNullOrWhiteSpace(apiUsername))
                return WrapResponse(ResultCode.Error_InvalidParameter, "Operator is NULL!");

            var domains = DomainManager.GetApiUsername_DomainDictionary();
            ceDomainConfigEx domain;
            if (!domains.TryGetValue(apiUsername.Trim(), out domain))
                return WrapResponse(ResultCode.Error_InvalidParameter, "Operator is invalid!");

            if (!IsWhitelistedIPAddress(domain, Request.GetRealUserAddress()))
                return WrapResponse(ResultCode.Error_BlockedIPAddress, string.Format("IP Address [{0}] is denied!", Request.GetRealUserAddress()));

            DomainManager.CurrentDomainID = domain.DomainID;

            try
            {
                bool isMobile = string.Equals(channel, "mobile", StringComparison.InvariantCultureIgnoreCase);
                string cacheKey = string.Format(RECENT_WINNERS_CACHE_KEY_FORMAT
                    , Constant.RecentWinnersCachePrefix
                    , domain.DomainID
                    , isMobile
                    );

                string filename = Path.Combine(FileSystemUtility.GetWebSiteTempDirectory(), cacheKey);

                Func<StringBuilder> func = () =>
                    {
                        try
                        {
                            StringBuilder data = new StringBuilder();
                            data.AppendLine("<winners>");


                            List<dwWinner> winners = DwAccessor.GetCasinoGameRecentWinners(domain, isMobile);
                            //List<ceCasinoGameBaseEx> games = CasinoGameAccessor.GetDomainGames(domain.DomainID, true, true);
                            List<ceCasinoGameBaseEx> games = CacheManager.GetGameList(domain.DomainID);

                            int count = 0;
                            foreach (dwWinner winner in winners)
                            {
                                ceCasinoGameBaseEx game = null;

                                string gameCode = winner.GameCode;
                                if ((VendorID)winner.VendorID == VendorID.NetEnt &&
                                    !string.IsNullOrWhiteSpace(gameCode) &&
                                    !gameCode.EndsWith("_sw"))
                                {
                                    gameCode += "_sw";
                                }

                                game = games.FirstOrDefault(g => g.VendorID == (VendorID)winner.VendorID &&
                                           string.Equals(g.GameCode, gameCode, StringComparison.InvariantCultureIgnoreCase));

                                if (game == null)
                                    continue;

                                data.AppendLine("\t<winner>");

                                data.AppendFormat("\t\t<vendor>{0}</vendor>\n", Enum.GetName(typeof(VendorID), winner.VendorID).SafeHtmlEncode());
                                data.AppendFormat("\t\t<currency>{0}</currency>\n", winner.Currency.SafeHtmlEncode());
                                data.AppendFormat("\t\t<amount>{0:f2}</amount>\n", winner.Amount);
                                dwWinner w = GetWinner(winner);
                                data.AppendFormat("\t\t<username>{0:f2}</username>\n", winner.Username);
                                data.AppendFormat("\t\t<firstname>{0}</firstname>\n", w.Firstname);
                                data.AppendFormat("\t\t<surname>{0}</surname>\n", domain.RecentWinnersExcludeOtherOperators ? w.Surname :
                                   (domain.DomainID == w.DomainID ? w.Surname : w.Surname.Truncate(1)));
                                data.AppendFormat("\t\t<displayName>{0} {1}</displayName>\n", w.Firstname, w.Surname.Truncate(1));
                                data.AppendFormat("\t\t<countryCode>{0}</countryCode>\n", winner.CountryCode.SafeHtmlEncode());
                                if (winner.WinTime.HasValue)
                                {
                                    data.AppendFormat("\t\t<winTime>{0}</winTime>\n", winner.WinTime.Value.ToString("r"));
                                }

                                if (game != null)
                                    data.AppendFormat("\t\t<game><id>{0}</id><shortName>{1}</shortName><name>{2}</name><url>{3}</url></game>\n"
                                        , game.ID
                                        , game.ShortName.SafeHtmlEncode()
                                        , game.GameName.SafeHtmlEncode()
                                        , GetLoaderUrl(domain, game.ID, game.Slug, game.VendorID).SafeHtmlEncode()
                                        );

                                data.AppendLine("\t</winner>");

                                count++;
                                if (count >= domain.RecentWinnersMaxRecords)
                                    break;
                            }


                            data.AppendLine("</winners>");
                            ObjectHelper.BinarySerialize<StringBuilder>(data, filename);
                            return data;
                        }
                        catch (Exception ex)
                        {
                            Logger.Exception(ex);
                            throw;
                        }
                    };

                StringBuilder sb;
                if (!DelayUpdateCache<StringBuilder>.TryGetValue(cacheKey, out sb, func, 20))
                {
                    sb = ObjectHelper.BinaryDeserialize<StringBuilder>(filename, null);
                    if (sb == null)
                    {
                        sb = new StringBuilder();
                        sb.AppendLine("<winners></winners>");
                    }
                }


                return WrapResponse(ResultCode.Success, string.Empty, sb);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return WrapResponse(ResultCode.Error_SystemFailure, ex.Message);
            }
        }

        private dwWinner GetWinner(dwWinner winner)
        {
            if (!string.IsNullOrEmpty(winner.Firstname) && !string.IsNullOrEmpty(winner.Surname))
                return winner;
            long userID = winner.UserID;
            string cacheKey = string.Format("XmlFeedsController.GetWinner.{0}", userID);
            winner = HttpRuntime.Cache[cacheKey] as dwWinner;
            if (winner != null)
                return winner;

            UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
            winner = ua.GetWinnerName(userID);
            HttpRuntime.Cache[cacheKey] = winner;

            return winner;
        }
        #endregion

        #region VendorList
        [HttpGet]
        public ContentResult VendorList(string apiUsername)
        {
            if (string.IsNullOrWhiteSpace(apiUsername))
                return WrapResponse(ResultCode.Error_InvalidParameter, "Operator is NULL!");

            var domains = DomainManager.GetApiUsername_DomainDictionary();
            ceDomainConfigEx domain;
            if (!domains.TryGetValue(apiUsername.Trim(), out domain))
                return WrapResponse(ResultCode.Error_InvalidParameter, "Operator is invalid!");

            if (!IsWhitelistedIPAddress(domain, Request.GetRealUserAddress()))
                return WrapResponse(ResultCode.Error_BlockedIPAddress, string.Format("IP Address [{0}] is denied!", Request.GetRealUserAddress()));

            DomainManager.CurrentDomainID = domain.DomainID;
            try
            {
                string cacheKey = string.Format(VENDORS_CACHE_KEY_FORMAT, Constant.VendorListCachePrefix, domain.DomainID);
                StringBuilderCache cache = HttpRuntime.Cache[cacheKey] as StringBuilderCache;
                if (cache == null || cache.IsExpried)
                {
                    CasinoVendorAccessor cva = CasinoVendorAccessor.CreateInstance<CasinoVendorAccessor>();
                    List<ceCasinoVendor> vendors = cva.GetEnabledVendorList(domain.DomainID, Constant.SystemDomainID);

                    StringBuilder data = new StringBuilder();
                    data.AppendLine("<vendorList>");

                    foreach (ceCasinoVendor vendor in vendors)
                    {
                        data.AppendLine("\t<vendor>");
                        data.AppendFormat("\t\t<id>{0}</id>\n", Enum.GetName(typeof(VendorID), vendor.VendorID).SafeHtmlEncode());
                        data.AppendFormat("\t\t<bonusDeduction>{0}</bonusDeduction>\n", vendor.BonusDeduction);
                        data.AppendLine("\t\t<restrictedTerritories>");

                        string[] codes = vendor.RestrictedTerritories.Split(',');
                        foreach (string code in codes)
                        {
                            if (string.IsNullOrWhiteSpace(code))
                                continue;
                            data.AppendFormat("\t\t\t<restrictedTerritory>{0}</restrictedTerritory>\n", code.SafeHtmlEncode());
                        }

                        data.AppendLine("\t\t</restrictedTerritories>");
                        data.AppendLine("\t</vendor>");
                    }


                    data.AppendLine("</vendorList>");

                    cache = new StringBuilderCache(data);
                    CacheManager.AddCache(cacheKey, cache);
                }
                return WrapResponse(ResultCode.Success, string.Empty, cache.Value);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return WrapResponse(ResultCode.Error_SystemFailure, ex.Message);
            }
        }
        #endregion


        #region Content Provider
        private string GetContentProviderLogoImage(ceContentProviderBase provider)
        {
            if (string.IsNullOrWhiteSpace(provider.Logo))
                return "//cdn.everymatrix.com/images/placeholder.png";

            return string.Format("{0}{1}"
                , (ConfigurationManager.AppSettings["ResourceUrl"] ?? "//cdn.everymatrix.com").TrimEnd('/')
                , provider.Logo
                );
        }

        [HttpGet]
        public ContentResult ContentProviderList(string apiUsername)
        {
            if (string.IsNullOrWhiteSpace(apiUsername))
                return WrapResponse(ResultCode.Error_InvalidParameter, "Operator is NULL!");

            var domains = DomainManager.GetApiUsername_DomainDictionary();
            ceDomainConfigEx domain;
            if (!domains.TryGetValue(apiUsername.Trim(), out domain))
                return WrapResponse(ResultCode.Error_InvalidParameter, "Operator is invalid!");

            if (!IsWhitelistedIPAddress(domain, Request.GetRealUserAddress()))
                return WrapResponse(ResultCode.Error_BlockedIPAddress, string.Format("IP Address [{0}] is denied!", Request.GetRealUserAddress()));

            DomainManager.CurrentDomainID = domain.DomainID;

            try
            {
                string cacheKey = string.Format(CONTENT_PROVIDERS_CACHE_KEY_FORMAT, Constant.ContentProviderListCachePrefix, domain.DomainID);
                StringBuilderCache cache = HttpRuntime.Cache[cacheKey] as StringBuilderCache;
                if (cache == null || cache.IsExpried)
                {
                    ContentProviderAccessor cpa = ContentProviderAccessor.CreateInstance<ContentProviderAccessor>();

                    List<ceContentProviderBase> providers = ContentProviderAccessor.GetEnabledProviderList(domain.DomainID, Constant.SystemDomainID);

                    StringBuilder data = new StringBuilder();
                    data.AppendLine("<contentProviderList>");

                    foreach (ceContentProviderBase provider in providers)
                    {
                        data.AppendLine("\t<contentProvider>");
                        data.AppendFormat("\t\t<id>{0}</id>\n", provider.Identifying);
                        if (!string.IsNullOrWhiteSpace(provider.Logo))
                            data.AppendFormat("\t\t<logo>{0}</logo>\n", GetContentProviderLogoImage(provider).SafeHtmlEncode());
                        data.AppendLine("\t</contentProvider>");
                    }

                    data.AppendLine("</contentProviderList>");

                    cache = new StringBuilderCache(data);
                    CacheManager.AddCache(cacheKey, cache);
                }
                return WrapResponse(ResultCode.Success, string.Empty, cache.Value);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return WrapResponse(ResultCode.Error_SystemFailure, ex.Message);
            }
        }
        #endregion

        #region Game Recommendation
        [HttpGet]
        public ActionResult UserRecommendedGames(string apiUsername, string _sid, string platform, bool includeMoreFields = true, bool useCache = true)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(apiUsername))
                    return WrapResponse(ResultCode.Error_InvalidParameter, "OperatorKey cannot be empty!");

                if (string.IsNullOrWhiteSpace(_sid))
                    return WrapResponse(ResultCode.Error_InvalidParameter, "Session ID cannot be empty!");

                if (string.IsNullOrWhiteSpace(platform))
                    return WrapResponse(ResultCode.Error_InvalidParameter, "Platform cannot be empty!");

                var domains = DomainManager.GetApiUsername_DomainDictionary();
                ceDomainConfigEx domain;
                if (!domains.TryGetValue(apiUsername.Trim(), out domain))
                    return WrapResponse(ResultCode.Error_InvalidParameter, "Invalid OperatorKey!");

                if (!IsWhitelistedIPAddress(domain, Request.GetRealUserAddress()))
                    return WrapResponse(ResultCode.Error_BlockedIPAddress, string.Format("IP Address [{0}] is denied!", Request.GetRealUserAddress()));

                SessionPayload sessionPayload = _agentClient.GetSessionByGuid(_sid);

                if (sessionPayload == null || sessionPayload.IsAuthenticated != true)
                    return WrapResponse(ResultCode.Error_InvalidSession, "Session ID is not available!");

                long userID = sessionPayload.UserID;
                int maxRecords = domain.RecommendationMaxPlayerRecords;

                bool isMobile = !string.Equals(platform, "PC", StringComparison.InvariantCultureIgnoreCase);

                string cacheKey = string.Format(GAME_LIST_CACHE_KEY_FORMAT
                    , Constant.GameListCachePrefix
                    , domain.ID.ToString()
                    , "USER"
                    , "RECOMMENDED"
                    , "GAMES"
                    , userID.ToString()
                    , platform
                    , maxRecords.ToString()
                    , includeMoreFields
                    );

                StringBuilderCache cache = HttpRuntime.Cache[cacheKey] as StringBuilderCache;

                if (cache == null || cache.IsExpried || !useCache)
                {
                    UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
                    string gender = ua.GetGender(userID);
                    DateTime? birthday = ua.GetBirthday(userID);
                    int countryID = sessionPayload.IpCountryID > 0 ? sessionPayload.IpCountryID : sessionPayload.UserCountryID;

                    List<RecommendedGame> recommendedGames;
                    bool success = UserRecommended.TryGet(domain.ID, isMobile, userID, countryID, gender, birthday, out recommendedGames);

                    List<ceCasinoGameBaseEx> games = CacheManager.GetGameDictionary(domain.DomainID).Where(d => d.Key == d.Value.ID.ToString()).Select(d => d.Value).ToList();

                    CasinoVendorAccessor cva = CasinoVendorAccessor.CreateInstance<CasinoVendorAccessor>();
                    Dictionary<VendorID, string> restrictedTerritoriesDictionary = cva.GetRestrictedTerritoriesDictionary(domain.DomainID);

                    List<ceCasinoGameBaseEx> list = new List<ceCasinoGameBaseEx>();
                    List<Tuple<VendorID, string>> excludeGames = GetExcludeGames(domain);
                    recommendedGames = recommendedGames.Where(g => excludeGames.FirstOrDefault(eg => eg.Item1 == g.VendorID && eg.Item2 == g.GameCode) == null).ToList();
                    recommendedGames = recommendedGames.OrderByDescending(rg => rg.Score).ToList();

                    foreach (RecommendedGame recommendedGame in recommendedGames)
                    {
                        ceCasinoGameBaseEx game = games.FirstOrDefault(g => g.VendorID == recommendedGame.VendorID && g.GameCode == recommendedGame.GameCode);
                        if (game == null)
                            continue;

                        if (!SafeSplit(game.ClientCompatibility).Contains(platform))
                            continue;

                        string[] restrictedTerritories = GetGameRestrictedTerritories(game, restrictedTerritoriesDictionary);
                        if (restrictedTerritories.Contains(sessionPayload.UserCountryCode)
                            || restrictedTerritories.Contains(sessionPayload.IpCountryCode))
                            continue;

                        list.Add(game);

                        if (list.Count >= maxRecords)
                            break;
                    }

                    // if the number of the games is too small, then fill the recommended games with popularity games
                    if (list.Count < maxRecords)
                    {
                        list.AddRange(GetPopularityGames(domain, games, excludeGames, restrictedTerritoriesDictionary, platform, sessionPayload.UserCountryCode, sessionPayload.IpCountryCode, maxRecords - list.Count));
                    }

                    StringBuilder data = GetRecommendedGameListXml(domain, list, restrictedTerritoriesDictionary, includeMoreFields);

                    cache = new StringBuilderCache(data, success ? 36000 : 18000);
                    CacheManager.AddCache(cacheKey, cache);
                }
                return WrapResponse(ResultCode.Success, string.Empty, cache.Value);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return WrapResponse(ResultCode.Error_SystemFailure, ex.Message);
            }
        }

        [HttpGet]
        public ActionResult GameRecommendedGames(string apiUsername, string ids, string platform, string userCountryCode, string ipCountryCode, bool includeMoreFields = true, bool useCache = true)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(apiUsername))
                    return WrapResponse(ResultCode.Error_InvalidParameter, "OperatorKey cannot be empty!");

                if (string.IsNullOrWhiteSpace(ids))
                    return WrapResponse(ResultCode.Error_InvalidParameter, "ids cannot be empty!");

                if (string.IsNullOrWhiteSpace(platform))
                    return WrapResponse(ResultCode.Error_InvalidParameter, "Platform cannot be empty!");

                List<long> filteredIDs = ids.Split(',')
                            .Where(c => Regex.IsMatch(c, @"^\d+$", RegexOptions.Compiled))
                            .Select(c => long.Parse(c))
                            .ToList();

                if (filteredIDs.Count == 0)
                    return WrapResponse(ResultCode.Error_InvalidParameter, "ids is not valid!");

                var domains = DomainManager.GetApiUsername_DomainDictionary();
                ceDomainConfigEx domain;
                if (!domains.TryGetValue(apiUsername.Trim(), out domain))
                    return WrapResponse(ResultCode.Error_InvalidParameter, "Invalid OperatorKey!");

                if (!IsWhitelistedIPAddress(domain, Request.GetRealUserAddress()))
                    return WrapResponse(ResultCode.Error_BlockedIPAddress, string.Format("IP Address [{0}] is denied!", Request.GetRealUserAddress()));

                int maxRecords = domain.RecommendationMaxGameRecords;

                bool isMobile = !string.Equals(platform, "PC", StringComparison.InvariantCultureIgnoreCase);

                string cacheKey = string.Format(GAME_LIST_CACHE_KEY_FORMAT
                    , Constant.GameListCachePrefix
                    , domain.ID.ToString()
                    , "GAME"
                    , "RECOMMENDED"
                    , "GAMES"
                    , ids
                    , platform
                    , maxRecords.ToString()
                    , includeMoreFields
                    );

                StringBuilderCache cache = HttpRuntime.Cache[cacheKey] as StringBuilderCache;

                if (cache == null || cache.IsExpried || !useCache)
                {
                    List<RecommendedGame> recommendedGames = new List<RecommendedGame>();
                    bool success = true;

                    List<ceCasinoGameBaseEx> games = CacheManager.GetGameDictionary(domain.DomainID).Where(d => d.Key == d.Value.ID.ToString()).Select(d => d.Value).ToList();
                    foreach (long id in filteredIDs)
                    {
                        ceCasinoGameBaseEx game = games.FirstOrDefault(g => g.ID == id);
                        if (game == null)
                            continue;

                        List<RecommendedGame> temp;
                        if (!GameRecommended.TryGet(domain.ID, isMobile, game.VendorID, game.GameCode, out temp))
                            success = false;
                        foreach (RecommendedGame item in temp)
                        {
                            if (recommendedGames.Any(rg => rg.VendorID == item.VendorID && rg.GameCode == item.GameCode))
                                continue;

                            recommendedGames.Add(item);
                        }
                    }

                    CasinoVendorAccessor cva = CasinoVendorAccessor.CreateInstance<CasinoVendorAccessor>();
                    Dictionary<VendorID, string> restrictedTerritoriesDictionary = cva.GetRestrictedTerritoriesDictionary(domain.DomainID);

                    List<Tuple<VendorID, string>> excludeGames = GetExcludeGames(domain);
                    recommendedGames = recommendedGames.Where(g => excludeGames.FirstOrDefault(eg => eg.Item1 == g.VendorID && eg.Item2 == g.GameCode) == null).ToList();
                    recommendedGames = recommendedGames.OrderByDescending(rg => rg.Score).ToList();

                    List<ceCasinoGameBaseEx> list = new List<ceCasinoGameBaseEx>();
                    foreach (RecommendedGame recommendedGame in recommendedGames)
                    {
                        ceCasinoGameBaseEx game = games.FirstOrDefault(g => g.VendorID == recommendedGame.VendorID && g.GameCode == recommendedGame.GameCode);
                        if (game == null)
                            continue;

                        if (!SafeSplit(game.ClientCompatibility).Contains(platform))
                            continue;

                        string[] restrictedTerritories = GetGameRestrictedTerritories(game, restrictedTerritoriesDictionary);
                        if (restrictedTerritories.Contains(userCountryCode)
                            || restrictedTerritories.Contains(ipCountryCode))
                            continue;

                        list.Add(game);

                        if (list.Count >= maxRecords)
                            break;
                    }

                    // if the number of the games is too small, then fill the recommended games with the games with same tags or same categories
                    if (list.Count < maxRecords)
                    {
                        List<ceCasinoGameBaseEx> currentGames = games.Where(g => filteredIDs.Contains(g.ID)).ToList();
                        list.AddRange(GetSimilarGames(currentGames, games, excludeGames, restrictedTerritoriesDictionary, platform, userCountryCode, ipCountryCode, maxRecords - list.Count));
                    }

                    StringBuilder data = GetRecommendedGameListXml(domain, list, null, includeMoreFields);

                    cache = new StringBuilderCache(data, success ? 36000 : 18000);
                    CacheManager.AddCache(cacheKey, cache);
                }
                return WrapResponse(ResultCode.Success, string.Empty, cache.Value);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return WrapResponse(ResultCode.Error_SystemFailure, ex.Message);
            }
        }

        private List<Tuple<VendorID, string>> GetExcludeGames(ceDomainConfigEx domain)
        {
            List<Tuple<VendorID, string>> tuples = new List<Tuple<VendorID, string>>();
            string[] excludeGames = domain.RecommendationExcludeGames.Split(",".ToArray(), StringSplitOptions.RemoveEmptyEntries);
            foreach (string excludeGame in excludeGames)
            {
                string vendor = excludeGame.Substring(0, excludeGame.IndexOf("@"));
                string code = excludeGame.Substring(excludeGame.IndexOf("@") + 1);
                VendorID vendorID;
                if (!Enum.TryParse<VendorID>(vendor, out vendorID))
                    continue;

                tuples.Add(new Tuple<VendorID, string>(vendorID, code));
            }
            return tuples;
        }

        private string[] GetGameRestrictedTerritories(ceCasinoGameBaseEx game, Dictionary<VendorID, string> restrictedTerritoriesDictionary)
        {
            List<string> territories = new List<string>();

            string restrictedTerritories;
            restrictedTerritoriesDictionary.TryGetValue(game.VendorID, out restrictedTerritories);

            string[] vendorTerritories = null;
            if (!string.IsNullOrWhiteSpace(restrictedTerritories))
            {
                vendorTerritories = restrictedTerritories.Split(',');
                foreach (string territory in vendorTerritories)
                {
                    if (!string.IsNullOrWhiteSpace(territory))
                        territories.Add(territory);
                }
            }

            if (!string.IsNullOrWhiteSpace(game.RestrictedTerritories))
            {
                string[] gameTerritories = game.RestrictedTerritories.Split(',').Where(t => !string.IsNullOrWhiteSpace(t)).ToArray();
                foreach (string territory in gameTerritories)
                {
                    if (vendorTerritories != null && vendorTerritories.Contains(territory))
                        continue;

                    territories.Add(territory);
                }
            }

            return territories.ToArray();
        }

        private List<ceCasinoGameBaseEx> GetPopularityGames(ceDomainConfigEx domain,
            List<ceCasinoGameBaseEx> games,
            List<Tuple<VendorID, string>> excludeGames,
            Dictionary<VendorID, string> restrictedTerritoriesDictionary,
            string platform,
            string userCountryCode,
            string ipCountryCode,
            int count)
        {
            Dictionary<long, long> popularities = GetGamePopularity(domain);
            List<Tuple<decimal, ceCasinoGameBaseEx>> temp = new List<Tuple<decimal, ceCasinoGameBaseEx>>();
            foreach (ceCasinoGameBaseEx game in games)
            {
                if (excludeGames.Any(eg => eg.Item1 == game.VendorID && eg.Item2 == game.GameCode))
                    continue;

                if (!SafeSplit(game.ClientCompatibility).Contains(platform))
                    continue;

                string[] restrictedTerritories = GetGameRestrictedTerritories(game, restrictedTerritoriesDictionary);
                if (restrictedTerritories.Contains(userCountryCode)
                    || restrictedTerritories.Contains(ipCountryCode))
                    continue;

                long popularity = 0L;
                popularities.TryGetValue(game.ID, out popularity);
                temp.Add(new Tuple<decimal, ceCasinoGameBaseEx>((popularity + 1) * game.PopularityCoefficient, game));
            }
            return temp.OrderByDescending(t => t.Item1).Select(t => t.Item2).Take(count).ToList();
        }

        private List<ceCasinoGameBaseEx> GetSimilarGames(List<ceCasinoGameBaseEx> currentGames,
            List<ceCasinoGameBaseEx> allGames,
            List<Tuple<VendorID, string>> excludeGames,
            Dictionary<VendorID, string> restrictedTerritoriesDictionary,
            string platform,
            string userCountryCode,
            string ipCountryCode,
            int count)
        {
            if (currentGames.Count == 0)
                return new List<ceCasinoGameBaseEx>();

            //calculate the scores
            //base on game's tags and categories
            //tag's weight will be ten times of the category's weight
            List<Tuple<long, int>> tuples = new List<Tuple<long, int>>();
            foreach (ceCasinoGameBaseEx game in allGames)
            {
                if (excludeGames.Any(eg => eg.Item1 == game.VendorID && eg.Item2 == game.GameCode))
                    continue;

                if (!SafeSplit(game.ClientCompatibility).Contains(platform))
                    continue;

                string[] restrictedTerritories = GetGameRestrictedTerritories(game, restrictedTerritoriesDictionary);
                if (restrictedTerritories.Contains(userCountryCode)
                    || restrictedTerritories.Contains(ipCountryCode))
                    continue;

                int score1 = 0;
                string[] tags1 = SafeSplit(game.Tags);
                if (tags1.Length > 0)
                {
                    foreach (ceCasinoGameBaseEx currentGame in currentGames)
                    {
                        string[] tags2 = SafeSplit(currentGame.Tags);
                        foreach (string tag2 in tags2)
                        {
                            if (tags1.Contains(tag2))
                                score1++;
                        }
                    }
                }

                int score2 = 0;
                string[] categories1 = SafeSplit(game.GameCategories);
                if (categories1.Length > 0)
                {
                    foreach (ceCasinoGameBaseEx currentGame in currentGames)
                    {
                        string[] categories2 = SafeSplit(currentGame.GameCategories);
                        foreach (string category2 in categories2)
                        {
                            if (categories1.Contains(category2))
                                score2++;
                        }
                    }
                }

                tuples.Add(new Tuple<long, int>(game.ID, score1 * 10 + score2));
            }

            tuples = tuples.OrderByDescending(s => s.Item2).ToList();
            tuples = tuples.Take(count).ToList();

            //if games still less then the count, get the random game
            Random ran = new Random();
            while (tuples.Count < count)
            {
                while (true)
                {
                    ceCasinoGameBaseEx game = allGames[ran.Next(0, allGames.Count - 1)];
                    if (!tuples.Any(s => s.Item1 == game.ID))
                    {
                        tuples.Add(new Tuple<long, int>(game.ID, 0));
                        break;
                    }
                }
            }

            List<ceCasinoGameBaseEx> list = new List<ceCasinoGameBaseEx>();
            foreach (Tuple<long, int> tuple in tuples)
            {
                ceCasinoGameBaseEx game = allGames.FirstOrDefault(g => g.ID == tuple.Item1);
                list.Add(game);
            }

            return list;
        }

        private string[] SafeSplit(string str)
        {
            if (string.IsNullOrWhiteSpace(str))
                return new string[0];

            return str.Split(",".ToArray(), StringSplitOptions.RemoveEmptyEntries);
        }

        private bool isSimilarGame(ceCasinoGameBaseEx game, List<ceCasinoGameBaseEx> currentGames)
        {
            foreach (ceCasinoGameBaseEx currentGame in currentGames)
            {
                if (isSimilarGame(game, currentGame))
                    return true;
            }
            return false;
        }

        private bool isSimilarGame(ceCasinoGameBaseEx game, ceCasinoGameBaseEx currentGame)
        {
            string[] tags = SafeSplit(currentGame.Tags);
            string[] tags2 = SafeSplit(game.Tags);

            if (tags == null || tags.Length == 0)
                return false;

            if (tags2 == null || tags2.Length == 0)
                return false;

            return (tags.FirstOrDefault(t => tags2.Contains(t)) != null);
        }

        private StringBuilder GetRecommendedGameListXml(ceDomainConfigEx domain, List<ceCasinoGameBaseEx> games, Dictionary<VendorID, string> restrictedTerritoriesDictionary, bool includeMoreFields)
        {
            if (restrictedTerritoriesDictionary == null)
            {
                CasinoVendorAccessor cva = CasinoVendorAccessor.CreateInstance<CasinoVendorAccessor>();
                restrictedTerritoriesDictionary = cva.GetRestrictedTerritoriesDictionary(domain.DomainID);
            }

            StringBuilder data = new StringBuilder();
            data.AppendLine("<games>");

            int rankId = 1;
            foreach (ceCasinoGameBaseEx game in games)
            {
                string restrictedTerritories;
                restrictedTerritoriesDictionary.TryGetValue(game.VendorID, out restrictedTerritories);

                data.Append("\t\t<game>");
                data.AppendFormat("<id>{0}</id>", game.ID);
                data.AppendFormat("<shortName>{0}</shortName>", game.ShortName.SafeHtmlEncode());
                data.AppendFormat("<name>{0}</name>", game.GameName.SafeHtmlEncode());
                data.AppendFormat("<url>{0}</url>", GetLoaderUrl(domain, game.ID, game.Slug, game.VendorID).SafeHtmlEncode());

                if (includeMoreFields)
                {
                    data.Append("\t\t<categories>");
                    string[] categories = game.GameCategories.DefaultIfNullOrEmpty(string.Empty).Split(',');
                    foreach (string category in categories)
                    {
                        if (!string.IsNullOrWhiteSpace(category))
                            data.AppendFormat("<category>{0}</category>", category.SafeHtmlEncode());
                    }
                    data.Append("</categories>\n");

                    data.Append("\t\t<tags>");
                    string[] tags = game.Tags.DefaultIfNullOrEmpty(string.Empty).Split(',');
                    foreach (string tag in tags)
                    {
                        if (!string.IsNullOrWhiteSpace(tag))
                            data.AppendFormat("<tag>{0}</tag>", tag.SafeHtmlEncode());
                    }
                    data.Append("</tags>\n");

                    data.Append("\t\t<restrictedTerritories>");
                    {
                        string[] vendorTerritories = null;
                        if (!string.IsNullOrWhiteSpace(restrictedTerritories))
                        {
                            vendorTerritories = restrictedTerritories.Split(',');
                            foreach (string territory in vendorTerritories)
                            {
                                if (!string.IsNullOrWhiteSpace(territory))
                                    data.AppendFormat("<restrictedTerritory>{0}</restrictedTerritory>", territory.SafeHtmlEncode());
                            }
                        }

                        if (!string.IsNullOrWhiteSpace(game.RestrictedTerritories))
                        {
                            string[] gameTerritories = game.RestrictedTerritories.Split(',').Where(t => !string.IsNullOrWhiteSpace(t)).ToArray();
                            foreach (string territory in gameTerritories)
                            {
                                if (vendorTerritories != null && vendorTerritories.Contains(territory))
                                    continue;

                                data.AppendFormat("<restrictedTerritory>{0}</restrictedTerritory>", territory.SafeHtmlEncode());
                            }
                        }
                    }
                    data.Append("</restrictedTerritories>\n");
                }

                data.AppendFormat("<rankId>{0}</rankId>", rankId);

                data.Append("</game>\n");

                rankId++;
            }

            data.AppendLine("</games>");
            return data;
        }


        #endregion
    }
}
