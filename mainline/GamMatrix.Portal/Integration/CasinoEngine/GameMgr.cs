using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using System.Web;
using System.Web.Caching;
using System.Web.Hosting;
using System.Xml.Linq;
using CM.Content;
using CM.db;
using CM.db.Accessor;
using CM.Sites;
using CM.State;
using GamMatrix.Infrastructure;

namespace CasinoEngine
{
    public sealed class LiveCasinoCategory
    {
        public string CategoryName { get; set; }
        public string CategoryKey { get; set; }
        public string CategoryTitle { get; set; }
        public string CategoryUrl { get; set; }
        public List<LiveCasinoTable> Tables { get; set; }
    }
    public sealed class JackpotGame
    {
        public Game Game { get; set; }
        public JackpotInfo JackpotInfo { get; set; }
    }

    /// <summary>
    /// Summary description for GameCategoryMgr
    /// </summary>
    public static class GameMgr
    {
        internal sealed class JsonDataCache
        {
            internal string JsonData { get; set; }
            internal int Count { get; set; }
        }

        public const string GAME_CATEGORY_XML_PATH = @"~/Views/{0}/.config/game_category.xml";
        public const string TABLE_CATEGORY_XML_PATH = @"~/Views/{0}/.config/live_casino_category.xml";

        /// <summary>
        /// Get the visitor's IP country code
        /// </summary>
        /// <returns></returns>
        private static string GetIPCountryCode()
        {
            try
            {
                if (CustomProfile.Current.IpCountryID > 0)
                    return CountryManager.GetAllCountries().First(c => CustomProfile.Current.IpCountryID == c.InternalID).ISO_3166_Alpha2Code;
            }
            catch
            {
            }
            return null;
        }

        /// <summary>
        /// Get the user platform
        /// </summary>
        /// <returns></returns>
        private static Platform GetUserPlatform()
        {
            try
            {
                string userAgent = HttpContext.Current.Request.UserAgent;
                if (Regex.IsMatch(userAgent, @"\biPad\b", RegexOptions.Compiled | RegexOptions.CultureInvariant))
                    return Platform.iPad;

                if (Regex.IsMatch(userAgent, @"\biPhone\b", RegexOptions.Compiled | RegexOptions.CultureInvariant))
                    return Platform.iPhone;

                if (Regex.IsMatch(userAgent, @"\bAndroid\b", RegexOptions.Compiled | RegexOptions.CultureInvariant))
                    return Platform.Android;

                if (Regex.IsMatch(userAgent, @"\bWindows(\s+)Phone(\s+)OS(\s+)7", RegexOptions.Compiled | RegexOptions.CultureInvariant))
                    return Platform.WM7;

                if (Regex.IsMatch(userAgent, @"\bWindows(\s+)Phone(\s+)8", RegexOptions.Compiled | RegexOptions.CultureInvariant))
                    return Platform.WP8;
            }
            catch
            {
            }
            return Platform.PC;
        }

        /// <summary>
        /// Get the user profile country code
        /// </summary>
        /// <returns></returns>
        private static string GetUserCountryCode()
        {
            try
            {
                if (CustomProfile.Current.IsAuthenticated)
                {
                    return CountryManager.GetAllCountries().First(c => CustomProfile.Current.UserCountryID == c.InternalID).ISO_3166_Alpha2Code;
                }
            }
            catch
            {
            }
            return null;
        }


        public static void SaveTableCategoryXml(cmSite site, string xmlContent)
        {
            XDocument xml = XDocument.Parse(xmlContent);

            string filename = HostingEnvironment.MapPath(string.Format(TABLE_CATEGORY_XML_PATH, site.DistinctName));
            FileSystemUtility.EnsureDirectoryExist(filename);

            IEnumerable<XElement> elements = xml.Descendants("node");
            foreach (XElement element in elements)
            {
                if (element.Attribute("type") == null ||
                    element.Attribute("label") == null ||
                    element.Attribute("id") == null)
                    continue;
                string type = element.Attribute("type").Value;
                string id = element.Attribute("id").Value;
                string label = element.Attribute("label").Value;
                if (string.IsNullOrWhiteSpace(type) || string.IsNullOrWhiteSpace(id) || string.IsNullOrWhiteSpace(label))
                    continue;

                switch (type.ToLower())
                {
                    //case "category":
                    //    {
                    //        if (id != "BACCARAT" && id != "ROULETTE" && id != "HOLDEM" && id != "BLACKJACK" 
                    //            && id != "POKER" && id != "SICBO")
                    //            throw new Exception("Unrecognized catetory!");
                    //        break;
                    //    }

                    case "group":
                        {
                            throw new Exception("Live Casino table does not support group!");
                        }
                }
            }

            string relativePath = "/.config/live_casino_category.xml";
            string name = "Live Casino Tables";
            Revisions.BackupIfNotExists(site, filename, relativePath, name);

            xml.Save(filename);

            Revisions.Backup(site, filename, relativePath, name);
        }

        public static void SaveGameCategoryXml(cmSite site, string xmlContent)
        {
            XDocument xml = XDocument.Parse(xmlContent);

            string filename = HostingEnvironment.MapPath(string.Format(GAME_CATEGORY_XML_PATH, site.DistinctName));
            FileSystemUtility.EnsureDirectoryExist(filename);

            IEnumerable<XElement> elements = xml.Descendants("node");
            foreach (XElement element in elements)
            {
                if (element.Attribute("type") == null ||
                    element.Attribute("label") == null ||
                    element.Attribute("id") == null)
                    continue;
                string type = element.Attribute("type").Value;
                string id = element.Attribute("id").Value;
                string label = element.Attribute("label").Value;
                if (string.IsNullOrWhiteSpace(type) || string.IsNullOrWhiteSpace(id) || string.IsNullOrWhiteSpace(label))
                    continue;

                switch (type.ToLower())
                {
                    case "category":
                        {
                            EnsureCategoryExist(site, id, label);
                            break;
                        }

                    case "group":
                        {
                            EnsureGroupExist(site, id, label);
                            break;
                        }
                }
            }

            string relativePath = "/.config/game_category.xml";
            string name = "Categories";
            Revisions.BackupIfNotExists(site, filename, relativePath, name);

            xml.Save(filename);

            Revisions.Backup(site, filename, relativePath, name);
        }//

        /// <summary>
        /// Ensure the category exists in metadata
        /// </summary>
        /// <param name="site"></param>
        /// <param name="id"></param>
        /// <param name="label"></param>
        public static void EnsureCategoryExist(cmSite site, string id, string label)
        {
            string path = string.Format(GameCategory.TRANSLATION_PATH, id);
            if (!string.IsNullOrEmpty(site.TemplateDomainDistinctName))
            {
                string physicalPath = HostingEnvironment.MapPath(string.Format("~/Views/{0}/{1}"
                    , site.TemplateDomainDistinctName
                    , path
                    ));
                if (Directory.Exists(physicalPath))
                    return;
            }
            if (Metadata.CreateMetadata(site, path))
            {
                Metadata.Save(site, path, null, "Name", label);
                Metadata.Save(site, path, null, "FriendlyID"
                    , Regex.Replace(label.ToLowerInvariant(), @"[^a-z0-9]", "-")
                    );
            }
        }


        /// <summary>
        ///  Ensure the group exists in metadata
        /// </summary>
        /// <param name="site"></param>
        /// <param name="id"></param>
        /// <param name="label"></param>
        public static void EnsureGroupExist(cmSite site, string id, string label)
        {
            string path = string.Format(GameCategory.TRANSLATION_PATH, id);
            if (!string.IsNullOrEmpty(site.TemplateDomainDistinctName))
            {
                string physicalPath = HostingEnvironment.MapPath(string.Format("~/Views/{0}/{1}"
                    , site.TemplateDomainDistinctName
                    , path
                    ));
                if (Directory.Exists(physicalPath))
                    return;
            }
            if (Metadata.CreateMetadata(site, path))
            {
                Metadata.Save(site, path, null, "Name", label);
                Metadata.Save(site, path, null, "ShortName", label);
                Metadata.Save(site, path, null, "Thumbnail", "<!--Insert Thumbnail Image here -->");
                Metadata.Save(site, path, null, "Logo", "<!--Insert Logo Image here -->");
                Metadata.Save(site, path, null, "BackgroundImage", "<!--Insert Background Image here -->");

            }
        }

        private static bool IsAvailableGame(GameRef g
            , string userIPCountryCode
            , string userCountryCode
            , Platform platform
            )
        {
            return IsAvailableGame(g.Game, userIPCountryCode, userCountryCode, platform);
        }

        private static bool IsAvailableGame(Game game
            , string userIPCountryCode
            , string userCountryCode
            , Platform platform
            )
        {
            if (game == null)
                return false;
            if (!game.Platforms.Contains(platform))
                return false;
            if (game.RestrictedTerritories == null ||
                game.RestrictedTerritories.Length == 0)
            {
                return true;
            }

            if (!string.IsNullOrWhiteSpace(userCountryCode))
            {
                if (game.RestrictedTerritories.FirstOrDefault(t =>
                    string.Equals(userCountryCode, t, StringComparison.InvariantCultureIgnoreCase)) != null)
                {
                    return false;
                }
            }
            if (!string.IsNullOrWhiteSpace(userIPCountryCode))
            {
                if (game.RestrictedTerritories.FirstOrDefault(t =>
                    string.Equals(userIPCountryCode, t, StringComparison.InvariantCultureIgnoreCase)) != null)
                {
                    return false;
                }
            }
            return true;
        }

        private static string GetCountryKey(string code1, string code2)
        {
            if (string.Compare(code1, code2, true) > 0)
                return string.Format(CultureInfo.InvariantCulture, "{0}|{1}", code1, code2);

            return string.Format(CultureInfo.InvariantCulture, "{0}|{1}", code2, code1);
        }

        private static string GetCacheKey(string prefix, string userIPCountryCode, string userCountryCode, Platform platform)
        {
            return string.Format(CultureInfo.InvariantCulture
                , "{0}_{1}_{2}_{3}_{4}_{5}"
                , prefix
                , SiteManager.Current.ID
                , GetCountryKey(userIPCountryCode, userCountryCode)
                , platform
                , CustomProfile.Current.IsAuthenticated
                , MultilingualMgr.GetCurrentCulture()
                );
        }

        private static CacheDependencyEx GetCacheDependency()
        {
            cmSite site = SiteManager.Current;
            List<string> dependedFiles = new List<string>();
            string physicalPath = HostingEnvironment.MapPath(string.Format(GAME_CATEGORY_XML_PATH, site.DistinctName));
            dependedFiles.Add(physicalPath);

            if (!global::System.IO.File.Exists(physicalPath))
            {
                if (!string.IsNullOrWhiteSpace(site.TemplateDomainDistinctName))
                {
                    physicalPath = HostingEnvironment.MapPath(
                        string.Format(GAME_CATEGORY_XML_PATH, site.TemplateDomainDistinctName)
                        );
                    dependedFiles.Add(physicalPath);
                }
            }
            return new CacheDependencyEx(dependedFiles.ToArray(), false);
        }


        /*
         * ID : identity of the game or group
         * P : Popularity number
         * V : VendorID number
         * G : Game name string
         * I : Image url string (Thumbnail)
         * F : 1/0, fun mode enabled
         * R : 1/0, real money mode enabled
         * S : Slug
         * N : 1/0, new game
         * T : 1/0, tournament
         * H : 1/0, hot games
         * C : [optional, array], games in group
         * O : Offer FPP
         * A : Short Name
         * L : Logo URL string
         */
        private static void SerializeGame(ref StringBuilder json, GameRef gameRef, bool includeDescription)
        {
            Game game;
            json.Append("{");
            if (!gameRef.IsGameGroup)
            {
                game = gameRef.Game;
                json.AppendFormat(CultureInfo.InvariantCulture
                    , "\"ID\":{0},\"P\":{1},\"V\":{2},\"G\":\"{3}\",\"I\":\"{4}\",\"F\":{5},\"R\":{6},\"S\":\"{7}\",\"N\":{8},\"T\":{9},\"H\":{10},\"O\":{11},\"D\":{12},\"L\":\"{13}\",\"CP\":\"{14}\" "
                    , game.ID
                    , Math.Min(game.Popularity, 9007199254740991)
                    , (int)game.VendorID
                    , game.ShortName.SafeJavascriptStringEncode()
                    , game.ThumbnailUrl.SafeJavascriptStringEncode()
                    , (CustomProfile.Current.IsAuthenticated ? game.IsFunModeEnabled : game.IsAnonymousFunModeEnabled) ? "1" : "0"
                    , (CustomProfile.Current.IsAuthenticated && game.IsRealMoneyModeEnabled) ? "1" : "0"
                    , game.Slug.DefaultIfNullOrEmpty(game.ID.ToString()).SafeJavascriptStringEncode()
                    , game.IsNewGame ? "1" : "0"
                    , "0"
                    , "0"
                    , game.FPP >= 1.00M ? "1" : "0"
                    , string.IsNullOrWhiteSpace(game.HelpUrl) ? "0" : "1"
                    , game.LogoUrl.SafeJavascriptStringEncode()
                    , game.ContentProvider.SafeJavascriptStringEncode()
                    );
                if (includeDescription)
                {
                    json.AppendFormat(",\"E\":\"{0}\"", game.Description.SafeJavascriptStringEncode());
                }
            }
            else if (gameRef.Children.Count > 0)
            {
                game = gameRef.Children[0].Game;
                bool isFunModeEnabled = (CustomProfile.Current.IsAuthenticated ? game.IsFunModeEnabled : game.IsAnonymousFunModeEnabled);
                json.AppendFormat(CultureInfo.InvariantCulture
                    , "\"ID\":\"{0}\",\"P\":{1},\"V\":{2},\"G\":\"{3}\",\"I\":\"{4}\",\"F\":{5},\"C\":["
                    , gameRef.ID
                    , Math.Min(gameRef.Popularity, 9007199254740991)
                    , (int)gameRef.VendorID
                    , gameRef.Name.SafeJavascriptStringEncode()
                    , gameRef.ThumbnailUrl.SafeJavascriptStringEncode()
                    , isFunModeEnabled ? "1" : "0"
                    );
                foreach (GameRef childRef in gameRef.Children)
                {
                    game = childRef.Game;
                    json.Append("{");
                    json.AppendFormat(CultureInfo.InvariantCulture
                        , "\"ID\":{0},\"P\":{1},\"V\":{2},\"G\":\"{3}\",\"I\":\"{4}\",\"F\":{5},\"R\":{6},\"S\":\"{7}\",\"N\":{8},\"T\":{9},\"H\":{10},\"O\":{11},\"A\":\"{12}\""
                        , game.ID
                        , Math.Min(game.Popularity, 9007199254740991)
                        , (int)game.VendorID
                        , game.ShortName.SafeJavascriptStringEncode()
                        , game.ThumbnailUrl.SafeJavascriptStringEncode()
                        , (CustomProfile.Current.IsAuthenticated ? game.IsFunModeEnabled : game.IsAnonymousFunModeEnabled) ? "1" : "0"
                        , game.IsRealMoneyModeEnabled ? "1" : "0"
                        , game.Slug.DefaultIfNullOrEmpty(game.ID.ToString()).SafeJavascriptStringEncode()
                        , game.IsNewGame ? "1" : "0"
                        , "0"
                        , "0"
                        , game.FPP >= 1.00M ? "1" : "0"
                        , game.ShortName.SafeJavascriptStringEncode()
                        );
                    if (includeDescription)
                    {
                        json.AppendFormat(",\"E\":\"{0}\"", game.Description.SafeJavascriptStringEncode());
                    }
                    json.Append("},");
                }
                if (json[json.Length - 1] == ',') json.Remove(json.Length - 1, 1);
                json.Append("]");

            }// if_else

            json.Append("}");
        }

        public static string GetCategoryJson(GameCategory category, int maxNumber)
        {
            return GetCategoryJson(category, maxNumber, false);
        }

        public static string GetCategoryJson(GameCategory category, int maxNumber, bool includeDescription)
        {
            string userIPCountryCode = GetIPCountryCode();
            string userCountryCode = GetUserCountryCode();
            Platform platform = GetUserPlatform();

            string prefix = string.Format(CultureInfo.InvariantCulture, "GameMgr.GetCategoryJson.{0}.{1}.{2}"
                , category.FriendlyID
                , maxNumber
                , includeDescription ? "1" : "0"
             );

            string cacheKey = GetCacheKey(prefix, userIPCountryCode, userCountryCode, platform);
            string json = HttpRuntime.Cache[cacheKey] as string;
            if (json != null)
                return json;

            StringBuilder sb = new StringBuilder();
            sb.Append("[");

            int count = 0;
            foreach (GameRef gameRef in category.Games)
            {
                SerializeGame(ref sb, gameRef, includeDescription);

                sb.Append(",");

                if (++count >= maxNumber && maxNumber > 0)
                    break;
            }
            if (sb[sb.Length - 1] == ',') sb.Remove(sb.Length - 1, 1);


            sb.Append("]");

            json = sb.ToString();

            HttpRuntime.Cache.Insert(cacheKey
               , json
               , GetCacheDependency()
               , DateTime.Now.AddMinutes(15)
               , Cache.NoSlidingExpiration
               );

            return json;
        }
        public static string GetNewGameJson(int maxNumber)
        {
            return GetNewGameJson(ref maxNumber, false);
        }

        public static string GetNewGameJson(int maxNumber, bool includeDescription)
        {
            return GetNewGameJson(ref maxNumber, includeDescription);
        }

        public static string GetNewGameJson(ref int maxNumber)
        {
            return GetNewGameJson(ref maxNumber, false);
        }

        public static string GetNewGameJson(ref int maxNumber, bool includeDescription)
        {
            string userIPCountryCode = GetIPCountryCode();
            string userCountryCode = GetUserCountryCode();
            Platform platform = GetUserPlatform();


            string cacheKey = GetCacheKey("GameMgr.GetNewGamesJson." + maxNumber, userIPCountryCode, userCountryCode, platform);
            JsonDataCache cache = HttpRuntime.Cache[cacheKey] as JsonDataCache;
            if (cache != null)
            {
                maxNumber = cache.Count;
                return cache.JsonData;
            }

            cache = new JsonDataCache();

            Dictionary<int, GameRef> newGamesDic = new Dictionary<int, GameRef>();



            int gameID;
            List<GameCategory> categoies = GetCategories();
            foreach (GameCategory category in categoies)
            {
                foreach (GameRef gameRef in category.Games)
                {
                    if (gameRef.IsGameGroup)
                    {
                        foreach (GameRef childRef in gameRef.Children)
                        {
                            if (childRef.IsNewGame &&
                                int.TryParse(childRef.ID, NumberStyles.Integer, CultureInfo.InvariantCulture, out gameID))
                            {
                                newGamesDic[gameID] = childRef;
                            }
                        }
                    }
                    else if (gameRef.IsNewGame &&
                             int.TryParse(gameRef.ID, NumberStyles.Integer, CultureInfo.InvariantCulture, out gameID))
                    {
                        newGamesDic[gameID] = gameRef;
                    }
                    else
                        continue;
                }
            }

            StringBuilder sb = new StringBuilder();
            sb.Append("[");

            cache.Count = 0;
            var query = newGamesDic.Keys.ToArray().OrderByDescending(k => k).Take(maxNumber > 0 ? maxNumber : int.MaxValue);
            foreach (int key in query)
            {
                SerializeGame(ref sb, newGamesDic[key], includeDescription);
                sb.Append(",");

                cache.Count += 1;
            }

            if (sb[sb.Length - 1] == ',') sb.Remove(sb.Length - 1, 1);
            sb.Append("]");

            maxNumber = cache.Count;
            cache.JsonData = sb.ToString();

            HttpRuntime.Cache.Insert(cacheKey
               , cache
               , GetCacheDependency()
               , DateTime.Now.AddMinutes(30)
               , Cache.NoSlidingExpiration
               );

            return cache.JsonData;
        }


        public static string GetSimilarGameJson(string gameID, ref int maxNumber)
        {
            string userIPCountryCode = GetIPCountryCode();
            string userCountryCode = GetUserCountryCode();
            Platform platform = GetUserPlatform();

            string cacheKeyPrefix = string.Format(CultureInfo.InvariantCulture
                , "GameMgr.GetSimilarGameJson.{0}.{1}"
                , gameID
                , maxNumber
                );
            string cacheKey = GetCacheKey(cacheKeyPrefix, userIPCountryCode, userCountryCode, platform);
            JsonDataCache cache = HttpRuntime.Cache[cacheKey] as JsonDataCache;
            if (cache != null)
            {
                maxNumber = cache.Count;
                return cache.JsonData;
            }

            Dictionary<int, GameRef> newGamesDic = new Dictionary<int, GameRef>();

            Dictionary<string, Game> allGames = CasinoEngineClient.GetGames();
            Game game;
            if (!allGames.TryGetValue(gameID, out game))
                return "[]";

            Func<Game, Game, bool> isSimilarGame = (g, g2) =>
            {
                if (g == null)
                    return false;
                if (g2.Tags == null || g2.Tags.Length == 0)
                    return false;
                if (g.Tags == null || g.Tags.Length == 0)
                    return false;
                if (CustomProfile.Current.IsAuthenticated && !g.IsRealMoneyModeEnabled)
                    return false;
                if (!CustomProfile.Current.IsAuthenticated && !g.IsFunModeEnabled)
                    return false;
                if (g.ID == g2.ID)
                    return false;
                return (g.Tags.FirstOrDefault(t => g2.Tags.Contains(t)) != null);
            };

            Game currentGame = null;
            GameCategory currentCategory = null;
            List<GameRef> currentCategoryGames = new List<GameRef>();
            List<GameRef> games = new List<GameRef>();
            List<GameCategory> categoies = GetCategories();
            foreach (GameCategory category in categoies)
            {
                if (currentCategory == null)
                    currentCategoryGames.Clear();

                foreach (GameRef gameRef in category.Games)
                {
                    if (gameRef.IsGameGroup)
                    {
                        foreach (CasinoEngine.GameRef childRef in gameRef.Children)
                        {
                            currentGame = childRef.Game;
                            if (isSimilarGame(currentGame, game))
                                games.Add(childRef);
                            if (game.ID == currentGame.ID)
                            {
                                currentCategory = category;
                            }
                            else
                            {
                                if (currentCategory == category ||
                                    currentCategory == null)
                                {
                                    currentCategoryGames.Add(childRef);
                                }
                            }
                        }
                    }
                    else
                    {
                        currentGame = gameRef.Game;
                        if (isSimilarGame(currentGame, game))
                            games.Add(gameRef);
                        if (game.ID == currentGame.ID)
                        {
                            currentCategory = category;
                        }
                        else
                        {
                            if (currentCategory == category ||
                                currentCategory == null)
                            {
                                currentCategoryGames.Add(gameRef);
                            }
                        }
                    }
                }
            }

            // none of similar game found, get from current category
            if (games.Count == 0 && currentCategoryGames != null)
            {
                games = currentCategoryGames.OrderByDescending(g => g.Popularity).ToList();
            }

            cache = new JsonDataCache();

            StringBuilder sb = new StringBuilder();
            sb.Append("[");

            cache.Count = 0;
            foreach (GameRef g in games)
            {
                SerializeGame(ref sb, g, false);
                sb.Append(",");

                cache.Count += 1;
                if (cache.Count > maxNumber)
                    break;
            }

            if (sb.Length > 0 && sb[sb.Length - 1] == ',') sb.Remove(sb.Length - 1, 1);
            sb.Append("]");

            maxNumber = cache.Count;
            cache.JsonData = sb.ToString();

            HttpRuntime.Cache.Insert(cacheKey
               , cache
               , GetCacheDependency()
               , DateTime.Now.AddMinutes(30)
               , Cache.NoSlidingExpiration
               );

            return cache.JsonData;
        }
        public static string GetPopularGameJson(int maxNumber)
        {
            return GetPopularGameJson(ref maxNumber, false);
        }

        public static string GetPopularGameJson(int maxNumber, bool includeDescription)
        {
            return GetPopularGameJson(ref maxNumber, includeDescription);
        }
        public static string GetPopularGameJson(ref int maxNumber)
        {
            return GetPopularGameJson(ref maxNumber, false);
        }

        public static string GetPopularGameJson(ref int maxNumber, bool includeDescription)
        {
            string userIPCountryCode = GetIPCountryCode();
            string userCountryCode = GetUserCountryCode();
            Platform platform = GetUserPlatform();


            string cacheKey = GetCacheKey("GameMgr.GetPopularGameJson." + maxNumber, userIPCountryCode, userCountryCode, platform);
            JsonDataCache cache = HttpRuntime.Cache[cacheKey] as JsonDataCache;
            if (cache != null)
            {
                maxNumber = cache.Count;
                return cache.JsonData;
            }

            cache = new JsonDataCache();
            List<GameRef> popularGames = new List<GameRef>();


            List<GameCategory> categoies = GetCategories();
            foreach (GameCategory category in categoies)
            {
                foreach (GameRef gameRef in category.Games)
                {
                    if (gameRef.IsGameGroup)
                    {
                        foreach (GameRef childRef in gameRef.Children)
                        {
                            if (childRef.Popularity > 1)
                            {
                                popularGames.Add(childRef);
                            }
                        }
                    }
                    else if (gameRef.Popularity > 1)
                    {
                        popularGames.Add(gameRef);
                    }
                    else
                        continue;
                }
            }

            StringBuilder sb = new StringBuilder();
            sb.Append("[");

            cache.Count = 0;
            var query = popularGames.Distinct(new GameRefComparer()).OrderByDescending(g => g.Popularity).Take(maxNumber > 0 ? maxNumber : int.MaxValue);
            foreach (GameRef gameRef in query)
            {
                SerializeGame(ref sb, gameRef, includeDescription);
                sb.Append(",");
                cache.Count += 1;
            }

            if (sb[sb.Length - 1] == ',') sb.Remove(sb.Length - 1, 1);
            sb.Append("]");

            maxNumber = cache.Count;
            cache.JsonData = sb.ToString();

            HttpRuntime.Cache.Insert(cacheKey
               , cache
               , GetCacheDependency()
               , DateTime.Now.AddMinutes(30)
               , Cache.NoSlidingExpiration
               );

            return cache.JsonData;
        }



        /// <summary>
        /// 
        /// </summary>
        /// <param name="maxNumOfNewGame"></param>
        /// <param name="maxNumOfPopularGame"></param>
        /// <returns>{'XXX':[],'YYY':[],'ZZZ':[]}</returns>
        public static string GetAllGamesJson(int maxNumOfNewGame, int maxNumOfPopularGame, bool includeDescription)
        {


            StringBuilder sb = new StringBuilder();
            sb.Append('{');

            sb.AppendFormat(CultureInfo.InvariantCulture, "\n\"newest\":{0}", GetNewGameJson(maxNumOfNewGame, includeDescription));
            sb.Append(",");
            sb.AppendFormat(CultureInfo.InvariantCulture, "\n\"popular\":{0}", GetPopularGameJson(maxNumOfPopularGame, includeDescription));
            sb.Append(",");


            {
                List<GameCategory> categoies = GetCategories();
                foreach (GameCategory category in categoies)
                {
                    sb.AppendFormat(CultureInfo.InvariantCulture, "\n\"{0}\":{1}"
                        , category.FriendlyID.SafeJavascriptStringEncode()
                        , GetCategoryJson(category, 0, includeDescription)
                        );

                    sb.Append(",");

                }// foreach


            }



            // favorite games
            {
                long clientIdentity = 0L;
                if (HttpContext.Current != null &&
                    HttpContext.Current.Request != null &&
                    HttpContext.Current.Request.Cookies[Settings.CLIENT_IDENTITY_COOKIE] != null)
                {
                    long.TryParse(HttpContext.Current.Request.Cookies[Settings.CLIENT_IDENTITY_COOKIE].Value
                        , NumberStyles.Any
                        , CultureInfo.InvariantCulture
                        , out clientIdentity
                        );
                }


                sb.Append("\n\"favorites\":[");
                CasinoFavoriteGameAccessor cfga = CasinoFavoriteGameAccessor.CreateInstance<CasinoFavoriteGameAccessor>();
                string[] gameIDs = cfga.GetByUser(SiteManager.Current.DomainID, CustomProfile.Current.UserID, clientIdentity).ToArray();
                foreach (string gameID in gameIDs)
                {
                    sb.AppendFormat(CultureInfo.InvariantCulture, "\"{0}\",", gameID);
                }
                if (sb[sb.Length - 1] == ',')
                    sb.Remove(sb.Length - 1, 1);

                sb.Append("]");
            }

            sb.Append("\n}");
            return sb.ToString();
        }

        /// <summary>
        /// Get games for each category
        /// </summary>
        /// <returns></returns>
        public static List<GameCategory> GetCategories()
        {
            string userIPCountryCode = GetIPCountryCode();
            string userCountryCode = GetUserCountryCode();
            Platform platform = GetUserPlatform();

            string cacheKey = GetCacheKey("GameMgr.GetCategories", userIPCountryCode, userCountryCode, platform);
            List<GameCategory> destCategories = HttpRuntime.Cache[cacheKey] as List<GameCategory>;
            if (destCategories != null)
                return destCategories;


            destCategories = new List<GameCategory>();
            List<GameCategory> srcCategories = InternalGetCategories();

            Func<GameRef, bool> isAvailableGame = (GameRef g) =>
             {
                 Game game = g.Game;
                 if (game == null)
                     return false;
                 if (!game.Platforms.Contains(platform))
                     return false;
                 if (game.RestrictedTerritories == null ||
                     game.RestrictedTerritories.Length == 0)
                 {
                     return true;
                 }

                 if (!string.IsNullOrWhiteSpace(userCountryCode))
                 {
                     if (game.RestrictedTerritories.FirstOrDefault(t =>
                         string.Equals(userCountryCode, t, StringComparison.InvariantCultureIgnoreCase)) != null)
                     {
                         return false;
                     }
                 }
                 if (!string.IsNullOrWhiteSpace(userIPCountryCode))
                 {
                     if (game.RestrictedTerritories.FirstOrDefault(t =>
                         string.Equals(userIPCountryCode, t, StringComparison.InvariantCultureIgnoreCase)) != null)
                     {
                         return false;
                     }
                 }
                 return true;
             };

            foreach (GameCategory srcCategory in srcCategories)
            {
                GameCategory category = srcCategory.Clone() as GameCategory;
                destCategories.Add(category);

                foreach (GameRef gameRef in srcCategory.Games)
                {
                    if (!gameRef.IsGameGroup)
                    {
                        if (isAvailableGame(gameRef))
                        {
                            category.Games.Add(gameRef.Clone() as GameRef);
                        }
                    }
                    else
                    {
                        GameRef parentRef = gameRef.Clone() as GameRef;
                        foreach (GameRef childRef in gameRef.Children)
                        {
                            if (isAvailableGame(childRef))
                                parentRef.Children.Add(childRef.Clone() as GameRef);
                        }
                        if (parentRef.Children.Count > 0)
                        {
                            if (parentRef.Children.Count == 1)
                            {
                                category.Games.Add(parentRef.Children[0]);
                            }
                            else
                            {
                                category.Games.Add(parentRef);
                            }
                        }
                    }
                }
            }

            HttpRuntime.Cache.Insert(cacheKey
               , destCategories
               , GetCacheDependency()
               , DateTime.Now.AddMinutes(15)
               , Cache.NoSlidingExpiration
               );

            return destCategories;
        }// GetCategories


        private static List<GameCategory> InternalGetCategories()
        {
            cmSite site = SiteManager.Current;
            string cacheKey = string.Format("_casinolobby_all_game_category_{0}_{1}"
                , CustomProfile.Current.SessionID
                , site.ID
                );

            List<GameCategory> categories = HttpRuntime.Cache[cacheKey] as List<GameCategory>;
            if (categories != null)
                return categories;

            categories = new List<GameCategory>();
            List<string> dependedFiles = new List<string>();
            string physicalPath = HostingEnvironment.MapPath(string.Format(GAME_CATEGORY_XML_PATH, site.DistinctName));
            dependedFiles.Add(physicalPath);

            if (!global::System.IO.File.Exists(physicalPath))
            {
                if (!string.IsNullOrWhiteSpace(site.TemplateDomainDistinctName))
                {
                    physicalPath = HostingEnvironment.MapPath(
                        string.Format(GAME_CATEGORY_XML_PATH, site.TemplateDomainDistinctName)
                        );
                    dependedFiles.Add(physicalPath);
                    if (!global::System.IO.File.Exists(physicalPath))
                        throw new Exception("Error, cannot find the file : " + physicalPath);
                }

            }

            Dictionary<string, Game> games = CasinoEngineClient.GetGames();
            XDocument xDoc = XDocument.Load(physicalPath);
            IEnumerable<XElement> categoryNodes = xDoc.Root.Elements("node");
            XAttribute attr = null;
            Game game = null;
            foreach (XElement categoryNode in categoryNodes)
            {
                GameCategory category = new GameCategory();

                attr = categoryNode.Attribute("type");
                if (attr == null || attr.Value != "category")
                    continue;

                attr = categoryNode.Attribute("id");
                if (attr == null || string.IsNullOrWhiteSpace(attr.Value))
                    continue;

                category.ID = attr.Value;

                IEnumerable<XElement> gameNodes = categoryNode.Elements("node");
                foreach (XElement gameNode in gameNodes)
                {
                    GameRef gameRef = new GameRef();

                    attr = gameNode.Attribute("type");
                    gameRef.IsGameGroup = attr != null && attr.Value == "group";

                    attr = gameNode.Attribute("id");
                    if (attr == null || string.IsNullOrWhiteSpace(attr.Value))
                        continue;
                    gameRef.ID = attr.Value;

                    // individual game
                    if (!gameRef.IsGameGroup)
                    {
                        if (!games.TryGetValue(gameRef.ID, out game))
                            continue;

                        category.Games.Add(gameRef);
                    }
                    else // if this is a game group, then loop the children
                    {
                        IEnumerable<XElement> subgameNodes = gameNode.Elements("node");
                        foreach (XElement subgameNode in subgameNodes)
                        {
                            GameRef subgameRef = new GameRef();
                            subgameRef.IsGameGroup = false;
                            attr = subgameNode.Attribute("id");
                            if (attr == null || string.IsNullOrWhiteSpace(attr.Value))
                                continue;
                            subgameRef.ID = attr.Value;

                            if (!games.TryGetValue(subgameRef.ID, out game))
                                continue;
                            gameRef.Children.Add(subgameRef);
                        }
                        if (gameRef.Children.Count > 0)
                            category.Games.Add(gameRef);
                    }

                }

                categories.Add(category);
            }

            HttpRuntime.Cache.Insert(cacheKey
                , categories
                , new CacheDependencyEx(dependedFiles.ToArray(), false)
                , DateTime.Now.AddMinutes(15)
                , Cache.NoSlidingExpiration
                );

            return categories;
        }// GetCategories

        private static Func<string, string> GetGameCacheKey =
            k => string.Format("_{0}_{1}_{2}_{3}_{4}"
                    , k
                    , SiteManager.Current.DistinctName
                    , GetIPCountryCode()
                    , GetUserCountryCode()
                    , GetUserPlatform()
                );

        /// <summary>
        /// Get all games
        /// </summary>
        /// <returns></returns>
        public static List<GameRef> GetAllGames()
        {
            string userIPCountryCode = GetIPCountryCode();
            string userCountryCode = GetUserCountryCode();
            Platform platform = GetUserPlatform();

            string cacheKey = GetCacheKey("GameMgr.GetAllGames", userIPCountryCode, userCountryCode, platform);
            List<GameRef> games = HttpRuntime.Cache[cacheKey] as List<GameRef>;
            if (games != null)
                return games;

            games = new List<GameRef>();

            Dictionary<string, object> addedGames = new Dictionary<string, object>();

            List<GameCategory> categories = GetCategories();
            foreach (GameCategory category in categories)
            {
                foreach (GameRef gameRef in category.Games)
                {
                    // filter dunplciate games on top level
                    if (!gameRef.IsGameGroup)
                    {
                        if (addedGames.ContainsKey(gameRef.ID))
                            continue;
                        addedGames.Add(gameRef.ID, null);
                    }

                    games.Add(gameRef);
                }
            }

            HttpRuntime.Cache.Insert(cacheKey
                , games
                , GetCacheDependency()
                , DateTime.Now.AddMinutes(15)
                , Cache.NoSlidingExpiration
                );

            return games;
        }



        public static List<Game> GetAllGamesWithoutGroup()
        {
            string userIPCountryCode = GetIPCountryCode();
            string userCountryCode = GetUserCountryCode();
            Platform platform = GetUserPlatform();

            string cacheKey = GetCacheKey("GameMgr.GetAllGamesWithoutGroup", userIPCountryCode, userCountryCode, platform);
            List<Game> games = HttpRuntime.Cache[cacheKey] as List<Game>;
            if (games != null)
                return games;

            games = new List<Game>();

            Dictionary<string, object> addedGames = new Dictionary<string, object>();

            List<GameCategory> categories = GetCategories();
            foreach (GameCategory category in categories)
            {
                foreach (GameRef gameRef in category.Games)
                {
                    if (!gameRef.IsGameGroup)
                    {
                        games.Add(gameRef.Game);
                    }
                    else
                    {
                        foreach (GameRef childRef in gameRef.Children)
                        {
                            games.Add(childRef.Game);
                        }
                    }
                }
            }

            HttpRuntime.Cache.Insert(cacheKey
                , games
                , GetCacheDependency()
                , DateTime.Now.AddMinutes(15)
                , Cache.NoSlidingExpiration
                );

            return games;
        }

        public static List<GameRef> GetAllMiniGame()
        {
            cmSite site = SiteManager.Current;
            string userIPCountryCode = GetIPCountryCode();
            string userCountryCode = GetUserCountryCode();
            Platform platform = GetUserPlatform();

            string cacheKey = GetCacheKey("GameMgr.GetAllMiniGame", userIPCountryCode, userCountryCode, platform);
            List<GameRef> games = HttpRuntime.Cache[cacheKey] as List<GameRef>;
            if (games != null)
                return games;

            string backupPath = HostingEnvironment.MapPath(string.Format("~/App_Data/{0}/CasinoEngine.MiniGames_{1}_{2}"
                , site.DistinctName
                , userIPCountryCode
                , userCountryCode
                ));
            games = ObjectHelper.BinaryDeserialize<List<GameRef>>(backupPath, new List<GameRef>());
            HttpRuntime.Cache.Insert(cacheKey
                , games
                , null
                , DateTime.Now.AddMinutes(1)
                , Cache.NoSlidingExpiration
                );

            if (Monitor.TryEnter(typeof(GameMgr)))
            {
                try
                {
                    games = new List<GameRef>();

                    Dictionary<string, Game> dic = CasinoEngineClient.GetGames(site, true);
                    if (dic != null)
                    {
                        #region
                        Func<GameRef, bool> isAvailableGame = (GameRef g) =>
                        {
                            Game game = g.Game;
                            if (game == null)
                                return false;
                            if (!game.Platforms.Contains(platform))
                                return false;
                            if (game.RestrictedTerritories == null ||
                                game.RestrictedTerritories.Length == 0)
                            {
                                return true;
                            }

                            if (!string.IsNullOrWhiteSpace(userCountryCode))
                            {
                                if (game.RestrictedTerritories.FirstOrDefault(t =>
                                    string.Equals(userCountryCode, t, StringComparison.InvariantCultureIgnoreCase)) != null)
                                {
                                    return false;
                                }
                            }
                            if (!string.IsNullOrWhiteSpace(userIPCountryCode))
                            {
                                if (game.RestrictedTerritories.FirstOrDefault(t =>
                                    string.Equals(userIPCountryCode, t, StringComparison.InvariantCultureIgnoreCase)) != null)
                                {
                                    return false;
                                }
                            }
                            return true;
                        };
                        #endregion

                        GameRef gameRef = new GameRef();
                        foreach (string key in dic.Keys)
                        {
                            if (dic[key].Categories != null && dic[key].Categories.Length > 0)
                            {
                                foreach (string category in dic[key].Categories)
                                {
                                    if (category.Equals("MINIGAMES", StringComparison.OrdinalIgnoreCase))
                                    {
                                        gameRef = new GameRef() { ID = key };
                                        if (isAvailableGame(gameRef))
                                        {
                                            games.Add(gameRef);
                                        }
                                        break;
                                    }
                                }
                            }
                        }
                    }

                    HttpRuntime.Cache.Insert(cacheKey
                                    , games
                                    , GetCacheDependency()
                                    , DateTime.Now.AddMinutes(60)
                                    , Cache.NoSlidingExpiration
                                    );
                    ObjectHelper.BinarySerialize<List<GameRef>>(games, backupPath);
                }
                catch
                {
                    games = new List<GameRef>();
                    HttpRuntime.Cache.Insert(cacheKey
                                    , games
                                    , GetCacheDependency()
                                    , DateTime.Now.AddMinutes(2)
                                    , Cache.NoSlidingExpiration
                                    );
                }
                finally
                {
                    Monitor.Exit(typeof(GameMgr));
                }
            }

            return games;
        }

        public static List<JackpotInfo> GetOriginalJackpotsData()
        {
            List<JackpotInfo> allJackpots = null;
            string cacheKey = string.Format(CultureInfo.InvariantCulture
                , "GameMgr.GetOriginalJackpots.{0}.{1}"
                , SiteManager.Current.ID
                , GetCountryKey(CustomProfile.Current.UserCountryID.ToString(), CustomProfile.Current.IpCountryID.ToString())
                );
            allJackpots = HttpRuntime.Cache[cacheKey] as List<JackpotInfo>;

            var needToUpdate = HttpRuntime.Cache["NeedToUpdateJackpots"];

            if (allJackpots == null || needToUpdate != null)
            {
                allJackpots = CasinoEngineClient.GetJackpots();

                if (allJackpots.Count > 0)
                {
                    HttpRuntime.Cache.Insert(cacheKey, allJackpots);
                    HttpRuntime.Cache.Remove("NeedToUpdateJackpots");
                }
            }
            return ObjectHelper.DeepClone<List<JackpotInfo>>(allJackpots);
        }

        public static List<JackpotGame> GetJackpotGames()
        {
            var allJackpots = GetOriginalJackpotsData().OrderByDescending(j => Guid.NewGuid());
            List<JackpotGame> jackpotGames = jackpotGames = new List<JackpotGame>();
            List<CountryInfo> countries = CountryManager.GetAllCountries();
            CountryInfo country;

            foreach (JackpotInfo jackpot in allJackpots)
            {
                for (int i = 0; jackpot.Games != null && i < jackpot.Games.Count; i++)
                {
                    if (jackpot.Games[i].RestrictedTerritories != null && jackpot.Games[i].RestrictedTerritories.Length > 0)
                    {
                        if (CustomProfile.Current.IsAuthenticated)
                        {
                            country = countries.FirstOrDefault(c => c.InternalID == CustomProfile.Current.UserCountryID);
                            if (country != null && jackpot.Games[i].RestrictedTerritories.Contains(country.ISO_3166_Alpha2Code))
                            {
                                continue;
                            }
                        }
                        if (CustomProfile.Current.IpCountryID > 0)
                        {
                            country = countries.FirstOrDefault(c => c.InternalID == CustomProfile.Current.IpCountryID);
                            if (country != null && jackpot.Games[i].RestrictedTerritories.Contains(country.ISO_3166_Alpha2Code))
                            {
                                continue;
                            }
                        }
                    }

                    JackpotGame jackpotGame = new JackpotGame()
                    {
                        JackpotInfo = jackpot,
                        Game = jackpot.Games[i],
                    };
                    jackpotGames.Add(jackpotGame);


                }
            }
            return jackpotGames;
        }

        /// ///////////////////////////////////////
        /// Live Casino
        /// ///////////////////////////////////////

        public static List<Game> GetLiveDealers()
        {
            return CasinoEngineClient.GetLiveCasinoTables().Values.ToList<Game>();
        }

        public static List<LiveCasinoCategory> GetLiveCasinoCategories(cmSite site)
        {
            string userIPCountryCode = GetIPCountryCode();
            string userCountryCode = GetUserCountryCode();
            Platform platform = GetUserPlatform();

            List<KeyValuePair<string, List<LiveCasinoTable>>> categories = GetLiveCasinoTables(SiteManager.Current);
            string cacheKey = GetCacheKey("GameMgr.GetLiveCasinoCategories", userIPCountryCode, userCountryCode, platform);
            List<LiveCasinoCategory> cache = HttpRuntime.Cache[cacheKey] as List<LiveCasinoCategory>;
            if (cache != null)
                return cache;
            List<LiveCasinoCategory> ctList = new List<LiveCasinoCategory>();
            foreach (KeyValuePair<string, List<LiveCasinoTable>> category in categories)
            {
                LiveCasinoCategory ct = new LiveCasinoCategory();
                ct.CategoryKey = category.Key;
                ct.CategoryName = CM.Content.Metadata.Get(string.Format(CultureInfo.InvariantCulture, "/Metadata/LiveCasino/GameCategory/{0}.Text", category.Key)).DefaultIfNullOrEmpty(category.Key);
                ct.CategoryTitle = CM.Content.Metadata.Get(string.Format(CultureInfo.InvariantCulture, "/Metadata/LiveCasino/GameCategory/{0}.Title", category.Key)).DefaultIfNullOrEmpty(ct.CategoryName);
                ct.Tables = category.Value;
                ctList.Add(ct);
            }

            List<string> dependedFiles = new List<string>();
            string physicalPath = HostingEnvironment.MapPath(string.Format(CultureInfo.InvariantCulture, TABLE_CATEGORY_XML_PATH, site.DistinctName));
            dependedFiles.Add(physicalPath);

            if (!global::System.IO.File.Exists(physicalPath))
            {
                if (!string.IsNullOrWhiteSpace(site.TemplateDomainDistinctName))
                {
                    physicalPath = HostingEnvironment.MapPath(
                        string.Format(CultureInfo.InvariantCulture, TABLE_CATEGORY_XML_PATH, site.TemplateDomainDistinctName)
                        );
                    dependedFiles.Add(physicalPath);
                }
            }
            HttpRuntime.Cache.Insert(cacheKey
            , ctList
            , new CacheDependencyEx(dependedFiles.ToArray(), false)
            , DateTime.Now.AddMinutes(2)
            , Cache.NoSlidingExpiration
            );
            return ctList;
        }

        public static List<KeyValuePair<string, List<LiveCasinoTable>>> GetLiveCasinoTables(cmSite site)
        {
            string userIPCountryCode = GetIPCountryCode();
            string userCountryCode = GetUserCountryCode();
            Platform platform = GetUserPlatform();

            string cacheKey = GetCacheKey("GameMgr.GetLiveCasinoTables", userIPCountryCode, userCountryCode, platform);

            List<KeyValuePair<string, List<LiveCasinoTable>>> cache = HttpRuntime.Cache[cacheKey]
                as List<KeyValuePair<string, List<LiveCasinoTable>>>;

            var needToUpdateCacheKey = string.Format("{0}_NeedToUpdateTables", site.DistinctName);

            var needToUpdateCacheValue = HttpRuntime.Cache[needToUpdateCacheKey];

            if (cache != null && needToUpdateCacheValue == null)
                return cache;

            cache = new List<KeyValuePair<string, List<LiveCasinoTable>>>();

            Dictionary<string, LiveCasinoTable> allTables = CasinoEngineClient.GetLiveCasinoTables()
                .Where(t => IsAvailableGame(t.Value, userIPCountryCode, userCountryCode, platform))
                .ToDictionary(t => t.Key, t => t.Value);

            HttpRuntime.Cache.Remove(needToUpdateCacheKey);

            if (allTables.Count == 0)
                return cache;

            List<string> dependedFiles = new List<string>();
            string physicalPath = HostingEnvironment.MapPath(string.Format(CultureInfo.InvariantCulture, TABLE_CATEGORY_XML_PATH, site.DistinctName));
            dependedFiles.Add(physicalPath);

            if (!global::System.IO.File.Exists(physicalPath))
            {
                if (!string.IsNullOrWhiteSpace(site.TemplateDomainDistinctName))
                {
                    physicalPath = HostingEnvironment.MapPath(
                        string.Format(CultureInfo.InvariantCulture, TABLE_CATEGORY_XML_PATH, site.TemplateDomainDistinctName)
                        );
                    dependedFiles.Add(physicalPath);
                }
            }
            else
            {
                XDocument doc = XDocument.Load(physicalPath);
                IEnumerable<XElement> nodes = doc.Root.Elements("node");
                foreach (XElement node in nodes)
                {
                    if (node.Attribute("type").Value != "category")
                        continue;
                    string cat = node.Attribute("id").Value;

                    List<LiveCasinoTable> list = new List<LiveCasinoTable>();

                    IEnumerable<XElement> children = node.Elements("node");
                    foreach (XElement child in children)
                    {
                        string tableID = child.Attribute("id").Value;
                        LiveCasinoTable table;
                        if (allTables.TryGetValue(tableID, out table))
                        {
                            list.Add(table);
                        }
                    }

                    if (list.Count > 0)
                    {
                        cache.Add(new KeyValuePair<string, List<LiveCasinoTable>>(cat, list));
                    }
                }
            }

            /*
            if( cache.Count == 0 )
            {
                Dictionary<string, List<LiveCasinoTable>> map = new Dictionary<string, List<LiveCasinoTable>>();
                foreach( var table in allTables )
                {
                    if (string.IsNullOrEmpty(table.Value.LiveCasinoCategory))
                        continue;
                    List<LiveCasinoTable> list;
                    if (!map.TryGetValue(table.Value.LiveCasinoCategory, out list))
                    {
                        list = new List<LiveCasinoTable>();
                        map[table.Value.LiveCasinoCategory] = list;
                    }
                    list.Add(table.Value);
                }
                cache = map.Select(p => new KeyValuePair<string, List<LiveCasinoTable>>(p.Key, p.Value)).ToList();
            }
             */

            if (cache.Count >= 0)
            {
                HttpRuntime.Cache.Insert(cacheKey
                    , cache
                    , new CacheDependencyEx(dependedFiles.ToArray(), false)
                    , DateTime.Now.AddMinutes(2)
                    , Cache.NoSlidingExpiration
                    );
            }

            return cache;
        }

    }
}