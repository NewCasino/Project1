using System;
using System.Collections.Generic;
using System.Configuration;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Net;
using System.Text;
using System.Web;
using System.Web.Script.Serialization;
using System.Xml.Linq;
using CE.db;
using CE.db.Accessor;
using CE.DomainConfig;
using CE.Utils;
using GamMatrixAPI;

namespace Jackpot
{
    public static class JackpotFeeds
    {
        public const string MG_URL = @"http://www.tickerassist.co.uk/ProgressiveTickers/WebServiceProgressiveTickerXMLAll.asmx/tickerXMLFeedAll";
        public const string PlaynGO_URL = @"https://cw.playngonetwork.com/Jackpots?pid={0}&currency=EUR";
        public const string IGT_URL = @"https://platform.rgsgames.com/JackpotMeter?JackpotID={0}&CurrencyCd=EUR";
        public const string BetSoft_URL = @"http://lobby.everymatrix.betsoftgaming.com/jackpots/jackpots_{0}.xml";

        #region Microgaming
        /// <summary>
        /// Returns the jackpots
        /// </summary>
        /// <returns></returns>
        public static Dictionary<string, JackpotInfo> GetMicrogamingJackpots(string customUrl = null)
        {
            string filepath = Path.Combine(FileSystemUtility.GetWebSiteTempDirectory(), "MicrogamingJackpotFeeds.cache");
            Dictionary<string, JackpotInfo> cached = HttpRuntime.Cache[filepath] as Dictionary<string, JackpotInfo>;
            if (cached != null && string.IsNullOrEmpty(customUrl))
                return cached;

            Func< Dictionary<string, JackpotInfo> > func = () =>
            {
                try
                {
                    Dictionary<string, JackpotInfo> jackpots = new Dictionary<string, JackpotInfo>(StringComparer.InvariantCultureIgnoreCase);

                    XDocument xDoc = XDocument.Load(customUrl ?? MG_URL);
                    var counters = xDoc.Root.Elements("Counter");
                    foreach (XElement counter in counters)
                    {
                        try
                        {
                            JackpotInfo jackpot = new JackpotInfo()
                            {
                                ID = counter.Element("jackpotID").Value,
                                Name = counter.Element("jackpotName").Value,
                                VendorID = VendorID.Microgaming,
                            };

                            // For Microgaming jackpors, the amount is always the same for all currencies
                            Dictionary<string, CurrencyExchangeRateRec> currencies = GamMatrixClient.GetCurrencyRates(Constant.SystemDomainID);
                            foreach (string key in currencies.Keys)
                            {
                                jackpot.Amounts[key] = decimal.Parse(counter.Element("jackpotCValue").Value, CultureInfo.InvariantCulture) / 100.00M;
                            }
                            jackpots[jackpot.ID] = jackpot;
                        }
                        catch
                        {
                        }
                    }
                    if (jackpots.Count > 0 && string.IsNullOrEmpty(customUrl))
                        ObjectHelper.BinarySerialize<Dictionary<string, JackpotInfo>>(jackpots, filepath);
                    return jackpots;
                }
                catch (Exception ex)
                {
                    Logger.Exception(ex);
                    throw;
                }
            };

            if (!string.IsNullOrEmpty(customUrl))
            {
                cached = func();
            }
            else if (!DelayUpdateCache<Dictionary<string, JackpotInfo>>.TryGetValue(filepath, out cached, func, 120))
            {
                cached = ObjectHelper.BinaryDeserialize<Dictionary<string, JackpotInfo>>(filepath, new Dictionary<string, JackpotInfo>());
            }
            return cached;
        }
        #endregion

        #region NetEnt
        /// <summary>
        /// Get NetEnt Jackpots
        /// </summary>
        /// <returns></returns>
        public static Dictionary<string, JackpotInfo> GetNetEntJackpots(long domainID)
        {
            string filepath = Path.Combine(FileSystemUtility.GetWebSiteTempDirectory()
                , "NetEntJackpotFeeds.cache"
                );
            Dictionary<string, JackpotInfo> cached = HttpRuntime.Cache[filepath] as Dictionary<string, JackpotInfo>;
            if (cached != null)
                return cached;

            Func<Dictionary<string, JackpotInfo>> func = () =>
            {
                try
                {
                    Dictionary<string, JackpotInfo> jackpots = new Dictionary<string, JackpotInfo>(StringComparer.InvariantCultureIgnoreCase);

                    using (GamMatrixClient client = new GamMatrixClient())
                    {
                        NetEntAPIRequest request = new NetEntAPIRequest()
                        {
                            GetIndividualJackpotInfo = true,
                            GetIndividualJackpotInfoCurrency = "EUR",
                        };
                        request = client.SingleRequest<NetEntAPIRequest>(domainID, request);

                        foreach (GamMatrixAPI.Jackpot j in request.GetIndividualJackpotInfoResponse)
                        {
                            if (!j.currentJackpotValueField.amountField.HasValue)
                                continue;

                            JackpotInfo jackpot = new JackpotInfo()
                            {
                                ID = j.jackpotNameField,
                                Name = j.jackpotNameField,
                                VendorID = VendorID.Neteller,
                            };
                            // For NetEnt jackpots, the amount is always converted from the primary currency
                            Dictionary<string, CurrencyExchangeRateRec> currencies = GamMatrixClient.GetCurrencyRates(Constant.SystemDomainID);
                            string currency = j.currentJackpotValueField.amountCurrencyISOCodeField;
                            decimal amout = j.currentJackpotValueField.amountField.Value;

                            foreach (string key in currencies.Keys)
                            {
                                jackpot.Amounts[key] = GamMatrixClient.TransformCurrency(currency, key, amout);
                            }

                            jackpots[jackpot.ID] = jackpot;
                        }
                    }

                    if (jackpots.Count > 0)
                        ObjectHelper.BinarySerialize<Dictionary<string, JackpotInfo>>(jackpots, filepath);
                    return jackpots;
                }
                catch (Exception ex)
                {
                    Logger.Exception(ex);
                    throw;
                }
            };

            if (!DelayUpdateCache<Dictionary<string, JackpotInfo>>.TryGetValue(filepath, out cached, func, 120))
            {
                cached = ObjectHelper.BinaryDeserialize<Dictionary<string, JackpotInfo>>(filepath, new Dictionary<string, JackpotInfo>());
            }

            return cached;
        }
        #endregion


        #region CTXM
        /// <summary>
        /// Get CTXM jackpots
        /// </summary>
        /// <returns></returns>
        public static Dictionary<string, JackpotInfo> GetCTXMJackpots(long domainID)
        {
            string filepath = Path.Combine(FileSystemUtility.GetWebSiteTempDirectory()
                , string.Format( "CTXMJackpotsFeeds.{0}.cache", domainID)
                );
            Dictionary<string, JackpotInfo> cached = HttpRuntime.Cache[filepath] as Dictionary<string, JackpotInfo>;
            if (cached != null)
                return cached;

            Func<Dictionary<string, JackpotInfo>> func = () =>
            {
                try
                {
                    Dictionary<string, JackpotInfo> jackpots = new Dictionary<string, JackpotInfo>(StringComparer.InvariantCultureIgnoreCase);

                    using (GamMatrixClient client = new GamMatrixClient())
                    {
                        //CTXMAPIRequest request = new CTXMAPIRequest()
                        //{
                        //    GetJackpotList = true,
                        //    GetJackpotListCurrency = "EUR",
                        //    GetJackpotListLanguage = "en",
                        //};
                        //request = client.SingleRequest<CTXMAPIRequest>(domainID, request);

                        //foreach (GamMatrixAPI.JackpotType j in request.GetJackpotListResponse.jackpotsField)
                        //{
                        //    JackpotInfo jackpot = new JackpotInfo()
                        //    {
                        //        ID = j.campaignIdField,
                        //        Name = j.campaignNameField,
                        //        VendorID = VendorID.CTXM,
                        //    };

                        //    // For CTXM jackpots, the amount is always converted from the primary currency
                        //    Dictionary<string, CurrencyExchangeRateRec> currencies = GamMatrixClient.GetCurrencyRates(Constant.SystemDomainID);
                        //    string currency = j.currencyField;
                        //    decimal amout = j.jackpotAmountField.Value;

                        //    foreach (string key in currencies.Keys)
                        //    {
                        //        jackpot.Amounts[key] = GamMatrixClient.TransformCurrency(currency, key, amout);
                        //    }
                        //    jackpots[jackpot.ID] = jackpot;
                        //}
                    }

                    if (jackpots.Count > 0)
                        ObjectHelper.BinarySerialize<Dictionary<string, JackpotInfo>>(jackpots, filepath);
                    return jackpots;
                }
                catch (Exception ex)
                {
                    Logger.Exception(ex);
                    throw;
                }
            };

            if (!DelayUpdateCache<Dictionary<string, JackpotInfo>>.TryGetValue(filepath, out cached, func, 120))
            {
                cached = ObjectHelper.BinaryDeserialize<Dictionary<string, JackpotInfo>>(filepath, new Dictionary<string, JackpotInfo>());
            }

            return cached;
        }
        #endregion



        #region Playn'GO
        public static Dictionary<string, JackpotInfo> GetPlaynGOJackpots(long domainID, string customUrl = null)
        {
            string filepath = Path.Combine(FileSystemUtility.GetWebSiteTempDirectory()
                , string.Format("PlaynGOJackpotsFeeds.{0}.cache", domainID)
                );
            Dictionary<string, JackpotInfo> cached = HttpRuntime.Cache[filepath] as Dictionary<string, JackpotInfo>;
            if (cached != null && string.IsNullOrEmpty(customUrl))
                return cached;

            Func<Dictionary<string, JackpotInfo>> func = () =>
            {
                string url = null;
                try
                {
                    Dictionary<string, JackpotInfo> jackpots = new Dictionary<string, JackpotInfo>(StringComparer.InvariantCultureIgnoreCase);

                    DomainConfigAccessor dca = DomainConfigAccessor.CreateInstance<DomainConfigAccessor>();
                    ceDomainConfigEx config = dca.GetByDomainID(domainID);

                    if (config != null)
                    {
                        url = customUrl ?? string.Format(PlaynGO_URL, config.GetCfg(PlaynGO.PID).DefaultIfNullOrEmpty("71"));
                        PlaynGOJackpot[] objects = null;

                        HttpWebRequest request = (HttpWebRequest)HttpWebRequest.Create(url);
                        request.Timeout = 50000;
                        using (HttpWebResponse response = (HttpWebResponse)request.GetResponse())
                        using (Stream stream = response.GetResponseStream())
                        using (StreamReader sr = new StreamReader(stream))
                        {
                            string json = sr.ReadToEnd();
                            JavaScriptSerializer jss = new JavaScriptSerializer();
                            objects = jss.Deserialize<PlaynGOJackpot[]>(json);
                        }


                        if (objects != null)
                        {

                            foreach (PlaynGOJackpot obj in objects)
                            {
                                JackpotInfo jackpot = new JackpotInfo()
                                {
                                    ID = obj.JackpotId.ToString(),
                                    Name = obj.Description,
                                    VendorID = VendorID.PlaynGO,
                                };

                                // Only 1 IGT jackpot
                                Dictionary<string, CurrencyExchangeRateRec> currencies = GamMatrixClient.GetCurrencyRates(Constant.SystemDomainID);
                                string currency = obj.Currency;
                                decimal amout = obj.BaseAmount;

                                foreach (string key in currencies.Keys)
                                {
                                    jackpot.Amounts[key] = GamMatrixClient.TransformCurrency(currency, key, amout);
                                }

                                jackpots[jackpot.ID] = jackpot;
                            }
                        }
                    }

                    if (jackpots.Count > 0 && string.IsNullOrEmpty(customUrl))
                        ObjectHelper.BinarySerialize<Dictionary<string, JackpotInfo>>(jackpots, filepath);
                    return jackpots;
                }
                catch (Exception ex)
                {

                    Logger.Exception(ex, string.Format(@" PlaynGO - Jackpots URL : {0}", url));
                    throw;
                }
            };

            if (!string.IsNullOrEmpty(customUrl))
            {
                cached = func();
            }
            else if (!DelayUpdateCache<Dictionary<string, JackpotInfo>>.TryGetValue(filepath, out cached, func, 120))
            {
                cached = ObjectHelper.BinaryDeserialize<Dictionary<string, JackpotInfo>>(filepath, new Dictionary<string, JackpotInfo>());
            }

            return cached;
        }
        #endregion


        #region IGT
        public static Dictionary<string, JackpotInfo> GetIGTJackpots(long domainID, string customUrl = null)
        {
            string filepath = Path.Combine(FileSystemUtility.GetWebSiteTempDirectory()
                , string.Format("IGTJackpotsFeeds.{0}.cache", domainID)
                );
            Dictionary<string, JackpotInfo> cached = HttpRuntime.Cache[filepath] as Dictionary<string, JackpotInfo>;
            if (cached != null && string.IsNullOrEmpty(customUrl))
                return cached;

            Func<Dictionary<string, JackpotInfo>> func = () =>
            {
                try
                {
                    Dictionary<string, JackpotInfo> jackpots = new Dictionary<string, JackpotInfo>(StringComparer.InvariantCultureIgnoreCase);

                    var domain = DomainManager.GetDomains().FirstOrDefault(d => d.DomainID == domainID);
                    if (domain == null && DomainManager.GetSysDomain().DomainID == domainID)
                        domain = DomainManager.GetSysDomain();

                    if (domain == null)
                        throw new Exception("domain can't be found");

                    string jackpotBaseURL = domain.GetCfg(IGT.JackpotBaseURL);
                    string url;
                    if (string.IsNullOrWhiteSpace(jackpotBaseURL))
                        url = customUrl ?? string.Format(IGT_URL, "0001");
                    else
                        url = customUrl ?? string.Format(jackpotBaseURL, "0001");

                    XDocument xDoc = XDocument.Load(url);
                    JackpotInfo jackpot = new JackpotInfo()
                    {
                        ID = xDoc.Root.Element("jackpotid").Value,
                        Name = xDoc.Root.Element("jackpotid").Value,
                        VendorID = VendorID.IGT,
                    };


                    // Only 1 IGT jackpot
                    Dictionary<string, CurrencyExchangeRateRec> currencies = GamMatrixClient.GetCurrencyRates(Constant.SystemDomainID);
                    string currency = "EUR";
                    decimal amout = decimal.Parse(xDoc.Root.Element("currentvalue").Value, CultureInfo.InvariantCulture);

                    foreach (string key in currencies.Keys)
                    {
                        jackpot.Amounts[key] = GamMatrixClient.TransformCurrency(currency, key, amout);
                    }

                    jackpots[jackpot.ID] = jackpot;

                    if (jackpots.Count > 0 && string.IsNullOrEmpty(customUrl))
                        ObjectHelper.BinarySerialize<Dictionary<string, JackpotInfo>>(jackpots, filepath);
                    return jackpots;
                }
                catch (Exception ex)
                {
                    Logger.Exception(ex);
                    throw;
                }
            };

            if (!string.IsNullOrEmpty(customUrl))
            {
                cached = func();
            }
            else if (!DelayUpdateCache<Dictionary<string, JackpotInfo>>.TryGetValue(filepath, out cached, func, 120))
            {
                cached = ObjectHelper.BinaryDeserialize<Dictionary<string, JackpotInfo>>(filepath, new Dictionary<string, JackpotInfo>());
            }

            return cached;
        }
        #endregion


        #region BetSoft
        public static Dictionary<string, JackpotInfo> GetBetSoftJackpots(ceDomainConfig domain, string customUrl = null)
        {
            string filepath = Path.Combine(FileSystemUtility.GetWebSiteTempDirectory()
                , domain == null ? "BetSoftJackpotsFeeds.cache" : string.Format("BetSoftJackpotsFeeds.{0}.cache", domain.GetCfg(BetSoft.BankID))
                );
            Dictionary<string, JackpotInfo> cached = HttpRuntime.Cache[filepath] as Dictionary<string, JackpotInfo>;
            if (cached != null && string.IsNullOrEmpty(customUrl))
                return cached;

            string url = "http://lobby.everymatrix.betsoftgaming.com/jackpots/jackpots_218.xml";
            if (domain != null && domain.DomainID != Constant.SystemDomainID)
                url = string.Format(CultureInfo.InvariantCulture, BetSoft_URL, domain.GetCfg(BetSoft.BankID));
            else
                url = ConfigurationManager.AppSettings["SystemJackpotListUrl"];

            url = customUrl ?? url;

            Func<Dictionary<string, JackpotInfo>> func = () =>
            {
                try
                {
                    Dictionary<string, JackpotInfo> jackpots = new Dictionary<string, JackpotInfo>(StringComparer.InvariantCultureIgnoreCase);

                    XDocument xDoc = XDocument.Load(url);
                    IEnumerable<XElement> elements = xDoc.Root.Elements("jackpotGame");
                    foreach (XElement elem in elements)
                    {
                        string id = elem.Element("gameId").Value;
                        JackpotInfo jackpot;
                        if (!jackpots.TryGetValue(id, out jackpot))
                        {
                            jackpot = new JackpotInfo()
                            {
                                ID = elem.Element("gameId").Value,
                                Name = elem.Element("gameName").Value,
                                VendorID = VendorID.BetSoft,
                            };
                        }


                        string currency = elem.Element("currencyCode").Value;
                        decimal amout = decimal.Parse(elem.Element("jackpotAmount").Value, CultureInfo.InvariantCulture);

                        jackpot.Amounts[currency] = amout;

                        jackpots[jackpot.ID] = jackpot;
                    }

                    Dictionary<string, CurrencyExchangeRateRec> currencies = GamMatrixClient.GetCurrencyRates(Constant.SystemDomainID);
                    foreach (JackpotInfo jackpotInfo in jackpots.Values)
                    {
                        if (jackpotInfo.Amounts.Count == 0)
                            continue;

                        decimal amount = 0.00M;
                        if (jackpotInfo.Amounts.ContainsKey("EUR"))
                            amount = jackpotInfo.Amounts["EUR"];
                        else
                            amount = jackpotInfo.Amounts.First().Value;

                        foreach (string key in currencies.Keys)
                        {
                            if (!jackpotInfo.Amounts.ContainsKey(key))
                            {
                                jackpotInfo.Amounts[key] = amount;
                            }
                        }
                    }


                    if (jackpots.Count > 0 && string.IsNullOrEmpty(customUrl))
                        ObjectHelper.BinarySerialize<Dictionary<string, JackpotInfo>>(jackpots, filepath);
                    return jackpots;
                }
                catch (Exception ex)
                {
                    Logger.Exception(ex);
                    throw;
                }
            };

            if (!string.IsNullOrEmpty(customUrl))
            {
                cached = func();
            }
            else if (!DelayUpdateCache<Dictionary<string, JackpotInfo>>.TryGetValue(filepath, out cached, func, 120))
            {
                cached = ObjectHelper.BinaryDeserialize<Dictionary<string, JackpotInfo>>(filepath, new Dictionary<string, JackpotInfo>());
            }

            return cached;
        }
        #endregion

        #region Sheriff
        public static Dictionary<string, JackpotInfo> GetSheriffJackpots(ceDomainConfig domain)
        {
            string filepath = Path.Combine(FileSystemUtility.GetWebSiteTempDirectory()
                , domain == null ? "SheriffJackpotsFeeds.cache" : string.Format("SheriffJackpotsFeeds.{0}.cache", domain.GetCfg(Sheriff.JackpotJsonURL).GetHashCode() )
                );
            Dictionary<string, JackpotInfo> cached = HttpRuntime.Cache[filepath] as Dictionary<string, JackpotInfo>;
            if (cached != null)
                return cached;

            // http://jetbull.nl1.gamingclient.com/jackpot/retrieve/{0}
            string urlFormat = null; 
            if (domain != null)
                urlFormat = domain.GetCfg(Sheriff.JackpotJsonURL);
            if( string.IsNullOrWhiteSpace(urlFormat) )
                urlFormat = ConfigurationManager.AppSettings["DefaultSheriffJackpotJsonUrl"];

            Func<Dictionary<string, JackpotInfo>> func = () =>
            {
                try
                {
                    Dictionary<string, JackpotInfo> jackpots = new Dictionary<string, JackpotInfo>(StringComparer.InvariantCultureIgnoreCase);

                    //List<ceCasinoGameBaseEx> games = CasinoGameAccessor.GetDomainGames(domain == null ? Constant.SystemDomainID : domain.DomainID)
                    //    .Where(g => g.VendorID == VendorID.Sheriff)
                    //    .ToList();

                    List<ceCasinoGameBaseEx> games = CacheManager.GetGameList(domain == null ? Constant.SystemDomainID : domain.DomainID, false, false)
                        .Where(g => g.VendorID == VendorID.Sheriff)
                        .ToList();


                    using (WebClient client = new WebClient())
                    {
                        JavaScriptSerializer jss = new JavaScriptSerializer();
                        Dictionary<string, CurrencyExchangeRateRec> currencies = GamMatrixClient.GetCurrencyRates(Constant.SystemDomainID);

                        foreach (ceCasinoGameBaseEx game in games)
                        {
                            string url = string.Format(CultureInfo.InvariantCulture, urlFormat, HttpUtility.UrlEncode(game.GameCode));
                            string json = client.DownloadString(url);
                            if (!string.IsNullOrWhiteSpace(json))
                            {
                                try
                                {
                                    Dictionary<string, SheriffJackpot> j = jss.Deserialize<Dictionary<string, SheriffJackpot>>(json);
                                    if (j.Count > 0)
                                    {
                                        JackpotInfo jackpot = new JackpotInfo();
                                        jackpot.ID = game.GameCode;
                                        jackpot.Name = game.GameName;
                                        jackpot.VendorID = VendorID.Sheriff;

                                        // For Sheriff jackpors, the amount is always the same for all currencies
                                        foreach (string key in currencies.Keys)
                                        {
                                            SheriffJackpot sj = j.First().Value;
                                            if (sj.totalAmount.HasValue)
                                                jackpot.Amounts[key] = sj.totalAmount.Value / 100.00M;
                                            else
                                                jackpot.Amounts[key] = sj.amount / 100.00M;
                                        }
                                        jackpots[jackpot.ID] = jackpot;
                                    }
                                }
                                catch (Exception ex)
                                {
                                    Logger.Exception(ex, string.Format(@" Sheriff - Jackpots URL : {0}", url));
                                }
                            }
                        }
                    }


                    if (jackpots.Count > 0)
                        ObjectHelper.BinarySerialize<Dictionary<string, JackpotInfo>>(jackpots, filepath);
                    return jackpots;
                }
                catch (Exception ex)
                {
                    Logger.Exception(ex);
                    throw;
                }
            };

            if (!DelayUpdateCache<Dictionary<string, JackpotInfo>>.TryGetValue(filepath, out cached, func, 120))
            {
                cached = ObjectHelper.BinaryDeserialize<Dictionary<string, JackpotInfo>>(filepath, new Dictionary<string, JackpotInfo>());
            }

            return cached;
        }// GetSheriffJackpots
        #endregion


        #region OMI
        private static OMIJackpot QueryOMIJackpot(string currency, string jackpotID, string operatorID)
        {
            string requestContent = string.Format(CultureInfo.InvariantCulture
                        , "{{\"@requestType\":\".GetJackpotInfoRequest\", \"currencyCode\" : \"{0}\", \"jackpotId\" : \"{1}\", \"operatorId\" : \"{2}\"}}"
                        , currency.SafeJavascriptStringEncode()
                        , jackpotID.SafeJavascriptStringEncode()
                        , operatorID.SafeJavascriptStringEncode()
                        );

            string url = ConfigurationManager.AppSettings["DefaultOMIJackpotJsonUrl"];
            HttpWebRequest request = HttpWebRequest.Create(url) as HttpWebRequest;
            request.Method = "POST";
            request.ContentType = "application/json";
            request.KeepAlive = false;
            using (Stream stream = request.GetRequestStream())
            {
                byte[] buffer = Encoding.UTF8.GetBytes(requestContent);
                stream.Write(buffer, 0, buffer.Length);
            }

            string json;
            try
            {
                HttpWebResponse response = request.GetResponse() as HttpWebResponse;
                using (Stream stream = response.GetResponseStream())
                {
                    using (StreamReader sr = new StreamReader(stream))
                    {
                        json = sr.ReadToEnd();
                    }
                }
                response.Close();

                // {"@responseType":".GetJackpotInfoResponse","responseMsg":null,"responseMsgDetails":null,"dbg":null,"responseCode":0,"apiVersion":1,"currentValue":0.01409393942356109700,"currencyCode":"AUD","currencySymbol":"AUD","lastWagerTransactionId":null,"lastWonTS":null,"lastWonValue":null}
                JavaScriptSerializer jss = new JavaScriptSerializer();
                OMIJackpot omiJackpot = jss.Deserialize<OMIJackpot>(json);
                if (omiJackpot.responseCode != 0 || string.IsNullOrEmpty(omiJackpot.currencyCode))
                    throw new Exception(json);
                return omiJackpot;
            }
            catch{}

            return null;
        }


        public static Dictionary<string, JackpotInfo> GetOMIJackpots(ceDomainConfig domain)
        {
            string omiOperatorID = ConfigurationManager.AppSettings["DefaultOMIOperatorID"];
            if (domain != null && !string.IsNullOrEmpty(domain.GetCfg(OMI.OperatorID)))
                omiOperatorID = domain.GetCfg(OMI.OperatorID);

            string filepath = Path.Combine(FileSystemUtility.GetWebSiteTempDirectory()
                , string.Format( CultureInfo.InvariantCulture, "OMIJackpotsFeeds.{0}.cache", omiOperatorID)
                );
            Dictionary<string, JackpotInfo> cached = HttpRuntime.Cache[filepath] as Dictionary<string, JackpotInfo>;
            if (cached != null)
                return cached;

            // https://vegasinstallation.com/gserver/api/game/slot
            

            Func<Dictionary<string, JackpotInfo>> func = () =>
            {
                try
                {
                    string str = "ARS,AUD,BRL,BGN,CAD,CHF,CNY,CZK,DKK,EUR,GBP,GEL,HKD,HUF,HRK,IDR,ISK,JPY,LTL,LVL,MXN,MYR,NGN,NOK,NZD,PLN,RON,RUB,SEK,SGD,THB,TRY,TWD,UAH,USD,VEF,ZAR";
                    string[] omiSupportCurrencies = str.ToUpperInvariant().Split(new char[] { ',' }, StringSplitOptions.RemoveEmptyEntries);
                    
                    Dictionary<string, CurrencyExchangeRateRec> currencies = GamMatrixClient.GetCurrencyRates(Constant.SystemDomainID);
                    Dictionary<string, JackpotInfo> jackpots = new Dictionary<string, JackpotInfo>(StringComparer.InvariantCultureIgnoreCase);

                    // hard-coded jackpotId: 
                    //  The jackpot id. For Jungle Fruits:"201", For Benny The Panda: "202" for maxi, "203" for mini
                    string[] jackpotIDs = new string[] { "201", "202", "203" };
                    string strFailed = "";
                    foreach (string jackpotID in jackpotIDs)
                    {
                        OMIJackpot omiJackpot = QueryOMIJackpot("EUR", jackpotID, omiOperatorID);

                        JackpotInfo jackpot;
                        jackpot = new JackpotInfo()
                        {
                            ID = jackpotID,
                            Name = jackpotID,
                            VendorID = VendorID.OMI,
                        };
                        jackpot.Amounts[omiJackpot.currencyCode] = omiJackpot.currentValue;


                        foreach (string key in currencies.Keys)
                        {
                            if (key.ToUpperInvariant() == "EUR" || !omiSupportCurrencies.Contains(key.ToUpperInvariant()))
                                continue;
                            omiJackpot = QueryOMIJackpot(key, jackpotID, omiOperatorID);
                            if (omiJackpot != null)
                                jackpot.Amounts[omiJackpot.currencyCode] = omiJackpot.currentValue;
                            else
                                strFailed += string.Format("jackpotID: {0}, currency: {1} /n", jackpotID, key);
                        }

                        jackpots[jackpot.ID] = jackpot;
                    }// foreach

                    if (!string.IsNullOrWhiteSpace(strFailed))
                        Logger.Information("OMI jackpots /n" + strFailed);
                    if (jackpots.Count > 0)
                        ObjectHelper.BinarySerialize<Dictionary<string, JackpotInfo>>(jackpots, filepath);
                    return jackpots;
                }
                catch (Exception ex)
                {
                    Logger.Exception(ex, string.Format(" OMI - omiOperatorID : {0}", omiOperatorID));
                    throw;
                }
            };// Func

            if (!DelayUpdateCache<Dictionary<string, JackpotInfo>>.TryGetValue(filepath, out cached, func, 300))
            {
                cached = ObjectHelper.BinaryDeserialize<Dictionary<string, JackpotInfo>>(filepath, new Dictionary<string, JackpotInfo>());
            }

            return cached;
        }// GetOMIJackpots
        #endregion
    }
}
