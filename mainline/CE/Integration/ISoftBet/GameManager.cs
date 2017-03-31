using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net;
using System.Xml.Linq;
using CE.db;

namespace ISoftBetIntegration
{
    public class GameManager
    {
        private const string CACHE_FILE_FORMAT = "ISoftBet.CasinoGames.{0}.{1}.dat";
        private const string DEFAULT_LANGUAGE = "en";

        private static string[] _SupportedLanguages = new string[] { "en", "fr", "de", "el", "it", "ja", "ro", "ru", "es", "gr" };
        //coming soon
        //da, no, tr
        //Danish, Norwegian, Turkish
        public static string[] SupportedLanguages
        {
            get
            {
                return _SupportedLanguages;
            }
        }

        private static string TargetServer { get; set; }

        public static ISoftBetIntegration.GameModel Get(ceDomainConfigEx domain, string gameID, bool isHtmlGame, string lang, params string[] countryCodes)
        {
            return GetFromXmlFeeds(domain, gameID, isHtmlGame, lang, countryCodes);
        }

        private static ISoftBetIntegration.GameModel GetFromXmlFeeds(ceDomainConfigEx domain, string gameID, bool isHtmlGame, string lang, params string[] countryCodes)
        {
            if (!SupportedLanguages.Contains(lang.ToLowerInvariant()))
                lang = DEFAULT_LANGUAGE;

            ISoftBetIntegration.GameModel game = null;

            TargetServer = domain.GetCountrySpecificCfg(CE.DomainConfig.ISoftBet.TargetServer, countryCodes);

            string url;
            if (isHtmlGame)
            {
                url = string.Format(domain.GetCountrySpecificCfg(CE.DomainConfig.ISoftBet.HTML5GameFeedsURL, countryCodes)
                        ,lang);
            }
            else
            {
                url = string.Format(domain.GetCountrySpecificCfg(CE.DomainConfig.ISoftBet.FlashGameFeedsURL, countryCodes)
                        , lang);
            }

            string xml = GetRawXmlFeeds(url);

            XDocument xDoc = XDocument.Parse(xml);
            IEnumerable<XElement> elements = xDoc.Root.Element("games").Elements("c");
            foreach (XElement element in elements)
            {
                string cid = element.GetAttributeValue("id");

                var cels = from x in element.Elements("g")
                           where string.Equals(x.Attribute("i").Value, gameID)
                           select x;

                if (cels != null && cels.Count() > 0)
                {
                    game = new GameModel();
                    game.CategoryID = cid;
                    game = AnalyzeXML(cels.First(), game, domain, isHtmlGame, lang, countryCodes);
                    break;
                }
            }

            return game;
        }

        private static ISoftBetIntegration.GameModel AnalyzeXML(XElement element, GameModel game, ceDomainConfigEx domain, bool isHtmlGame, string lang, params string[] countryCodes)
        {
            game = new GameModel();

            game.PresentationType = isHtmlGame ? PresentationType.Html : PresentationType.Flash;
            game.ID = element.GetAttributeValue("i");
            game.Identifier = element.GetAttributeValue("i");
            game.GameID = element.GetAttributeValue("id");
            game.Name = element.GetAttributeValue("n");
            game.Image = element.GetAttributeValue("img");
            game.FunModel = string.Equals(element.GetAttributeValue("fa"), "1", StringComparison.InvariantCultureIgnoreCase);
            game.RealModel = string.Equals(element.GetAttributeValue("ra"), "1", StringComparison.InvariantCultureIgnoreCase);
            game.TestFunMode = string.Equals(element.GetAttributeValue("tfa"), "1", StringComparison.InvariantCultureIgnoreCase);
            game.TestRealMode = string.Equals(element.GetAttributeValue("tra"), "1", StringComparison.InvariantCultureIgnoreCase);
            game.MainCategory = element.GetElementValue("main_cat");
            game.UserIDs = element.GetAttributeValue("ta").Split(new char[] { ';' }, StringSplitOptions.RemoveEmptyEntries);

            string strCoins = element.GetAttributeValue("c");
            if (!string.IsNullOrWhiteSpace(strCoins))
            {
                string[] coins = strCoins.Split(new char[] { ';' }, StringSplitOptions.RemoveEmptyEntries);
                if (coins != null && coins.Length > 0)
                {
                    game.Coins = new decimal[coins.Length];
                    for (int i = 0; i < coins.Length; i++)
                    {
                        decimal.TryParse(coins[i], out game.Coins[i]);
                    }
                }
            }

            game.Translated = element.GetAttributeValue("translated") == "1";
            game.Description = element.GetElementValue("d");


            string url = string.Format(domain.GetCfg(CE.DomainConfig.ISoftBet.GameInfoUrl)
                        , TargetServer
                        , game.Identifier);
            string gameXml = GetRawXmlFeeds(url);
            if (!string.IsNullOrWhiteSpace(gameXml))
            {
                XDocument xGameDoc = XDocument.Parse(gameXml);
                XElement gInfoEle = xGameDoc.Element("game");                
                game.SkinID = gInfoEle.GetElementValue("skin_id");
                game.WMode = gInfoEle.GetElementValue("wmode");
                decimal coin;
                if (decimal.TryParse(gInfoEle.GetElementValue("coin_min"), out coin))
                    game.MinCoin = coin;
                if (decimal.TryParse(gInfoEle.GetElementValue("coin_max"), out coin))
                    game.MaxCoin = coin;
            }

            return game;
        }



        private static string GetLanguage(string lang)
        {
            if (string.IsNullOrWhiteSpace(lang))
                return DEFAULT_LANGUAGE;

            lang = lang.ToLowerInvariant();
            if (!SupportedLanguages.Contains(lang))
                return DEFAULT_LANGUAGE;

            return lang;
        }

        private static string GetRawXmlFeeds(string url)
        {
            string xml = null;
            try
            {
                HttpWebRequest request = HttpWebRequest.Create(url) as HttpWebRequest;
                request.Accept = "application/json";
                request.ContentType = "application/xml";
                request.Method = "GET";

                HttpWebResponse response = request.GetResponse() as HttpWebResponse;
                using (Stream s = response.GetResponseStream())
                {
                    using (StreamReader sr = new StreamReader(s))
                    {
                        xml = sr.ReadToEnd();
                    }
                }
            }
            catch (Exception ex)
            { }
            return xml;
        }
    }
}
