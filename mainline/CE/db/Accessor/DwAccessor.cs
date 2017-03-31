using System;
using System.Collections.Generic;
using System.Globalization;
using System.Text;
using System.Collections.Specialized;
using System.Configuration;
using System.Linq;
using System.Threading.Tasks;

using BLToolkit.Data;
using BLToolkit.DataAccess;
using log4net;

using GamMatrixAPI;

using EveryMatrix.ReportingAgent;
using EveryMatrix.ReportingAgent.DTO;

namespace CE.db.Accessor
{
    using Utils;

    public abstract class DwAccessor : DataAccessor
    {
        readonly static NameValueCollection _environments = (NameValueCollection)ConfigurationManager.GetSection("environments");
        readonly static string BASE_URL = ConfigurationManager.AppSettings["Reporting.AgentUrl"];
        readonly static bool AGENT_ENABLED = Convert.ToBoolean(ConfigurationManager.AppSettings["Reporting.AgentEnabled"]);
        readonly static Env CURRENT_ENV = (Env)Enum.Parse(typeof(Env), ConfigurationManager.AppSettings["Reporting.Env"], true);
        readonly static Agent _agent = new Agent(new AgentOption()
        {
            BaseUri = BASE_URL,
            ILog = LogManager.GetLogger(typeof(DwAccessor)),
            LogstashUrls = ConfigurationManager.AppSettings["Logstash.Urls"].Split(new char[] { ',', ';', '|' }, StringSplitOptions.RemoveEmptyEntries),
        });

        #region SQL for queries, don't call directly
        [SqlQuery(@"EXEC GetCasinoGameTopWinners @vendorIDs, @domainIDs, @daysBack, @recordCount, @minEurAmount, @isMobile")]
        public abstract List<dwWinner> GetCasinoGameTopWinners(string vendorIDs
            , string domainIDs
            , int daysBack
            , int recordCount
            , decimal minEurAmount
            , bool isMobile
            );


        [SqlQuery(@"DECLARE @temp TABLE (col varchar(20))   
WHILE(charindex(',',@countryCodes)<>0)  
BEGIN  
  INSERT @temp(col) VALUES (substring(@countryCodes,1,charindex(',',@countryCodes)-1))  
  SET @countryCodes = stuff(@countryCodes,1,charindex(',',@countryCodes),'')  
END  
INSERT @temp(col) VALUES (@countryCodes)  
 
IF( @countryFilterMode = 0 )
BEGIN
	SELECT DISTINCT Alpha2Code FROM DwCountry WITH(NOLOCK) 
	WHERE Alpha2Code NOT IN ( SELECT col FROM @temp )
END
ELSE
BEGIN
	SELECT col AS Alpha2Code FROM @temp
END")]
        public abstract List<string> GetCountryCodes(bool countryFilterMode
            , string countryCodes
            );

        [SqlQuery(@"EXEC GetCasinoGameRecentWinners @vendorIDs=@filteredVendorIDs, @gameCodes=@filteredGameCodes, @domainIDs=@filteredDomainIDs, @countryAlpha2Codes=@filteredCountryCodes, @minWinInEUR=@minAmount, @IsUniqueUsersOnly=@returnDistinctUserOnly, @betFromTime=@startTime, @betEndTime=@endTime, @isMobile=@returnMobile")]
        public abstract List<dwWinner> GetCasinoGameRecentWinners(string filteredVendorIDs
            , string filteredGameCodes
            , string filteredDomainIDs
            , string filteredCountryCodes
            , decimal minAmount
            , bool returnDistinctUserOnly
            , DateTime startTime
            , DateTime endTime
            , bool returnMobile
            );

        [SqlQuery(@"EXEC GetMostPopularGames @domainIDs, @startTime, @endTime, @isGameRounds")]
        public abstract List<dwGamePopularity> GetGamePopularity(string domainIDs
            , DateTime startTime
            , DateTime endTime
            , bool isGameRounds
            );

        [SqlQuery(@"EXEC [CE_GetMostPopularGamesV2] @domainIDs,@betFromTime ,@betEndTime,@isGameRounds   ")]
        public abstract List<dwGamePopularity> GetMostPopularGamesV2(string domainIDs, DateTime betFromTime, DateTime betEndTime, bool isGameRounds
        //, int countryId, int GameType
        );


        [SqlQuery(@"EXEC [CE_GetPlayerLastGames] @domainID, @userid,@betFromTime ,@betEndTime,@recordCount,@isDuplicatedGames ")]
        public abstract List<ceCasinoGameTranStatus> GetPlayerLastGames(long domainID, long userid,
            DateTime betFromTime,
            DateTime betEndTime,
            int recordCount,
            bool isDuplicatedGames
            );

        [SqlQuery(@"EXEC [CE_GetPlayerMostPlayedGames] @domainID,@userID,@betFromTime ,@betEndTime,@recordCount,@minRoundCounts ")]
        public abstract List<ceCasinoGameRounds> GetPlayerMostPlayedGames(long domainID, long userId, DateTime betFromTime, DateTime betEndTime, int recordCount, int minRoundCounts);

        [SqlQuery(@"EXEC [CE_GetPlayerBiggestWinGames] @domainID,@userID,@betFromTime ,@betEndTime,@recordCount,@minWinEURAmounts,@isDuplicatedGames ")]
        public abstract List<ceCasinoGameWins> GetPlayerBiggestWinGames(long domainID, long userId, DateTime betFromTime, DateTime betEndTime, int recordCount, decimal minWinEURAmounts, bool isDuplicatedGames);
        #endregion






        public static string GetCasinoGameRecentWinnersInternalSql(ceDomainConfigEx domain, bool isMobile)
        {
            using (DbManager db = new DbManager("Dw"))
            {
                DwAccessor da = DwAccessor.CreateInstance<DwAccessor>(db);

                List<string> countryCodes = da.GetCountryCodes(domain.RecentWinnersCountryFilterMode
                    , domain.RecentWinnersCountryCodes
                    );


                return string.Format(CultureInfo.InvariantCulture, @"EXEC [GetCasinoGameRecentWinners] 
@vendorIDs='{0}',
@gameCodes='{1}',
@domainIDs='{2}',
@countryAlpha2Codes='{3}',
@minWinInEUR={4:F2},
@IsUniqueUsersOnly={5},
@betFromTime='{6}',
@betEndTime='{7}',
@isMobile={8}"
                    , domain.RecentWinnersFilteredVendorIDs
                    , domain.RecentWinnersFilteredGameCodes
                    , domain.RecentWinnersExcludeOtherOperators ? domain.DomainID.ToString() : null
                    , string.Join(",", countryCodes.ToArray())
                    , domain.RecentWinnersMinAmount
                    , domain.RecentWinnersReturnDistinctUserOnly ? 1 : 0
                    , DateTime.Now.AddDays(-12).ToString("yyyy-MM-dd HH:mm:ss")
                    , DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss")
                    , isMobile ? 1 : 0
                    );
            }
        }

        /// <summary>
        /// Get TOP {recordCount} Casino Latest Winners in recent {daysBack} days
        /// </summary>
        /// <param name="daysBack"></param>
        /// <param name="recordCount"></param>
        /// <param name="vendors"></param>
        /// <param name="domains"></param>
        /// <returns></returns>
        public static List<dwWinner> GetCasinoGameTopWinners(decimal minEurAmount
            , int daysBack
            , int recordCount
            , bool isMobile
            , VendorID[] vendors = null
            , long[] operators = null
            )
        {
            // prepare the vendors parameter
            StringBuilder vendorIDs = new StringBuilder();
            if (vendors == null || vendors.Length == 0)
            {
                foreach (VendorID vendorID in GlobalConstant.AllVendors)
                {
                    vendorIDs.AppendFormat("{0},", (int)vendorID);
                }
            }
            else
            {
                foreach (VendorID vendorID in vendors)
                {
                    vendorIDs.AppendFormat("{0},", (int)vendorID);
                }
            }
            if (vendorIDs.Length > 0 && vendorIDs[vendorIDs.Length - 1] == ',')
                vendorIDs.Remove(vendorIDs.Length - 1, 1);

            // prepare the domains parameter
            StringBuilder domainIDs = new StringBuilder();
            if (operators == null || operators.Length == 0)
            {
                DomainConfigAccessor dca = DomainConfigAccessor.CreateInstance<DomainConfigAccessor>();
                List<ceDomainConfigEx> domains = dca.GetAll(ActiveStatus.InActive);
                foreach (ceDomainConfigEx domain in domains)
                {
                    domainIDs.AppendFormat("{0},", domain.DomainID);
                }
            }
            else
            {
                foreach (long id in operators)
                {
                    domainIDs.AppendFormat("{0},", id);
                }
            }
            if (domainIDs.Length > 0 && domainIDs[domainIDs.Length - 1] == ',')
                domainIDs.Remove(domainIDs.Length - 1, 1);

            if (AGENT_ENABLED)
            {
                try
                {
                    EveryMatrix.ReportingAgent.DTO.GetTopWinnersResponse response = _agent.GetTopWinners(new GetTopWinnersRequest()
                    {
                        Environment = CURRENT_ENV,
                        VendorIDs = vendorIDs.ToString(),
                        DomainIDs = domainIDs.ToString(),
                        DaysBack = daysBack,
                        RecordCount = recordCount,
                        MinEurAmount = minEurAmount,
                        Platform = isMobile ? Platform.Mobile : Platform.Desktop,
                    });

                    if (response.TopWinners == null)
                        return new List<dwWinner>();

                    return response.TopWinners.Select(w => new dwWinner()
                    {
                        Amount = w.Amount,
                        CountryCode = w.CountryCode,
                        Currency = w.Currency,
                        DomainID = w.DomainID,
                        Firstname = w.Firstname,
                        GameCode = w.GameCode,
                        Surname = w.Surname,
                        UserID = w.UserID,
                        Username = w.Username,
                        VendorID = w.VendorID,
                        WinTime = w.WinTime,
                    }).ToList();
                }
                catch
                {
                    return new List<dwWinner>();
                }
            }

            try
            {
                using (DbManager db = new DbManager("Dw"))
                {
                    DwAccessor da = DwAccessor.CreateInstance<DwAccessor>(db);
                    return da.GetCasinoGameTopWinners(vendorIDs.ToString()
                        , domainIDs.ToString()
                        , daysBack
                        , recordCount
                        , minEurAmount
                        , isMobile
                        );
                }
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return new List<dwWinner>();
            }
        }

        public static List<dwWinner> GetCasinoGameRecentWinners(ceDomainConfigEx domain, bool isMobile)
        {
            if (AGENT_ENABLED)
            {
                try
                {
                    GetRecentWinnersResponse response = _agent.GetRecentWinners(new GetRecentWinnersRequest()
                    {
                        Environment = CURRENT_ENV,
                        CountryFilterMode = domain.RecentWinnersCountryFilterMode,
                        CountryCodes = domain.RecentWinnersCountryCodes,
                        VendorIDs = domain.RecentWinnersFilteredVendorIDs,
                        GameCodes = domain.RecentWinnersFilteredGameCodes,
                        DomainIDs = domain.RecentWinnersExcludeOtherOperators ? domain.DomainID.ToString() : null,
                        MinAmount = domain.RecentWinnersMinAmount,
                        DistinctUserOnly = domain.RecentWinnersReturnDistinctUserOnly,
                        StartTime = DateTime.Now.AddDays(-12),
                        EndTime = DateTime.Now,
                        Platform = isMobile ? Platform.Mobile : Platform.Desktop,
                    });

                    if (response.RecentWinners == null)
                        return new List<dwWinner>();

                    return response.RecentWinners.Select(w => new dwWinner()
                    {
                        Amount = w.Amount,
                        CountryCode = w.CountryCode,
                        Currency = w.Currency,
                        DomainID = w.DomainID,
                        Firstname = w.Firstname,
                        GameCode = w.GameCode,
                        Surname = w.Surname,
                        UserID = w.UserID,
                        Username = w.Username,
                        VendorID = w.VendorID,
                        WinTime = w.WinTime,
                    }).ToList();
                }
                catch
                {
                    return new List<dwWinner>();
                }
            }

            try
            {
                using (DbManager db = new DbManager("Dw"))
                {
                    DwAccessor da = DwAccessor.CreateInstance<DwAccessor>(db);

                    List<string> countryCodes = da.GetCountryCodes(domain.RecentWinnersCountryFilterMode
                        , domain.RecentWinnersCountryCodes
                        );

                    /*
    DECLARE @endDate DATETIME
    DECLARE @startDate DATETIME
    SELECT @endDate = GETDATE()
    SELECT @startDate = DATEADD( day, -12, GETDATE())
    EXEC [GetCasinoGameRecentWinners] 
    @vendorIDs='108,109',
    @gameCodes=NULL,
    @domainIDs=NULL,
    @countryAlpha2Codes='AF,AL,DZ,AS,AD,AO,AI,AQ,AG,AR,AM,AW,AU,AT,AZ,BS,BH,BD,BB,BY,BE,BZ,BJ,BM,BT,BO,BA,BW,BV,BR,IO,BN,BG,BF,BI,KH,CM,CA,CV,KY,CF,TD,CL,CN,CX,CC,CO,KM,CG,CK,CR,CI,HR,CU,CY,CZ,DK,DJ,DM,DO,TP,EC,EG,SV,GQ,ER,EE,ET,FK,FO,FJ,FI,FR,FX,GF,PF,TF,GA,GM,GE,DE,GH,GI,GR,GL,GD,GP,GU,GT,GN,GW,GY,HT,HM,HN,HK,HU,IS,IN,ID,IR,I,IE,IL,IT,JM,JP,JO,KZ,KE,KI,KW,KG,LA,LV,LB,LS,LR,LY,LI,LT,LU,MO,MK,MG,MW,MY,MV,ML,MT,MH,MQ,MR,MU,YT,MX,FM,MD,MC,MN,MS,MA,MZ,MM,NA,NR,NP,NL,AN,NC,NZ,NI,NE,NG,NU,NF,KP,MP,NO,OM,xx,PK,PW,PA,PG,PY,PE,PH,PN,PL,PT,PR,QA,RE,RO,RU,RW,KN,LC,VC,WS,SM,ST,SA,SN,SC,SL,SG,SK,SI,SB,SO,ZA,GS,KR,ES,LK,SH,PM,SD,SR,SJ,SZ,SE,CH,SY,TW,TJ,TZ,TH,TG,TK,TO,TT,TN,TR,TM,TC,TV,UG,UA,AE,GB,US,UM,UY,UZ,VU,VA,VE,VN,VI,VG,WF,EH,YE,ZR,ZM,ZW,RS,ME,0X,AX,CD,GG,IM,JE,PS,CS,TL,BL,EU,MF,A1,A2,AP',
    @minWinInEUR=1,
    @IsUniqueUsersOnly=0,
    @betFromTime=@startDate,
    @betEndTime=@endDate,
    @isMobile=1
                     */
                    string contries = string.Join(",", countryCodes.ToArray());
                    List<dwWinner> dw = da.GetCasinoGameRecentWinners(domain.RecentWinnersFilteredVendorIDs
                        , domain.RecentWinnersFilteredGameCodes
                        , domain.RecentWinnersExcludeOtherOperators ? domain.DomainID.ToString() : null
                        , contries
                        , domain.RecentWinnersMinAmount
                        , domain.RecentWinnersReturnDistinctUserOnly
                        , DateTime.Now.AddDays(-12)
                        , DateTime.Now
                        , isMobile
                        );
                    if (domain.RecentWinnersExcludeOtherOperators && domain.DomainID > 0)
                    {
                        for (int i = 0; i < dw.Count; i++)
                        {
                            dw[i].DomainID = domain.DomainID;
                        }
                    }
                    return dw;
                }
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return new List<dwWinner>();
            }
        }

        public static List<dwGamePopularity> GetGamePopularity(long? domainID, int recentDays, bool caculateByTimes)
        {
            string domainIDs = string.Empty;
            if (domainID.HasValue)
                domainIDs = domainID.Value.ToString();

            DateTime endTime = DateTime.Now.AddDays(-1);
            endTime = endTime.AddHours(23 - endTime.Hour).AddMinutes(59 - endTime.Minute).AddSeconds(59 - endTime.Second);
            DateTime startTime = endTime.AddDays(-1 * Math.Abs(recentDays) - 1);
            startTime = startTime.AddHours(-1 * startTime.Hour).AddMinutes(-1 * startTime.Hour).AddSeconds(-1 * startTime.Second);

            try
            {
                if (AGENT_ENABLED)
                {
                    GetGamePopularityResponse response = _agent.GetGamePopularity(new GetGamePopularityRequest()
                    {
                        Environment = CURRENT_ENV,
                        DomainIDs = domainIDs,
                        StartTime = startTime,
                        EndTime = endTime,
                        IsGameRounds = caculateByTimes,
                    });

                    if (response.Popularities == null)
                        return new List<dwGamePopularity>();

                    return response.Popularities.Select(p => new dwGamePopularity()
                    {
                        CountryCode = p.CountryCode,
                        GameCode = p.GameCode,
                        GameType = p.GameType,
                        Popularity = p.Popularity,
                        VendorID = p.VendorID,
                    }).ToList();
                }

                using (DbManager db = new DbManager("Dw"))
                {
                    db.Command.CommandTimeout = 1200;
                    DwAccessor da = DwAccessor.CreateInstance<DwAccessor>(db);
                    return da.GetGamePopularity(domainIDs, startTime, endTime, caculateByTimes);
                }
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return new List<dwGamePopularity>();
            }
        }

        public static List<dwGamePopularity> GetMostPopularGames(DateTime betFromTime, DateTime betEndTime, string domainIDs, bool isGameRounds
            //, int countryId, int GameType
            )
        {
            if (AGENT_ENABLED)
            {
                try
                {
                    GetGamePopularityV2Response response = _agent.GetGamePopularityV2(new GetGamePopularityV2Request()
                    {
                        Environment = CURRENT_ENV,
                        DomainIDs = domainIDs,
                        BetFromTime = betFromTime,
                        BetEndTime = betEndTime,
                        IsGameRounds = isGameRounds,
                    });

                    if (response.Popularities == null)
                        return new List<dwGamePopularity>();

                    return response.Popularities.Select(p => new dwGamePopularity()
                    {
                        CountryCode = p.CountryCode,
                        GameCode = p.GameCode,
                        GameType = p.GameType,
                        Popularity = p.Popularity,
                        VendorID = p.VendorID,
                    }).ToList();
                }
                catch
                {
                    return new List<dwGamePopularity>();
                }
            }

            try
            {
                using (DbManager db = new DbManager("Dw"))
                {
                    //CE_GetPlayerLastGames
                    DwAccessor da = DwAccessor.CreateInstance<DwAccessor>(db);
                    //if (domainIDs == "6")
                    //    domainIDs = "24";
                    return da.GetMostPopularGamesV2(domainIDs,
                          betFromTime,
                          betEndTime,
                          isGameRounds
                        //, countryId
                        //,   GameType
                        );
                }
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return new List<dwGamePopularity>();
            }
        }

        public static List<ceCasinoGameTranStatus> GetLastPlayedGames(long domainID, long userid,
            DateTime betFromTime,
            DateTime betEndTime,
            int recordCount,
            bool isDuplicatedGames)
        {
            if (userid == 0 || betFromTime == betEndTime || recordCount < 1)
            {
                return null;
            }
            //if (recordCount > 300) {
            //    recordCount = 300;
            //}

            if (AGENT_ENABLED)
            {
                try
                {
                    GetLastPlayedGamesResponse response = _agent.GetLastPlayedGames(new GetLastPlayedGamesRequest()
                    {
                        Environment = CURRENT_ENV,
                        DomainID = domainID,
                        UserID = userid,
                        BetFromTime = betFromTime,
                        BetEndTime = betEndTime,
                        RecordCount = recordCount,
                        IsDuplicatedGames = isDuplicatedGames,
                    });

                    if (response.Games == null)
                        return new List<ceCasinoGameTranStatus>();

                    return response.Games.Select(g => new ceCasinoGameTranStatus()
                    {
                        ID = g.ID,
                        GameCode = g.GameCode,
                        GameID = g.GameID,
                        GameName = g.GameName,
                        TransCompleted = g.TransCompleted,
                        VendorID = (VendorID)g.VendorID,
                    }).ToList();
                }
                catch
                {
                    return new List<ceCasinoGameTranStatus>();
                }
            }

            try
            {
                using (DbManager db = new DbManager("Dw"))
                {
                    //CE_GetPlayerLastGames
                    DwAccessor da = DwAccessor.CreateInstance<DwAccessor>(db);
                    return da.GetPlayerLastGames(domainID, userid,
                  betFromTime,
                  betEndTime,
                  recordCount,
                  isDuplicatedGames
                        );
                }
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return new List<ceCasinoGameTranStatus>();
            }
        }

        public static List<ceCasinoGameRounds> GetMostPlayedGames(long domainID, long userId, DateTime betFromTime, DateTime betEndTime, int recordCount, int minRoundCounts)
        {
            if (AGENT_ENABLED)
            {
                try
                {
                    GetMostPlayedGamesResponse response = _agent.GetMostPlayedGames(new GetMostPlayedGamesRequest()
                    {
                        Environment = CURRENT_ENV,
                        DomainID = domainID,
                        UserID = userId,
                        BetFromTime = betFromTime,
                        BetEndTime = betEndTime,
                        RecordCount = recordCount,
                        MinRoundCounts = minRoundCounts,
                    });

                    if (response.Games == null)
                        return new List<ceCasinoGameRounds>();

                    return response.Games.Select(g => new ceCasinoGameRounds()
                    {
                        ID = g.ID,
                        GameCode = g.GameCode,
                        GameID = g.GameID,
                        GameName = g.GameName,
                        GameRounds = g.GameRounds,
                        VendorID = (VendorID)g.VendorID,
                    }).ToList();
                }
                catch
                {
                    return new List<ceCasinoGameRounds>();
                }
            }

            try
            {
                using (DbManager db = new DbManager("Dw"))
                {
                    //CE_GetPlayerLastGames
                    DwAccessor da = DwAccessor.CreateInstance<DwAccessor>(db);
                    return da.GetPlayerMostPlayedGames(
                        domainID,
                        userId,
                  betFromTime,
                  betEndTime,
                  recordCount,
                  minRoundCounts
                        );
                }
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return new List<ceCasinoGameRounds>();
            }
        }

        public static List<ceCasinoGameWins> GetBiggestPlayerWinGames(long domainID, long userId, DateTime betFromTime, DateTime betEndTime, int recordCount, decimal minWinEURAmounts, bool isDuplicatedGames)
        {
            if (AGENT_ENABLED)
            {
                try
                {
                    GetBiggestWinGamesResponse response = _agent.GetBiggestWinGames(new GetBiggestWinGamesRequest()
                    {
                        Environment = CURRENT_ENV,
                        DomainID = domainID,
                        UserID = userId,
                        BetFromTime = betFromTime,
                        BetEndTime = betEndTime,
                        RecordCount = recordCount,
                        MinWinEURAmounts = minWinEURAmounts,
                        IsDuplicatedGames = isDuplicatedGames,
                    });

                    if (response.Games == null)
                        return new List<ceCasinoGameWins>();

                    return response.Games.Select(g => new ceCasinoGameWins()
                    {
                        ID = g.ID,
                        GameCode = g.GameCode,
                        GameID = g.GameID,
                        GameName = g.GameName,
                        PostingAmountEUR = g.PostingAmountEUR,
                        VendorID = (VendorID)g.VendorID,
                    }).ToList();
                }
                catch
                {
                    return new List<ceCasinoGameWins>();
                }
            }

            try
            {
                using (DbManager db = new DbManager("Dw"))
                {
                    DwAccessor da = DwAccessor.CreateInstance<DwAccessor>(db);
                    return da.GetPlayerBiggestWinGames(domainID,
                      userId,
                      betFromTime,
                      betEndTime,
                      recordCount,
                      minWinEURAmounts,
                      isDuplicatedGames
                    );
                }
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return new List<ceCasinoGameWins>();
            }
        }

    }

}
