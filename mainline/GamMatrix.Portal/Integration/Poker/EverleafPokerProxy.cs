using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Net;
using System.Threading;
using System.Web;
using System.Web.Caching;
using System.Web.Hosting;
using System.Xml.Linq;
using CM.Content;
using CM.Sites;
using CM.State;
using GamMatrixAPI;
using GmCore;

namespace Poker
{
    public class EverleafPokerProxy
    {

        #region Tournaments
        public enum TournamentMatchType
        {
            REGULAR,
            FREEROLL,
            SPECIAL,
        }

        public static List<Tournament> GetTournaments()
        {
            return GetTournaments(true);
        }

        public static List<Tournament> GetTournaments(bool unstart)
        {
            List<Tournament> tournaments = new List<Tournament>();

            tournaments.AddRange(GetTournaments(TournamentMatchType.REGULAR, unstart));
            tournaments.AddRange(GetTournaments(TournamentMatchType.FREEROLL, unstart));
            tournaments.AddRange(GetTournaments(TournamentMatchType.SPECIAL, unstart));

            return tournaments;
        }

        public static List<Tournament> GetTournaments(TournamentMatchType tournamentMatchType)
        {
            return GetTournaments(tournamentMatchType, true);
        }

        private sealed class AsyncTaskInfo
        {
            public int PendingCount;
            public List<Tournament> Result { get; private set; }

            public AsyncTaskInfo()
            {
                this.Result = new List<Tournament>();
            }
        }

        public static List<Tournament> GetTournaments(TournamentMatchType tournamentMatchType, bool unstart)
        {
            string backupFile = HostingEnvironment.MapPath(string.Format("~/App_Data/{0}/EverleafPokerProxy.GetTournaments.{1}.unstart_{2}"
                , SiteManager.Current.DistinctName
                , tournamentMatchType
                , unstart
                ) );

            List<Tournament> tournaments = HttpRuntime.Cache[backupFile] as List<Tournament>;
            if (tournaments != null)
                return tournaments;

            // load from backup file 
            tournaments = ObjectHelper.BinaryDeserialize<List<Tournament>>(backupFile, new List<Tournament>());
            HttpRuntime.Cache.Insert(backupFile
                , tournaments
                , null
                , DateTime.Now.AddMinutes(5)
                , Cache.NoSlidingExpiration
                , CacheItemPriority.NotRemovable
                , null
                );

            try
            {
                // start loading from vendor
                EverleafNetworkAPIRequest request = new EverleafNetworkAPIRequest()
                {
                    GetTournamentInfos = true,
                    GetTournamentInfosTYPE = "INFOS",
                    SESSION_ID = GamMatrixClient.GetSessionIDForCurrentOperator(),
                    SESSION_USERID = CustomProfile.Current.UserID,
                    SESSION_USERIP = HttpContext.Current.Request.GetRealUserAddress(),
                    SESSION_USERSESSIONID = CustomProfile.Current.SessionID
                };

                Dictionary<string, string> query = new Dictionary<string, string>();
                query.Add("TournamentType", tournamentMatchType.ToString());
                if (unstart)
                {
                    query.Add("DateFrom", DateTime.Now.ToUniversalTime().ToString("yyyy-MM-dd hh:mm:ss"));
                }
                request.GetTournamentInfosQUERY = query;

                const int MAX_SET_COUNT = 10;
                AsyncTaskInfo counter = new AsyncTaskInfo() { PendingCount = MAX_SET_COUNT };
                for (int i = 0; i < MAX_SET_COUNT; i++)
                {
                    request.GetTournamentInfosSETNUMBER = i.ToString(CultureInfo.InvariantCulture);
                    GamMatrixClient.SingleRequestAsync<EverleafNetworkAPIRequest>(request, OnGetTournamentInfo, counter, backupFile);
                }
            }
            catch { }

            return tournaments;
        }

        private static void OnGetTournamentInfo(AsyncResult result)
        {
            AsyncTaskInfo info = result.UserState1 as AsyncTaskInfo;
            string backupFile = result.UserState2 as string;
            try
            {
                EverleafNetworkAPIRequest response = result.EndSingleRequest().Get<EverleafNetworkAPIRequest>();

                #region Xml Parse
                string xml = response.GetTournamentInfosResponse;
                if (!string.IsNullOrEmpty(xml))
                {
                    XDocument doc = XDocument.Parse(xml);
                    IEnumerable<XElement> elements = doc.Root.Element("tournaments").Elements("tournament");

                    int count = 0;
                    foreach (XElement element in elements)
                    {
                        Tournament tournament = new Tournament();
                        long tournamentID;
                        if (long.TryParse(element.GetElementValue("id"), NumberStyles.Number | NumberStyles.AllowDecimalPoint, CultureInfo.InvariantCulture, out tournamentID))
                        {
                            tournament.ID = tournamentID;
                        }

                        tournament.Name = element.GetElementValue("name");

                        DateTime datetime;
                        if (DateTime.TryParse(element.GetElementValue("registerstart"), out datetime))
                        {
                            tournament.RegistrationTime = datetime;
                        }

                        if (DateTime.TryParse(element.GetElementValue("starttime"), out datetime))
                        {
                            tournament.StartTime = datetime;
                        }

                        decimal amount = 0.00M;
                        if (decimal.TryParse(element.GetElementValue("buyinmoney"), NumberStyles.Number | NumberStyles.AllowDecimalPoint, CultureInfo.InvariantCulture, out amount))
                            tournament.BuyIn = amount;

                        if (decimal.TryParse(element.GetElementValue("fee"), NumberStyles.Number | NumberStyles.AllowDecimalPoint, CultureInfo.InvariantCulture, out amount))
                            tournament.EntryFee = amount;

                        if (decimal.TryParse(element.GetElementValue("prizepool"), NumberStyles.Number | NumberStyles.AllowDecimalPoint, CultureInfo.InvariantCulture, out amount))
                            tournament.PrizePool = amount;

                        int status_id;
                        if (int.TryParse(element.GetElementValue("status_id"), NumberStyles.Integer, CultureInfo.InvariantCulture, out status_id))
                        {                                                        
                            TournamentStatus _tempStatus;
                            if (Enum.TryParse(status_id.ToString(), out _tempStatus))
                            {
                                tournament.Status = _tempStatus;
                            }
                        }

                        info.Result.Add(tournament);
                        count++;
                    }
                }
                #endregion Xml Parse
            }
            catch
            {
                //Logger.Exception(ex);
            }
            finally
            {
                try
                {
                    if (info != null && Interlocked.Decrement(ref info.PendingCount) == 0)
                    {
                        if (backupFile != null && info.Result.Count > 0)
                        {
                            List<Tournament> list = info.Result.OrderBy(p => p.StartTime).ToList();
                            HttpRuntime.Cache.Insert(backupFile
                                , list
                                , null
                                , DateTime.Now.AddMinutes(5)
                                , Cache.NoSlidingExpiration
                                , CacheItemPriority.NotRemovable
                                , null
                                );
                            ObjectHelper.BinarySerialize<List<Tournament>>(list, backupFile);
                        }
                    }
                }
                catch (Exception ex)
                {
                    Logger.Exception(ex);
                }
            }
        }

        
        #endregion Tournaments

        public static void GenerateSessionIDAsync(Action<string> callback)
        {
            if (CustomProfile.Current.IsAuthenticated)
            {
                AccountData account = GamMatrixClient.GetUserGammingAccounts(CustomProfile.Current.UserID).FirstOrDefault(a => a.Record.VendorID == VendorID.EverleafNetwork);

                if (account != null)
                {
                    Dictionary<string, string> queryValue = new Dictionary<string, string>();
                    queryValue.Add("PLAYERID", account.Record.InternalAccountNo);
                    EverleafNetworkAPIRequest request = new EverleafNetworkAPIRequest()
                    {
                        GetSessionID = true,
                        GetSessionIDQUERYTYPE = "PLAYERID",
                        GetSessionIDQUERYVALUE = queryValue,
                    };
                    GamMatrixClient.SingleRequestAsync<EverleafNetworkAPIRequest>(request, OnGenerateSessionID, callback);
                    return;
                }
            }
            callback(string.Empty);
        }

        private static void OnGenerateSessionID(AsyncResult result)
        {
            Action<string> callback = result.UserState1 as Action<string>;
            try
            {
                EverleafNetworkAPIRequest response = result.EndSingleRequest().Get<EverleafNetworkAPIRequest>();
                if (callback != null)
                    callback(response.GetSessionIDResponse);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                if (callback != null)
                    callback(string.Empty);
            }
        }

        #region GetTopWinners
        class WinnersFeed {
            public double FeedMultiple { get; set; }
            public string FeedUrl { get; set; }
            public string FeedName { get; set; }
        }
        class WinnersAgrs{
            public bool IsHistory { get; set; }
            public string BackupPath { get; set; }
            public string CurrentDomainDistinctName { get; set; }
            public List<WinnersFeed> WinnersFeeds{get;set;}
        }

        public static object objGetTopWinnersLock = new object();
        public static List<Winner> GetTopWinners(bool isHistory = false)
        {
            string cacheKey = HostingEnvironment.MapPath(string.Format("~/App_Data/{0}/EverleafPokerProxy.GetTopWinners_{1}"
                   , SiteManager.Current.DistinctName, isHistory
                   ));

            List<Winner> winners = HttpRuntime.Cache[cacheKey] as List<Winner>;
            if (winners != null)
                return winners;

            winners = ObjectHelper.BinaryDeserialize<List<Winner>>(cacheKey, new List<Winner>());
            HttpRuntime.Cache.Insert(cacheKey
                        , winners
                        , null
                        , DateTime.Now.AddSeconds(90)
                        , Cache.NoSlidingExpiration
                        , CacheItemPriority.NotRemovable
                        , null
                        );

            if (Monitor.TryEnter(objGetTopWinnersLock))
            {
                try
                {
                    
                    string[] paths;
                    //Get Feeds Information
                    if (isHistory)
                    {
                        paths = Metadata.GetChildrenPaths("/Metadata/Poker/EverLeafPoker/HistoryFeeds");
                    }
                    else
                    {
                        paths = Metadata.GetChildrenPaths("/Metadata/Poker/EverLeafPoker/Feeds");
                    }

                    if (paths.Length > 0)
                    {
                        #region Structure Feeds Agrs
                        WinnersAgrs agrs = new WinnersAgrs();
                        agrs.BackupPath = cacheKey;
                        agrs.IsHistory = isHistory;
                        agrs.CurrentDomainDistinctName = SiteManager.Current.DistinctName;
                        agrs.WinnersFeeds = new List<WinnersFeed>();

                        double multiple = 1.00;
                        string name = string.Empty;
                        string url = string.Empty;
                        WinnersFeed feed = new WinnersFeed();
                        foreach (string path in paths)
                        {
                            double.TryParse(Metadata.Get(path + ".FeedMultiple").DefaultIfNullOrEmpty("").Trim(), NumberStyles.Float, CultureInfo.InvariantCulture, out multiple);
                            url = Metadata.Get(path + ".FeedUrl").DefaultIfNullOrEmpty("").Trim();
                            name = name = path.Substring(path.LastIndexOf("/") + 1).ToLowerInvariant();
                            if (!string.IsNullOrEmpty(url))
                            {
                                feed = new WinnersFeed();
                                feed.FeedName = name;
                                feed.FeedUrl = string.Format("{0}{1}_t={2}", url, url.IndexOf("?") > 0 ? "&" : "?", DateTime.Now.Ticks);
                                feed.FeedMultiple = multiple;

                                agrs.WinnersFeeds.Add(feed);
                            }
                        }
                    #endregion Structure Feed Agrs

                        if (agrs.WinnersFeeds.Count > 0)
                            ThreadPool.QueueUserWorkItem(new WaitCallback(GetTopWinnersTask), agrs);
                    }
                }
                catch (Exception ex) {
                    Logger.Exception(ex);
                }
                finally {
                    Monitor.Exit(objGetTopWinnersLock);
                }
            }
            return winners;
        }

        private static void GetTopWinnersTask(object objAgrs)
        {
            try
            {
                if (objAgrs == null)
                    return;                
                WinnersAgrs agrs = objAgrs as WinnersAgrs;
                if (agrs == null || agrs.WinnersFeeds.Count == 0)
                    return;

                List<Winner> list = new List<Winner>();

                foreach (WinnersFeed feed in agrs.WinnersFeeds)
                {
                    if (!string.IsNullOrEmpty(feed.FeedUrl))
                    {
                        list.AddRange(ProcessWonHands(GetTopWinners(feed.FeedUrl), feed.FeedMultiple));
                    }
                }

                if (list != null)
                {
                    List<Winner> winners = new List<Winner>();
                    foreach (Winner winner in list)
                    {
                        if (winners.Exists(p => p.Nickname.Equals(winner.Nickname, StringComparison.OrdinalIgnoreCase)))
                        {
                            winners.First(p => p.Nickname.Equals(winner.Nickname, StringComparison.OrdinalIgnoreCase)).GamesWon += winner.GamesWon;
                        }
                        else
                        {
                            winners.Add(winner);
                        }
                    }
                    winners = winners.OrderByDescending(p => p.GamesWon).ToList();

                    ObjectHelper.BinarySerialize<List<Winner>>(winners, agrs.BackupPath);

                    HttpRuntime.Cache.Insert(agrs.BackupPath
                            , winners
                            , null
                            , DateTime.Now.AddSeconds(270)
                            , Cache.NoSlidingExpiration
                            );                    
                }
                else
                {
                    Logger.Warning("Everleaf Top Winners", "No data can be got", null);
                }

            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
            }
        }

        #region XML
        /*
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" media="screen" href="/~d/styles/rss2full.xsl"?>
<?xml-stylesheet type="text/css" media="screen" href="http://feeds.feedburner.com/~d/styles/itemcontent.css"?>
<rss xmlns:media="http://search.yahoo.com/mrss/" xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd" xmlns:creativeCommons="http://backend.userland.com/creativeCommonsRssModule" xmlns:feedburner="http://rssnamespace.org/feedburner/ext/1.0" xmlns:atom="http://www.w3.org/2005/Atom" version="2.0">
	<channel>
		<title>POKER4EVER Best player ranking today</title>
		<link>http://www.poker4ever.com</link>
		<atom10:link xmlns:atom10="http://www.w3.org/2005/Atom" rel="self" type="application/rss+xml" href="http://www.poker4ever.com/rss/playerranking.php?feedtype=today&amp;places=50" />
		<atom10:link xmlns:atom10="http://www.w3.org/2005/Atom" rel="hub" href="http://pubsubhubbub.appspot.com/" />
		<atom:link href="http://www.poker4ever.com/rss/playerranking.php?feedtype=today&amp;places=50" rel="self" type="application/rss+xml" />
		<description><![CDATA[ This is the POKER4EVER Best player ranking today Feed. ]]></description>
		<language>en-us</language>
		<managingEditor>support@poker4ever.com (POKER4EVER)</managingEditor>
		<webMaster>support@poker4ever.com (POKER4EVER)</webMaster>
		<pubDate>Thu, 15 Nov 2007 13:37:42 +0100</pubDate>
		<lastBuildDate>Wed, 04 Jul 2012 04:11:14 +0000</lastBuildDate>
		<openSearch:totalResults xmlns:openSearch="http://a9.com/-/spec/opensearchrss/1.0/">4</openSearch:totalResults>
		<openSearch:startIndex xmlns:openSearch="http://a9.com/-/spec/opensearchrss/1.0/">1</openSearch:startIndex>
		<openSearch:itemsPerPage xmlns:openSearch="http://a9.com/-/spec/opensearchrss/1.0/">4</openSearch:itemsPerPage>
		<media:thumbnail url="http://www.poker4ever.com/bin_images/casino_logo.png" />
		<media:category scheme="http://www.itunes.com/dtds/podcast-1.0.dtd">Games &amp; Hobbies/Other Games</media:category>
		<media:category scheme="http://www.itunes.com/dtds/podcast-1.0.dtd">Games &amp; Hobbies/Video Games</media:category>
		<media:category scheme="http://www.itunes.com/dtds/podcast-1.0.dtd">Sports &amp; Recreation/Professional</media:category>
		<itunes:owner><itunes:email>support@poker4ever.com (POKER4EVER)</itunes:email></itunes:owner>
		<itunes:explicit>no</itunes:explicit>
		<itunes:image href="http://www.poker4ever.com/bin_images/casino_logo.png" />
		<itunes:subtitle>This is the POKER4EVER Best player ranking today Feed.</itunes:subtitle>
		<itunes:category text="Games &amp; Hobbies"><itunes:category text="Other Games" /></itunes:category>
		<itunes:category text="Games &amp; Hobbies"><itunes:category text="Video Games" /></itunes:category>
		<itunes:category text="Sports &amp; Recreation"><itunes:category text="Professional" /></itunes:category>
		<creativeCommons:license>http://creativecommons.org/licenses/by-sa/3.0/</creativeCommons:license>
		<image>
			<link>http://www.poker4ever.com</link>
			<url>http://www.poker4ever.com/bin_images/casino_logo.png</url>
			<title>POKER4EVER Best player ranking today</title>
			<description>This is the POKER4EVER Best player ranking today Feed.</description>
		</image>
		<ttl>30</ttl>
		<!-- Items begin here //-->
		<item>
			<title>Ranking of Lexus</title>
			<description><![CDATA[Ranking: 1<br />Games won: 27<br />Gametype: Omaha<br />Limit: pot limit<br />Stakes: EUR 0.20/0.40<br />Time: 2012-07-04 00:00:00 - 2012-07-04 04:11:14<br />]]></description>
			<link>http://www.poker4ever.com</link>
			<pubDate>2012-07-04 04:11:14</pubDate>
			<category></category>
			<guid isPermaLink="false">1</guid>
			<ranking>1</ranking>
			<nick>Lexus</nick>
			<currency>EUR</currency>
			<count_won>27</count_won>
			<gametype>Omaha</gametype>
			<limit>pot limit</limit>
			<stake_low>0.20</stake_low>
			<stake_high>0.40</stake_high>
			<begin>2012-07-04 00:00:00</begin>
			<end>2012-07-04 04:11:14</end>
		</item>

		<item>
			<title>Ranking of imbarcato1</title>
			<description><![CDATA[Ranking: 2<br />Games won: 15<br />Gametype: HoldEm<br />Limit: no limit<br />Stakes: EUR 0.02/0.04<br />Time: 2012-07-04 00:00:00 - 2012-07-04 04:11:14<br />]]></description>
			<link>http://www.poker4ever.com</link>
			<pubDate>2012-07-04 04:11:14</pubDate>
			<category></category>
			<guid isPermaLink="false">2</guid>
			<ranking>2</ranking>
			<nick>imbarcato1</nick>
			<currency>EUR</currency>
			<count_won>15</count_won>
			<gametype>HoldEm</gametype>
			<limit>no limit</limit>
			<stake_low>0.02</stake_low>
			<stake_high>0.04</stake_high>
			<begin>2012-07-04 00:00:00</begin>
			<end>2012-07-04 04:11:14</end>
		</item>

		<item>
			<title>Ranking of solare101</title>
			<description><![CDATA[Ranking: 3<br />Games won: 10<br />Gametype: HoldEm<br />Limit: no limit<br />Stakes: EUR 1.00/2.00<br />Time: 2012-07-04 00:00:00 - 2012-07-04 04:11:14<br />]]></description>
			<link>http://www.poker4ever.com</link>
			<pubDate>2012-07-04 04:11:14</pubDate>
			<category></category>
			<guid isPermaLink="false">3</guid>
			<ranking>3</ranking>
			<nick>solare101</nick>
			<currency>EUR</currency>
			<count_won>10</count_won>
			<gametype>HoldEm</gametype>
			<limit>no limit</limit>
			<stake_low>1.00</stake_low>
			<stake_high>2.00</stake_high>
			<begin>2012-07-04 00:00:00</begin>
			<end>2012-07-04 04:11:14</end>
		</item>

		<item>
			<title>Ranking of mimisan</title>
			<description><![CDATA[Ranking: 4<br />Games won: 3<br />Gametype: HoldEm<br />Limit: no limit<br />Stakes: EUR 0.20/0.40<br />Time: 2012-07-04 00:00:00 - 2012-07-04 04:11:14<br />]]></description>
			<link>http://www.poker4ever.com</link>
			<pubDate>2012-07-04 04:11:14</pubDate>
			<category></category>
			<guid isPermaLink="false">4</guid>
			<ranking>4</ranking>
			<nick>mimisan</nick>
			<currency>EUR</currency>
			<count_won>3</count_won>
			<gametype>HoldEm</gametype>
			<limit>no limit</limit>
			<stake_low>0.20</stake_low>
			<stake_high>0.40</stake_high>
			<begin>2012-07-04 00:00:00</begin>
			<end>2012-07-04 04:11:14</end>
		</item>


		<!-- Items end here //-->
		<media:rating>nonadult</media:rating>
		<media:description type="plain">POKER4EVER Best player ranking today</media:description>
	</channel>
</rss>
*/
        #endregion
        private static List<Winner> GetTopWinners(string feedUrl)
        {
            List<Winner> winners = new List<Winner>();

            string downloadString = string.Empty;
            WebClient client = new WebClient();
            try
            {
                downloadString = client.DownloadString(new Uri(feedUrl));
            }
            catch(Exception ex) {
                Logger.Exception(ex);
            }


            if (!string.IsNullOrEmpty(downloadString))
            {
                XDocument xDoc = XDocument.Parse(downloadString);
                winners = new List<Winner>();

                #region paste XML
                IEnumerable<XElement> items = xDoc.Root.Element("channel").Elements("item");
                foreach (XElement item in items)
                {
                    Winner winner = new Winner()
                    {
                        Nickname = item.GetElementValue("nick"),
                        Currency = item.GetElementValue("currency"),
                        GamesWon = int.Parse(item.GetElementValue("count_won")),
                        GameType = item.GetElementValue("gametype"),
                        Limit = item.GetElementValue("limit"),
                    };

                    decimal stake;
                    if (decimal.TryParse(item.GetElementValue("stake_low"), NumberStyles.Number | NumberStyles.AllowDecimalPoint, CultureInfo.InvariantCulture, out stake))
                        winner.StakeLow = stake;
                    if (decimal.TryParse(item.GetElementValue("stake_high"), NumberStyles.Number | NumberStyles.AllowDecimalPoint, CultureInfo.InvariantCulture, out stake))
                        winner.StakeHigh = stake;

                    DateTime time = DateTime.Now;
                    if (DateTime.TryParseExact(item.GetElementValue("begin"), "yyyy-MM-dd HH:mm:ss", CultureInfo.InvariantCulture, DateTimeStyles.None, out time))
                        winner.StartTime = time;

                    if (DateTime.TryParseExact(item.GetElementValue("end"), "yyyy-MM-dd HH:mm:ss", CultureInfo.InvariantCulture, DateTimeStyles.None, out time))
                        winner.EndTime = time;

                    winners.Add(winner);
                }
                #endregion paste XML                
            }

            return winners;
        }

        private static List<Winner> ProcessWonHands(List<Winner> list, double multiple)
        {
            if (list != null && multiple > 0.00 && multiple!=1.00)
            {
                foreach (Winner winner in list)
                {
                    winner.GamesWon = (int)(winner.GamesWon * multiple);
                }
            }
            return list;
        }

        #endregion GetTopWinners
    }
}