using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;
using System.Web.Hosting;
using System.Globalization;
using System.Collections.Concurrent;
using System.Web;
using System.Web.Caching;

using GamMatrix.Infrastructure;
using CM.Sites;

using Newtonsoft.Json;
using System.Text.RegularExpressions;
using CM.Content;

namespace CasinoEngine
{
    public class Watcher
    {
        static readonly BlockingCollection<string> ChangedFiles = new BlockingCollection<string>(new ConcurrentQueue<string>());
        static FileSystemWatcher _watcher = null;
        static object _lock = new object();

        public static void Initialize()
        {
            Regex.CacheSize = 100000;
            if (_watcher == null)
            {
                lock (_lock)
                {
                    if (_watcher == null)
                    {
                        string path = Path.Combine(HostingEnvironment.MapPath("~/App_Data/")
                            , ".casino"
                            );

                        _watcher = new FileSystemWatcher();
                        _watcher.Created += Watcher_Created;
                        _watcher.Changed += Watcher_Changed;
                        _watcher.Deleted += Watcher_Deleted;
                        _watcher.Renamed += Watcher_Renamed;
                        _watcher.Error += Watcher_Error;
                        _watcher.Filter = "*.json";
                        _watcher.Path = path;
                        _watcher.IncludeSubdirectories = true;
                        _watcher.EnableRaisingEvents = true;

#pragma warning disable CS4014 // Because this call is not awaited, execution of the current method continues before the call is completed
                        Task.Run(() =>
                        {
                            AnalyseFiles();
                        });
#pragma warning restore CS4014 // Because this call is not awaited, execution of the current method continues before the call is completed
                    }
                }
            }
        }

        static void AnalyseFiles()
        {
            foreach (string file in ChangedFiles.GetConsumingEnumerable())
            {
                try
                {
                    if (!File.Exists(file)) {
                        Logger.Warning("CasinoFileNotFind", "can't find this file:" + file);
                        continue;
                    }

                    string json = WinFileIO.ReadWithoutLock(file);
                    string[] strs = file.Split("\\".ToArray(), StringSplitOptions.RemoveEmptyEntries);
                    int domainID = Convert.ToInt32(strs[strs.Length - 2]);
                    string name = strs[strs.Length - 1];

                    switch (name)
                    {
                        case "content-providers.json":
                            {
                                string cacheKey = string.Format(CacheKeyFormat.ContentProviders, domainID);
                                List<ContentProvider> contentProviders = JsonConvert.DeserializeObject<List<ContentProvider>>(json);
                                SetCache(cacheKey, contentProviders);
                            }
                            break;

                        case "game-popularities.json":
                            {
                                string cacheKey = string.Format(CacheKeyFormat.GamePopularities, domainID);
                                List<GamePopularity> popularities = JsonConvert.DeserializeObject<List<GamePopularity>>(json);
                                SetCache(cacheKey, popularities);
                            }
                            break;

                        case "games.json":
                            {
                                string cacheKey = string.Format(CacheKeyFormat.Games, domainID);
                                Dictionary<string, Game> games = JsonConvert.DeserializeObject<Dictionary<string, Game>>(json);
                                SetCache(cacheKey, games);
                            }
                            break;

                        case "jackpots.json":
                            {
                                string cacheKey = string.Format(CacheKeyFormat.Jackpots, domainID);
                                List<JackpotInfo> jackpots = JsonConvert.DeserializeObject<List<JackpotInfo>>(json);
                                var site = SiteManager.GetSites().FirstOrDefault(s => s.DomainID == domainID);
                                Dictionary<string, Game> games = CasinoEngineClient.GetGames(site);
                                List<JackpotInfo> list = new List<JackpotInfo>();

                                foreach (JackpotInfo jackpot in jackpots)
                                {
                                    jackpot.Games = new List<Game>();
                                    if (jackpot.GameIDs != null && jackpot.GameIDs.Count > 0)
                                    {
                                        foreach (string gameID in jackpot.GameIDs)
                                        {
                                            Game game;
                                            if (games.TryGetValue(gameID, out game))
                                                jackpot.Games.Add(game);
                                        }

                                        if (jackpot.Games.Any())
                                            list.Add(jackpot);
                                    }
                                }
                                SetCache(cacheKey, list);
                            }
                            break;

                        case "recent-winners-desktop.json":
                            {
                                string cacheKey = string.Format(CacheKeyFormat.DesktopRecentWinners, domainID);
                                List<WinnerInfo> winners = JsonConvert.DeserializeObject<List<WinnerInfo>>(json);
                                var site = SiteManager.GetSites().FirstOrDefault(s => s.DomainID == domainID);
                                Dictionary<string, Game> games = CasinoEngineClient.GetGames(site);
                                foreach (WinnerInfo winner in winners)
                                {
                                    if (!string.IsNullOrWhiteSpace(winner.GameID))
                                    {
                                        Game game;
                                        if (games.TryGetValue(winner.GameID, out game))
                                            winner.Game = game;
                                    }
                                }

                                SetCache(cacheKey, winners);
                            }
                            break;

                        case "recent-winners-mobile.json":
                            {
                                string cacheKey = string.Format(CacheKeyFormat.MobileRecentWinners, domainID);
                                List<WinnerInfo> winners = JsonConvert.DeserializeObject<List<WinnerInfo>>(json);
                                var site = SiteManager.GetSites().FirstOrDefault(s => s.DomainID == domainID);
                                Dictionary<string, Game> games = CasinoEngineClient.GetGames(site);
                                foreach (WinnerInfo winner in winners)
                                {
                                    if (!string.IsNullOrWhiteSpace(winner.GameID))
                                    {
                                        Game game;
                                        if (games.TryGetValue(winner.GameID, out game))
                                            winner.Game = game;
                                    }
                                }

                                SetCache(cacheKey, winners);
                            }
                            break;

                        case "tables.json":
                            {
                                string cacheKey = string.Format(CacheKeyFormat.Tables, domainID);
                                Dictionary<string, LiveCasinoTable> tables = JsonConvert.DeserializeObject<Dictionary<string, LiveCasinoTable>>(json);
                                SetCache(cacheKey, tables);
                            }
                            break;

                        case "top-winners-desktop.json":
                            {
                                string cacheKey = string.Format(CacheKeyFormat.DesktopTopWinners, domainID);
                                List<WinnerInfo> winners = JsonConvert.DeserializeObject<List<WinnerInfo>>(json);
                                var site = SiteManager.GetSites().FirstOrDefault(s => s.DomainID == domainID);
                                Dictionary<string, Game> games = CasinoEngineClient.GetGames(site);
                                foreach (WinnerInfo winner in winners)
                                {
                                    if (!string.IsNullOrWhiteSpace(winner.GameID))
                                    {
                                        Game game;
                                        if (games.TryGetValue(winner.GameID, out game))
                                            winner.Game = game;
                                    }
                                }

                                SetCache(cacheKey, winners);
                            }
                            break;

                        case "top-winners-mobile.json":
                            {
                                string cacheKey = string.Format(CacheKeyFormat.MobileTopWinners, domainID);
                                List<WinnerInfo> winners = JsonConvert.DeserializeObject<List<WinnerInfo>>(json);
                                var site = SiteManager.GetSites().FirstOrDefault(s => s.DomainID == domainID);
                                Dictionary<string, Game> games = CasinoEngineClient.GetGames(site);
                                foreach (WinnerInfo winner in winners)
                                {
                                    if (!string.IsNullOrWhiteSpace(winner.GameID))
                                    {
                                        Game game;
                                        if (games.TryGetValue(winner.GameID, out game))
                                            winner.Game = game;
                                    }
                                }

                                SetCache(cacheKey, winners);
                            }
                            break;

                        case "vendors.json":
                            {
                                string cacheKey = string.Format(CacheKeyFormat.Vendors, domainID);
                                List<VendorInfo> vendors = JsonConvert.DeserializeObject<List<VendorInfo>>(json);
                                var site = SiteManager.GetSites().FirstOrDefault(s => s.DomainID == domainID);
                                List<CountryInfo> countries = CountryManager.GetAllCountries(site.DistinctName);
                                foreach (VendorInfo vendorInfo in vendors)
                                {
                                    if (vendorInfo.RestrictedTerritories == null)
                                        vendorInfo.RestrictedTerritories = new List<int>();
                                    else
                                        vendorInfo.RestrictedTerritories.Clear();
                                    if (vendorInfo.RestrictedTerritoryCountryCodes != null)
                                    {
                                        foreach (string territory in vendorInfo.RestrictedTerritoryCountryCodes)
                                        {
                                            CountryInfo country = countries.FirstOrDefault(c => string.Equals(c.ISO_3166_Alpha2Code, territory, StringComparison.InvariantCultureIgnoreCase));
                                            if (country != null)
                                                vendorInfo.RestrictedTerritories.Add(country.InternalID);
                                        }
                                    }
                                }
                                SetCache(cacheKey, vendors);
                            }
                            break;

                        default:
                            break;
                    }
                }
                catch (Exception ex)
                {
                    Logger.Exception(ex);
                }
            }
        }

        static void SetCache(string key, object value)
        {
            HttpRuntime.Cache.Insert(key
                , value
                , null
                , Cache.NoAbsoluteExpiration
                , Cache.NoSlidingExpiration
                , CacheItemPriority.NotRemovable
                , null
                );
        }

        private static void Watcher_Created(object sender, FileSystemEventArgs e)
        {
            System.Diagnostics.Debug.WriteLine(e.FullPath);
            ChangedFiles.Add(e.FullPath);
        }

        private static void Watcher_Changed(object sender, FileSystemEventArgs e)
        {
            System.Diagnostics.Debug.WriteLine(e.FullPath);
            ChangedFiles.Add(e.FullPath);
        }

        private static void Watcher_Deleted(object sender, FileSystemEventArgs e)
        {
            System.Diagnostics.Debug.WriteLine(e.FullPath);
            ChangedFiles.Add(e.FullPath);
        }

        private static void Watcher_Renamed(object sender, RenamedEventArgs e)
        {
            System.Diagnostics.Debug.WriteLine(e.FullPath);
            ChangedFiles.Add(e.FullPath);
        }

        private static void Watcher_Error(object sender, ErrorEventArgs e)
        {
            //System.Diagnostics.Debug.WriteLine(e.ToString());
            //System.Diagnostics.Debug.WriteLine(e.GetException().ToString());
        }



    }
}
