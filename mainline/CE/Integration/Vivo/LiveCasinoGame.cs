using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.Threading;
using System.Web;
using System.Web.Caching;
using CE.Utils;
using GamMatrixAPI;

namespace VivoAPI
{
    public class LiveCasinoTable
    {
        private static object lockObj = new object();
        private const string CACHE_KEY_FORMAT = "Vivo.LiveCasinoGames.{0}.{1}.{2}.{3}.dat";
        private const string LineSEPARATOR = "[NEW_LINE]";
        private const string PropertySEPARATOR = ",";
        private const string ValueSEPARATOR = "=";

        private const string PropertyTableID = "TableID";
        private const string PropertyLimitName = "LimitName";
        private const string PropertyLimitID = "LimitID";
        private const string PropertyLimitMin = "LimitMin";
        private const string PropertyLimitMax = "LimitMax";
        private const string PropertyDealerName = "DealerName";
        private const string PropertyTableStatus = "TableStatus";
        private const string PropertyResaultHistory = "ResaultHistory";

        public static List<VivoActiveTable> GetActiveTables(string webServiceUrl, long domainID, long operatorID, string gameName, string currency)
        {
            string cacheKey = string.Format(CACHE_KEY_FORMAT, domainID, operatorID, gameName, currency);
            List<VivoActiveTable> list = HttpRuntime.Cache[cacheKey] as List<VivoActiveTable>;
            if (list != null)
                return list;

            if (Monitor.TryEnter(lockObj))
            {
                try
                {
                    list = HttpRuntime.Cache[cacheKey] as List<VivoActiveTable>;
                    if (list != null)
                        return list;

                    if (string.IsNullOrEmpty(webServiceUrl))
                    {
                        list = GetRawActiveTables(domainID, operatorID, gameName, currency);
                    }
                    else
                    {
                        GmLogger.Instance.Trace("GetRawActiveTables Webservice url: " + webServiceUrl);
                        list = GetRawActiveTables(webServiceUrl, gameName, operatorID, currency);
                    }
                    int cacheTime = 30 * 60;
                    if (list == null)
                    {
                        cacheTime = 30;
                        list = new List<VivoActiveTable>();
                    }
                    HttpRuntime.Cache.Insert(cacheKey
                           , list
                           , null
                           , DateTime.Now.AddSeconds(cacheTime)
                           , Cache.NoSlidingExpiration
                           );
                }
                finally
                {
                    Monitor.Exit(lockObj);
                }
            }

            return list;
        }

        public static Dictionary<string, List<VivoActiveTable>> GetAllRawActiveTables(long domainID, long operatorID, string currency)
        {
            string[] games = new string[] { "Baccarat", "Roulette", "BLACKJACK", "Craps", "Caribbean", "BlackJack", "DRAGONTIGER" };

            Dictionary<string, List<VivoActiveTable>> dic = new Dictionary<string, List<VivoActiveTable>>();
            foreach (string game in games)
            {

            }

            return dic;
        }

        private static List<VivoActiveTable> GetRawActiveTables(long domainID, long operatorID, string gameName, string currency)
        {
            List<VivoActiveTable> list = new List<VivoActiveTable>();

            using (GamMatrixClient client = new GamMatrixClient())
            {
                VivoGetActiveTablesRequest request = new VivoGetActiveTablesRequest()
                {
                    GameName = gameName,
                    OperatorID = operatorID,
                    PlayerCurrency = currency,
                    ContextDomainID = domainID,
                };
                request = client.SingleRequest<VivoGetActiveTablesRequest>(domainID, request);
                if (request != null)
                {
                    list = request.ActiveTables;
                }
            }

            return list;
        }

        public static List<VivoActiveTable> GetRawActiveTables(string webServiceUrl, string gameName, long operatorID, string playerCurrency)
        {
            string response = HttpHelper.GetData(new Uri(webServiceUrl + string.Format("GetActiveTables.aspx?Gamename={0}&OperatorID={1}&PlayerCurrency={2}", gameName, operatorID, playerCurrency)));

            if (!string.IsNullOrEmpty(response))
            {
                GmLogger.Instance.Trace("GetRawActiveTables live tables raw: " + response);
                List<VivoActiveTable> tables = ParseResponse(response);
                return tables;
            }
            return null;
        }

        private static List<VivoActiveTable> ParseResponse(string responseText)
        {
            if (string.IsNullOrEmpty(responseText))
            {
                return null;
            }

            string[] lines = responseText.Split(new string[] { LineSEPARATOR }, StringSplitOptions.RemoveEmptyEntries).Where(x => !string.IsNullOrEmpty(x.Trim())).ToArray();
            if (lines == null || lines.Length == 0)
            {
                return null;
            }

            List<VivoActiveTable> tables = new List<VivoActiveTable>();
            foreach (string line in lines)
            {
                VivoActiveTable table = ParseSingleTable(line);
                if (table != null)
                {
                    tables.Add(table);
                }
            }
            return tables;
        }

        private static VivoActiveTable ParseSingleTable(string tableString)
        {
            VivoActiveTable result = new VivoActiveTable();

            int position = tableString.IndexOf(PropertyResaultHistory + ValueSEPARATOR);
            if (position > -1)
            {
                result.ResultHistory = tableString.Substring(position + PropertyResaultHistory.Length + ValueSEPARATOR.Length);
                // Remove ResultHistory
                tableString = tableString.Remove(position);
            }

            string[] properties = tableString.Split(new string[] { PropertySEPARATOR }, StringSplitOptions.RemoveEmptyEntries).Where(x => !string.IsNullOrEmpty(x.Trim())).ToArray();
            if (properties != null)
            {
                result.TableID = GetPropertyValue<long>(properties, PropertyTableID);
                result.LimitName = GetPropertyValue<string>(properties, PropertyLimitName);
                result.LimitID = GetPropertyValue<long>(properties, PropertyLimitID);
                result.LimitMin = GetPropertyValue<int>(properties, PropertyLimitMin);
                result.LimitMax = GetPropertyValue<int>(properties, PropertyLimitMax);
                result.DealerName = GetPropertyValue<string>(properties, PropertyDealerName);
                result.TableStatus = GetPropertyValue<string>(properties, PropertyTableStatus);
            }

            return result;
        }

        private static T GetPropertyValue<T>(string[] properties, string propertyName)
        {
            string property = properties.Where(x => x.Contains(propertyName)).FirstOrDefault();
            if (string.IsNullOrEmpty(property))
            {
                return default(T);
            }

            string[] value = property.Split(new string[] { ValueSEPARATOR }, StringSplitOptions.RemoveEmptyEntries).Where(x => !string.IsNullOrEmpty(x.Trim())).ToArray();
            if (value == null || value.Length != 2)
            {
                return default(T);
            }

            try
            {
                return (T)TypeDescriptor.GetConverter(typeof(T)).ConvertFromInvariantString(value[1]);
            }
            catch
            {
                return default(T);
            }
        }
    }
}
