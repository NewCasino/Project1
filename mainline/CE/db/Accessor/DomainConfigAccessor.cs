using System;
using System.Collections.Generic;
using System.Globalization;
using BLToolkit.Data;
using BLToolkit.DataAccess;

namespace CE.db.Accessor
{
    public abstract class DomainConfigAccessor : DataAccessor<ceDomainConfigEx>
    {
        private const string FIELDS = @"
GmDomain.DomainID,
GmDomain.Name,
GmDomain.SecurityToken,
CeDomainConfig.ApiUsername,
CeDomainConfig.ApiPassword,
CeDomainConfig.ApiWhitelistIP,
CeDomainConfig.GameListChangedNotificationUrl,
CeDomainConfig.WcfApiUsername,
CeDomainConfig.WcfApiPassword,
CeDomainConfig.MobileCashierUrl,
CeDomainConfig.MobileLobbyUrl,
CeDomainConfig.MobileAccountHistoryUrl,
CeDomainConfig.DomainDefaultCurrencyCode,
CeDomainConfig.CashierUrl,
CeDomainConfig.LobbyUrl,
CeDomainConfig.AccountHistoryUrl,
CeDomainConfig.GoogleAnalyticsAccount,
CeDomainConfig.GameLoaderDomain,
CeDomainConfig.GameResourceDomain,
CeDomainConfig.NewStatusCasinoGameExpirationDays,
CeDomainConfig.NewStatusLiveCasinoGameExpirationDays,
CeDomainConfig.TopWinnersDaysBack,
CeDomainConfig.TopWinnersMaxRecords,
CeDomainConfig.TopWinnersExcludeOtherOperators,
CeDomainConfig.TopWinnersMinAmount,
CeDomainConfig.RecentWinnersFilteredVendorIDs,
CeDomainConfig.RecentWinnersFilteredGameCodes,
CeDomainConfig.RecentWinnersCountryFilterMode,
CeDomainConfig.RecentWinnersCountryCodes,
CeDomainConfig.RecentWinnersMinAmount,
CeDomainConfig.RecentWinnersMaxRecords,
CeDomainConfig.RecentWinnersExcludeOtherOperators,
CeDomainConfig.RecentWinnersReturnDistinctUserOnly,
CeDomainConfig.PopularityExcludeOtherOperators,
CeDomainConfig.PopularityCalculationMethod,
CeDomainConfig.PopularityDaysBack,
CeDomainConfig.EnableScalableThumbnail,
CeDomainConfig.ScalableThumbnailWidth,
CeDomainConfig.ScalableThumbnailHeight,
CeDomainConfig.Ins,
CeDomainConfig.TemplateID,
CeDomainConfig.LastPlayedGamesMaxRecords,
CeDomainConfig.LastPlayedGamesIsDuplicated ,
CeDomainConfig.LastPlayedGamesLastDayNum ,
CeDomainConfig.MostPlayedGamesLastDayNum,
CeDomainConfig.MostPlayedGamesMinRoundCounts ,
CeDomainConfig.PlayerBiggestWinGamesIsDuplicated,
CeDomainConfig.PlayerBiggestWinGamesLastDayNum ,
CeDomainConfig.PlayerBiggestWinGamesMinWinEURAmounts ,
CeDomainConfig.RecommendationExcludeGames ,
CeDomainConfig.RecommendationMaxPlayerRecords ,
CeDomainConfig.RecommendationMaxGameRecords ,
CeDomainConfig.PopularityNotByCountry ,
CeDomainConfig.PopularityConfigurationByCountry ";


        private sealed class DynamicQuery_GetAll : SqlQueryEx
        {
            protected override string GetSqlText(DatabaseType dbType)
            {
                return string.Format(CultureInfo.InvariantCulture, @"
SELECT {0}
FROM GmDomain
LEFT JOIN ceDomainConfig ON GmDomain.DomainID = ceDomainConfig.ID
WHERE GmDomain.Type = 2 AND ( GmDomain.ActiveStatus = 0 OR GmDomain.ActiveStatus = @activeStatus ) "
                            , FIELDS
                            );
            }
        } // DynamicQuery_GetAll

        private sealed class DynamicQuery_GetSys : SqlQueryEx
        {
            protected override string GetSqlText(DatabaseType dbType)
            {
                return string.Format(CultureInfo.InvariantCulture, @"
SELECT {0}
FROM GmDomain
LEFT JOIN ceDomainConfig ON GmDomain.DomainID = ceDomainConfig.ID
WHERE GmDomain.DomainID = {1} "
                            , FIELDS
                            , Constant.SystemDomainID
                            );
            }
        } // DynamicQuery_GetSys

        [DynamicQuery_GetAll]
        public abstract List<ceDomainConfigEx> GetAll(GamMatrixAPI.ActiveStatus activeStatus);


        [DynamicQuery_GetSys]
        public abstract ceDomainConfigEx GetSys();        


        private sealed class DynamicQuery_GetByDomainID : SqlQueryEx
        {
            protected override string GetSqlText(DatabaseType dbType)
            {
                switch (dbType)
                {
                    case DatabaseType.MSSQL:
                        {
                            return string.Format(CultureInfo.InvariantCulture, @"
SELECT TOP 1 {0}
FROM GmDomain WITH(NOLOCK)
LEFT JOIN ceDomainConfig WITH(NOLOCK) ON GmDomain.DomainID = ceDomainConfig.ID
WHERE GmDomain.DomainID=@domainID"
                            , FIELDS
                            );
                        }

                    case DatabaseType.MySQL:
                        {
                            return string.Format(CultureInfo.InvariantCulture, @"
SELECT {0}
FROM GmDomain
LEFT JOIN ceDomainConfig ON GmDomain.DomainID = ceDomainConfig.ID
WHERE GmDomain.DomainID=@domainID
LIMIT 0, 1"
                            , FIELDS
                            );
                        }

                    default:
                        throw new NotSupportedException();
                }
            }
        } // DynamicQuery_GetByDomainID

        [DynamicQuery_GetByDomainID]
        public abstract ceDomainConfigEx GetByDomainID(long domainID);

        [Index("ItemName")]
        [ScalarFieldName("ItemValue")]
        [SqlQuery(@"SELECT a.* FROM CeDomainConfig a INNER JOIN CeCasinoVendor b ON a.DomainID = b.DomainID AND b.VendorID = @vendorID AND b.Enabled = 1")]
        public abstract List<ceDomainConfigEx> GetDomainsWithSpecificVendor(int vendorID);

        [Index("ItemName")]
        [ScalarFieldName("ItemValue")]
        [SqlQuery(@"SELECT CeCasinoVendor.VendorID, CeCasinoVendor.DomainID, GmDomain.Name
                    FROM   CeCasinoVendor inner join [GmDomain] on GmDomain.DomainID = CeCasinoVendor.DomainID
                    WHERE  CeCasinoVendor.DomainID <> @systemDomainID ORDER BY GmDomain.Name")]
        public abstract List<DomainVendorConfig> GetEnabledVendorsForAllOperators(long systemDomainID);

        [Index("ItemName")]
        [SqlQuery(@"SELECT * FROM CeDomainConfigItem WHERE DomainID=@domainID")]
        public abstract Dictionary<string, ceDomainConfigItem> GetConfigurationItemsByDomainID(long domainID);

        [SqlQuery(@"
DELETE CeDomainConfigItem WHERE DomainID=@domainID AND ItemName=@itemName;
INSERT INTO CeDomainConfigItem( DomainID, ItemName, ItemValue, CountrySpecificCfg)
VALUES( @domainID, @itemName, @itemValue, @countrySpecificCfg );
")]
        public abstract void SetConfigurationItemValue(long domainID, string itemName, string itemValue, string countrySpecificCfg);
    }
}
