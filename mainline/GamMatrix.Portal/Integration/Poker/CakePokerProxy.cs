using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Caching;
using System.Xml.Linq;
using CM.Sites;
using GamMatrixAPI;
using GmCore;

namespace Poker
{
    /// <summary>
    /// Summary description for CakePokerProxy
    /// </summary>
    public static class CakePokerProxy
    {
        /// <summary>
        /// Get the overview
        /// </summary>
        /// <returns></returns>
        public static OverviewData GetOverview()
        {
            string cacheKey = string.Format("Poker.CakePokerProxy.GetOverview.{0}", SiteManager.Current.DistinctName);
            OverviewData data = HttpRuntime.Cache[cacheKey] as OverviewData;
            if (data != null)
                return data;

            try
            {
                XDocument xDoc = XDocument.Load("http://feeds.ckpnetwork.eu/PlayersOnline/xml");
                data = new OverviewData()
                {
                    OnlinePlayerNumber = int.Parse( xDoc.Root.Element("playersonline").GetElementValue("content") )
                };

            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                data = new OverviewData();
            }

            HttpRuntime.Cache.Insert(cacheKey, data, null, DateTime.Now.AddMinutes(2), Cache.NoSlidingExpiration);
            return data;
        }


        /// <summary>
        /// Get the tournaments
        /// </summary>
        /// <returns></returns>
        public static List<Tournament> GetTournaments()
        {
            //string cacheKey = string.Format("Poker.CakePokerProxy.GetTournaments.{0}", SiteManager.Current.DistinctName);
            //List<Tournament> list = HttpRuntime.Cache[cacheKey] as List<Tournament>;
            //if (list != null)
            //    return list;

            //try
            //{
            //    list = new List<Tournament>();

            //    CakePartnerAPICurrentTournamentsRequest request = new CakePartnerAPICurrentTournamentsRequest()
            //    {
            //        Max = 10000,
            //    };

            //    using (GamMatrixClient client = GamMatrixClient.Get() )
            //    {
            //        request = client.SingleRequest<CakePartnerAPICurrentTournamentsRequest>(request);
            //    }

            //    if (request.Data.tournamentField != null)
            //    {
            //        foreach (TournamentsTournament t in request.Data.tournamentField.Where( t => !string.IsNullOrWhiteSpace(t.startDateField)) )
            //        {
            //            Tournament tournament = new Tournament()
            //            {
            //                Currency = "USD",
            //                Type = TournamentType.Current,
            //                PrizePool = t.guaranteedWinAmountField,
            //                BuyIn = t.buyInField,
            //                EntryFee = t.feeField,
            //                Name = t.descriptionField,
            //                Entrants = (int)t.registeredPlayersField,
            //                MaxRebuy = t.maxRebuyField,
            //                GameType = t.gameTypeField,
            //                LimitType = t.limitTypeField
            //            };

            //            if (!string.IsNullOrWhiteSpace(t.startDateField))
            //            {
            //                tournament.StartTime = Convert.ToDateTime(t.startDateField);
            //            }


            //            list.Add(tournament);
            //        }
            //    }

            //    if (list.Count > 0)
            //        HttpRuntime.Cache.Insert(cacheKey, list, null, DateTime.Now.AddMinutes(5), Cache.NoSlidingExpiration);
            //}
            //catch (Exception ex)
            //{
            //    Logger.Exception(ex);
            //    list = new List<Tournament>();
            //}
            //return list;
            return null;
        }
    }

}