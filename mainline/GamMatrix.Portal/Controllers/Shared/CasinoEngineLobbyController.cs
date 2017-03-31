using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using BLToolkit.DataAccess;
using CM.Content;
using CM.db;
using CM.db.Accessor;
using CM.Sites;
using CM.State;
using CM.Web;
using Finance;
using GamMatrixAPI;
using GmCore;

namespace GamMatrix.CMS.Controllers.Shared
{
    [ControllerExtraInfo(DefaultAction = "Index")]

    public class CasinoEngineLobbyController : AsyncControllerEx
    {
        [HttpGet]
        [MasterPageViewData(Name = "CurrentPageClass", Value = "CasinoLobby")]
        [CompressFilter]
        public virtual ActionResult Index()
        {
            return this.View();
        }




        /// <summary>
        /// 
        /// </summary>
        /// <param name="categoryID">optional, the category id to filter</param>
        /// <param name="keywords">optional, the keywords to filter</param>
        /// <param name="onlyFavorites">optional, true to return only the favorites games</param>
        /// <param name="onlyPopularGames">optional, true to return only the popular games</param>
        /// <param name="onlyNewGames">optional, true to return only the new games</param>
        /// <param name="vendorID">optional, the VendorID to filter the result</param>
        /// <param name="sortType">optional, the sort type</param>
        /// <returns></returns>
        public ActionResult SearchGames(string categoryID
            , string keywords
            , bool? onlyFavorites
            , bool? onlyPopularGames
            , bool? onlyNewGames
            , VendorID? vendorID
            , CasinoEngine.SortType? sortType
            )
        {
            if (!sortType.HasValue) sortType = CasinoEngine.SortType.None;
            if (!onlyFavorites.HasValue) onlyFavorites = false;
            if (!onlyPopularGames.HasValue) onlyPopularGames = false;
            if (!onlyNewGames.HasValue) onlyNewGames = false;


            List<CasinoEngine.GameRef> games = null;
            if (!string.IsNullOrWhiteSpace(categoryID))
            {
                List<CasinoEngine.GameCategory> categories = CasinoEngine.GameMgr.GetCategories();
                CasinoEngine.GameCategory category = categories.FirstOrDefault(c => string.Equals(c.ID, categoryID, StringComparison.InvariantCultureIgnoreCase));
                if (category != null)
                    games = category.Games;
                else
                    games = new List<CasinoEngine.GameRef>();
            }
            else
            {
                games = CasinoEngine.GameMgr.GetAllGames();
            }


            return this.View("GameBoxWidget_List", games);
        }



        /// <summary>
        /// JackpotBox Widget
        /// </summary>
        /// <param name="currency"></param>
        /// <param name="allJackpotsPageUrl"></param>
        public ActionResult JackpotBoxWidget(string currency, string allJackpotsPageUrl)
        {
            IPLocation ipLocation = IPLocation.GetByIP(Request.GetRealUserAddress());
            List<CasinoEngine.JackpotInfo> jackpots = new List<CasinoEngine.JackpotInfo>();

            List<CountryInfo> countries = CountryManager.GetAllCountries();

            var allJackpots = CasinoEngine.CasinoEngineClient.GetJackpots().OrderByDescending(j => j.Amount["EUR"]).ToList();
            foreach (CasinoEngine.JackpotInfo jackpot in allJackpots)
            {
                if (jackpot.Games != null)
                {
                    for (int i = jackpot.Games.Count - 1; i >= 0; i--)
                    {
                        if (!jackpot.Games[i].IsAvailable)
                        {
                            jackpot.Games.RemoveAt(i);
                            continue;
                        }
                    }
                }

                jackpots.Add(jackpot);
            }

            this.ViewData["Currency"] = currency;
            this.ViewData["AllJackpotsPageUrl"] = allJackpotsPageUrl;
            return this.View("JackpotBoxWidget", jackpots);
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="gameID"></param>
        /// <returns></returns>
        public JsonResult GetGameInfo(string gameID, bool playForFun)
        {
            Dictionary<string, CasinoEngine.Game> games = CasinoEngine.CasinoEngineClient.GetGames();
            CasinoEngine.Game game;
            if (games.TryGetValue(gameID, out game))
            {
                if (playForFun && (CustomProfile.Current.IsAuthenticated && !game.IsFunModeEnabled))
                {
                    return this.Json(new
                    {
                        @success = false,
                        @errorCode = "-1",
                        @error = "Error, this game cannot be played in fun mode!",
                    }, JsonRequestBehavior.AllowGet);
                }

                if (playForFun && (!CustomProfile.Current.IsAuthenticated && !game.IsAnonymousFunModeEnabled))
                {
                    return this.Json(new
                    {
                        @success = false,
                        @errorCode = "-2",
                        @error = "Error, this game cannot be played in fun mode before you logged in!",
                    }, JsonRequestBehavior.AllowGet);
                }

                if (!playForFun && !game.IsRealMoneyModeEnabled)
                {
                    return this.Json(new
                    {
                        @success = false,
                        @errorCode = "-3",
                        @error = "Error, this game cannot be played in real money mode!",
                    }, JsonRequestBehavior.AllowGet);
                }

                if (!playForFun && !CustomProfile.Current.IsAuthenticated)
                {
                    return this.Json(new
                    {
                        @success = false,
                        @errorCode = "-4",
                        @error = "Your session has timed out, please login again!",
                    }, JsonRequestBehavior.AllowGet);
                }

                if (!playForFun && CustomProfile.Current.IsAuthenticated)
                {
                    if (!CustomProfile.Current.IsEmailVerified)
                    {
                        UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
                        cmUser user = ua.GetByID(CustomProfile.Current.UserID);
                        if (!user.IsEmailVerified)
                        {
                            return this.Json(new
                            {
                                @success = false,
                                @errorCode = "-5",
                                @error = "You must first activate your account to play in real money mode!",
                            }, JsonRequestBehavior.AllowGet);
                        }
                        else
                            CustomProfile.Current.IsEmailVerified = true;
                    }
                }

                string url = string.Format("{0}?language={1}"
                    , game.Url
                    , MultilingualMgr.GetCurrentCulture()
                    );
                if (CustomProfile.Current.IsAuthenticated)
                {
                    url = string.Format(CultureInfo.InvariantCulture, "{0}&_sid={1}"
                        , url
                        , HttpUtility.UrlEncode(CustomProfile.Current.SessionID)
                        );
                }

                string realMoneyModeUrl = null;
                if (game.IsRealMoneyModeEnabled)
                    realMoneyModeUrl = string.Format(CultureInfo.InvariantCulture, "{0}&funMode=False", url);

                string demoModeUrl = null;
                if ((CustomProfile.Current.IsAuthenticated && game.IsFunModeEnabled) ||
                    (!CustomProfile.Current.IsAuthenticated && game.IsAnonymousFunModeEnabled))
                {
                    demoModeUrl = string.Format(CultureInfo.InvariantCulture, "{0}&funMode=True", url);
                }


                string helpUrl = game.HelpUrl;
                if (!string.IsNullOrWhiteSpace(helpUrl))
                {
                    helpUrl = string.Format("{0}?language={1}"
                        , game.HelpUrl
                        , MultilingualMgr.GetCurrentCulture()
                        );
                }


                var jackpots = CasinoEngine.CasinoEngineClient.GetJackpots()
                    .Where(j => j.Games.Exists(g => g.ID == gameID))
                    .OrderByDescending(j => j.Amount["EUR"])
                    .Take(1);

                string jackpotCurrency = CustomProfile.Current.UserCurrency.DefaultIfNullOrEmpty("EUR");
                decimal jackpotAmount = 0.00M;
                foreach (var jackpot in jackpots)
                {
                    jackpotAmount = jackpot.Amount[jackpotCurrency];
                    break;
                }

                var ret = new
                {
                    @success = true,
                    @game = new
                    {
                        ID = game.ID,
                        VendorID = game.VendorID.ToString(),
                        IsNewGame = game.IsNewGame,
                        IsMiniGame = game.IsMiniGame,
                        IsRealMoneyModeEnabled = game.IsRealMoneyModeEnabled,
                        IsFunModeEnabled = game.IsFunModeEnabled,
                        IsJackpotGame = game.IsJackpotGame,
                        LogoUrl = game.LogoUrl,
                        ThumbnailUrl = game.ThumbnailUrl,
                        BackgroundImageUrl = game.BackgroundImageUrl,
                        Url = url,
                        FunModeUrl = demoModeUrl,
                        RealMoneyModeUrl = realMoneyModeUrl,
                        HelpUrl = helpUrl,
                        Width = game.Width.HasValue ? game.Width.Value : 0,
                        Height = game.Height.HasValue ? game.Height.Value : 0,
                        Tags = string.Join(",", game.Tags),
                        Name = game.Name,
                        ShortName = game.ShortName,
                        JackpotCurrency = jackpotCurrency,
                        JackpotAmount = jackpotAmount,
                        JackpotMoney = MoneyHelper.FormatWithCurrencySymbol(jackpotCurrency, jackpotAmount),
                        PlayForFun = playForFun,
                        LicenseType = game.LicenseType,
                        Slug = game.Slug.DefaultIfNullOrEmpty(game.ID),
                    }
                };
                return this.Json(ret, JsonRequestBehavior.AllowGet);
            }

            return this.Json(new
            {
                @success = false,
                @errorCode = "-3",
                @error = "Error, this game cannot is not avaliable any more!",
            }, JsonRequestBehavior.AllowGet);
        }


        public ActionResult TopWinnersWidget(string currency, int? maxWinners, string allWinnersUrl, bool? isMobile)
        {
            if (!isMobile.HasValue)
                isMobile = false;
            if (!maxWinners.HasValue)
                maxWinners = 0;

            IPLocation ipLocation = IPLocation.GetByIP(Request.GetRealUserAddress());

            List<CasinoEngine.WinnerInfo> winners = CasinoEngine.CasinoEngineClient.GetTopWinners(SiteManager.Current, isMobile.Value);

            List<CountryInfo> countries = CountryManager.GetAllCountries();
            #region Restricted Territories
            winners = winners.Where(delegate(CasinoEngine.WinnerInfo winner)
            {
                CountryInfo country;
                if (winner.Game != null)
                {
                    if (winner.Game.RestrictedTerritories != null && winner.Game.RestrictedTerritories.Length > 0)
                    {
                        if (CustomProfile.Current.IsAuthenticated)
                        {
                            country = countries.FirstOrDefault(c => c.InternalID == CustomProfile.Current.UserCountryID);
                            if (country != null && winner.Game.RestrictedTerritories.Contains(country.ISO_3166_Alpha2Code))
                            {
                                return false;
                            }
                        }
                        if (ipLocation.CountryID > 0)
                        {
                            country = countries.FirstOrDefault(c => c.InternalID == ipLocation.CountryID);
                            if (country != null && winner.Game.RestrictedTerritories.Contains(country.ISO_3166_Alpha2Code))
                            {
                                return false;
                            }
                        }
                    }

                    return true;
                }
                return false;
            }).ToList();
            #endregion Restricted Territories
            if (maxWinners > 0)
                winners = winners.Take(maxWinners.Value).ToList();

            this.ViewData["allWinnersUrl"] = allWinnersUrl;

            return this.View("TopWinnersWidget", winners);
        }

        public ActionResult GameGalleryWidget(int? maxCount)
        {
            if (!maxCount.HasValue)
                maxCount = 50;

            Random random = new Random();
            List<CasinoEngine.Game> allGames = CasinoEngine.GameMgr.GetAllGamesWithoutGroup();
            List<CasinoEngine.Game> games = new List<CasinoEngine.Game>();
            for (int i = 0; i < maxCount.Value && allGames.Count > 0; )
            {
                int index = random.Next() % allGames.Count;
                if (!CustomProfile.Current.IsAuthenticated &&
                    !allGames[index].IsFunModeEnabled)
                {
                    allGames.RemoveAt(index);
                    continue;
                }
                games.Add(allGames[index]);
                i++;
            }
            return this.View("GameGalleryWidget", games);
        }

        public ActionResult SimilarGamesWidget(string gameID, int? maxCount)
        {
            if (string.IsNullOrWhiteSpace(gameID))
                return this.Content(string.Empty);

            if (!maxCount.HasValue || maxCount <= 0)
                maxCount = 50;

            CasinoEngine.Game game;
            List<CasinoEngine.Game> similarGames = GetSimilarGames(gameID, out game, maxCount.Value);

            if (game == null)
                return this.Content(string.Empty);

            this.ViewData["SimilarGameList"] = similarGames;
            return this.View("SimilarGamesWidget", game);
        }

        public ActionResult SimilarGameSliderWidget(string gameID, int? maxCount)
        {
            if (string.IsNullOrWhiteSpace(gameID))
                return this.Content(string.Empty);

            if (!maxCount.HasValue || maxCount <= 0)
                maxCount = 50;

            CasinoEngine.Game game;
            List<CasinoEngine.Game> similarGames = GetSimilarGames(gameID, out game, maxCount.Value);

            if (game == null)
                return this.Content(string.Empty);

            this.ViewData["SimilarGameList"] = similarGames;
            return this.View("SimilarGameSliderWidget", game);
        }

        private List<CasinoEngine.Game> GetSimilarGames(string gameID, out CasinoEngine.Game game, int maxCount)
        {
            List<CasinoEngine.Game> games = new List<CasinoEngine.Game>();
            game = null;
            if (string.IsNullOrWhiteSpace(gameID))
                return games;

            Dictionary<string, CasinoEngine.Game> allGames = CasinoEngine.CasinoEngineClient.GetGames();
            if (!allGames.TryGetValue(gameID, out game))
                return games;

            Func<CasinoEngine.Game, CasinoEngine.Game, bool> isSimilarGame = (g, g2) =>
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

            List<CasinoEngine.GameCategory> categories = CasinoEngine.GameMgr.GetCategories();
            CasinoEngine.Game currentGame = null;
            CasinoEngine.GameCategory currentCategory = null;
            List<CasinoEngine.Game> currentCategoryGames = new List<CasinoEngine.Game>();
            foreach (CasinoEngine.GameCategory category in categories)
            {
                if (currentCategory == null)
                    currentCategoryGames.Clear();
                foreach (CasinoEngine.GameRef gameRef in category.Games)
                {
                    if (gameRef.IsGameGroup)
                    {
                        foreach (CasinoEngine.GameRef childRef in gameRef.Children)
                        {
                            currentGame = childRef.Game;
                            if (isSimilarGame(currentGame, game))
                                games.Add(currentGame);
                            if (game.ID == currentGame.ID)
                            {
                                currentCategory = category;
                            }
                            else
                            {
                                if (currentCategory == category ||
                                    currentCategory == null)
                                {
                                    currentCategoryGames.Add(currentGame);
                                }
                            }
                        }
                    }
                    else
                    {
                        currentGame = gameRef.Game;
                        if (isSimilarGame(currentGame, game))
                            games.Add(currentGame);
                        if (game.ID == currentGame.ID)
                        {
                            currentCategory = category;
                        }
                        else
                        {
                            if (currentCategory == category ||
                                currentCategory == null)
                            {
                                currentCategoryGames.Add(currentGame);
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

            return games.Take(maxCount).ToList();
        }


        /// <summary>
        /// Add the game id to favorite
        /// </summary>
        /// <param name="gameID"></param>
        /// <returns></returns>
        public JsonResult AddToFavorites(string gameID)
        {
            if (string.IsNullOrWhiteSpace(gameID))
                return this.Json(new { @success = true });

            long userID = 0;
            if (CustomProfile.Current.IsAuthenticated)
                userID = CustomProfile.Current.UserID;
            else
            {
                if (Request.Cookies[Settings.CLIENT_IDENTITY_COOKIE] != null)
                {
                    long.TryParse(Request.Cookies[Settings.CLIENT_IDENTITY_COOKIE].Value, out userID);
                }
                if (userID == 0)
                {
                    if (Request.Cookies[Settings.CLIENT_IDENTITY_COOKIE] == null)
                    {
                        userID = UniqueInt64.Generate() * -1;
                        HttpCookie cookie = new HttpCookie(Settings.CLIENT_IDENTITY_COOKIE, userID.ToString());
                        cookie.HttpOnly = false;
                        cookie.Secure = false;
                        cookie.Expires = DateTime.Now.AddYears(1);
                        if (!string.IsNullOrWhiteSpace(SiteManager.Current.SessionCookieDomain))
                            cookie.Domain = SiteManager.Current.SessionCookieDomain;
                        Response.Cookies.Add(cookie);
                    }
                }
            }

            try
            {
                SqlQuery<cmCasinoFavoriteGame> query = new SqlQuery<cmCasinoFavoriteGame>();
                cmCasinoFavoriteGame favoriteGame = new cmCasinoFavoriteGame()
                {
                    UserID = userID,
                    DomainID = SiteManager.Current.DomainID,
                    GameID = gameID,
                    Ins = DateTime.Now
                };
                query.Insert(favoriteGame);
            }
            catch // ignore dunplicate insert exception 
            {
            }
            return this.Json(new { @success = true }, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// Remove a game from favorites
        /// </summary>
        /// <param name="gameID"></param>
        /// <returns></returns>
        public JsonResult RemoveFromFavorites(string gameID)
        {
            if (string.IsNullOrWhiteSpace(gameID))
                return this.Json(new { @success = true });


            long userID = 0;
            if (CustomProfile.Current.IsAuthenticated)
            {
                userID = CustomProfile.Current.UserID;
            }

            long clientIdentity = 0;
            if (Request.Cookies[Settings.CLIENT_IDENTITY_COOKIE] != null)
            {
                long.TryParse(Request.Cookies[Settings.CLIENT_IDENTITY_COOKIE].Value, out clientIdentity);
            }

            CasinoFavoriteGameAccessor cfga = CasinoFavoriteGameAccessor.CreateInstance<CasinoFavoriteGameAccessor>();
            cfga.DeleteByUserID(SiteManager.Current.DomainID, userID, clientIdentity, gameID);
            return this.Json(new { @success = true }, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// Winners now widget
        /// </summary>
        /// <param name="currency"></param>
        /// <param name="maxWinners"></param>
        /// <param name="allWinnersUrl"></param>
        /// <returns></returns>
        public ActionResult RecentWinnersWidget(string currency, bool? showCapitalName, int? maxWinners, int? rollingCount)
        {
            this.ViewData["Currency"] = currency;
            this.ViewData["ShowCapitalName"] = showCapitalName;
            this.ViewData["MaxWinners"] = maxWinners;
            this.ViewData["RollingCount"] = rollingCount;
            return this.View("RecentWinnersWidget");
        }


        public JsonResult GetRecentWinners(string currency, bool? showCapitalName, bool? isMobile,bool? needConvert)
        {
            if (!showCapitalName.HasValue)
                showCapitalName = false;
            if (!isMobile.HasValue)
                isMobile = false;
            if (!needConvert.HasValue)
                needConvert = false;
            if (string.IsNullOrEmpty(currency))
                currency = "EUR";

            IPLocation ipLocation = IPLocation.GetByIP(Request.GetRealUserAddress());
            List<CountryInfo> countries = CountryManager.GetAllCountries();
            List<CasinoEngine.WinnerInfo> winners = CasinoEngine.CasinoEngineClient.GetRecentWinners(
                SiteManager.Current,
                isMobile.Value
            );
            Dictionary<string, CurrencyExchangeRateRec> dicExchangeRate = null;
            if(needConvert.Value)
                dicExchangeRate=GamMatrixClient.GetCurrencyRates();

            #region Restricted Territories
            winners = winners.Where(delegate(CasinoEngine.WinnerInfo winner)
            {
                CountryInfo country;
                if (winner.Game != null)
                {
                    if (winner.Game.RestrictedTerritories != null && winner.Game.RestrictedTerritories.Length > 0)
                    {
                        if (CustomProfile.Current.IsAuthenticated)
                        {
                            country = countries.FirstOrDefault(c => c.InternalID == CustomProfile.Current.UserCountryID);
                            if (country != null && winner.Game.RestrictedTerritories.Contains(country.ISO_3166_Alpha2Code))
                            {
                                return false;
                            }
                        }
                        if (ipLocation.CountryID > 0)
                        {
                            country = countries.FirstOrDefault(c => c.InternalID == ipLocation.CountryID);
                            if (country != null && winner.Game.RestrictedTerritories.Contains(country.ISO_3166_Alpha2Code))
                            {
                                return false;
                            }
                        }
                    }
                    return true;
                }
                return false;
            }).ToList();
            #endregion Restricted Territories

            Func<string, string> getCountryFlagName = delegate(string countryCode)
            {
                CountryInfo country = countries.FirstOrDefault(c => string.Equals(c.ISO_3166_Alpha2Code, countryCode, StringComparison.InvariantCultureIgnoreCase));
                if (country != null)
                {
                    if (!Settings.Site_IsUnWhitelabel && CountryManager.IsFrenchNational(country.InternalID))
                        return "europeanunion";
                    else
                        return country.GetCountryFlagName();
                }
                return string.Empty;
            };

            Func<string, string> getCountryName = delegate(string countryCode)
            {
                CountryInfo country = countries.FirstOrDefault(c => string.Equals(c.ISO_3166_Alpha2Code, countryCode, StringComparison.InvariantCultureIgnoreCase));
                if (country != null)
                {
                    if (!Settings.Site_IsUnWhitelabel && CountryManager.IsFrenchNational(country.InternalID))
                        return Metadata.Get("/Metadata/Country.EUROPEAN_UNION");
                    else
                        return country.DisplayName;
                }
                return string.Empty;
            };

            Func<CasinoEngine.WinnerInfo, string> getDisplayName = (CasinoEngine.WinnerInfo winner) =>
                {
                    return showCapitalName.Value ? string.Format(CultureInfo.InvariantCulture, "{0} {1}",                        winner.FirstName, winner.SurName.Truncate(1)) :                         (!string.IsNullOrWhiteSpace(winner.SurName) ? string.Format(CultureInfo.InvariantCulture, "{0}. {1}.", winner.FirstName.Truncate(1), winner.SurName.Truncate(1)) : string.Format(CultureInfo.InvariantCulture, "{0}.", winner.FirstName.Truncate(1)));
                };
            Func<CasinoEngine.WinnerInfo, string> getFormattedAmount = (CasinoEngine.WinnerInfo w) =>
            {
                if (needConvert.Value && dicExchangeRate != null)
                    return MoneyHelper.FormatWithCurrencySymbol(currency, MoneyHelper.TransformCurrency(w.Currency, currency, w.Amount, dicExchangeRate));
                else
                    return MoneyHelper.FormatWithCurrencySymbol(w.Currency, w.Amount);
            };

            DateTime basic = new DateTime(2010, 1, 1, 0, 0, 0);
            var result = winners.Select(w => new
            {
                ThumbnailUrl = w.Game.ThumbnailUrl,
                WinTimeTicks = (w.DateTime - basic).TotalSeconds,
                ElapsedSeconds = (int)Math.Truncate((DateTime.Now - w.DateTime).TotalSeconds),
                DisplayName = getDisplayName(w),
                FormattedAmount = getFormattedAmount(w),
                GameName = w.Game != null ? w.Game.ShortName : string.Empty,
                GameID = w.Game != null ? w.Game.ID : string.Empty,
                Url = w.Game != null ? (this.Url.RouteUrl("CasinoGame", new { @action = "Index", @gameID = w.Game.ID })) : string.Empty,
                CountryFlagName = getCountryFlagName(w.CountryCode),
                CountryName = getCountryName(w.CountryCode),
                OriginalCurrency = w.Currency
            }).ToArray();


            return this.Json(new { @success = true, @winners = result }, JsonRequestBehavior.AllowGet);
        }

        #region GetFrequentPlayerPoints
        public void GetFrequentPlayerPointsAsync()
        {
            CasinoEngine.CasinoEngineClient.GetFrequentPlayerPointsAsync(OnGetFrequentPlayerPoints);
            AsyncManager.OutstandingOperations.Increment();
        }

        private void OnGetFrequentPlayerPoints(bool success, string errorMessage, CasinoFPPClaimRec rec)
        {
            AsyncManager.Parameters["Success"] = success;
            AsyncManager.Parameters["ErrorMessage"] = errorMessage;
            AsyncManager.Parameters["CasinoFPPClaimRec"] = rec;
            AsyncManager.OutstandingOperations.Decrement();
        }

        public JsonResult GetFrequentPlayerPointsCompleted()
        {
            try
            {
                CasinoFPPClaimRec rec = AsyncManager.Parameters["CasinoFPPClaimRec"] as CasinoFPPClaimRec;
                if (rec != null)
                {
                    return this.Json(new
                    {
                        @success = AsyncManager.Parameters["Success"],
                        @error = AsyncManager.Parameters["ErrorMessage"],
                        @points = rec.Points,
                        @convertionAmount = rec.CfgConvertionAmount,
                        @convertionCurrency = rec.CfgConvertionCurrency,
                        @convertionMinClaimPoints = rec.CfgConvertionMinClaimPoints,
                        @convertionPoints = rec.CfgConvertionPoints,
                        @convertionType = rec.CfgConvertionType,
                    }, JsonRequestBehavior.AllowGet);
                }
                else
                {
                    return this.Json(new { @success = false, @error = "record is null" }, JsonRequestBehavior.AllowGet);
                }
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false, @error = GmException.TryGetFriendlyErrorMsg(ex) }, JsonRequestBehavior.AllowGet);
            }
        }
        #endregion


        #region ClaimFrequentPlayerPoints
        public void ClaimFrequentPlayerPointsAsync()
        {
            CasinoEngine.CasinoEngineClient.ClaimFrequentPlayerPointsAsync(OnClaimFrequentPlayerPoints);
            AsyncManager.OutstandingOperations.Increment();
        }

        private void OnClaimFrequentPlayerPoints(bool success, string errorMessage, CasinoFPPClaimRec rec)
        {
            AsyncManager.Parameters["Success"] = success;
            AsyncManager.Parameters["ErrorMessage"] = errorMessage;
            AsyncManager.Parameters["CasinoFPPClaimRec"] = rec;
            AsyncManager.OutstandingOperations.Decrement();
        }

        public JsonResult ClaimFrequentPlayerPointsCompleted()
        {
            try
            {
                CasinoFPPClaimRec rec = AsyncManager.Parameters["CasinoFPPClaimRec"] as CasinoFPPClaimRec;
                if (rec == null)
                    return this.Json(new
                    {
                        @success = false,
                        @error = AsyncManager.Parameters["ErrorMessage"],
                    }, JsonRequestBehavior.AllowGet);

                return this.Json(new
                {
                    @success = AsyncManager.Parameters["Success"],
                    @error = AsyncManager.Parameters["ErrorMessage"],
                    @converted = rec.Converted,
                    @remainder = rec.Remainder,
                    @rewardCurrency = rec.RewardCurrency,
                    @rewardAmount = rec.RewardAmount,
                    @convertionAmount = rec.CfgConvertionAmount,
                    @convertionCurrency = rec.CfgConvertionCurrency,
                    @convertionMinClaimPoints = rec.CfgConvertionMinClaimPoints,
                    @convertionPoints = rec.CfgConvertionPoints,
                    @convertionType = rec.CfgConvertionType,
                }, JsonRequestBehavior.AllowGet);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false, @error = GmException.TryGetFriendlyErrorMsg(ex) }, JsonRequestBehavior.AllowGet);
            }
        }
        #endregion

    }
}
