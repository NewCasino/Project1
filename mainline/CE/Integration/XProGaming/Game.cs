using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Web;
using System.Xml.Linq;

namespace XProGaming
{
    [Serializable]
    public enum GameType : int
    {
        AllGames = 0,
        Roulette = 1,
        Blackjack = 2,
        Baccarat = 4,
        SinglePlayerPoker = 8,
    }

    [Serializable]
    public sealed class Game
    {
        private const string CACHE_FILE_FORMAT = "XProGaming.Games.{0}.dat";

        public string GameID { get; set; }
        public GameType GameType { get; set; }
        public string GameName { get; set; }
        public string ConnectionUrl { get; set; }
        public string WindowParams { get; set; }
        public string OpenHour { get; set; }
        public string CloseHour { get; set; }
        public string DealerName { get; set; }
        public string DealerImageUrl { get; set; }
        public bool IsOpen { get; set; }

        public List<LimitSet> LimitSets { get; private set; }

        public Game()
        {
            this.LimitSets = new List<LimitSet>();
        }

        public static XProGaming.Game Get(long domainID, string gameID)
        {
            XProGaming.Game game = null;
            Dictionary<string, XProGaming.Game> games = GetAll(domainID);
            if (games.TryGetValue(gameID, out game))
                return game;
            return null;
        }

        public static Dictionary<string, XProGaming.Game> GetAll(long domainID)
        {
            string cacheFile = Path.Combine(FileSystemUtility.GetWebSiteTempDirectory()
                , string.Format(CultureInfo.InvariantCulture, CACHE_FILE_FORMAT, domainID)
                );
            Dictionary<string, XProGaming.Game> dic = HttpRuntime.Cache[cacheFile] as Dictionary<string, XProGaming.Game>;
            if (dic != null)
                return dic;

            dic = ObjectHelper.BinaryDeserialize<Dictionary<string, XProGaming.Game>>(cacheFile, new Dictionary<string, XProGaming.Game>());

            return dic;
        }

        public static void ClearCache(long domainID)
        {
            string cacheFile = Path.Combine(FileSystemUtility.GetWebSiteTempDirectory()
                , string.Format(CultureInfo.InvariantCulture, CACHE_FILE_FORMAT, domainID)
                );

            CacheManager.ClearCache(cacheFile);
        }

        public static Dictionary<string, XProGaming.Game> ParseXml(long domainID, string inputXml)
        {
            Dictionary<string, XProGaming.Game> dic = new Dictionary<string, XProGaming.Game>(StringComparer.InvariantCultureIgnoreCase);

            XElement root = XElement.Parse(inputXml);
            XNamespace ns = root.GetDefaultNamespace();
            if (root.Element(ns + "errorCode").Value != "0")
                throw new Exception(root.Element(ns + "description").Value);

            IEnumerable<XElement> games = root.Element(ns + "gamesList").Elements(ns + "game");
            foreach (XElement game in games)
            {
                XProGaming.Game gameToAdd = new XProGaming.Game()
                {
                    GameID = game.Element(ns + "gameID").Value,
                    GameType = (XProGaming.GameType)int.Parse(game.Element(ns + "gameType").Value, CultureInfo.InvariantCulture),
                    GameName = game.Element(ns + "gameName").Value,
                    ConnectionUrl = game.Element(ns + "connectionUrl").Value,
                    WindowParams = game.Element(ns + "winParams").Value,
                    OpenHour = game.Element(ns + "openHour").Value,
                    CloseHour = game.Element(ns + "closeHour").Value,
                    DealerName = game.Element(ns + "dealerName").Value,
                    DealerImageUrl = game.Element(ns + "dealerImageUrl").Value,
                    IsOpen = string.Equals(game.Element(ns + "isOpen").Value, "1", StringComparison.InvariantCultureIgnoreCase),
                };

                IEnumerable<XElement> limitSets = game.Element(ns + "limitSetList").Elements(ns + "limitSet");
                foreach (XElement limitSet in limitSets)
                {
                    XProGaming.LimitSet limitSetToAdd = new XProGaming.LimitSet();

                    decimal temp;
                    limitSetToAdd.ID = limitSet.Element(ns + "limitSetID").Value;
                    if (limitSet.Element(ns + "minBet") != null && decimal.TryParse(limitSet.Element(ns + "minBet").Value, NumberStyles.Number | NumberStyles.AllowDecimalPoint, CultureInfo.InvariantCulture, out temp))
                        limitSetToAdd.MinBet = temp;
                    if (limitSet.Element(ns + "maxBet") != null && decimal.TryParse(limitSet.Element(ns + "maxBet").Value, NumberStyles.Number | NumberStyles.AllowDecimalPoint, CultureInfo.InvariantCulture, out temp))
                        limitSetToAdd.MaxBet = temp;
                    if (limitSet.Element(ns + "minInsideBet") != null && decimal.TryParse(limitSet.Element(ns + "minInsideBet").Value, NumberStyles.Number | NumberStyles.AllowDecimalPoint, CultureInfo.InvariantCulture, out temp))
                        limitSetToAdd.MinInsideBet = temp;
                    if (limitSet.Element(ns + "maxInsideBet") != null && decimal.TryParse(limitSet.Element(ns + "maxInsideBet").Value, NumberStyles.Number | NumberStyles.AllowDecimalPoint, CultureInfo.InvariantCulture, out temp))
                        limitSetToAdd.MaxInsideBet = temp;
                    if (limitSet.Element(ns + "minOutsideBet") != null && decimal.TryParse(limitSet.Element(ns + "minOutsideBet").Value, NumberStyles.Number | NumberStyles.AllowDecimalPoint, CultureInfo.InvariantCulture, out temp))
                        limitSetToAdd.MinOutsideBet = temp;
                    if (limitSet.Element(ns + "maxOutsideBet") != null && decimal.TryParse(limitSet.Element(ns + "maxOutsideBet").Value, NumberStyles.Number | NumberStyles.AllowDecimalPoint, CultureInfo.InvariantCulture, out temp))
                        limitSetToAdd.MaxOutsideBet = temp;
                    if (limitSet.Element(ns + "minPlayerBet") != null && decimal.TryParse(limitSet.Element(ns + "minPlayerBet").Value, NumberStyles.Number | NumberStyles.AllowDecimalPoint, CultureInfo.InvariantCulture, out temp))
                        limitSetToAdd.MinPlayerBet = temp;
                    if (limitSet.Element(ns + "maxPlayerBet") != null && decimal.TryParse(limitSet.Element(ns + "maxPlayerBet").Value, NumberStyles.Number | NumberStyles.AllowDecimalPoint, CultureInfo.InvariantCulture, out temp))
                        limitSetToAdd.MaxPlayerBet = temp;

                    gameToAdd.LimitSets.Add(limitSetToAdd);
                }


                dic[gameToAdd.GameID] = gameToAdd;
            }

            string cacheFile = Path.Combine(FileSystemUtility.GetWebSiteTempDirectory()
                , string.Format(CultureInfo.InvariantCulture, CACHE_FILE_FORMAT, domainID)
                );
            ObjectHelper.BinarySerialize<Dictionary<string, XProGaming.Game>>(dic, cacheFile);
            HttpRuntime.Cache[cacheFile] = dic;
            return dic;
        }
    }

    [Serializable]
    public sealed class LimitSet
    {
        public string ID { get; set; }
        public decimal? MinBet { get; set; }
        public decimal? MaxBet { get; set; }
        public decimal? MinPlayerBet { get; set; }
        public decimal? MaxPlayerBet { get; set; }
        public decimal? MinInsideBet { get; set; }
        public decimal? MaxInsideBet { get; set; }
        public decimal? MinOutsideBet { get; set; }
        public decimal? MaxOutsideBet { get; set; }

    }
}
