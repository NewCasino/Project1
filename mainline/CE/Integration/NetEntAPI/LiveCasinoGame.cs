using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Web;
using CE.db;
using GamMatrixAPI;

namespace NetEntAPI
{
    [Serializable]
    public sealed class LiveCasinoTable
    {
        private const string CACHE_FILE_FORMAT = "NetEnt.LiveCasinoGames.{0}.dat";

        public string GameID { get; set; }
        public string TableID { get; set; }
        public LiveCasinoTableLimit Limitation { get; set; }

        public LiveCasinoTable()
        {
            this.Limitation = new LiveCasinoTableLimit();
        }

        public static NetEntAPI.LiveCasinoTable Get(long domainID, string gameID, string tableID)
        {
            Dictionary<string, NetEntAPI.LiveCasinoTable> dic = GetAll(domainID);
            string key = string.Format( "{0}|{1}", gameID, tableID);
            NetEntAPI.LiveCasinoTable table = null;
            dic.TryGetValue(key, out table);
            return table;
        }

        public static Dictionary<string, NetEntAPI.LiveCasinoTable> GetAll(long domainID)
        {
            ceDomainConfigEx domain;
            if (domainID == Constant.SystemDomainID)
                domain = DomainManager.GetSysDomain();
            else
                domain = DomainManager.GetDomains().FirstOrDefault(d => d.DomainID == domainID);

            string cacheFile = Path.Combine(FileSystemUtility.GetWebSiteTempDirectory()
                , string.Format(CultureInfo.InvariantCulture, CACHE_FILE_FORMAT, CRC64.ComputeAsUtf8String(domain.GetCfg(CE.DomainConfig.NetEnt.LiveCasinoQueryOpenTablesApiURL)))
                );            

            Dictionary<string, NetEntAPI.LiveCasinoTable> dic = HttpRuntime.Cache[cacheFile] as Dictionary<string, NetEntAPI.LiveCasinoTable>;
            if (dic != null)
                return dic;

            dic = ObjectHelper.BinaryDeserialize<Dictionary<string, NetEntAPI.LiveCasinoTable>>(cacheFile, new Dictionary<string, NetEntAPI.LiveCasinoTable>());
            HttpRuntime.Cache[cacheFile] = dic;
            return dic;
        }

        public static void ClearCache(long domainID)
        {
            ceDomainConfigEx domain;
            if (domainID == Constant.SystemDomainID)
                domain = DomainManager.GetSysDomain();
            else
                domain = DomainManager.GetDomains().FirstOrDefault(d => d.DomainID == domainID);

            string cacheFile = Path.Combine(FileSystemUtility.GetWebSiteTempDirectory()
                , string.Format(CultureInfo.InvariantCulture, CACHE_FILE_FORMAT, CRC64.ComputeAsUtf8String(domain.GetCfg(CE.DomainConfig.NetEnt.LiveCasinoQueryOpenTablesApiURL)))
                );

            CacheManager.ClearCache(cacheFile);
        }

        public static string GetCachePrefixKey(long domainID)
        {
            ceDomainConfigEx domain;
            if (domainID == Constant.SystemDomainID)
                domain = DomainManager.GetSysDomain();
            else
                domain = DomainManager.GetDomains().FirstOrDefault(d => d.DomainID == domainID);

            string cacheFile = Path.Combine(FileSystemUtility.GetWebSiteTempDirectory()
                , string.Format(CultureInfo.InvariantCulture, CACHE_FILE_FORMAT, CRC64.ComputeAsUtf8String(domain.GetCfg(CE.DomainConfig.NetEnt.LiveCasinoQueryOpenTablesApiURL)))
                );

            return cacheFile;
        }


        public static Dictionary<string, NetEntAPI.LiveCasinoTable> ParseJson(long domainID, string urlFormat)
        {
            string cacheFile = Path.Combine(FileSystemUtility.GetWebSiteTempDirectory()
                , string.Format(CultureInfo.InvariantCulture, CACHE_FILE_FORMAT, CRC64.ComputeAsUtf8String(urlFormat))
                );

            Dictionary<string, NetEntAPI.LiveCasinoTable> dic = new Dictionary<string, NetEntAPI.LiveCasinoTable>(StringComparer.InvariantCultureIgnoreCase);

            // first get the EUR currency data
            string url = string.Format(CultureInfo.InvariantCulture, urlFormat, "EUR");
            RawNetEntLiveCasinoTable[] rawTables = RawNetEntLiveCasinoTable.Get(url);
            foreach (RawNetEntLiveCasinoTable rawTable in rawTables)
            {
                foreach (RawNetEntLiveCasinoGame rawGame in rawTable.Games)
                {                   
                    string key = string.Format(CultureInfo.InvariantCulture, "{0}|{1}", rawGame.GameID, rawTable.TableID);
                    dic[key] = new NetEntAPI.LiveCasinoTable()
                    {
                        GameID = rawGame.GameID,
                        TableID = rawTable.TableID.ToString(),
                    };
                    dic[key].Limitation.Type = LiveCasinoTableLimitType.SpecificForEachCurrency;
                }
            }

            CurrencyData [] currencies = GamMatrixClient.GetSupportedCurrencies();
            foreach (CurrencyData currency in currencies)
            {
                url = string.Format(CultureInfo.InvariantCulture, urlFormat, currency.ISO4217_Alpha);
                rawTables = RawNetEntLiveCasinoTable.Get(url);
                foreach (RawNetEntLiveCasinoTable rawTable in rawTables)
                {
                    foreach (RawNetEntLiveCasinoGame rawGame in rawTable.Games)
                    {
                        if (!rawGame.@params.ContainsKey("MINBET") || !rawGame.@params.ContainsKey("MAXBET"))
                            continue;

                        decimal minBet, maxBet;
                        if (!decimal.TryParse(rawGame.@params["MINBET"].ToString(), out minBet) ||
                            !decimal.TryParse(rawGame.@params["MAXBET"].ToString(), out maxBet) ||
                            minBet >= maxBet)
                        {
                            continue;
                        }
                        minBet /= 100.00M;
                        maxBet /= 100.00M;

                        string key = string.Format(CultureInfo.InvariantCulture, "{0}|{1}", rawGame.GameID, rawTable.TableID);
                        NetEntAPI.LiveCasinoTable table;
                        if (dic.TryGetValue(key, out table))
                        {
                            table.Limitation.CurrencyLimits[currency.ISO4217_Alpha] = new LimitAmount()
                            {
                                MinAmount = minBet,
                                MaxAmount = maxBet,
                            };
                        }
                    }
                }
            }
            if (dic.Keys.Count > 0)
            {
                ObjectHelper.BinarySerialize<Dictionary<string, NetEntAPI.LiveCasinoTable>>(dic, cacheFile);
                HttpRuntime.Cache[cacheFile] = dic;
            }
            return dic;
        }
    }
}
