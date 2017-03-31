using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Globalization;
using System.Net;
using System.Threading;
using System.Web;
using System.Web.Caching;
using System.Web.Hosting;
using System.Xml.Linq;
using CM.Sites;

namespace Poker
{
    /// <summary>
    /// Summary description for MergePokerProxy
    /// </summary>
    public static class MergePokerProxy
    {
        private sealed class AsyncDownloadInfo
        {
            public int PendingCount;
            public string CacheKey { get; set; }
            public string BackupFile { get; set; }
            public List<Tournament> Result { get; private set; }

            public AsyncDownloadInfo()
            {
                this.Result = new List<Tournament>();
            }
        }

        private sealed class AsyncDownloadTask
        {
            public TournamentType Type { get; set; }
            public AsyncDownloadInfo Info { get; set; }
        }
        /// <summary>
        /// Get the tournaments
        /// </summary>
        /// <returns></returns>
        public static List<Tournament> GetTournaments()
        {
            string cacheKey = string.Format("Poker.MergePokerProxy.GetTournaments.{0}", SiteManager.Current.DistinctName);
            List<Tournament> tournaments = HttpRuntime.Cache[cacheKey] as List<Tournament>;
            if (tournaments != null)
                return tournaments;

            string backupFile = HostingEnvironment.MapPath(string.Format("~/App_Data/{0}/MergePokerProxy.GetTournaments"
                , SiteManager.Current.DistinctName
                ));
            tournaments = ObjectHelper.BinaryDeserialize<List<Tournament>>(backupFile, new List<Tournament>());
            HttpRuntime.Cache.Insert(cacheKey
                        , tournaments
                        , null
                        , DateTime.Now.AddMinutes(5)
                        , Cache.NoSlidingExpiration
                        , CacheItemPriority.NotRemovable
                        , null
                        );

            AsyncDownloadInfo info = new AsyncDownloadInfo()
            {
                PendingCount = 3,
                CacheKey = cacheKey,
                BackupFile = backupFile,
            };

            

            SynchronizationContext context = AsyncOperationManager.SynchronizationContext;
            try
            {
                AsyncOperationManager.SynchronizationContext = new SynchronizationContext();

                AsyncDownloadTask task = new AsyncDownloadTask()
                {
                    Info = info,
                    Type = TournamentType.Current,
                };
                WebClient client = new WebClient();
                client.DownloadStringCompleted += new DownloadStringCompletedEventHandler(OnDownloadStringCompleted);
                client.DownloadStringAsync(new Uri(Settings.MergePoker_CurrentTournamentsUrl), task);

                task = new AsyncDownloadTask()
                {
                    Info = info,
                    Type = TournamentType.UpcommingFreerolls,
                };
                client = new WebClient();
                client.DownloadStringCompleted += new DownloadStringCompletedEventHandler(OnDownloadStringCompleted);
                client.DownloadStringAsync(new Uri(Settings.MergePoker_UpcomingFreerollsUrl), task);

                task = new AsyncDownloadTask()
                {
                    Info = info,
                    Type = TournamentType.UpcommingGuaranteeds,
                };
                client = new WebClient();
                client.DownloadStringCompleted += new DownloadStringCompletedEventHandler(OnDownloadStringCompleted);
                client.DownloadStringAsync(new Uri(Settings.MergePoker_UpcomingGuaranteedsUrl), task);
            }
            finally
            {
                AsyncOperationManager.SynchronizationContext = context;
            }
            
            return tournaments;
        }

        private static void OnDownloadStringCompleted(object sender, DownloadStringCompletedEventArgs e)
        {
            WebClient client = sender as WebClient;
            if (client != null)
                client.Dispose();
            AsyncDownloadTask task = e.UserState as AsyncDownloadTask;
            if (task == null)
                return;

            if (e.Error == null && !e.Cancelled && !string.IsNullOrEmpty(e.Result))
            {
                try
                {
                    XDocument xDoc = XDocument.Parse(e.Result);
                    IEnumerable<XElement> elements = xDoc.Root.Elements("tournament");
                    foreach (XElement element in elements)
                    {
                        Tournament tournament = new Tournament()
                        {
                            Name = element.GetElementValue("name"),
                            Type = task.Type,
                            Currency = "USD", // always USD for merge poker
                        };

                        decimal amount = 0.00M;
                        if (decimal.TryParse(element.GetElementValue("buy_in"), NumberStyles.Number | NumberStyles.AllowDecimalPoint, CultureInfo.InvariantCulture, out amount))
                            tournament.BuyIn = amount;

                        if (decimal.TryParse(element.GetElementValue("entry_fee"), NumberStyles.Number | NumberStyles.AllowDecimalPoint, CultureInfo.InvariantCulture, out amount))
                            tournament.EntryFee = amount;

                        if (decimal.TryParse(element.GetElementValue("total_prizepool"), NumberStyles.Number | NumberStyles.AllowDecimalPoint, CultureInfo.InvariantCulture, out amount))
                            tournament.PrizePool = amount;

                        DateTime time = DateTime.Now;
                        if (DateTime.TryParse(element.GetElementValue("registration"), out time))
                            tournament.RegistrationTime = time;

                        if (DateTime.TryParse(element.GetElementValue("start_time"), out time))
                            tournament.StartTime = time;
                        else
                            continue; // start time can't be empty

                        int num = 0;
                        if (int.TryParse(element.GetElementValue("entrants"), NumberStyles.Number, CultureInfo.InvariantCulture, out num))
                            tournament.Entrants = num;

                        task.Info.Result.Add(tournament);
                    }
                }
                catch (Exception ex)
                {
                    Logger.Exception(ex);
                }
            }

            try
            {
                if (Interlocked.Decrement(ref task.Info.PendingCount) == 0)
                {
                    HttpRuntime.Cache.Insert(task.Info.CacheKey
                        , task.Info.Result
                        , null
                        , DateTime.Now.AddMinutes(5)
                        , Cache.NoSlidingExpiration
                        , CacheItemPriority.NotRemovable
                        , null
                        );
                    ObjectHelper.BinarySerialize(task.Info.Result, task.Info.BackupFile);
                }
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
            }
        }


        /// <summary>
        /// Get overview data
        /// </summary>
        /// <returns></returns>
        public static OverviewData GetOverview()
        {
            string cacheKey = string.Format("Poker.MergePokerProxy.GetOverview.{0}", SiteManager.Current.DistinctName);
            OverviewData data = HttpRuntime.Cache[cacheKey] as OverviewData;
            if (data != null)
                return data;

            string backupFile = HostingEnvironment.MapPath(string.Format("~/App_Data/{0}/MergePokerProxy.GetOverview"
                , SiteManager.Current.DistinctName
                ));
            data = ObjectHelper.BinaryDeserialize<OverviewData>(backupFile, new OverviewData());
            HttpRuntime.Cache.Insert(cacheKey
                        , data
                        , null
                        , DateTime.Now.AddMinutes(5)
                        , Cache.NoSlidingExpiration
                        , CacheItemPriority.NotRemovable
                        , null
                        );

            AsyncDownloadInfo info = new AsyncDownloadInfo()
            {
                CacheKey = cacheKey,
                BackupFile = backupFile,
            };

            SynchronizationContext context = AsyncOperationManager.SynchronizationContext;
            try
            {
                AsyncOperationManager.SynchronizationContext = new SynchronizationContext();

                WebClient client = new WebClient();
                client.DownloadStringCompleted += new DownloadStringCompletedEventHandler(OnDownloadOverviewDataCompleted);
                client.DownloadStringAsync(new Uri(Settings.MergePoker_NetworkUrl), info);
            }
            finally
            {
                AsyncOperationManager.SynchronizationContext = context;
            }
            
            return data;            
        }

        private static void OnDownloadOverviewDataCompleted(object sender, DownloadStringCompletedEventArgs e)
        {
            try
            {
                WebClient client = sender as WebClient;
                if (client != null)
                    client.Dispose();

                AsyncDownloadInfo info = e.UserState as AsyncDownloadInfo;
                if (info == null)
                    return;

                XDocument xDoc = XDocument.Parse(e.Result);
                OverviewData data = new OverviewData()
                {
                    OnlinePlayerNumber = int.Parse(xDoc.Root.GetElementValue("players_online", "0")),
                    TournamentsNumber = int.Parse(xDoc.Root.GetElementValue("tournaments_in_progress", "0")),
                    TableNumber = int.Parse(xDoc.Root.GetElementValue("active_poker_tables", "0")),
                };

                HttpRuntime.Cache.Insert(info.CacheKey
                        , data
                        , null
                        , DateTime.Now.AddMinutes(5)
                        , Cache.NoSlidingExpiration
                        , CacheItemPriority.NotRemovable
                        , null
                        );
                ObjectHelper.BinarySerialize(data, info.BackupFile);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
            }
        }
    }



}