using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net;
using System.Xml.Linq;
using CE.db;

namespace ISoftBetIntegration
{
    public class GameMgt
    {
        private const string CACHE_FILE_FORMAT = "ISoftBet.CasinoGames.{0}.{1}.dat";
        private const string DEFAULT_LANGUAGE = "en";

        private static string[] _SupportedLanguages = new string[] { "en", "fr", "de", "el", "it", "ja", "ro", "ru", "es", "gr" };
        //coming soon
        //da, no, tr
        //Danish, Norwegian, Turkish
        public static string[] SupportedLanguages
        {
            get{
                return _SupportedLanguages;    
            }
        }
            
        public static ISoftBetIntegration.Game Get(ceDomainConfigEx domain, string gameID, bool funMode, bool isHtmlGame, string lang, params string[] countryCodes)
        {
            if(!SupportedLanguages.Contains(lang.ToLowerInvariant()))
                lang = DEFAULT_LANGUAGE;

            ISoftBetIntegration.Game game = null;            

            string url = domain.GetCountrySpecificCfg(CE.DomainConfig.ISoftBet.TargetServer, countryCodes);
            if (isHtmlGame)
            {
                url = string.Format(domain.GetCountrySpecificCfg(CE.DomainConfig.ISoftBet.HTML5GameFeedsURL, countryCodes)
                        , url
                        , lang);
            }
            else
            {
                url = string.Format(domain.GetCountrySpecificCfg(CE.DomainConfig.ISoftBet.FlashGameFeedsURL, countryCodes)
                        , url
                        , lang);
            }

            string xml = GetRawXmlFeeds(url);

            XDocument xDoc = XDocument.Parse(xml);
            IEnumerable<XElement> elements = xDoc.Root.Element("games").Elements("c");
            foreach (XElement element in elements)
            {
                string cid = element.GetAttributeValue("id");

                var cels = from x in element.Elements("g")
                            where string.Equals(x.Attribute("i").Value, gameID) select x;

                if (cels != null && cels.Count() > 0)
                {
                    string targetServer = funMode ? domain.GetCountrySpecificCfg(CE.DomainConfig.ISoftBet.TargetServer, countryCodes) :
                                        domain.GetCountrySpecificCfg(CE.DomainConfig.ISoftBet.RealModeTargetServer, countryCodes);

                    game = isHtmlGame ? AnalyzeElementForHtmlGame(cels.First(), domain, cid, funMode, targetServer) :
                        AnalyzeElementForFlashGame(cels.First(), domain, cid, funMode, targetServer);

                    game = InitGameInfo(domain, game, funMode, countryCodes);

                    break;
                }
            }

            return game;
        }

        private static Game AnalyzeElementForFlashGame(XElement element, ceDomainConfigEx domain, string cid, bool funMode, string targetServer, params string[] countryCodes)
        {
            ISoftBetIntegration.Game g = new ISoftBetIntegration.Game();
            g.CategoryID = cid;
            g.PresentationType = PresentationType.Flash;
            //g.ID = gEle.GetAttributeValue("id");
            g.ID = element.GetAttributeValue("i");
            if (g.ID.ToLowerInvariant() == "heavy_metal_pmvc")
                g.ID = g.ID;
            g.Identifier = element.GetAttributeValue("i");
            g.Name = element.GetAttributeValue("n");
            g.Image = element.GetAttributeValue("img");
            g.FunModel = string.Equals(element.GetAttributeValue("fa"), "1", StringComparison.InvariantCultureIgnoreCase);
            g.RealModel = string.Equals(element.GetAttributeValue("ra"), "1", StringComparison.InvariantCultureIgnoreCase);
            g.TestFunMode = string.Equals(element.GetAttributeValue("tfa"), "1", StringComparison.InvariantCultureIgnoreCase);
            g.TestRealMode = string.Equals(element.GetAttributeValue("tra"), "1", StringComparison.InvariantCultureIgnoreCase);
            g.UserIDs = element.GetAttributeValue("ta").Split(new char[] { ';' }, StringSplitOptions.RemoveEmptyEntries);

            string strCoins = element.GetAttributeValue("c");
            if (!string.IsNullOrWhiteSpace(strCoins))
            {
                string[] coins = strCoins.Split(new char[] { ';' }, StringSplitOptions.RemoveEmptyEntries);
                if (coins != null && coins.Length > 0)
                {
                    g.Coins = new decimal[coins.Length];
                    for (int i = 0; i < coins.Length; i++)
                    {
                        decimal.TryParse(coins[i], out g.Coins[i]);
                    }
                }
            }

            g.Translated = element.GetAttributeValue("translated") == "1";
            g.Description = element.GetElementValue("d");

            return g;
        }

        private static Game AnalyzeElementForHtmlGame(XElement element, ceDomainConfigEx domain, string cid, bool funMode, string targetServer, params string[] countryCodes)
        {
            ISoftBetIntegration.Game g = new ISoftBetIntegration.Game();
            g.CategoryID = cid;
            g.PresentationType = PresentationType.Flash;
            //g.ID = gEle.GetAttributeValue("id");
            g.ID = element.GetAttributeValue("i");
            g.Identifier = element.GetAttributeValue("i");
            g.Name = element.GetAttributeValue("n");
            g.Image = element.GetAttributeValue("img");
            g.FunModel = string.Equals(element.GetAttributeValue("fa"), "1", StringComparison.InvariantCultureIgnoreCase);
            g.RealModel = string.Equals(element.GetAttributeValue("ra"), "1", StringComparison.InvariantCultureIgnoreCase);
            g.TestFunMode = string.Equals(element.GetAttributeValue("tfa"), "1", StringComparison.InvariantCultureIgnoreCase);
            g.TestRealMode = string.Equals(element.GetAttributeValue("tra"), "1", StringComparison.InvariantCultureIgnoreCase);
            g.UserIDs = element.GetAttributeValue("ta").Split(new char[] { ';' }, StringSplitOptions.RemoveEmptyEntries);

            string strCoins = element.GetAttributeValue("c");
            if (!string.IsNullOrWhiteSpace(strCoins))
            {
                string[] coins = strCoins.Split(new char[] { ';' }, StringSplitOptions.RemoveEmptyEntries);
                if (coins != null && coins.Length > 0)
                {
                    g.Coins = new decimal[coins.Length];
                    for (int i = 0; i < coins.Length; i++)
                    {
                        decimal.TryParse(coins[i], out g.Coins[i]);
                    }
                }
            }

            g.Translated = element.GetAttributeValue("translated") == "1";
            g.Description = element.GetElementValue("d");

            return g;
        }

        private static Game InitGameInfo(ceDomainConfigEx domain, Game g, bool funMode, params string[] countryCodes)
        {
            bool loaded = false;
            string targetServer;
            string url;
            string gameXml;

            #region fun
            targetServer = domain.GetCountrySpecificCfg(CE.DomainConfig.ISoftBet.TargetServer, countryCodes);
            url = string.Format(domain.GetCfg(CE.DomainConfig.ISoftBet.GameInfoUrl)
                        , targetServer
                        , g.Identifier);
            gameXml = GetRawXmlFeeds(url);

            if (!string.IsNullOrWhiteSpace(gameXml))
            {
                XDocument xGameDoc = XDocument.Parse(gameXml);
                XElement gInfoEle = xGameDoc.Element("game");

                g.SkinID = gInfoEle.GetElementValue("skin_id");
                g.URL = gInfoEle.GetElementValue("url");
                g.SwfRevision = gInfoEle.GetElementValue("swf_revision");
                g.Host = gInfoEle.GetElementValue("host");
                g.UseCustomLoader = gInfoEle.GetElementValue("use_custom_loader") == "1";
                g.CustomLoader = gInfoEle.GetElementValue("custom_loader");
                g.WMode = gInfoEle.GetElementValue("wmode");
                g.Casino = gInfoEle.GetElementValue("casino");
                g.RestrictedCountries = gInfoEle.GetElementValue("restricted_countries").Split(new char[] { ';' }, StringSplitOptions.RemoveEmptyEntries);
                g.CustomBackgrounds = gInfoEle.GetElementValue("custom_backgrounds");
                g.Provider = gInfoEle.GetElementValue("provider");
                g.MainCategory = gInfoEle.GetElementValue("main_cat");

                decimal coin;
                if (decimal.TryParse(gInfoEle.GetElementValue("coin"), out coin))
                    g.DefaultCoin = coin;
                if (decimal.TryParse(gInfoEle.GetElementValue("coin_min"), out coin))
                    g.MinCoin = coin;
                if (decimal.TryParse(gInfoEle.GetElementValue("coin_max"), out coin))
                    g.MaxCoin = coin;

                loaded = true;
            }
            #endregion

            #region real
            targetServer = domain.GetCountrySpecificCfg(CE.DomainConfig.ISoftBet.RealModeTargetServer, countryCodes);
            url = string.Format(domain.GetCfg(CE.DomainConfig.ISoftBet.GameInfoUrl)
                        , targetServer
                        , g.Identifier);
            gameXml = GetRawXmlFeeds(url);

            if (!string.IsNullOrWhiteSpace(gameXml))
            {
                XDocument xGameDoc = XDocument.Parse(gameXml);
                XElement gInfoEle = xGameDoc.Element("game");

                g.SkinID = gInfoEle.GetElementValue("skin_id");
                g.RealModeURL = gInfoEle.GetElementValue("url");
                g.RealModeSwfRevision = gInfoEle.GetElementValue("swf_revision");
                g.RealModeHost = gInfoEle.GetElementValue("host");
                g.RealModeUseCustomLoader = gInfoEle.GetElementValue("use_custom_loader") == "1";
                g.RealModeCustomLoader = gInfoEle.GetElementValue("custom_loader");

                if (string.IsNullOrWhiteSpace(g.WMode))
                    g.WMode = gInfoEle.GetElementValue("wmode");
                if (string.IsNullOrWhiteSpace(g.Casino))
                    g.Casino = gInfoEle.GetElementValue("casino");
                if (g.RestrictedCountries == null || g.RestrictedCountries.Length == 0)
                    g.RestrictedCountries = gInfoEle.GetElementValue("restricted_countries").Split(new char[] { ';' }, StringSplitOptions.RemoveEmptyEntries);
                if (string.IsNullOrWhiteSpace(g.CustomBackgrounds))
                    g.CustomBackgrounds = gInfoEle.GetElementValue("custom_backgrounds");
                if (string.IsNullOrWhiteSpace(g.Provider))
                    g.Provider = gInfoEle.GetElementValue("provider");
                if (string.IsNullOrWhiteSpace(g.MainCategory))
                    g.MainCategory = gInfoEle.GetElementValue("main_cat");

                loaded = true;
            }
            #endregion

            if (!loaded)
                return null;

            return g;
        }

        public static string GetFeedsIdentifier(ceDomainConfigEx domain)
        {
            if (domain != null)
                return CRC64.ComputeAsUtf8String(domain.GetCfg(CE.DomainConfig.ISoftBet.FlashGameFeedsURL) + domain.GetCfg(CE.DomainConfig.ISoftBet.HTML5GameFeedsURL)).ToString();

            return null;
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
