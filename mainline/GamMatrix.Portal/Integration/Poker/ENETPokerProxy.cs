using System;
using System.Collections.Generic;
using System.Globalization;
using System.Text.RegularExpressions;
using System.Web;
using System.Web.Caching;
using System.Web.Hosting;
using System.Xml;
using CM.Sites;
using GamMatrixAPI;
using GmCore;

namespace Poker
{
    /// <summary>
    /// Summary description for ENetManager
    /// </summary>
    public static class ENETPokerProxy
    {
        private static string ConvertToCentralEuropeanTimeString(DateTime time)
        {
            TimeZoneInfo tzi = TimeZoneInfo.FindSystemTimeZoneById("Central European Standard Time");
            DateTime cet = TimeZoneInfo.ConvertTime(time, tzi);

            return cet.ToString("yyyy/MM/dd HH:mm:ss");
        }

        private static bool TryParseCentralEuropeanTimeString(string str, out DateTime datetime)
        {
            datetime = DateTime.Now;

            Match m = Regex.Match(str, @"(?<month>\d{1,2})\/(?<day>\d{1,2})\/(?<year>\d{4,4})(\s+)(?<hour>\d{1,2})\:(?<minute>\d{1,2})\:(?<second>\d{1,2})", RegexOptions.Compiled | RegexOptions.ECMAScript);
            if (m.Success)
            {
                DateTime cet = new DateTime(int.Parse(m.Groups["year"].Value)
                    , int.Parse(m.Groups["month"].Value)
                    , int.Parse(m.Groups["day"].Value)
                    , int.Parse(m.Groups["hour"].Value)
                    , int.Parse(m.Groups["minute"].Value)
                    , int.Parse(m.Groups["second"].Value)
                    , DateTimeKind.Unspecified
                    );

                TimeZoneInfo tzi = TimeZoneInfo.FindSystemTimeZoneById("Central European Standard Time");
                datetime = TimeZoneInfo.ConvertTime(cet, tzi, TimeZoneInfo.Local);

                return datetime.Year > 2010;
            }
            return false;
        }

        /// <summary>
        /// Get the tournaments
        /// </summary>
        public static List<Tournament> GetTournaments()
        {
            return GetTournamentsAsync(null);
        }

        public static List<Tournament> GetTournamentsAsync(Action<List<Tournament>> callback)
        {
            string cacheKey = string.Format("Poker.ENETProxy.GetTournaments.{0}", SiteManager.Current.DistinctName);
            List<Tournament> list = HttpRuntime.Cache[cacheKey] as List<Tournament>;
            if (list != null)
            {
                if( callback != null )
                    callback(list);
                return list;
            }

            string backupFile = HostingEnvironment.MapPath(string.Format("~/App_Data/{0}/ENETPokerProxy.GetTournaments"
                , SiteManager.Current.DistinctName
                ));
            list = ObjectHelper.BinaryDeserialize<List<Tournament>>(backupFile, new List<Tournament>());
            HttpRuntime.Cache.Insert(cacheKey
                        , list
                        , null
                        , DateTime.Now.AddMinutes(5)
                        , Cache.NoSlidingExpiration
                        , CacheItemPriority.NotRemovable
                        , null
                        );

            ENETAPIRequest request = new ENETAPIRequest()
            {
                ProductGettournaments = true,
            };


            GamMatrixClient.SingleRequestAsync<ENETAPIRequest>(request, OnGetTournaments, callback, cacheKey, backupFile);
            return list;
        }

        private static void OnGetTournaments(AsyncResult result)
        {
            Action<List<Tournament>> callback = result.UserState1 as Action<List<Tournament>>;
            try
            {
                List<Tournament> list = new List<Tournament>();
                ENETAPIRequest response = result.EndSingleRequest().Get<ENETAPIRequest>();

                
                string xml = response.ProductGettournamentsResponse;

                #region XML for test
                //xml = @"<?xml version=""1.0"" encoding=""utf-8""?><response xmlns:xsd=""http://www.w3.org/2001/XMLSchema"" xmlns:xsi=""http://www.w3.org/2001/XMLSchema-instance"" status=""1""><elaborationtime>0.36</elaborationtime><result xsi:type=""ARgettournaments""><products><product id=""5"" name=""Poker""><tournaments><tournament name=""100 Euro Guaranteed Freezeout"" buyin=""2.00"" buyinfee=""0.20"" /><tournament name=""100 Euro Guaranteed Rebuy Turbo"" buyin=""1.00"" buyinfee=""0.10"" /><tournament name=""2 Euro Freezeout"" buyin=""2.00"" buyinfee=""0.20"" /><tournament name=""2 Euro Freezeout"" buyin=""2.00"" buyinfee=""0.20"" /><tournament name=""2 Euro Freezeout"" buyin=""2.00"" buyinfee=""0.20"" /><tournament name=""2 Euro Freezeout"" buyin=""2.00"" buyinfee=""0.20"" /><tournament name=""2 Euro Freezeout"" buyin=""2.00"" buyinfee=""0.20"" /><tournament name=""200 Euro Guaranteed Rebuy Turbo"" buyin=""2.00"" buyinfee=""0.20"" /><tournament name=""200 Euro Guaranteed Rebuy Turbo"" buyin=""2.00"" buyinfee=""0.20"" /><tournament name=""200 Euro Guaranteed Rebuy Turbo"" buyin=""2.00"" buyinfee=""0.20"" /><tournament name=""250 Euro Guaranteed Rebuy"" buyin=""3.00"" buyinfee=""0.30"" /><tournament name=""3 Euro Rebuy"" buyin=""3.00"" buyinfee=""0.30"" /><tournament name=""3 Euro Rebuy"" buyin=""3.00"" buyinfee=""0.30"" /><tournament name=""3 Euro Rebuy"" buyin=""3.00"" buyinfee=""0.30"" /><tournament name=""3 Euro Rebuy"" buyin=""3.00"" buyinfee=""0.30"" /><tournament name=""300 Euro Guaranteed Freezeout"" buyin=""5.00"" buyinfee=""0.50"" /><tournament name=""300 Euro Guaranteed Rebuy"" buyin=""3.00"" buyinfee=""0.30"" /><tournament name=""300 Euro Guaranteed Rebuy Six Handed"" buyin=""3.00"" buyinfee=""0.30"" /><tournament name=""400 Euro Guaranteed Rebuy"" buyin=""5.00"" buyinfee=""0.50"" /><tournament name=""5 Euro Freezeout"" buyin=""5.00"" buyinfee=""0.50"" /><tournament name=""5 Euro Freezeout"" buyin=""5.00"" buyinfee=""0.50"" /><tournament name=""5 Euro Freezeout"" buyin=""5.00"" buyinfee=""0.50"" /><tournament name=""5 Euro Rebuy"" buyin=""5.00"" buyinfee=""0.50"" /><tournament name=""5 Euro Rebuy"" buyin=""5.00"" buyinfee=""0.50"" /><tournament name=""5 Euro Rebuy"" buyin=""5.00"" buyinfee=""0.50"" /><tournament name=""5 Euro Rebuy"" buyin=""5.00"" buyinfee=""0.50"" /><tournament name=""5 Euro Rebuy"" buyin=""5.00"" buyinfee=""0.50"" /><tournament name=""50 Euro Rebuy"" buyin=""1.00"" buyinfee=""0.10"" /><tournament name=""50 Euro Rebuy"" buyin=""1.00"" buyinfee=""0.10"" /><tournament name=""50 Euro Rebuy"" buyin=""1.00"" buyinfee=""0.10"" /><tournament name=""50 Euro Rebuy"" buyin=""1.00"" buyinfee=""0.10"" /><tournament name=""500 Euro Guaranteed Rebuy"" buyin=""5.00"" buyinfee=""0.50"" /><tournament name=""500 Euro Guaranteed Rebuy Turbo"" buyin=""5.00"" buyinfee=""0.50"" /><tournament name=""75 Euro Guaranteed Freezeout"" buyin=""2.00"" buyinfee=""0.20"" /><tournament name=""Cappuccino Time Freeroll 10 Euro"" buyin=""0.00"" buyinfee=""0.00"" /><tournament name=""Coffee Time Freeroll 10 Euro"" buyin=""0.00"" buyinfee=""0.00"" /><tournament name=""Daily Omaha 300 Euro Guaranteed Rebuy"" buyin=""5.00"" buyinfee=""0.50"" /><tournament name=""Dessert Time Freeroll 10 Euro"" buyin=""0.00"" buyinfee=""0.00"" /><tournament name=""Dinner Time Freeroll 40 Euro"" buyin=""0.00"" buyinfee=""0.00"" /><tournament name=""Lunch Time Freeroll 10 Euro"" buyin=""0.00"" buyinfee=""0.00"" /><tournament name=""Tea Time Freeroll 20 Euro"" buyin=""0.00"" buyinfee=""0.00"" /></tournaments></product></products></result></response>";
                #endregion

                XmlDocument doc = new XmlDocument();
                doc.LoadXml(xml);

                XmlNode node = doc.SelectSingleNode("/response/result/products/product[@id=\"5\"]");
                if (node != null)
                {
                    XmlNodeList nodes = node.SelectNodes("tournaments/tournament");
                    foreach( XmlNode child in nodes )
                    {
                        if (child.Attributes["name"] == null)
                            continue;

                        Tournament tournament = new Tournament()
                        {
                            Currency = "EUR",
                            Name = child.Attributes["name"].Value,
                        };

                        decimal amount;
                        if (child.Attributes["buyin"] != null &&
                             decimal.TryParse(child.Attributes["buyin"].Value, NumberStyles.AllowDecimalPoint, CultureInfo.InvariantCulture, out amount))
                        {
                            tournament.BuyIn = amount;
                        }

                        if (child.Attributes["buyinfee"] != null &&
                             decimal.TryParse(child.Attributes["buyinfee"].Value, NumberStyles.AllowDecimalPoint, CultureInfo.InvariantCulture, out amount))
                        {
                            tournament.EntryFee = amount;
                        }
                        list.Add(tournament);
                    }

                    string cacheKey = result.UserState2 as string;
                    HttpRuntime.Cache.Insert(cacheKey
                            , list
                            , null
                            , DateTime.Now.AddMinutes(5)
                            , Cache.NoSlidingExpiration
                            , CacheItemPriority.NotRemovable
                            , null
                            );
                    string backupFile = result.UserState3 as string;
                    ObjectHelper.BinarySerialize<List<Tournament>>(list, backupFile);
                }
                                
                if (callback != null)
                    callback(list);
            }
            catch(Exception ex)
            {
                Logger.Exception(ex);
                if (callback != null)
                    callback(new List<Tournament>());
            }
        }


        /// <summary>
        /// Get overview data
        /// </summary>
        /// <returns></returns>
        public static OverviewData GetOverview()
        {
            string cacheKey = string.Format("Poker.ENETPokerProxy.GetOverview.{0}", SiteManager.Current.DistinctName);
            OverviewData data = HttpRuntime.Cache[cacheKey] as OverviewData;
            if (data != null)
                return data;

            string backupFile = HostingEnvironment.MapPath(string.Format("~/App_Data/{0}/ENETPokerProxy.GetOverview"
                , SiteManager.Current.DistinctName
                ));
            data = ObjectHelper.BinaryDeserialize<OverviewData>(backupFile, new OverviewData());
            HttpRuntime.Cache.Insert(cacheKey
                        , data
                        , null
                        , DateTime.Now.AddMinutes(2)
                        , Cache.NoSlidingExpiration
                        , CacheItemPriority.NotRemovable
                        , null
                        );

            ENETAPIRequest request = new ENETAPIRequest()
            {
                ProductGetnetworknumbers = true,
            };
            GamMatrixClient.SingleRequestAsync<ENETAPIRequest>(request, OnGetOverviewData, null, cacheKey, backupFile);
            return data;
        }

        private static void OnGetOverviewData(AsyncResult result)
        {
            try
            {
                ENETAPIRequest response = result.EndSingleRequest().Get<ENETAPIRequest>();

                string xml = response.ProductGetnetworknumbersResponse;
                    
                //xml = @"<?xml version=""1.0"" encoding=""utf-8""?><response xmlns:xsd=""http://www.w3.org/2001/XMLSchema"" xmlns:xsi=""http://www.w3.org/2001/XMLSchema-instance"" status=""1""><elaborationtime>0.015</elaborationtime><result xsi:type=""ARGetNetworksnumber""><products><product id=""5"" name=""QTPOKER""><activetables>70</activetables><loggedplayers>313</loggedplayers><sitdownplayers>313</sitdownplayers><sitdownuniqueplayers>147</sitdownuniqueplayers></product></products></result></response>";

                XmlDocument doc = new XmlDocument();
                doc.LoadXml(xml);

                XmlNode node = doc.SelectSingleNode("/response/result/products/product[@id=\"5\"]/loggedplayers/text()");
                if (node != null)
                {
                    OverviewData data = new OverviewData()
                    {
                        OnlinePlayerNumber = int.Parse( node.Value, NumberStyles.Any, CultureInfo.InvariantCulture),
                        TableNumber = 0,
                    };

                    string cacheKey = result.UserState2 as string;
                    HttpRuntime.Cache.Insert(cacheKey
                            , data
                            , null
                            , DateTime.Now.AddMinutes(2)
                            , Cache.NoSlidingExpiration
                            , CacheItemPriority.NotRemovable
                            , null
                            );
                    string backupFile = result.UserState3 as string;
                    ObjectHelper.BinarySerialize<OverviewData>(data, backupFile);
                }
            }
            catch(Exception ex)
            {
                Logger.Exception(ex);
            }
        }
    }
}