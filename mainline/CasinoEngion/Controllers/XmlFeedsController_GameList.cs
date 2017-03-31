using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Globalization;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Web;
using System.Web.Mvc;

using CE.db;
using CE.db.Accessor;
using CE.Extensions;
using CE.Utils;
using GamMatrixAPI;

namespace CasinoEngine.Controllers
{
    public partial class XmlFeedsController : ServiceControllerBase
    {
        private const string GAME_LIST_CACHE_KEY_FORMAT = "{0}{1}_{2}_{3}_{4}_{5}_{6}_{7}_{8}";
        private const string TABLE_LIST_CACHE_KEY_FORMAT = "{0}{1}_{2}_{3}_{4}";
        private const string GAME_POPULARITY_CACHE_KEY_FORMAT = "{0}{1}_{2}";

        #region Common
        private List<ceContentProviderBase> _ContentProviders = null;
        private List<ceContentProviderBase> ContentProviders
        {
            get {
                if (_ContentProviders == null)
                {
                    _ContentProviders = ContentProviderAccessor.GetAll(DomainManager.CurrentDomainID, Constant.SystemDomainID);
                }
                return _ContentProviders;
            }
        }
        #endregion

        #region GameList
        /// <summary>
        /// Game List
        /// </summary>
        /// <param name="apiUsername"></param>
        /// <param name="tags"></param>
        /// <param name="categories"></param>
        /// <param name="platforms"></param>
        /// <param name="vendors"></param>
        /// <returns></returns>
        [HttpGet]
        public ContentResult GameList(string apiUsername
            , string tags
            , string categories
            , string platforms
            , string vendors
            , string ids
            , string slugs
            , string countryCode 
            , bool? includeMoreFields
            , bool allowCache = true 
            ,int gameType = 0
            )
        {
 
            if (string.IsNullOrWhiteSpace(apiUsername))
                return WrapResponse(ResultCode.Error_InvalidParameter, string.Format("Operator [{0}] is NULL!", apiUsername));

            var domains = DomainManager.GetApiUsername_DomainDictionary();
            ceDomainConfigEx domain;
            if (!domains.TryGetValue(apiUsername.Trim(), out domain))
                return WrapResponse(ResultCode.Error_InvalidParameter, "Operator is invalid!");

            if (!IsWhitelistedIPAddress(domain, Request.GetRealUserAddress()))
                return WrapResponse(ResultCode.Error_BlockedIPAddress, string.Format("IP Address [{0}] is denied!", Request.GetRealUserAddress()));

            DomainManager.CurrentDomainID = domain.DomainID;
            try
            {
                if (!includeMoreFields.HasValue)
                    includeMoreFields = false;

                string cacheKey = string.Format(GAME_LIST_CACHE_KEY_FORMAT
                    , Constant.GameListCachePrefix
                    , domain.DomainID
                    , tags
                    , categories
                    , platforms
                    , vendors
                    , ids
                    , includeMoreFields.Value
                    , slugs
                    );
                StringBuilderCache cache = HttpRuntime.Cache[cacheKey] as StringBuilderCache;
                if (cache == null || cache.IsExpried || !allowCache)
                {
                    //List<ceCasinoGameBaseEx> games = CasinoGameAccessor.GetDomainGames(domain.DomainID, true, true);
                    List<ceCasinoGameBaseEx> games = CacheManager.GetGameList(domain.DomainID, true, true, allowCache);

                    if (!string.IsNullOrWhiteSpace(vendors))
                    {
                        List<string> filteredVendors = vendors.Split(',')
                            .Where(c => !string.IsNullOrWhiteSpace(c))
                            .Select(c => c.Trim().ToUpperInvariant())
                            .ToList();
                        games = games.Where(g => filteredVendors.Contains(g.VendorID.ToString(), StringComparer.InvariantCultureIgnoreCase))
                            .ToList();
                    }

                    if (!string.IsNullOrWhiteSpace(ids))
                    {
                        List<long> filteredIDs = ids.Split(',')
                            .Where(c => Regex.IsMatch(c, @"^\d+$", RegexOptions.Compiled))
                            .Select(c => long.Parse(c))
                            .ToList();
                        games = games.Where(g => filteredIDs.Contains(g.ID))
                            .ToList();
                    }

                    if (!string.IsNullOrWhiteSpace(slugs))
                    {
                        List<string> filteredSlugs = slugs.Split(',').ToList();
                        games = games.Where(g => !string.IsNullOrEmpty(g.Slug) && filteredSlugs.Contains(g.Slug))
                            .ToList();
                    }

                    if (!string.IsNullOrWhiteSpace(categories))
                        games = games.Where(g => HasIntersection(categories, g.GameCategories)).ToList();

                    if (!string.IsNullOrWhiteSpace(tags))
                        games = games.Where(g => HasIntersection(tags, g.Tags)).ToList();

                    if (!string.IsNullOrWhiteSpace(platforms))
                        games = games.Where(g => HasIntersection(platforms, g.ClientCompatibility)).ToList();

                    StringBuilder sb = GetGameListXml(domain, games, includeMoreFields.Value , allowCache, gameType);
                    cache = new StringBuilderCache(sb, 36000);
                    CacheManager.AddCache(cacheKey, cache);
                }

                return WrapResponse(ResultCode.Success, string.Empty, cache.Value);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return WrapResponse(ResultCode.Error_SystemFailure, ex.Message);
            }
        }

        

        private StringBuilder GetGameListXml(ceDomainConfigEx domain, List<ceCasinoGameBaseEx> games, bool includeMoreFields ,bool allowCache = true, int gameType = 0)
        {
            StringBuilder data = new StringBuilder();
            data.AppendLine("<gameList>");

            CasinoVendorAccessor cva = CasinoVendorAccessor.CreateInstance<CasinoVendorAccessor>();
            Dictionary<VendorID, string> dic = cva.GetRestrictedTerritoriesDictionary(DomainManager.CurrentDomainID); 
            Dictionary<VendorID, string> dicLanguages = cva.GetLanguagesDictionary(DomainManager.CurrentDomainID);
            Dictionary<VendorID, string> dicCurrencies = cva.GetCurrenciesDictionary(DomainManager.CurrentDomainID);
            //Dictionary<long, List<dwGamePopularity>> popularities = GetGamePopularityV2(domain , allowCache, gameType);
            Dictionary<long, long> popularities = GetGamePopularity(domain);
            foreach (ceCasinoGameBaseEx game in games)
            {
                if (game.IsLiveCasinoGame())
                    continue;

                long popularity = 0L;
                popularities.TryGetValue(game.ID, out popularity);

                string loaderUrl = GetLoaderUrl(domain, game.ID, game.Slug, game.VendorID) + "/"; 
                string helperUrl = GetHelpUrl(domain, game);

                string restrictedTerritories;
                dic.TryGetValue(game.VendorID, out restrictedTerritories);

                string vendorLanguages;
                dicLanguages.TryGetValue(game.VendorID, out vendorLanguages);

                string vendorCurrencies;
                dicCurrencies.TryGetValue(game.VendorID, out vendorCurrencies);

                data.AppendLine("\t<game>");
                data.AppendFormat("\t\t<id>{0}</id>\n", game.ID);
                
                PopulateGameBasicProperties(data
                    , domain
                    , game
                    , popularity
                    , domain.EnableScalableThumbnail
                    , includeMoreFields
                    , restrictedTerritories
                    , loaderUrl
                    , helperUrl
                    );

                data.Append("\t\t<platforms>");
                string[] platforms = game.ClientCompatibility.DefaultIfNullOrEmpty(string.Empty).Split(',');
                if (platforms.Contains("PC") && !platforms.Contains("Windows81"))
                {
                    data.AppendFormat("<platform>Windows81</platform>");
                }
                foreach (string platform in platforms)
                {
                    if (!string.IsNullOrWhiteSpace(platform))
                        data.AppendFormat("<platform>{0}</platform>", platform.SafeHtmlEncode());
                }
                data.Append("</platforms>\n");

                data.Append("\t\t<languages>");

                string[] languages = null;
                string strLanguages = game.Languages.DefaultIfNullOrEmpty(string.Empty);
                if ("All".Equals(strLanguages))
                {
                    strLanguages = Language.getAllLanguagesToString();
                }
                else if (string.IsNullOrEmpty(strLanguages))
                {
                    strLanguages = vendorLanguages;
                }
                if (!string.IsNullOrWhiteSpace(strLanguages))
                {
                    languages = strLanguages.Split(",".ToArray(), StringSplitOptions.RemoveEmptyEntries);
                    foreach (string language in languages)
                    {
                        data.AppendFormat("<language>{0}</language>", language.SafeHtmlEncode());
                    }

                }
                data.Append("</languages>\n");

                data.Append("\t\t<currencies>");
                string[] currencies = null;
                string strCurrencies = vendorCurrencies.DefaultIfNullOrEmpty(string.Empty);
                if (!string.IsNullOrWhiteSpace(strCurrencies))
                {
                    currencies = strCurrencies.Split(",".ToArray(), StringSplitOptions.RemoveEmptyEntries);
                    foreach (string currency in currencies)
                    {
                        data.AppendFormat("<currency>{0}</currency>", currency.SafeHtmlEncode());
                    }

                }
                data.Append("</currencies>\n");

                Dictionary<string, CasinoGameLimitAmount> items = GetCurrencyLimitAmountForGame(game);
                if (items.Count > 0)
                {
                    data.Append("\t\t<limits>\n");
                    foreach (var item in items)
                    {
                        data.AppendFormat("\t\t\t<limit currency=\"{0}\">\n", item.Key.SafeHtmlEncode());
                        data.AppendFormat("\t\t\t\t<min>{0:0.##}</min>\n", item.Value.MinAmount);
                        data.AppendFormat("\t\t\t\t<max>{0:0.##}</max>\n", item.Value.MaxAmount);
                        data.Append("\t\t\t</limit>\n");
                    }
                    data.Append("\t\t</limits>\n");
                }

                data.AppendLine("\t</game>");
            }


            data.AppendLine("</gameList>");
            return data;
        }
        #endregion


        #region LiveCasinoTableList
        /// <summary>
        /// Game List
        /// </summary>
        /// <param name="apiUsername"></param>
        /// <param name="tags"></param>
        /// <param name="categories"></param>
        /// <param name="platforms"></param>
        /// <param name="vendors"></param>
        /// <returns></returns>
        [HttpGet]
        public ContentResult LiveCasinoTableList(string apiUsername
            , string platforms
            , string vendors
            , bool? includeMoreFields
            )
        {
            if (string.IsNullOrWhiteSpace(apiUsername))
                return WrapResponse(ResultCode.Error_InvalidParameter, "Operator is NULL!");

            var domains = DomainManager.GetApiUsername_DomainDictionary();
            ceDomainConfigEx domain;
            if (!domains.TryGetValue(apiUsername.Trim(), out domain))
                return WrapResponse(ResultCode.Error_InvalidParameter, "Operator is invalid!");

            if (!IsWhitelistedIPAddress(domain, Request.GetRealUserAddress()))
                return WrapResponse(ResultCode.Error_BlockedIPAddress, string.Format("IP Address [{0}] is denied!", Request.GetRealUserAddress()));

            DomainManager.CurrentDomainID = domain.DomainID;
            try
            {
                if (!includeMoreFields.HasValue)
                    includeMoreFields = false;
                string cacheKey = string.Format(TABLE_LIST_CACHE_KEY_FORMAT
                    , Constant.LiveCasinoTableListCachePrefix
                    , domain.DomainID
                    , platforms
                    , vendors
                    , includeMoreFields.Value
                    );
                StringBuilderCache cache = HttpRuntime.Cache[cacheKey] as StringBuilderCache;
                if (cache == null || cache.IsExpried)
                {
                    //List<ceCasinoGameBaseEx> games = CasinoGameAccessor.GetDomainGames(domain.DomainID, true, true);
                    List<ceCasinoGameBaseEx> games = CacheManager.GetGameList(domain.DomainID);

                    if (!string.IsNullOrWhiteSpace(vendors))
                    {
                        List<string> filteredVendors = vendors.Split(',')
                            .Where(c => !string.IsNullOrWhiteSpace(c))
                            .Select(c => c.Trim().ToUpperInvariant())
                            .ToList();
                        games = games.Where(g => filteredVendors.Contains(g.VendorID.ToString(), StringComparer.InvariantCultureIgnoreCase))
                            .ToList();
                    }

                    if (!string.IsNullOrWhiteSpace(platforms))
                        games = games.Where(g => HasIntersection(platforms, g.ClientCompatibility)).ToList();

                    cache = new StringBuilderCache(GetLiveCasinoTableListXml(domain, games, includeMoreFields.Value), 36000);
                    CacheManager.AddCache(cacheKey, cache);
                }

                return WrapResponse(ResultCode.Success, string.Empty, cache.Value);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return WrapResponse(ResultCode.Error_SystemFailure, ex.Message);
            }
        }

        private StringBuilder GetLiveCasinoTableListXml(ceDomainConfigEx domain, List<ceCasinoGameBaseEx> games, bool includeMoreFields)
        {
            StringBuilder data = new StringBuilder();
            data.AppendLine("<tableList>");

            CasinoVendorAccessor cva = CasinoVendorAccessor.CreateInstance<CasinoVendorAccessor>();
            Dictionary<VendorID, string> dic = cva.GetRestrictedTerritoriesDictionary(DomainManager.CurrentDomainID);

            List<ceLiveCasinoTableBaseEx> allTables = LiveCasinoTableAccessor.GetDomainTables(domain.DomainID, null, true, true);

            Dictionary<long, long> popularities = GetGamePopularity(domain);
            foreach (ceCasinoGameBaseEx game in games)
            {
                List<ceLiveCasinoTableBaseEx> tables = allTables.Where(t => t.CasinoGameBaseID == game.ID && t.Enabled).ToList();

                if (tables.Count == 0)
                    continue;

                long popularity = 0L;
                popularities.TryGetValue(game.ID, out popularity);
                 
                string helperUrl = GetHelpUrl(domain, game);

                string restrictedTerritories;
                dic.TryGetValue(game.VendorID, out restrictedTerritories);

                foreach (ceLiveCasinoTableBaseEx table in tables)
                {
                    string loaderUrl = string.Format(CultureInfo.InvariantCulture, "{0}/?tableID={1:D}"
                        , GetLoaderUrl(domain, game.ID, game.Slug, game.VendorID)
                        , table.ID
                        );

                    data.AppendLine("\t<table>");

                    bool isOpen = table.IsOpen(domain.DomainID);

                    if (!string.IsNullOrWhiteSpace(table.TableName))
                    {
                        game.GameName = table.TableName;
                        game.ShortName = table.TableName;
                    }

                    game.Thumbnail = table.Thumbnail;

                    data.AppendFormat("\t\t<id>{0:D}</id>\n", table.ID);
                    data.AppendFormat("\t\t<category>{0}</category>\n", table.Category.SafeHtmlEncode());
                    data.AppendFormat("\t\t<gameId>{0}</gameId>\n", game.ID);
                    data.AppendFormat("\t\t<isOpen>{0}</isOpen>\n", isOpen ? "true" : "false");
                    data.AppendFormat("\t\t<vipTable>{0}</vipTable>\n", table.VIPTable ? "true" : "false");
                    data.AppendFormat("\t\t<newTable>{0}</newTable>\n", (table.NewTable && table.NewTableExpirationDate > DateTime.Now.Date) ? "true" : "false");
                    data.AppendFormat("\t\t<turkishTable>{0}</turkishTable>\n", table.TurkishTable ? "true" : "false");
                    data.AppendFormat("\t\t<betBehindAvailable>{0}</betBehindAvailable>\n", table.BetBehindAvailable ? "true" : "false");
                    data.AppendFormat("\t\t<excludeFromRandomLaunch>{0}</excludeFromRandomLaunch>\n", table.ExcludeFromRandomLaunch ? "true" : "false");
                    data.AppendFormat("\t\t<seatsUnlimited>{0}</seatsUnlimited>\n", table.SeatsUnlimited ? "true" : "false");
                    data.AppendFormat("\t\t<dealerGender>{0}</dealerGender>\n", table.DealerGender);
                    data.AppendFormat("\t\t<dealerOrigin>{0}</dealerOrigin>\n", table.DealerOrigin);

                    if (!string.IsNullOrWhiteSpace(table.OpenHoursTimeZone))
                    {
                        data.Append("\t\t<openingTime>\n");
                        if (table.OpenHoursStart != table.OpenHoursEnd)
                        {
                            data.Append("\t\t\t<is24HoursOpen>false</is24HoursOpen>\n");
                            data.AppendFormat("\t\t\t<timeZone>{0}</timeZone>\n", table.OpenHoursTimeZone.SafeHtmlEncode());
                            data.AppendFormat("\t\t\t<startTime>{0:D2}:{1:D2}</startTime>\n", table.OpenHoursStart / 60, table.OpenHoursStart % 60);
                            data.AppendFormat("\t\t\t<endTime>{0:D2}:{1:D2}</endTime>\n", table.OpenHoursEnd / 60, table.OpenHoursEnd % 60);
                        }
                        else
                        {
                            data.Append("\t\t\t<is24HoursOpen>true</is24HoursOpen>\n");
                        }
                        data.Append("\t\t</openingTime>\n");
                    }

                    if (table.Limit.Type != LiveCasinoTableLimitType.None)
                    {
                        Dictionary<string, LimitAmount> items = GetCurrencyLimitAmount(table);
                        if (items.Count > 0)
                        {
                            data.Append("\t\t<limits>\n");
                            foreach (var item in items)
                            {
                                data.AppendFormat("\t\t\t<limit currency=\"{0}\">\n", item.Key.SafeHtmlEncode());
                                data.AppendFormat("\t\t\t\t<min>{0:0.##}</min>\n", item.Value.MinAmount);
                                data.AppendFormat("\t\t\t\t<max>{0:0.##}</max>\n", item.Value.MaxAmount);
                                data.Append("\t\t\t</limit>\n");
                            }
                            data.Append("\t\t</limits>\n");
                        }
                    }

                    data.Append("\t\t<platforms>");
                    string[] platforms = (table.ClientCompatibility ?? string.Empty).Split( new char[] { ',' }, StringSplitOptions.RemoveEmptyEntries);
                    if (platforms == null || platforms.Length == 0)
                        platforms = (game.ClientCompatibility ?? string.Empty).Split(new char[] { ',' }, StringSplitOptions.RemoveEmptyEntries);
                    foreach (string platform in platforms)
                    {
                        if (!string.IsNullOrWhiteSpace(platform))
                            data.AppendFormat("<platform>{0}</platform>", platform.SafeHtmlEncode());
                    }
                    data.Append("</platforms>\n"); 
                    PopulateGameBasicProperties(data
                        , domain
                        , game
                        , popularity
                        , false
                        , includeMoreFields
                        , restrictedTerritories
                        , loaderUrl
                        , helperUrl
                        ); 
                    data.AppendLine("\t</table>");
                }
            }


            data.AppendLine("</tableList>");
            return data;
        }


        private Dictionary<string, LimitAmount> GetCurrencyLimitAmount(ceLiveCasinoTableBaseEx table)
        {
            Dictionary<string, LimitAmount> dic = new Dictionary<string,LimitAmount>(StringComparer.InvariantCultureIgnoreCase);
            CurrencyData [] currencies = GamMatrixClient.GetSupportedCurrencies();
            if (table.Limit.Type == LiveCasinoTableLimitType.AutoConvertBasingOnCurrencyRate)
            {
                foreach (CurrencyData currency in currencies)
                {
                    dic[currency.ISO4217_Alpha] = new LimitAmount()
                    {
                        MinAmount = GamMatrixClient.TransformCurrency( table.Limit.BaseCurrency, currency.ISO4217_Alpha, table.Limit.BaseLimit.MinAmount),
                        MaxAmount = GamMatrixClient.TransformCurrency(table.Limit.BaseCurrency, currency.ISO4217_Alpha, table.Limit.BaseLimit.MaxAmount),
                    };
                }
            }
            else if (table.Limit.Type == LiveCasinoTableLimitType.SameForAllCurrency)
            {
                foreach (CurrencyData currency in currencies)
                {
                    dic[currency.ISO4217_Alpha] = new LimitAmount()
                    {
                        MinAmount = table.Limit.BaseLimit.MinAmount,
                        MaxAmount = table.Limit.BaseLimit.MaxAmount,
                    };
                }
            }
            else if (table.Limit.Type == LiveCasinoTableLimitType.SpecificForEachCurrency)
            {
                foreach (var limit in table.Limit.CurrencyLimits)
                {
                    if (limit.Value.MaxAmount == 0.00M)
                        continue;

                    dic[limit.Key] = new LimitAmount()
                    {
                        MinAmount = limit.Value.MinAmount,
                        MaxAmount = limit.Value.MaxAmount,
                    };
                }
            }

            return dic;
        }
        private Dictionary<string, CasinoGameLimitAmount> GetCurrencyLimitAmountForGame(ceCasinoGameBaseEx casinoGame)
        {
            Dictionary<string, CasinoGameLimitAmount> dic = new Dictionary<string, CasinoGameLimitAmount>(StringComparer.InvariantCultureIgnoreCase);
            if (!string.IsNullOrWhiteSpace(casinoGame.LimitationXml))
            {
                Dictionary<string, CasinoGameLimitAmount> limitAmounts = Newtonsoft.Json.JsonConvert.DeserializeObject<Dictionary<string, CasinoGameLimitAmount>>(casinoGame.LimitationXml);
                foreach (string currency in limitAmounts.Keys)
                {
                    if (limitAmounts[currency].MaxAmount == 0.00M)
                        continue;

                    dic.Add(currency, new CasinoGameLimitAmount()
                    {
                        MinAmount = limitAmounts[currency].MinAmount,
                        MaxAmount = limitAmounts[currency].MaxAmount,
                    });
                }
            }

            return dic;
        }
        #endregion

        private void PopulateGameBasicProperties(StringBuilder data
           , ceDomainConfigEx domain
           , ceCasinoGameBaseEx game
           , long popularity
           , bool enableScalableThumbnail
           , bool includeMoreFields
           , string restrictedTerritories
           , string loaderUrl
           , string helpUrl
           )
        {
            data.AppendFormat("\t\t<vendor>{0}</vendor>\n", Enum.GetName(typeof(VendorID), game.VendorID).SafeHtmlEncode());

            VendorID originalVendorID = game.OriginalVendorID;
            if (originalVendorID == VendorID.Unknown)
                originalVendorID = game.VendorID;
            data.AppendFormat("\t\t<originalVendor>{0}</originalVendor>\n", Enum.GetName(typeof(VendorID), originalVendorID).SafeHtmlEncode());

            if (game.ContentProviderID > 0 && ContentProviders.Exists(p => p.ID == game.ContentProviderID))
            {
                ceContentProviderBase provider = ContentProviders.FirstOrDefault(p => p.ID == game.ContentProviderID);
                data.AppendFormat("\t\t<contentProvider>{0}</contentProvider>\n", provider.Identifying.SafeHtmlEncode());
            }
            else
                data.AppendFormat("\t\t<contentProvider>{0}</contentProvider>\n", Enum.GetName(typeof(VendorID), game.VendorID).SafeHtmlEncode());

            data.AppendFormat("\t\t<name>{0}</name>\n", game.GameName.SafeHtmlEncode());
            if (!string.IsNullOrEmpty(game.Slug))
                data.AppendFormat("\t\t<slug>{0}</slug>\n", game.Slug.SafeHtmlEncode());
            data.AppendFormat("\t\t<shortName>{0}</shortName>\n", game.ShortName.SafeHtmlEncode());
            data.AppendFormat("\t\t<description>{0}</description>\n", game.Description.SafeHtmlEncode());
            data.AppendFormat("\t\t<anonymousFunMode>{0}</anonymousFunMode>\n", game.AnonymousFunMode.ToString().ToLowerInvariant());
            data.AppendFormat("\t\t<funMode>{0}</funMode>\n", game.FunMode.ToString().ToLowerInvariant());
            data.AppendFormat("\t\t<realMode>{0}</realMode>\n", game.RealMode.ToString().ToLowerInvariant());
            data.AppendFormat("\t\t<newGame>{0}</newGame>\n", (game.NewGame && game.NewGameExpirationDate > DateTime.Now.Date).ToString().ToLowerInvariant());
            data.AppendFormat("\t\t<license>{0}</license>\n", game.License.ToString().ToLowerInvariant());
            data.AppendFormat("\t\t<popularity>{0}</popularity>\n", (popularity + 1) * game.PopularityCoefficient);

            if (game.Width > 0 && game.Height > 0)
            {
                data.AppendFormat("\t\t<width>{0}</width>\n", game.Width);
                data.AppendFormat("\t\t<height>{0}</height>\n", game.Height);
            }

            data.AppendFormat("\t\t<thumbnail>");
            if (!enableScalableThumbnail)
            {
                if (!string.IsNullOrWhiteSpace(game.Thumbnail))
                    data.Append(string.Format("//{0}{1}", domain.GameResourceDomain, game.Thumbnail).SafeHtmlEncode());
            }
            else
            {
                if (!string.IsNullOrWhiteSpace(game.ScalableThumbnailPath))
                    data.Append(string.Format("//{0}{1}", domain.GameResourceDomain, game.ScalableThumbnailPath).SafeHtmlEncode());
            }
            data.Append("</thumbnail>\n");

            data.AppendFormat("\t\t<logo>");
            if (!string.IsNullOrWhiteSpace(game.Logo))
                data.Append(string.Format("//{0}{1}", domain.GameResourceDomain, game.Logo).SafeHtmlEncode());
            data.Append("</logo>\n");

            data.AppendFormat("\t\t<backgroundImage>");
            if (!string.IsNullOrWhiteSpace(game.BackgroundImage))
                data.Append(string.Format("//{0}{1}", domain.GameResourceDomain, game.BackgroundImage).SafeHtmlEncode());
            data.Append("</backgroundImage>\n");

            if (!string.IsNullOrEmpty(game.Icon))
            {
                data.AppendFormat("\t\t<icons format=\"//{0}{1}\">\n"
                    , domain.GameResourceDomain
                    , game.Icon.SafeHtmlEncode()
                    );
                int[] sizes = new int[] { 114, 88, 72, 57, 44, 22 };
                foreach (int size in sizes)
                {
                    data.AppendFormat("\t\t\t<icon size=\"{2}\">//{0}{1}</icon>"
                        , domain.GameResourceDomain
                        , string.Format(game.Icon, size).SafeHtmlEncode()
                        , size
                        );
                }
                data.AppendLine("\t\t</icons>");
            }


            data.AppendFormat("\t\t<url>{0}</url>\n", loaderUrl.SafeHtmlEncode());

            if (!string.IsNullOrEmpty(helpUrl))
                data.AppendFormat("\t\t<helpUrl>{0}/</helpUrl>\n", helpUrl.SafeHtmlEncode());

            data.Append("\t\t<categories>");
            string[] categories = game.GameCategories.DefaultIfNullOrEmpty(string.Empty).Split(',');
            foreach (string category in categories)
            {
                if (!string.IsNullOrWhiteSpace(category))
                    data.AppendFormat("<category>{0}</category>", category.SafeHtmlEncode());
            }
            data.Append("</categories>\n");

            data.Append("\t\t<tags>");
            string newTags = RemoveDuplicateData(game.Tags);
            string[] tags = newTags.DefaultIfNullOrEmpty(string.Empty).Split(',');
            foreach (string tag in tags)
            {
                if (!string.IsNullOrWhiteSpace(tag))
                    data.AppendFormat("<tag>{0}</tag>", tag.SafeHtmlEncode());
            }
            data.Append("</tags>\n");




            data.Append("\t\t<restrictedTerritories>");
            {
                string[] vendorTerritories = null;
                if (!string.IsNullOrWhiteSpace(restrictedTerritories))
                {
                    vendorTerritories = restrictedTerritories.Split(',');
                    foreach (string territory in vendorTerritories)
                    {
                        if (!string.IsNullOrWhiteSpace(territory))
                            data.AppendFormat("<restrictedTerritory>{0}</restrictedTerritory>", territory.SafeHtmlEncode());
                    }
                }

                if (!string.IsNullOrWhiteSpace(game.RestrictedTerritories))
                {
                    string[] gameTerritories = game.RestrictedTerritories.Split(',').Where(t => !string.IsNullOrWhiteSpace(t)).ToArray();
                    foreach (string territory in gameTerritories)
                    {
                        if (vendorTerritories != null && vendorTerritories.Contains(territory))
                            continue;

                        data.AppendFormat("<restrictedTerritory>{0}</restrictedTerritory>", territory.SafeHtmlEncode());
                    }
                }
            }
            data.Append("</restrictedTerritories>\n");


            if (includeMoreFields)
            {
                data.AppendFormat("\t\t<thirdPartyFee>{0:f5}</thirdPartyFee>\n", game.ThirdPartyFee);
                data.AppendFormat("\t\t<theoreticalPayOut>{0:f5}</theoreticalPayOut>\n", game.TheoreticalPayOut);
                data.AppendFormat("\t\t<bonusContribution>{0:f5}</bonusContribution>\n", game.BonusContribution);
                data.AppendFormat("\t\t<jackpotContribution>{0:f5}</jackpotContribution>\n", game.JackpotContribution);
                data.AppendFormat("\t\t<fpp>{0:f5}</fpp>\n", game.FPP);
                data.AppendFormat("\t\t<reportCategory>{0}</reportCategory>\n", game.ReportCategory.SafeHtmlEncode());
                data.AppendFormat("\t\t<invoicingGroup>{0:f}</invoicingGroup>\n", game.InvoicingGroup.SafeHtmlEncode());
            }
        }
        private string RemoveDuplicateData(string oldData)
        {
            if (!string.IsNullOrWhiteSpace(oldData))
            {
                List<string> oldList = new List<string>(oldData.Split(new string[] { "," }, StringSplitOptions.RemoveEmptyEntries));
                var newList = (from a in oldList select a).Distinct().OrderBy(g => g);
                return string.Join(",", newList.ToArray());
            }
            else
            {
                return null;
            }
        }
        // PopulateGameBasicProperties
        private void PopulateGameBasicPropertiesV2(StringBuilder data
            , ceDomainConfigEx domain
            , ceCasinoGameBaseEx game
            , List<dwGamePopularity> popularity
            , bool enableScalableThumbnail
            , bool includeMoreFields
            , string restrictedTerritories
            , string loaderUrl
            , string helpUrl
            )
        {
            data.AppendFormat("\t\t<vendor>{0}</vendor>\n", Enum.GetName(typeof(VendorID), game.VendorID).SafeHtmlEncode());

            VendorID originalVendorID = game.OriginalVendorID;
            if (originalVendorID == VendorID.Unknown)
                originalVendorID = game.VendorID;
            data.AppendFormat("\t\t<originalVendor>{0}</originalVendor>\n", Enum.GetName(typeof(VendorID), originalVendorID).SafeHtmlEncode());

            if (game.ContentProviderID > 0 && ContentProviders.Exists(p => p.ID == game.ContentProviderID))
            {
                ceContentProviderBase provider = ContentProviders.FirstOrDefault(p => p.ID == game.ContentProviderID);
                data.AppendFormat("\t\t<contentProvider>{0}</contentProvider>\n", provider.Identifying.SafeHtmlEncode());

                //data.AppendFormat("\t\t<contentProviderLogo>");
                //if (!string.IsNullOrWhiteSpace(provider.Logo))
                //    data.Append(string.Format("//{0}{1}", domain.GameResourceDomain, provider.Logo).SafeHtmlEncode());
                //data.Append("</contentProviderLogo>\n");
            }
            else
                data.AppendFormat("\t\t<contentProvider>{0}</contentProvider>\n", Enum.GetName(typeof(VendorID), game.VendorID).SafeHtmlEncode());

            data.AppendFormat("\t\t<name>{0}</name>\n", game.GameName.SafeHtmlEncode());
            if (!string.IsNullOrEmpty(game.Slug))
                data.AppendFormat("\t\t<slug>{0}</slug>\n", game.Slug.SafeHtmlEncode());
            data.AppendFormat("\t\t<shortName>{0}</shortName>\n", game.ShortName.SafeHtmlEncode());
            data.AppendFormat("\t\t<description>{0}</description>\n", game.Description.SafeHtmlEncode());
            data.AppendFormat("\t\t<anonymousFunMode>{0}</anonymousFunMode>\n", game.AnonymousFunMode.ToString().ToLowerInvariant());
            data.AppendFormat("\t\t<funMode>{0}</funMode>\n", game.FunMode.ToString().ToLowerInvariant());
            data.AppendFormat("\t\t<realMode>{0}</realMode>\n", game.RealMode.ToString().ToLowerInvariant());
            data.AppendFormat("\t\t<newGame>{0}</newGame>\n", (game.NewGame && game.NewGameExpirationDate > DateTime.Now.Date).ToString().ToLowerInvariant());
            data.AppendFormat("\t\t<license>{0}</license>\n", game.License.ToString().ToLowerInvariant());
            //data.AppendFormat("\t\t<popularity>{0}</popularity>\n", (popularity + 1) * game.PopularityCoefficient);
            if ((popularity != null && popularity.Count > 0 && game != null))
            {
                data.AppendFormat("\t\t<popularity>{0}</popularity>\n", (popularity.Sum(p => p.Popularity) + 1) * game.PopularityCoefficient);

            }
            else
            {
                data.AppendFormat("\t\t<popularity>{0}</popularity>\n", "1");
                //data.Append("\t\t<popularityDetails/>\n");
            }
            if (game.Width > 0 && game.Height > 0)
            {
                data.AppendFormat("\t\t<width>{0}</width>\n", game.Width);
                data.AppendFormat("\t\t<height>{0}</height>\n", game.Height);
            }

            data.AppendFormat("\t\t<thumbnail>");
            if (!enableScalableThumbnail)
            {
                if (!string.IsNullOrWhiteSpace(game.Thumbnail))
                    data.Append(string.Format("//{0}{1}", domain.GameResourceDomain, game.Thumbnail).SafeHtmlEncode());
            }
            else
            {
                if (!string.IsNullOrWhiteSpace(game.ScalableThumbnailPath))
                    data.Append(string.Format("//{0}{1}", domain.GameResourceDomain, game.ScalableThumbnailPath).SafeHtmlEncode());
            }
            data.Append("</thumbnail>\n");

            data.AppendFormat("\t\t<logo>");
            if (!string.IsNullOrWhiteSpace(game.Logo))
                data.Append(string.Format("//{0}{1}", domain.GameResourceDomain, game.Logo).SafeHtmlEncode());
            data.Append("</logo>\n");

            data.AppendFormat("\t\t<backgroundImage>");
            if (!string.IsNullOrWhiteSpace(game.BackgroundImage))
                data.Append(string.Format("//{0}{1}", domain.GameResourceDomain, game.BackgroundImage).SafeHtmlEncode());
            data.Append("</backgroundImage>\n");

            if (!string.IsNullOrEmpty(game.Icon))
            {
                data.AppendFormat("\t\t<icons format=\"//{0}{1}\">\n"
                    , domain.GameResourceDomain
                    , game.Icon.SafeHtmlEncode()
                    );
                int[] sizes = new int[] { 114, 88, 72, 57, 44, 22 };
                foreach (int size in sizes)
                {
                    data.AppendFormat("\t\t\t<icon size=\"{2}\">//{0}{1}</icon>"
                        , domain.GameResourceDomain
                        , string.Format(game.Icon, size).SafeHtmlEncode()
                        , size
                        );
                }
                data.AppendLine("\t\t</icons>");
            }


            data.AppendFormat("\t\t<url>{0}</url>\n", loaderUrl.SafeHtmlEncode());

            if (!string.IsNullOrEmpty(helpUrl))
                data.AppendFormat("\t\t<helpUrl>{0}/</helpUrl>\n", helpUrl.SafeHtmlEncode());

            data.Append("\t\t<categories>");
            string[] categories = game.GameCategories.DefaultIfNullOrEmpty(string.Empty).Split(',');
            foreach (string category in categories)
            {
                if (!string.IsNullOrWhiteSpace(category))
                    data.AppendFormat("<category>{0}</category>", category.SafeHtmlEncode());
            }
            data.Append("</categories>\n");

            data.Append("\t\t<tags>");
            string[] tags = game.Tags.DefaultIfNullOrEmpty(string.Empty).Split(',');
            foreach (string tag in tags)
            {
                if (!string.IsNullOrWhiteSpace(tag))
                    data.AppendFormat("<tag>{0}</tag>", tag.SafeHtmlEncode());
            }
            data.Append("</tags>\n");




            data.Append("\t\t<restrictedTerritories>");
            {
                string[] vendorTerritories = null;
                if (!string.IsNullOrWhiteSpace(restrictedTerritories))
                {
                    vendorTerritories = restrictedTerritories.Split(',');
                    foreach (string territory in vendorTerritories)
                    {
                        if (!string.IsNullOrWhiteSpace(territory))
                            data.AppendFormat("<restrictedTerritory>{0}</restrictedTerritory>", territory.SafeHtmlEncode());
                    }
                }

                if (!string.IsNullOrWhiteSpace(game.RestrictedTerritories))
                {
                    string[] gameTerritories = game.RestrictedTerritories.Split(',').Where(t => !string.IsNullOrWhiteSpace(t)).ToArray();
                    foreach (string territory in gameTerritories)
                    {
                        if (vendorTerritories != null && vendorTerritories.Contains(territory))
                            continue;

                        data.AppendFormat("<restrictedTerritory>{0}</restrictedTerritory>", territory.SafeHtmlEncode());
                    }
                }
            }
            data.Append("</restrictedTerritories>\n");


            if (includeMoreFields)
            {
                data.AppendFormat("\t\t<thirdPartyFee>{0:f5}</thirdPartyFee>\n", game.ThirdPartyFee);
                data.AppendFormat("\t\t<theoreticalPayOut>{0:f5}</theoreticalPayOut>\n", game.TheoreticalPayOut);
                data.AppendFormat("\t\t<bonusContribution>{0:f5}</bonusContribution>\n", game.BonusContribution);
                data.AppendFormat("\t\t<jackpotContribution>{0:f5}</jackpotContribution>\n", game.JackpotContribution);
                data.AppendFormat("\t\t<fpp>{0:f5}</fpp>\n", game.FPP);
                data.AppendFormat("\t\t<reportCategory>{0}</reportCategory>\n", game.ReportCategory.SafeHtmlEncode());
                data.AppendFormat("\t\t<invoicingGroup>{0:f}</invoicingGroup>\n", game.InvoicingGroup.SafeHtmlEncode());
            }
        }// PopulateGameBasicProperties
    }
}