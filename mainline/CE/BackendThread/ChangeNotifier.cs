using System;
using System.Collections.Generic;
using System.Collections.Specialized;
using System.Configuration;
using System.IO;
using System.Linq;
using System.Net;
using System.Text;
using System.Threading;
using System.Web;
using BLToolkit.DataAccess;
using CE.db;
using CE.db.Accessor;
using CE.Utils;
using GamMatrixAPI;
using Newtonsoft.Json;

namespace CE.BackendThread
{
    public static class ChangeNotifier
    {
        public enum ChangeType
        {
            GameList,
            LiveCasinoTableList,
            JackpotList
        }

        public static void Init()
        {
            BackgroundThreadPool.QueueUserWorkItem("ChangeNotifier", LongRunThread, null);
        }

        private static void LongRunThread(object state)
        {
            for (; ; )
            {
                //Thread.Sleep(60 * 60 * 1000);
                UpdateOriginalFeeds();
                Thread.Sleep(60 * 60 * 1000);
            }
        }

        #region load original feeds from game vendor
        public static void ReloadOriginalFeeds()
        {
            ReloadNetentOriginalFeeds();
            UpdateOriginalFeeds();
        }

        private static bool UpdateOriginalFeeds()
        {
            try
            {
                string iSoftBetHash = string.Empty;
                List<string> listISoftBetHash = new List<string>();

                ceDomainConfigEx systemDomain = new ceDomainConfigEx()
                {
                    DomainID = Constant.SystemDomainID,
                };

                ParseXProLiveCasinoGameList(systemDomain);

                //iSoftBetHash = ISoftBetIntegration.GameMgt.GetFeedsIdentifier(systemDomain);
                //ISoftBetIntegration.GameMgt.LoadRawGameFeeds(systemDomain);
                //if (!string.IsNullOrWhiteSpace(iSoftBetHash))
                //    listISoftBetHash.Add(iSoftBetHash);

                List<ceDomainConfigEx> domains = DomainManager.GetDomains();
                CasinoVendorAccessor cva = CasinoVendorAccessor.CreateInstance<CasinoVendorAccessor>();
                ChangeNotificationAccessor cna = ChangeNotificationAccessor.CreateInstance<ChangeNotificationAccessor>();
                List<VendorID> liveCasinoVendors = new List<VendorID>()
                    {
                        VendorID.EvolutionGaming, VendorID.XProGaming
                    };

                foreach (ceDomainConfigEx domain in domains)
                {
                    if (domain.DomainID == Constant.SystemDomainID)
                        continue;

                    List<VendorID> vendors = cva.GetLiveCasinoVendors(domain.DomainID);

                    if (!vendors.Exists(v => liveCasinoVendors.Contains(v)))
                        continue;

                    //iSoftBetHash = ISoftBetIntegration.GameMgt.GetFeedsIdentifier(domain);
                    //if (!string.IsNullOrWhiteSpace(iSoftBetHash) && !listISoftBetHash.Exists(h => h == iSoftBetHash))
                    //{
                    //    ISoftBetIntegration.GameMgt.LoadRawGameFeeds(domain);
                    //    listISoftBetHash.Add(iSoftBetHash);
                    //}

                    long xproGamesHash = 0L;
                    if (vendors.Exists(v => v == VendorID.XProGaming))
                    {
                        xproGamesHash = (long)ParseXProLiveCasinoGameList(domain);
                    }

                    long tableStatusHash = (long)GetLiveCasinoTableStatusHash(domain);

                    if (tableStatusHash > 0L || xproGamesHash > 0L)
                    {
                        ceChangeNotification notification = cna.GetLastSuccessfulChangeNotification(domain.DomainID
                            , ChangeType.LiveCasinoTableList.ToString()
                            , DateTime.Now.AddHours(-1)
                            );
                        if (notification != null &&
                            notification.HashValue1 == xproGamesHash &&
                            notification.HashValue2 == tableStatusHash)
                        {
                            continue;
                        }

                        string error;
                        bool success = Send(domain, ChangeType.LiveCasinoTableList, out error);

                        SqlQuery<ceChangeNotification> query = new SqlQuery<ceChangeNotification>();
                        notification = new ceChangeNotification();
                        notification.Ins = DateTime.Now;
                        notification.DomainID = domain.DomainID;
                        notification.Succeeded = success;
                        notification.Type = ChangeType.LiveCasinoTableList.ToString();
                        notification.HashValue1 = xproGamesHash;
                        notification.HashValue2 = tableStatusHash;
                        query.Insert(notification);
                    }
                }
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return false;
            }

            return true;
        }

        private static bool ReloadNetentOriginalFeeds()
        {
            try
            {
                ulong netentFeedURLHash = 0;
                Dictionary<ulong, bool> dicNetentFeedURLHash = new Dictionary<ulong, bool>();

                ceDomainConfigEx systemDomain = new ceDomainConfigEx()
                {
                    DomainID = Constant.SystemDomainID,
                };

                ParseNetEntLiveCasinoTableList(systemDomain);
                netentFeedURLHash = CRC64.ComputeAsUtf8String(systemDomain.GetCfg(CE.DomainConfig.NetEnt.LiveCasinoQueryOpenTablesApiURL));
                dicNetentFeedURLHash.Add(netentFeedURLHash, true);

                List<ceDomainConfigEx> domains = DomainManager.GetDomains();
                CasinoVendorAccessor cva = CasinoVendorAccessor.CreateInstance<CasinoVendorAccessor>();
                ChangeNotificationAccessor cna = ChangeNotificationAccessor.CreateInstance<ChangeNotificationAccessor>();

                foreach (ceDomainConfigEx domain in domains)
                {
                    if (domain.DomainID == Constant.SystemDomainID)
                        continue;

                    List<VendorID> vendors = cva.GetLiveCasinoVendors(domain.DomainID);

                    if (!vendors.Exists(v => v == VendorID.NetEnt))
                        continue;

                    long hash1 = (long)CRC64.ComputeAsUtf8String(VendorID.NetEnt.ToString());
                    long hash2 = 0L;
                    netentFeedURLHash = CRC64.ComputeAsUtf8String(domain.GetCfg(CE.DomainConfig.NetEnt.LiveCasinoQueryOpenTablesApiURL));
                    if (!dicNetentFeedURLHash.Keys.Contains(netentFeedURLHash))
                    {
                        dicNetentFeedURLHash.Add(netentFeedURLHash, true);
                        ParseNetEntLiveCasinoTableList(domain);

                        hash2 = domain.DomainID;
                    }

                    if (hash1 > 0L || hash2 > 0L)
                    {
                        ceChangeNotification notification = cna.GetLastSuccessfulChangeNotification(domain.DomainID
                            , ChangeType.LiveCasinoTableList.ToString()
                            , DateTime.Now.AddHours(-1)
                            );
                        if (notification != null &&
                            notification.HashValue1 == hash1 &&
                            notification.HashValue2 == hash2)
                        {
                            continue;
                        }

                        string error;
                        bool success = Send(domain, ChangeType.LiveCasinoTableList, out error);

                        SqlQuery<ceChangeNotification> query = new SqlQuery<ceChangeNotification>();
                        notification = new ceChangeNotification();
                        notification.Ins = DateTime.Now;
                        notification.DomainID = domain.DomainID;
                        notification.Succeeded = success;
                        notification.Type = ChangeType.LiveCasinoTableList.ToString();
                        notification.HashValue1 = hash1;
                        notification.HashValue2 = hash2;
                        query.Insert(notification);
                    }
                }
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return false;
            }

            return true;
        }
        #endregion

        #region send
        public static string SendToAllOld(ChangeType changeType, long domainID = 0)
        {
            bool success = true;
            StringBuilder errorMessages = new StringBuilder();

            string outputError;

            List<ceDomainConfigEx> domains = DomainManager.GetDomains();
            if (domainID == 0 || domainID == Constant.SystemDomainID)
            {
                if (DomainManager.CurrentDomainID != Constant.SystemDomainID)
                {
                    domains = domains.Where(d => d.DomainID == DomainManager.CurrentDomainID).ToList();
                }

                foreach (ceDomainConfigEx domain in domains)
                {
                    if (!Send(domain, changeType, out outputError))
                    {
                        success = false;
                        errorMessages.AppendLine(outputError);
                    }
                }
            }
            else
            {
                if (domains.Exists(d => d.DomainID == domainID))
                {
                    if (!Send(domains.FirstOrDefault(d => d.DomainID == domainID), changeType, out outputError))
                    {
                        success = false;
                        errorMessages.AppendLine(outputError);
                    }
                }
            }
            if (success)
                return "SUCCESS";

            return errorMessages.ToString();
        }

        public static bool Send(ceDomainConfigEx domain, ChangeType changeType, out string error)
        {
            bool success = true;
            StringBuilder errorMessages = new StringBuilder();
            try
            {
                if (!string.IsNullOrWhiteSpace(domain.GameListChangedNotificationUrl))
                {
                    List<string> urls = domain.GameListChangedNotificationUrl
                        .Split(new string[] { "\n" }, StringSplitOptions.RemoveEmptyEntries)
                        .Where(u => u.StartsWith("http://", StringComparison.InvariantCultureIgnoreCase) || u.StartsWith("https://", StringComparison.InvariantCultureIgnoreCase)
                    ).ToList();

                    foreach (string url in urls)
                    {
                        string urlWithParam = string.Format("{0}{1}ChangeType={2}"
                            , url
                            , url.IndexOf("?") > 0 ? "&" : "?"
                            , changeType.ToString()
                            );
                        try
                        {
                            using (WebClient webClient = new WebClient())
                            {
                                webClient.DownloadData(urlWithParam);
                            }
                        }
                        catch (HttpException hex)
                        {
                            errorMessages.AppendFormat("ERROR {0} - {1}\n", hex.ErrorCode, hex.Message);
                            success = false;
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                success = false;
                Logger.Exception(ex);
            }

            if (success)
                error = "SUCCEED";
            else
                error = errorMessages.ToString();
            return success;
        }

        public static string SendToAll(ChangeType changeType, long domainID = 0)
        {
            StringBuilder errorMessages = new StringBuilder();

            string outputError;
            Dictionary<long, string> dict = new Dictionary<long, string>();

            List<ceDomainConfigEx> domains = DomainManager.GetDomains();
            if (domainID == 0 || domainID == Constant.SystemDomainID)
            {
                if (DomainManager.CurrentDomainID != Constant.SystemDomainID)
                {
                    domains = domains.Where(d => d.DomainID == DomainManager.CurrentDomainID).ToList();
                }

                foreach (ceDomainConfigEx domain in domains)
                {
                    dict.Add(domain.DomainID, changeType.ToString());
                    if (!Send(domain, changeType, out outputError))
                    {
                        errorMessages.AppendLine(outputError);
                    }
                }
            }
            else
            {
                if (domains.Exists(d => d.DomainID == domainID))
                {
                    dict.Add(domainID, changeType.ToString());
                    if (!Send(domains.FirstOrDefault(d => d.DomainID == domainID), changeType, out outputError))
                    {
                        errorMessages.AppendLine(outputError);
                    }
                }
            }
            string json = JsonConvert.SerializeObject(dict);

            NameValueCollection gameListChangedNotificationUrls = ConfigurationManager.GetSection("gameListChangedNotificationUrls") as NameValueCollection;
            if (gameListChangedNotificationUrls == null || gameListChangedNotificationUrls.Count == 0)
                throw new Exception("Error, can not find the notification configration.");

            foreach (string key in gameListChangedNotificationUrls.Keys)
            {
                string url = gameListChangedNotificationUrls[key];

                HttpWebRequest request = HttpWebRequest.Create(url) as HttpWebRequest;
                request.KeepAlive = false;
                request.Method = "POST";
                request.ProtocolVersion = Version.Parse("1.0");
                request.ContentLength = json.Length;
                request.AutomaticDecompression = DecompressionMethods.GZip | DecompressionMethods.Deflate;
                request.Accept = "text/plain";

                using (Stream stream = request.GetRequestStream())
                using (StreamWriter writer = new StreamWriter(stream))
                {
                    writer.Write(json);
                    writer.Flush();
                }

                HttpWebResponse response = request.GetResponse() as HttpWebResponse;
                string respText = null;
                using (Stream stream = response.GetResponseStream())
                {
                    using (StreamReader sr = new StreamReader(stream))
                    {
                        respText = sr.ReadToEnd();
                    }
                }
                response.Close();

                bool success = string.Compare(respText, "OK", true) == 0;
                if (!success)
                    errorMessages.AppendLine(respText);
            }

            return errorMessages.Length == 0 ? "SUCCESS" : errorMessages.ToString();
        }
        #endregion

        private static ulong GetLiveCasinoTableStatusHash(ceDomainConfigEx domain)
        {
            StringBuilder sb = new StringBuilder();
            List<ceLiveCasinoTableBaseEx> tables = LiveCasinoTableAccessor.GetDomainTables(domain.DomainID, null, true, true)
                .OrderBy(t => t.ID).ToList();
            foreach (ceLiveCasinoTableBaseEx table in tables)
            {
                sb.AppendFormat("{0}-{1}\n", table.ID, table.IsOpen(domain.DomainID));
            }

            return CRC64.ComputeAsAsciiString(sb.ToString());
        }

        #region Parse
        private static ulong ParseXProLiveCasinoGameList(ceDomainConfigEx domain)
        {
            try
            {
                using (GamMatrixClient client = new GamMatrixClient())
                {
                    XProGamingAPIRequest request = new XProGamingAPIRequest()
                    {
                        GetGamesListWithLimits = true,
                        GetGamesListWithLimitsGameType = (int)XProGaming.GameType.AllGames,
                        GetGamesListWithLimitsOnlineOnly = 0,
                        //GetGamesListWithLimitsUserName = "dummy"
                    };
                    request = client.SingleRequest<XProGamingAPIRequest>(domain.DomainID, request);

                    if (string.IsNullOrWhiteSpace(request.GetGamesListWithLimitsResponse))
                        return 0L;

                    string xml = request.GetGamesListWithLimitsResponse;
                    XProGaming.Game.ParseXml(domain.DomainID, xml);

                    return CRC64.ComputeAsAsciiString(xml);
                }
            }
            catch (GmException gex)
            {
                if (gex.ReplyResponse.ErrorCode == "SYS_1008")
                    return 0L;
                Logger.Exception(gex);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
            }
            return 0L;
        }

        private static void ParseNetEntLiveCasinoTableList(ceDomainConfigEx domain)
        {
            try
            {
                string urlFormat = domain.GetCfg(CE.DomainConfig.NetEnt.LiveCasinoQueryOpenTablesApiURL);
                if (string.IsNullOrWhiteSpace(urlFormat))
                    return;

                NetEntAPI.LiveCasinoTable.ParseJson(domain.DomainID, urlFormat);

            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
            }
        }
        #endregion
    }
}
