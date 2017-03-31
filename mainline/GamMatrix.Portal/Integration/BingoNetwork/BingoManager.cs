using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Threading;
using System.Web;
using System.Web.Caching;
using System.Web.Hosting;
using BLToolkit.DataAccess;
using CM.Content;
using CM.db.Accessor;
using CM.Sites;
using CM.State;
using GamMatrix.Infrastructure;
using GamMatrixAPI;
using GmCore;

namespace Bingo
{
    /// <summary>
    /// the wrap class for bingo api
    /// </summary>
    public static class BingoManager
    {       

        public static List<AvatarEntry> GetBingoAvatarList(int category)
        {
            string cacheKey = HostingEnvironment.MapPath(
                string.Format("~/App_Data/{0}/BingoManager.GetBingoAvatarList.{1}", SiteManager.Current.DistinctName, category)
                );
            List<AvatarEntry> cache = HttpRuntime.Cache[cacheKey] as List<AvatarEntry>;
            if (cache != null)
                return cache;

            cache = ObjectHelper.BinaryDeserialize<List<AvatarEntry>>(cacheKey, new List<AvatarEntry>());
            HttpRuntime.Cache.Insert(cacheKey
                , cache
                , null
                , DateTime.Now.AddMinutes(2)
                , Cache.NoSlidingExpiration
                , CacheItemPriority.NotRemovable
                , null
                );

            try
            {
                using (GamMatrixClient client = GamMatrixClient.Get() )
                {
                    BingoNetworkAPIGetAvatarsRequest request =
                    client.SingleRequest<BingoNetworkAPIGetAvatarsRequest>(new BingoNetworkAPIGetAvatarsRequest()
                    {
                        Category = category
                    });

                    if (request != null && request.Data != null)
                    {
                        cache = request.Data;
                        HttpRuntime.Cache.Insert(cacheKey
                            , cache
                            , null
                            , DateTime.Now.AddMinutes(90)
                            , Cache.NoSlidingExpiration
                            );
                        ObjectHelper.BinarySerialize<List<AvatarEntry>>(cache, cacheKey);
                        return cache;
                    }
                }
            }
            catch(Exception ex)
            {
                Logger.Exception(ex);
            }

            return new List<AvatarEntry>();
        }

        /// <summary>
        /// Get jackpots ranking list
        /// </summary>
        /// <param name="count"></param>
        /// <returns></returns>
        public static List<JackpotInfo> GetJackpotsRanking(int count)
        {
            List<JackpotInfo> list = GetJackpots();
            
            if (list != null)
            {
                if (list.Count > count)
                {
                    return list.OrderByDescending(p => p.Amount).Take(count).ToList();
                }
                else
                {
                    return list.OrderByDescending(p => p.Amount).ToList();
                }
            }

            return new List<JackpotInfo>();
        }



        /// <summary>
        /// Get jackpots from GmCore
        /// </summary>
        /// <param name="language"></param>
        /// <param name="userID"></param>
        /// <returns></returns>
        public static List<JackpotInfo> GetJackpots()
        {
            string cacheKey = string.Format("~/App_Data/{0}/BingoManager.GetJackpots.{1}.{2}"
                , SiteManager.Current.DistinctName
                , MultilingualMgr.GetCurrentCulture()
                , CustomProfile.Current.IsAuthenticated ? CustomProfile.Current.UserCurrency : "EUR"
                );
            cacheKey = HostingEnvironment.MapPath(cacheKey);
            List<JackpotInfo> list = null;//HttpRuntime.Cache[cacheKey] as List<JackpotInfo>;
            if (list != null)
                return list;

            list = ObjectHelper.BinaryDeserialize<List<JackpotInfo>>(cacheKey, new List<JackpotInfo>());
            HttpRuntime.Cache.Insert(cacheKey
                , list
                , null
                , DateTime.Now.AddMinutes(2)
                , Cache.NoSlidingExpiration
                );

            try
            {
                BingoNetworkAPIGetJackpotsRequest request;
                using (GamMatrixClient client = GamMatrixClient.Get() )
                {
                    request = client.SingleRequest <BingoNetworkAPIGetJackpotsRequest>(new BingoNetworkAPIGetJackpotsRequest()
                    {
                        Language = MultilingualMgr.GetCurrentCulture(),
                        UserID = CustomProfile.Current.UserID
                    });
                }
                if (request != null)
                {                    
                    if (request.Data != null)
                    {
                        list = new List<JackpotInfo>();
                        foreach (BingoJackpot entity in request.Data)
                        {
                            list.Add(new JackpotInfo
                            {
                                Amount = entity.jackpotAmountField,
                                Currency = entity.currencyCodeField,
                                Name = entity.jackpotNameField,
                                RoomID = entity.roomIdField
                            });
                        }

                        HttpRuntime.Cache.Insert(cacheKey
                            , list
                            , null
                            , DateTime.Now.AddMinutes(15)
                            , Cache.NoSlidingExpiration
                            );
                        ObjectHelper.BinarySerialize<List<JackpotInfo>>(list, cacheKey);
                        return list;
                    }
                }
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
            }
            return new List<JackpotInfo>();
        }

    

        private sealed class BingRoomsCacheEntry : CacheEntryBase<List<BingoRoom>>
        {
            public override int ExpirationSeconds { get { return 10; } }

            public BingRoomsCacheEntry(List<BingoRoom> bingoRooms)
                : base(bingoRooms)
            {
            }
        }

        /// <summary>
        /// GetRooms
        /// </summary>
        /// <returns></returns>
        public static List<BingoRoom> GetRooms()
        {
            string cacheKey = string.Format("~/App_Data/{0}/BingoManager.GetRooms.{1}.{2}"
                , SiteManager.Current.DistinctName
                , MultilingualMgr.GetCurrentCulture()
                , CustomProfile.Current.IsAuthenticated ? CustomProfile.Current.UserCurrency : "EUR"
                );

            BingRoomsCacheEntry cache = HttpRuntime.Cache[cacheKey] as BingRoomsCacheEntry;
            if (cache != null && !cache.IsExpried && cache.Value != null)
                return cache.Value;
            try
            {
                if( Monitor.TryEnter(typeof(BingoNetworkAPIGetBingoRoomsRequest)) )
                {
                    try
                    {
                        cache = HttpRuntime.Cache[cacheKey] as BingRoomsCacheEntry;
                        if (cache != null && !cache.IsExpried && cache.Value != null)
                            return cache.Value;


                        using (GamMatrixClient client = GamMatrixClient.Get())
                        {
                            BingoNetworkAPIGetBingoRoomsRequest request
                                = client.SingleRequest(new BingoNetworkAPIGetBingoRoomsRequest()
                                {
                                    Language = MultilingualMgr.GetCurrentCulture(),
                                    UserID = CustomProfile.Current.UserID,
                                });

                            if (request != null && request.Data != null)
                            {
                                HttpRuntime.Cache.Insert(cacheKey
                                    , new BingRoomsCacheEntry(request.Data)
                                    , null
                                    , Cache.NoAbsoluteExpiration
                                    , TimeSpan.FromMinutes(10)
                                    );

                                return request.Data;
                            }
                        }
                    }
                    finally
                    {
                        Monitor.Exit(typeof(BingoNetworkAPIGetBingoRoomsRequest));
                    }
                }

                if (cache != null && cache.Value != null)
                    return cache.Value;
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
            }

            return new List<BingoRoom>();
        }// GetRooms


        /// <summary>
        /// Returns 5 largest winnings last 48 hours  
        /// </summary>
        /// <returns></returns>
        public static List<Winner> GetTopWinners()
        {
            string cacheKey = string.Format("~/App_Data/{0}/BingoManager.GetTopWinners.{1}.{2}"
                , SiteManager.Current.DistinctName
                , MultilingualMgr.GetCurrentCulture()
                , CustomProfile.Current.IsAuthenticated ? CustomProfile.Current.UserCurrency : "EUR"
                );
            cacheKey = HostingEnvironment.MapPath(cacheKey);
            List<Winner> winners = HttpRuntime.Cache[cacheKey] as List<Winner>;
            if (winners != null)
                return winners;

            winners = ObjectHelper.BinaryDeserialize<List<Winner>>(cacheKey, new List<Winner>());
            HttpRuntime.Cache.Insert(cacheKey
                , winners
                , null
                , DateTime.Now.AddMinutes(2)
                , Cache.NoSlidingExpiration
                );
            try
            {
                using (GamMatrixClient client = GamMatrixClient.Get())
                {
                    BingoNetworkAPIGetWinnersTopListRequest request
                        = client.SingleRequest<BingoNetworkAPIGetWinnersTopListRequest>(new BingoNetworkAPIGetWinnersTopListRequest()
                        {
                            Language = MultilingualMgr.GetCurrentCulture(),
                            UserID = CustomProfile.Current.UserID,
                        });

                    if (request.Data != null)
                    {
                        winners = new List<Winner>();
                        foreach (BingoWinner entity in request.Data)
                        {
                            winners.Add(new Winner
                            {
                                Amount = (decimal)entity.amountField,
                                DateWon = entity.dateWonField,
                                Currency = entity.currencyCodeField,
                                UserID = entity.user_idField,
                                NickName = entity.nickField,
                                AvatarUrl = entity.avatar_urlField,
                                City = entity.cityField
                            });
                        }
                        HttpRuntime.Cache.Insert(cacheKey
                            , winners
                            , null
                            , DateTime.Now.AddMinutes(5)
                            , Cache.NoSlidingExpiration
                            );
                        ObjectHelper.BinarySerialize<List<Winner>>(winners, cacheKey);
                        return winners;
                    }
                }
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
            }


            return new List<Winner>();
        }

        /// <summary>
        /// Get free play winners
        /// </summary>
        /// <returns></returns>
        public static List<Winner> GetFreePlayWinners()
        {
            string cacheKey = string.Format("~/App_Data/{0}/BingoManager.GetFreePlayWinners.{1}.{2}"
                , SiteManager.Current.DistinctName
                , MultilingualMgr.GetCurrentCulture()
                , CustomProfile.Current.IsAuthenticated ? CustomProfile.Current.UserCurrency : "EUR"
                );
            cacheKey = HostingEnvironment.MapPath(cacheKey);
            List<Winner> winners = HttpRuntime.Cache[cacheKey] as List<Winner>;
            if (winners != null)
                return winners;

            winners = ObjectHelper.BinaryDeserialize<List<Winner>>(cacheKey, new List<Winner>());
            HttpRuntime.Cache.Insert(cacheKey
                , winners
                , null
                , DateTime.Now.AddMinutes(2)
                , Cache.NoSlidingExpiration
                );
            try
            {
                using (GamMatrixClient client = GamMatrixClient.Get())
                {
                    BingoNetworkAPIGetFreePlayWinnersTopListRequest request
                        = client.SingleRequest<BingoNetworkAPIGetFreePlayWinnersTopListRequest>(new BingoNetworkAPIGetFreePlayWinnersTopListRequest()
                        {
                            Language = MultilingualMgr.GetCurrentCulture(),
                            UserID = CustomProfile.Current.UserID,
                        });

                    if (request.Data != null)
                    {
                        winners = new List<Winner>();
                        foreach (BingoWinner entity in request.Data)
                        {
                            winners.Add(new Winner
                            {
                                Amount = (decimal)entity.amountField,
                                DateWon = entity.dateWonField,
                                Currency = entity.currencyCodeField,
                                UserID = entity.user_idField,
                                NickName = entity.nickField,
                                AvatarUrl = entity.avatar_urlField,
                                City = entity.cityField
                            });
                        }
                        HttpRuntime.Cache.Insert(cacheKey
                            , winners
                            , null
                            , DateTime.Now.AddMinutes(5)
                            , Cache.NoSlidingExpiration
                            );
                        ObjectHelper.BinarySerialize<List<Winner>>(winners, cacheKey);
                        return winners;
                    }
                }
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
            }


            return new List<Winner>();
        }

        /// <summary>
        /// get last [days] days' daily top winner
        /// </summary>
        /// <param name="days"></param>
        /// <returns></returns>
        public static List<Winner> GetHistoryFreePlayWinners(int days = 0)
        {
            string cacheKey = string.Format("~/App_Data/{0}/BingoManager.GetHistoryFreePlayWinners.{1}.{2}"
                , SiteManager.Current.DistinctName
                , MultilingualMgr.GetCurrentCulture()
                , CustomProfile.Current.IsAuthenticated ? CustomProfile.Current.UserCurrency : "EUR"
                );
            cacheKey = HostingEnvironment.MapPath(cacheKey);
            List<Winner> winners = HttpRuntime.Cache[cacheKey] as List<Winner>;

            if (winners == null)
            {
                winners = ObjectHelper.BinaryDeserialize<List<Winner>>(cacheKey, new List<Winner>());

                if (Monitor.TryEnter(typeof(BingoNetworkAPIGetWinnerOfTheDayRequest)))
                {
                    try {
                        Winner winner = GetWinnerOfTheDay();                        

                        if (winner != null && winner.UserID > 0)
                        {
                            if (winners.Exists(p => p.DateWon < DateTime.Now.AddDays(-30)))
                            {
                                winners.RemoveAll(p=>p.DateWon < DateTime.Now.AddDays(-30));
                            }

                            if (winners.Exists(p => p.DateWon.Date == winner.DateWon.Date))
                            {
                                winners.RemoveAll(p => p.DateWon.Date == winner.DateWon.Date);                                
                            }
                            winners.Insert(0, winner);

                            winners = winners.OrderByDescending(p => p.DateWon).ToList();

                            ObjectHelper.BinarySerialize<List<Winner>>(winners, cacheKey);
                        }

                        HttpRuntime.Cache.Insert(cacheKey
                            , winners
                            , null
                            , DateTime.Now.AddMinutes(1)
                            , Cache.NoSlidingExpiration
                            );                        
                    }
                    finally {
                        Monitor.Exit(typeof(BingoNetworkAPIGetWinnerOfTheDayRequest));
                    }
                }
            }

            if (winners != null)                 
            {
                if (days > 0 && winners.Count > days)
                    return winners.Take(days).ToList();

                return winners;
            }

            return new List<Winner>();
        }

        /// <summary>
        /// get top winner of the day
        /// </summary>
        /// <returns></returns>
        public static Winner GetWinnerOfTheDay()
        {
            string cacheKey = string.Format("~/App_Data/{0}/BingoManager.GetWinnersOfTheDay.{1}.{2}"
                , SiteManager.Current.DistinctName
                , MultilingualMgr.GetCurrentCulture()
                , CustomProfile.Current.IsAuthenticated ? CustomProfile.Current.UserCurrency : "EUR"
                );
            cacheKey = HostingEnvironment.MapPath(cacheKey);
            Winner winner = HttpRuntime.Cache[cacheKey] as Winner;
            if (winner != null)
                return winner;

            winner = ObjectHelper.BinaryDeserialize<Winner>(cacheKey, new Winner());
            HttpRuntime.Cache.Insert(cacheKey
                , winner
                , null
                , DateTime.Now.AddMinutes(30)
                , Cache.NoSlidingExpiration
                );
            try
            {
                using (GamMatrixClient client = GamMatrixClient.Get())
                {

                    BingoNetworkAPIGetWinnerOfTheDayRequest request
                        = client.SingleRequest<BingoNetworkAPIGetWinnerOfTheDayRequest>(new BingoNetworkAPIGetWinnerOfTheDayRequest()
                        {
                            Language = MultilingualMgr.GetCurrentCulture(),                            
                        });

                    if (request.Data != null)
                    {
                        winner = new Winner
                            {
                                Amount = (decimal)request.Data.amountField,
                                DateWon = request.Data.dateWonField,
                                Currency = request.Data.currencyCodeField,
                                UserID = request.Data.user_idField,
                                NickName = request.Data.nickField,
                                AvatarUrl = request.Data.avatar_urlField,
                                City = request.Data.cityField
                            };
                        
                        HttpRuntime.Cache.Insert(cacheKey
                            , winner
                            , null
                            , DateTime.Now.AddMinutes(30)
                            , Cache.NoSlidingExpiration
                            );
                        ObjectHelper.BinarySerialize<Winner>(winner, cacheKey);
                        return winner;
                    }
                }
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
            }


            return new Winner();
        }
        /// <summary>
        /// Retrieve the Session ID for bingo game
        /// </summary>
        /// <returns></returns>
        public static string GetSessionID()
        {
            if (!CustomProfile.Current.IsAuthenticated)
                return string.Empty;

            try
            {

                using (GamMatrixClient client = GamMatrixClient.Get() )
                {
                    BingoNetworkAPICreateSessionRequest request
                        = client.SingleRequest(new BingoNetworkAPICreateSessionRequest()
                        {
                            UserID = CustomProfile.Current.UserID,
                            UserIP = HttpContext.Current.Request.GetRealUserAddress(),
                        });

                    if (request != null && request.Data != null)
                    {
                        // Accept the Terms and Conditions
                        if (!request.Data.successField &&
                            request.Data.tc_must_acceptField &&
                            !string.IsNullOrEmpty(request.Data.tc_accept_urlField))
                        {
                            string password = DataAccessor.CreateInstance<UserAccessor>().GetHashedPassword(CustomProfile.Current.UserID);
                            if (!string.IsNullOrEmpty(password))
                            {
                                string url = string.Format("{0}?a={1}&b={2}&c=1"
                                    , request.Data.tc_accept_urlField
                                    , request.Data.user_idField
                                    , HttpUtility.UrlEncode(password)
                                    );
                                using (WebClient webClient = new WebClient())
                                {
                                    webClient.DownloadString(url);
                                }

                                request = client.SingleRequest(new BingoNetworkAPICreateSessionRequest()
                                {
                                    UserID = CustomProfile.Current.UserID,
                                    UserIP = HttpContext.Current.Request.GetRealUserAddress(),
                                });
                            }
                            else {
                                request = null;                                    
                            }
                        }

                        if (request != null && request.Data.successField)
                        {
                            return request.Data.session_idField;
                        }
                        else
                            throw new Exception(request.Data.exceptionField);
                    }
                }
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
            }

            return string.Empty;
        }// GetSessionID     


    }
}