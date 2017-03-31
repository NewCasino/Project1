using System;
using System.Collections.Generic;
using System.Data;
using System.Globalization;
using System.Text;
using System.Text.RegularExpressions;
using BLToolkit.Data;
using BLToolkit.DataAccess;
using GamMatrixAPI;

namespace CE.db.Accessor
{
    public abstract class CasinoGameAccessor : DataAccessor
    {
        private static StringBuilder GetPrimarySQL(DatabaseType dbType)
        { 
            string isNull = dbType == DatabaseType.MySQL ? "IFNULL" : "ISNULL";

            StringBuilder sql = new StringBuilder();

            sql.AppendFormat(CultureInfo.InvariantCulture, @"
SELECT
    b.ID,
    a.ID as 'CasinoGameId',
    {0}( a.Ins, b.Ins) AS 'Ins',
    b.VendorID,
    b.OriginalVendorID,
    b.ContentProviderID,
    b.GameCode,
    b.GameID, 
    {0}( a.Languages, b.Languages) AS 'Languages',
    {0}( a.ExtraParameter1, b.ExtraParameter1) AS 'ExtraParameter1',
    b.ExtraParameter2,
    b.Slug,    
    b.Width,
    b.Height,
    {0}( a.AgeLimit, b.AgeLimit) AS 'AgeLimit',
    {0}( a.LaunchGameInHtml5, b.LaunchGameInHtml5) AS 'LaunchGameInHtml5',
    {0}( a.RestrictedTerritories, b.RestrictedTerritories) AS 'RestrictedTerritories',
    {0}( a.FunMode, b.FunMode) AS 'FunMode',
    {0}( a.RealMode, b.RealMode) AS 'RealMode',
    {0}( a.AnonymousFunMode, b.AnonymousFunMode) AS 'AnonymousFunMode',
    {0}( a.ClientCompatibility, b.ClientCompatibility) AS 'ClientCompatibility',
    {0}( a.GameName, b.GameName) AS 'GameName',
    {0}( a.ShortName, b.ShortName) AS 'ShortName',
    {0}( a.Logo, b.Logo) AS 'Logo',
    {0}( a.Icon, b.Icon) AS 'Icon',
    {0}( a.Thumbnail, b.Thumbnail) AS 'Thumbnail',
    {0}( a.ScalableThumbnail, b.ScalableThumbnail) AS 'ScalableThumbnail',
    y.FilePath AS 'ScalableThumbnailPath',
    {0}( a.BackgroundImage, b.BackgroundImage) AS 'BackgroundImage',
    {0}( a.Description, b.Description) AS 'Description',
    {0}( a.GameCategories, b.GameCategories) AS 'GameCategories',
    {0}( a.Tags, b.Tags) AS 'Tags',
    {0}( a.ReportCategory, b.ReportCategory) AS 'ReportCategory',
    {0}( a.InvoicingGroup, b.InvoicingGroup) AS 'InvoicingGroup',
    {0}( a.GameLaunchUrl, b.GameLaunchUrl) AS 'GameLaunchUrl',
    {0}( a.MobileGameLaunchUrl, b.MobileGameLaunchUrl) AS 'MobileGameLaunchUrl',
    {0}( a.TheoreticalPayOut, b.TheoreticalPayOut) AS 'TheoreticalPayOut',
    {0}( a.ThirdPartyFee, b.ThirdPartyFee) AS 'ThirdPartyFee',
    {0}( a.BonusContribution, b.BonusContribution) AS 'BonusContribution',
    {0}( a.FPP, b.FPP) AS 'FPP',
    {0}( a.JackpotContribution, b.JackpotContribution) AS 'JackpotContribution',
    {0}( a.NewGame, b.NewGame) AS 'NewGame',
    {0}( a.NewGameExpirationDate, b.NewGameExpirationDate) AS 'NewGameExpirationDate',
    {0}( a.Enabled, b.Enabled) AS 'Enabled',
    {0}( a.PopularityCoefficient, b.PopularityCoefficient) AS 'PopularityCoefficient',
    {0}( a.License, b.License ) AS 'License',
    {0}( a.JackpotType, b.JackpotType ) AS 'JackpotType',
    {0}( a.OpVisible, b.OpVisible ) AS 'OpVisible',
    {0}( a.DefaultCoin, b.DefaultCoin ) AS 'DefaultCoin',
    {0}( a.ExcludeFromBonuses, b.ExcludeFromBonuses ) AS 'ExcludeFromBonuses',
    {0}( a.ExcludeFromBonuses_EditableByOperator, b.ExcludeFromBonuses_EditableByOperator ) AS 'ExcludeFromBonuses_EditableByOperator',
    {0}( a.SpinLines, b.SpinLines ) AS 'SpinLines',
    {0}( a.SpinCoins, b.SpinCoins ) AS 'SpinCoins',
    {0}( a.SpinDenominations, b.SpinDenominations ) AS 'SpinDenominations',
    {0}( a.SupportFreeSpinBonus, b.SupportFreeSpinBonus ) AS 'SupportFreeSpinBonus',
    {0}( a.FreeSpinBonus_DefaultLine, b.FreeSpinBonus_DefaultLine ) AS 'FreeSpinBonus_DefaultLine',
    {0}( a.FreeSpinBonus_DefaultCoin, b.FreeSpinBonus_DefaultCoin ) AS 'FreeSpinBonus_DefaultCoin',
    {0}( a.FreeSpinBonus_DefaultDenomination, b.FreeSpinBonus_DefaultDenomination ) AS 'FreeSpinBonus_DefaultDenomination',
    {0}( a.LimitationXml, b.LimitationXml) AS 'LimitationXml',
    @domainID AS 'DomainID'
FROM CeCasinoGameBase b
LEFT JOIN CeCasinoGame a ON a.CasinoGameBaseID = b.ID AND a.DomainID = @domainID
LEFT JOIN (  
	SELECT c.FilePath, c.OrginalFileName
	FROM CeScalableThumbnail c
	LEFT JOIN CeDomainConfig d ON d.DomainID = @domainID
	WHERE c.Width =   d.ScalableThumbnailWidth 
	  AND c.Height =  d.ScalableThumbnailHeight 
) AS y ON y.OrginalFileName = {0}( a.ScalableThumbnail, b.ScalableThumbnail)"
                , isNull
                );

            return sql;
        }

        /// <summary>
        /// Get the domain special game via ID
        /// </summary>
        /// <param name="domainID"></param>
        /// <param name="id"></param>
        /// <returns></returns>
        public static ceCasinoGameBaseEx GetDomainGame(long domainID, long id)
        {
            List<ceCasinoGameBaseEx> games = InternalGetDomainGames(domainID, false, false, id);
            if (games.Count > 0)
                return games[0];
            return null;
        }

        /// <summary>
        /// Get the domain special games 
        /// </summary>
        /// <param name="domainID"></param>
        /// <param name="excludeDisabled"></param>
        /// <returns></returns>
        public static List<ceCasinoGameBaseEx> GetDomainGames(long domainID, bool excludeDisabled = false, bool excludeOperatorInvisible = false)
        {
            return InternalGetDomainGames(domainID, excludeDisabled, excludeOperatorInvisible);
        }

        private static List<ceCasinoGameBaseEx> InternalGetDomainGames(long domainID, bool excludeDisabled = false, bool excludeOperatorInvisible = false, long id = 0)
        {
            using (DbManager db = new DbManager())
            {
                StringBuilder sql = GetPrimarySQL(db.DatabaseType);

                if (domainID != Constant.SystemDomainID)
                {
                    sql.AppendLine("\nINNER JOIN CeCasinoVendor e ON b.VendorID = e.VendorID AND e.Enabled = 1 AND e.DomainID = @domainID ");
                }

                sql.Append("WHERE 1=1 ");
                if (excludeOperatorInvisible)
                {
                    sql.Append("\nAND (a.OpVisible=1 OR (a.OpVisible IS NULL AND b.OpVisible=1)) ");
                }
                if (excludeDisabled)
                {
                    sql.AppendLine("\nAND (( a.Enabled=1 ) OR ( a.Enabled IS NULL AND b.Enabled = 1 )) ");
                }
                if (id > 0)
                {
                    sql.AppendLine("\nAND b.ID = @id ");
                }

                sql.AppendLine("\nORDER BY b.ID DESC ");

                db.SetCommand(sql.ToString()
                    , db.Parameter("@domainID", domainID)
                    , db.Parameter("@id", id)
                    );
                return db.ExecuteList<ceCasinoGameBaseEx>();
            }
        }

        public static List<ceCasinoGameBaseEx> GetBaseGames(long[] gameIDs)
        {
            using (DbManager db = new DbManager())
            {
                StringBuilder sql = GetPrimarySQL(db.DatabaseType);
                sql.Append("\nINNER JOIN CeCasinoVendor e ON e.DomainID = @domainID AND b.VendorID = e.VendorID AND e.Enabled = 1 ");

                sql.Insert(0, "SELECT * FROM (");
                sql.Append(") AS XXXXX ");

                if (gameIDs != null && gameIDs.Length > 0)
                {
                    sql.AppendLine("\nWHERE ID IN (");
                    int lastIndex = gameIDs.Length - 1;
                    for (int i = 0; i < gameIDs.Length; i++)
                    {
                        sql.AppendFormat(CultureInfo.InvariantCulture, "{0:D},", gameIDs[i]);
                    }
                    sql.Remove(sql.Length - 1, 1);
                    sql.Append(")");


                    db.SetCommand(sql.ToString(), db.Parameter("@domainID", Constant.SystemDomainID));
                    return db.ExecuteList<ceCasinoGameBaseEx>();
                }

            }
            return new List<ceCasinoGameBaseEx>();
        }

        public static List<ceCasinoGameBaseEx> SearchGames(int pageIndex, int pageSize, long domainID, Dictionary<string, object> parameters, bool excludeDisabled = false)
        {
            int total = -1;
            return SearchGames(pageIndex, pageSize, domainID, parameters, out total, excludeDisabled);
        }

        public static List<ceCasinoGameBaseEx> SearchGames(int pageIndex, int pageSize, long domainID, Dictionary<string, object> parameters, out int total, bool excludeDisabled = false, bool excludeOperatorInvisible = true)
        {
            using (DbManager db = new DbManager())
            {

                StringBuilder mainSql = GetPrimarySQL(db.DatabaseType);

                if (domainID != Constant.SystemDomainID)
                {
                    mainSql.AppendLine("\nINNER JOIN CeCasinoVendor e ON e.DomainID = @domainID AND b.VendorID = e.VendorID AND e.Enabled = 1 ");
                }
                mainSql.AppendLine("\nWHERE 1=1 ");
                if (excludeOperatorInvisible)
                {
                    mainSql.Append("AND (a.OpVisible=1 OR (a.OpVisible IS NULL AND b.OpVisible=1)) ");
                }
                if (excludeDisabled)
                {
                    mainSql.Append("AND (( a.Enabled=1 ) OR ( a.Enabled IS NULL AND b.Enabled = 1 )) ");
                }

                #region WHERE Clause
                StringBuilder whereClause = new StringBuilder();
                List<IDbDataParameter> param = new List<IDbDataParameter>();
                param.Add(db.Parameter("@domainID", domainID));

                int pIndex = 0;
                string paramName;

                if (parameters != null)
                {
                    foreach (string key in parameters.Keys)
                    {
                        if (key == null ||
                            parameters[key] == null ||
                            !Regex.IsMatch(key, @"^([a-z0-9]+)$", RegexOptions.Compiled | RegexOptions.IgnoreCase | RegexOptions.CultureInvariant))
                        {
                            continue;
                        }

                        switch (key.ToUpperInvariant())
                        {
                            case "TAGS":
                            case "GAMENAME":
                                {
                                    paramName = string.Format(CultureInfo.InvariantCulture, "@{0:D}", ++pIndex);
                                    whereClause.AppendFormat(CultureInfo.InvariantCulture, "\nAND {0} LIKE {1}", key, paramName);
                                    param.Add(
                                            db.Parameter(paramName
                                                , string.Format(CultureInfo.InvariantCulture, "%{0}%", parameters[key].ToString())
                                            )
                                    );
                                    break;
                                }

                            case "CLIENTCOMPATIBILITY":
                                {
                                    string[] clients = parameters[key].ToString().Split(new char[] { ',' }, StringSplitOptions.RemoveEmptyEntries);
                                    if (clients.Length > 0)
                                    {
                                        whereClause.Append("\nAND (");

                                        for (int i = 0; i < clients.Length; i++)
                                        {
                                            if (i > 0)
                                                whereClause.Append(" OR ");

                                            paramName = string.Format(CultureInfo.InvariantCulture, "@{0:D}", ++pIndex);
                                            whereClause.AppendFormat(CultureInfo.InvariantCulture, "{0} LIKE {1}", key, paramName);
                                            param.Add(db.Parameter(paramName, string.Format(CultureInfo.InvariantCulture, "%,{0},%", clients[i])));
                                        }

                                        whereClause.Append(")");
                                    }
                                    break;
                                }

                            case "GAMECATEGORIES":
                                {
                                    string[] categories = (string[])parameters[key];
                                    if (categories.Length > 0)
                                    {
                                        whereClause.Append("\nAND (");
                                        for (int i = 0; i < categories.Length; i++)
                                        {
                                            if (i > 0)
                                                whereClause.Append(" OR ");

                                            if (string.Equals("Uncategorized", categories[i], StringComparison.InvariantCultureIgnoreCase))
                                            {
                                                whereClause.AppendFormat(CultureInfo.InvariantCulture, "({0} IS NULL OR {0} = '' OR {0} = ',')", key);
                                            }
                                            else
                                            {
                                                paramName = string.Format(CultureInfo.InvariantCulture, "@{0:D}", ++pIndex);
                                                whereClause.AppendFormat(CultureInfo.InvariantCulture, "{0} LIKE {1}", key, paramName);
                                                param.Add(db.Parameter(paramName, string.Format(CultureInfo.InvariantCulture, "%,{0},%", categories[i])));
                                            }
                                        }
                                        whereClause.Append(")");
                                    }
                                    break;
                                }

                            case "VENDORID":
                                {
                                    VendorID[] vendors = (VendorID[])parameters[key];
                                    if (vendors.Length > 0)
                                    {
                                        whereClause.Append("\nAND (");

                                        for (int i = 0; i < vendors.Length; i++)
                                        {
                                            if (i > 0)
                                                whereClause.Append(" OR ");

                                            paramName = string.Format(CultureInfo.InvariantCulture, "@{0:D}", ++pIndex);
                                            whereClause.AppendFormat(CultureInfo.InvariantCulture, "{0} = {1}", key, paramName);
                                            param.Add(db.Parameter(paramName, (int)vendors[i]));
                                        }

                                        whereClause.Append(")");
                                    }
                                    break;
                                }

                            case "GAMECODE":
                                {
                                    paramName = string.Format(CultureInfo.InvariantCulture, "@{0:D}", ++pIndex);
                                    whereClause.AppendFormat(CultureInfo.InvariantCulture
                                    , "\nAND ( GameCode LIKE {0} OR GameID LIKE {0} ) "
                                    , paramName
                                    );
                                    param.Add(
                                            db.Parameter(paramName
                                                , string.Format(CultureInfo.InvariantCulture, "%{0}%", parameters[key].ToString())
                                            )
                                    );
                                    break;
                                }

                            default:
                                {
                                    paramName = string.Format(CultureInfo.InvariantCulture, "@{0:D}", ++pIndex);
                                    whereClause.AppendFormat(CultureInfo.InvariantCulture
                                        , "\nAND {0} = {1}"
                                        , key
                                        , paramName
                                        );
                                    param.Add(db.Parameter(paramName, parameters[key]));
                                    break;
                                }
                        }// switch
                    }// foreach
                }// if (parameters != null)

                if (whereClause.Length > 0)
                    whereClause.Insert(0, "\nWHERE 1=1 ");
                #endregion WHERE CLAUSE

                string sql = string.Format(CultureInfo.InvariantCulture
                    , "SELECT COUNT(*) FROM ( SELECT YYYYY.* FROM ({0}) AS YYYYY {1} ) AS XXXXX"
                    , mainSql.ToString()
                    , whereClause.ToString()
                    );

                db.SetCommand(sql, param.ToArray());
                total = int.Parse(db.ExecuteScalar().ToString());

                if (db.DatabaseType == DatabaseType.MySQL)
                {
                    sql = string.Format(CultureInfo.InvariantCulture
                        , "SELECT YYYYY.* FROM ({0}) AS YYYYY {1} LIMIT {2}, {3}"
                        , mainSql.ToString()
                        , whereClause.ToString()
                        , (pageIndex - 1) * pageSize
                        , pageSize
                        );
                }
                else if (db.DatabaseType == DatabaseType.MSSQL)
                {
                    sql = string.Format(CultureInfo.InvariantCulture
                        , "SELECT * FROM (SELECT ROW_NUMBER() OVER(ORDER BY ID DESC) AS row_index, YYYYY.* FROM ({0}) AS YYYYY {1}) AS XXXXX WHERE row_index BETWEEN {2} AND {3}"
                        , mainSql.ToString()
                        , whereClause.ToString()
                        , (pageIndex - 1) * pageSize + 1
                        , pageIndex * pageSize
                        );
                }

                db.SetCommand(sql, param.ToArray());
                return db.ExecuteList<ceCasinoGameBaseEx>();
            }
        }

        [SqlQueryEx(MSSqlText = @"SELECT TOP 1 * FROM ceCasinoGame WITH(NOLOCK) WHERE CasinoGameBaseID=@id AND DomainID=@domainID"
            , MySqlText = @"SELECT * FROM ceCasinoGame WHERE CasinoGameBaseID=@id AND DomainID=@domainID LIMIT 0,1")]
        public abstract ceCasinoGame QueryDomainGame(long domainID, long id);

        public static List<ceCasinoGame> GetGameOverrides(long casinoGameBaseId)
        {
            using (DbManager db = new DbManager())
            {
                db.SetCommand(@"SELECT * FROM ceCasinoGame WITH(NOLOCK) WHERE CasinoGameBaseID=@id", db.Parameter("@id", casinoGameBaseId));
                return db.ExecuteList<ceCasinoGame>();
            }
        }

        [SqlQueryEx(MSSqlText = @"
IF( @casinoGameID <= 0 )
BEGIN
    SELECT @casinoGameID = @@IDENTITY FROM CeCasinoGame
END

INSERT INTO CeCasinoGameHistory (
Ins ,SessionID ,SessionUserID ,DomainID ,CasinoGameID  ,CasinoGameBaseID ,GameName ,ShortName ,Logo ,Icon ,Thumbnail ,ScalableThumbnail ,BackgroundImage ,Description ,GameCategories ,ClientCompatibility ,Tags ,ReportCategory ,InvoicingGroup ,ThirdPartyFee ,BonusContribution ,FPP ,TheoreticalPayOut ,JackpotContribution ,FunMode ,RealMode ,NewGame ,NewGameExpirationDate ,Width ,Height ,PopularityCoefficient ,Enabled ,License ,JackpotType ,OpVisible, AnonymousFunMode, ExcludeFromBonuses, ExcludeFromBonuses_EditableByOperator, SpinLines, SpinCoins, SpinDenominations, SupportFreeSpinBonus, FreeSpinBonus_DefaultLine, FreeSpinBonus_DefaultCoin, FreeSpinBonus_DefaultDenomination,RestrictedTerritories,ExtraParameter1)
SELECT 
@ins ,@sessionID ,@sessionUserID ,DomainID ,@CasinoGameID ,CasinoGameBaseID ,GameName ,ShortName ,Logo ,Icon ,Thumbnail ,ScalableThumbnail ,BackgroundImage ,Description ,GameCategories ,ClientCompatibility ,Tags ,ReportCategory ,InvoicingGroup ,ThirdPartyFee ,BonusContribution ,FPP ,TheoreticalPayOut ,JackpotContribution ,FunMode ,RealMode ,NewGame ,NewGameExpirationDate ,Width ,Height ,PopularityCoefficient ,Enabled ,License ,JackpotType ,OpVisible, AnonymousFunMode, ExcludeFromBonuses, ExcludeFromBonuses_EditableByOperator, SpinLines, SpinCoins, SpinDenominations, SupportFreeSpinBonus, FreeSpinBonus_DefaultLine, FreeSpinBonus_DefaultCoin, FreeSpinBonus_DefaultDenomination,RestrictedTerritories,ExtraParameter1 
FROM CeCasinoGame WITH(NOLOCK)
WHERE CeCasinoGame.ID = @CasinoGameID

DECLARE @HID BIGINT
SELECT @HID = @@IDENTITY FROM CeCasinoGameHistory

UPDATE CeCasinoGame SET HID = @HID WHERE ID = @casinoGameID",
        MySqlText = @"
SET @gameID := CASE WHEN @casinoGameID <= 0 THEN LAST_INSERT_ID() ELSE @casinoGameID END;

INSERT INTO CeCasinoGameHistory (                                                                                                                                                                                                                                                                                                         
Ins ,SessionID  ,SessionUserID ,DomainID ,CasinoGameID  ,CasinoGameBaseID ,GameName ,ShortName ,Logo ,Icon ,Thumbnail ,ScalableThumbnail ,BackgroundImage ,Description ,GameCategories ,ClientCompatibility ,Tags ,ReportCategory ,InvoicingGroup ,ThirdPartyFee ,BonusContribution ,FPP ,TheoreticalPayOut ,JackpotContribution ,FunMode ,RealMode ,NewGame ,Width ,Height ,PopularityCoefficient ,Enabled ,License ,JackpotType ,OpVisible, AnonymousFunMode, ExcludeFromBonuses, ExcludeFromBonuses_EditableByOperator, SpinLines, SpinCoins, SpinDenominations, SupportFreeSpinBonus, FreeSpinBonus_DefaultLine, FreeSpinBonus_DefaultCoin, FreeSpinBonus_DefaultDenomination,RestrictedTerritories,ExtraParameter1)
SELECT 
@ins ,@sessionID ,@sessionUserID,DomainID ,@gameID       ,CasinoGameBaseID ,GameName ,ShortName ,Logo ,Icon ,Thumbnail ,ScalableThumbnail ,BackgroundImage ,Description ,GameCategories ,ClientCompatibility ,Tags ,ReportCategory ,InvoicingGroup ,ThirdPartyFee ,BonusContribution ,FPP ,TheoreticalPayOut ,JackpotContribution ,FunMode ,RealMode ,NewGame ,Width ,Height ,PopularityCoefficient ,Enabled ,License ,JackpotType ,OpVisible, AnonymousFunMode, ExcludeFromBonuses, ExcludeFromBonuses_EditableByOperator, SpinLines, SpinCoins, SpinDenominations, SupportFreeSpinBonus, FreeSpinBonus_DefaultLine, FreeSpinBonus_DefaultCoin, FreeSpinBonus_DefaultDenomination,RestrictedTerritories,ExtraParameter1 
FROM CeCasinoGame
WHERE CeCasinoGame.ID = @CasinoGameID;

SET @HID := LAST_INSERT_ID();
UPDATE CeCasinoGame SET HID = @HID WHERE ID = @gameID;
")]
        public abstract void BackupCasinoGame(string sessionID, long sessionUserID, long casinoGameID, DateTime ins);


        [SqlQueryEx(MSSqlText = @"
IF( @casinoGameBaseID <= 0 )
BEGIN
    SELECT @casinoGameBaseID = @@IDENTITY FROM CeCasinoGameBase
END
INSERT INTO CeCasinoGameBaseHistory (
Ins      ,SessionID,  SessionUserID ,CasinoGameBaseID  ,DomainID ,VendorID ,OriginalVendorID ,GameCode ,GameID ,ExtraParameter1 ,ExtraParameter2 ,GameName ,ShortName ,Logo ,Icon ,Thumbnail ,ScalableThumbnail ,BackgroundImage ,Description ,GameCategories ,Tags ,RestrictedTerritories ,ClientCompatibility ,ReportCategory ,InvoicingGroup ,TheoreticalPayOut ,ThirdPartyFee ,BonusContribution ,FPP ,JackpotContribution ,FunMode ,AnonymousFunMode ,RealMode ,NewGame ,NewGameExpirationDate ,Enabled ,Width ,Height ,PopularityCoefficient ,License ,Languages ,Slug ,JackpotType ,OpVisible, DefaultCoin, ExcludeFromBonuses, ExcludeFromBonuses_EditableByOperator, SpinLines, SpinCoins, SpinDenominations, SupportFreeSpinBonus, FreeSpinBonus_DefaultLine, FreeSpinBonus_DefaultCoin, FreeSpinBonus_DefaultDenomination, ContentProviderID)
SELECT      
@ins     ,@sessionID,@sessionUserID ,@casinoGameBaseID ,DomainID ,VendorID ,OriginalVendorID ,GameCode ,GameID ,ExtraParameter1 ,ExtraParameter2 ,GameName ,ShortName ,Logo ,Icon ,Thumbnail ,ScalableThumbnail ,BackgroundImage ,Description ,GameCategories ,Tags ,RestrictedTerritories ,ClientCompatibility ,ReportCategory ,InvoicingGroup ,TheoreticalPayOut ,ThirdPartyFee ,BonusContribution ,FPP ,JackpotContribution ,FunMode ,AnonymousFunMode ,RealMode ,NewGame ,NewGameExpirationDate ,Enabled ,Width ,Height ,PopularityCoefficient ,License ,Languages ,Slug ,JackpotType ,OpVisible, DefaultCoin, ExcludeFromBonuses, ExcludeFromBonuses_EditableByOperator, SpinLines, SpinCoins, SpinDenominations, SupportFreeSpinBonus, FreeSpinBonus_DefaultLine, FreeSpinBonus_DefaultCoin, FreeSpinBonus_DefaultDenomination, ContentProviderID
FROM CeCasinoGameBase WITH(NOLOCK)
WHERE CeCasinoGameBase.ID = @casinoGameBaseID

DECLARE @HID BIGINT
SELECT @HID = @@IDENTITY FROM CeCasinoGameBaseHistory

UPDATE CeCasinoGameBase SET HID = @HID WHERE ID = @casinoGameBaseID",

        MySqlText = @"
SET @baseID := CASE WHEN @casinoGameBaseID <= 0 THEN LAST_INSERT_ID() ELSE @casinoGameBaseID END;

INSERT INTO CeCasinoGameBaseHistory (
Ins      ,SessionID  ,SessionUserID  ,CasinoGameBaseID  ,DomainID ,VendorID ,OriginalVendorID ,GameCode ,GameID ,ExtraParameter1 ,ExtraParameter2 ,GameName ,ShortName ,Logo ,Icon ,Thumbnail ,ScalableThumbnail ,BackgroundImage ,Description ,GameCategories ,Tags ,RestrictedTerritories ,ClientCompatibility ,ReportCategory ,InvoicingGroup ,TheoreticalPayOut ,ThirdPartyFee ,BonusContribution ,FPP ,JackpotContribution ,FunMode ,AnonymousFunMode ,RealMode ,NewGame ,Enabled ,Width ,Height ,PopularityCoefficient ,License ,Languages ,Slug ,JackpotType ,OpVisible, DefaultCoin, ExcludeFromBonuses, ExcludeFromBonuses_EditableByOperator, SpinLines, SpinCoins, SpinDenominations, SupportFreeSpinBonus, FreeSpinBonus_DefaultLine, FreeSpinBonus_DefaultCoin, FreeSpinBonus_DefaultDenomination, ContentProviderID)
SELECT      
@ins     ,@sessionID ,@sessionUserID ,@baseID           ,DomainID ,VendorID ,OriginalVendorID ,GameCode ,GameID ,ExtraParameter1 ,ExtraParameter2 ,GameName ,ShortName ,Logo ,Icon ,Thumbnail ,ScalableThumbnail ,BackgroundImage ,Description ,GameCategories ,Tags ,RestrictedTerritories ,ClientCompatibility ,ReportCategory ,InvoicingGroup ,TheoreticalPayOut ,ThirdPartyFee ,BonusContribution ,FPP ,JackpotContribution ,FunMode ,AnonymousFunMode ,RealMode ,NewGame ,Enabled ,Width ,Height ,PopularityCoefficient ,License ,Languages ,Slug ,JackpotType ,OpVisible, DefaultCoin, ExcludeFromBonuses, ExcludeFromBonuses_EditableByOperator, SpinLines, SpinCoins, SpinDenominations, SupportFreeSpinBonus, FreeSpinBonus_DefaultLine, FreeSpinBonus_DefaultCoin, FreeSpinBonus_DefaultDenomination, ContentProviderID
FROM CeCasinoGameBase
WHERE CeCasinoGameBase.ID = @baseID;

SET @HID := LAST_INSERT_ID();
UPDATE CeCasinoGameBase SET HID = @HID WHERE ID = @baseID;")]
        public abstract void BackupCasinoGameBase(string sessionID, long sessionUserID, long casinoGameBaseID, DateTime ins);

        public static void InsertNewGameWithSpecificProperty(DbManager db
            , long domainID
            , long casinoGameBaseID
            , string userSessionID
            , long sessionUserID
            , string column
            , object value
            , bool baseGameEnabled
            , bool baseGameOpVisible
            )
        {

            bool isEnabledColumn = string.Equals(column, "Enabled", StringComparison.InvariantCultureIgnoreCase);
            bool isOpVisibleColumn = string.Equals(column, "OpVisible", StringComparison.InvariantCultureIgnoreCase);
            string sql = string.Format(@"
INSERT INTO CeCasinoGame 
(
DomainID, Ins, HID, CasinoGameBaseID, SessionUserID, SessionID, {0} {1} {2}
) 
VALUES 
(
@domainID, @ins, 0, @casinoGameBaseID, @sessionUserID, @sessionID, @value {3} {4}
)"
                , column
                , isEnabledColumn ? string.Empty : ",Enabled"
                , isOpVisibleColumn ? string.Empty : ",OpVisible"
                , isEnabledColumn ? string.Empty : (baseGameEnabled ? ",1" : ",0")
                , isOpVisibleColumn ? string.Empty : (baseGameOpVisible ? ",1" : ",0")
                );

            db.SetCommand(sql
                , db.Parameter("@domainID", domainID)
                , db.Parameter("@ins", DateTime.Now)
                , db.Parameter("@casinoGameBaseID", casinoGameBaseID)
                , db.Parameter("@sessionUserID", sessionUserID)
                , db.Parameter("@sessionID", sessionUserID)
                , db.Parameter("@value", value == null ? DBNull.Value : value)
                );
            db.ExecuteNonQuery();
        }

        public static void UpdateGameProperty(DbManager db, string column, object value, long casinoGameID)
        {
            string sql = string.Format(CultureInfo.InvariantCulture, "UPDATE CeCasinoGame SET {0} = @value WHERE ID = @casinoGameID", column);
            db.SetCommand(sql
                , db.Parameter("@value", value == null ? DBNull.Value : value)
                , db.Parameter("@casinoGameID", casinoGameID)
                );
            db.ExecuteNonQuery();
        }


        public static void UpdateGameBaseProperty(DbManager db, string column, object value, long casinoGameBaseID)
        {
            string sql = string.Format(CultureInfo.InvariantCulture, "UPDATE CeCasinoGameBase SET {0} = @value WHERE ID = @casinoGameBaseID", column);
            db.SetCommand(sql
                , db.Parameter("@value", value == null ? DBNull.Value : value)
                , db.Parameter("@casinoGameBaseID", casinoGameBaseID)
                );
            db.ExecuteNonQuery();
        }

        //[SqlQueryEx(MSSqlText = @"SELECT * FROM CeCasinoGameBaseHistory WITH(NOLOCK) WHERE CasinoGameBaseID = @gameID"
        //    , MySqlText = @"SELECT * FROM CeCasinoGameBaseHistory WHERE CasinoGameBaseID = @gameID")]
        //public abstract List<ceCasinoGameBase> QueryBaseGameHistory(long gameID);

        [SqlQueryEx(MSSqlText = @"SELECT * FROM CeCasinoGameBase WITH(NOLOCK) WHERE ID = @gameID",
            MySqlText = @"SELECT * FROM CeCasinoGameBase WHERE ID = @gameID")]
        public abstract DataTable QueryCasinoGameBase(long gameID);

        [SqlQueryEx(MSSqlText = @"SELECT * FROM CeCasinoGame WITH(NOLOCK) WHERE CasinoGameBaseID = @gameID",
            MySqlText = @"SELECT * FROM CeCasinoGame WHERE CasinoGameBaseID = @gameID")]
        public abstract DataTable QueryCasinoGame(long domainID, long gameID);


        public static DataTable SearchUpdatedGames(int pageIndex, int pageSize, long domainID, Dictionary<string, object> parameters, out int total)
        {
            using (DbManager db = new DbManager())
            {
                StringBuilder whereClause = new StringBuilder();
                #region where
                List<IDbDataParameter> param = new List<IDbDataParameter>();
                param.Add(db.Parameter("@domainID", domainID));
                whereClause.Append("\nWHERE DomainID = @domainID");

                int pIndex = 0;
                string paramName;

                if (parameters != null)
                {
                    foreach (string key in parameters.Keys)
                    {
                        if (key == null ||
                            parameters[key] == null ||
                            !Regex.IsMatch(key, @"^([a-z0-9]+)$", RegexOptions.Compiled | RegexOptions.IgnoreCase | RegexOptions.CultureInvariant))
                        {
                            continue;
                        }

                        switch (key.ToUpperInvariant())
                        {
                            case "VENDORID":
                                {
                                    paramName = string.Format(CultureInfo.InvariantCulture, "@{0:D}", ++pIndex);
                                    whereClause.AppendFormat(CultureInfo.InvariantCulture, "\nAND {0} = {1}", key, paramName);
                                    param.Add(
                                            db.Parameter(paramName
                                                , (int)parameters[key]
                                            )
                                    );
                                    break;
                                }
                            case "DATEFROM":
                                {
                                    paramName = string.Format(CultureInfo.InvariantCulture, "@{0:D}", ++pIndex);
                                    whereClause.AppendFormat(CultureInfo.InvariantCulture, "\nAND Ins >= {0}", paramName);
                                    param.Add(
                                            db.Parameter(paramName
                                                , (DateTime)parameters[key]
                                            )
                                    );
                                    break;
                                }
                            case "DATETO":
                                {
                                    paramName = string.Format(CultureInfo.InvariantCulture, "@{0:D}", ++pIndex);
                                    whereClause.AppendFormat(CultureInfo.InvariantCulture, "\nAND Ins < {0}", paramName);
                                    param.Add(
                                            db.Parameter(paramName
                                                , (DateTime)parameters[key]
                                            )
                                    );
                                    break;
                                }
                            default:
                                {
                                    paramName = string.Format(CultureInfo.InvariantCulture, "@{0:D}", ++pIndex);
                                    whereClause.AppendFormat(CultureInfo.InvariantCulture
                                        , "\nAND {0} = {1}"
                                        , key
                                        , paramName
                                        );
                                    param.Add(db.Parameter(paramName, parameters[key]));
                                    break;
                                }
                        }
                    }
                }

                #endregion where

                bool isAll = domainID == Constant.SystemDomainID;
                string gameTableName = isAll ? "CeCasinoGameBase" : "CeCasinoGame";
                string hisTableName = isAll ? "CeCasinoGameBaseHistory" : "CeCasinoGameHistory";
                string identiferName = isAll ? "ID" : "CasinoGameBaseID";
                string identiferNameForJoin = isAll ? "CasinoGameBaseID" : "CasinoGameID";

                string mainSql = string.Format(@"SELECT ID, GameName FROM dbo.CeCasinoGameBase WHERE ID in 
(
(SELECT DISTINCT({3}) FROM dbo.{0} with(nolock) {4})
UNION
(SELECT DISTINCT(CasinoGameBaseID) AS ID FROM 
(SELECT a.* FROM dbo.{1} AS a with(nolock) Inner JOIN dbo.{0} AS b with(nolock) ON
a.{2} = b.ID) AS TTTT 
{4})
)
", gameTableName
 , hisTableName
 , identiferNameForJoin
 , identiferName
 , whereClause.ToString());

                string sql = string.Format(CultureInfo.InvariantCulture
                    , "SELECT COUNT(*) FROM ( SELECT YYYYY.* FROM ({0}) AS YYYYY ) AS XXXXX"
                    , mainSql.ToString()
                    );

                db.SetCommand(sql, param.ToArray());
                total = int.Parse(db.ExecuteScalar().ToString());


                if (db.DatabaseType == DatabaseType.MySQL)
                {
                    sql = string.Format(CultureInfo.InvariantCulture
                        , "SELECT YYYYY.* FROM ({0}) AS YYYYY LIMIT {1}, {2}"
                        , mainSql.ToString()
                        , (pageIndex - 1) * pageSize
                        , pageSize
                        );
                }
                else if (db.DatabaseType == DatabaseType.MSSQL)
                {
                    sql = string.Format(CultureInfo.InvariantCulture
                        , "SELECT * FROM (SELECT ROW_NUMBER() OVER(ORDER BY ID DESC) AS row_index, YYYYY.* FROM ({0}) AS YYYYY) AS XXXXX WHERE row_index BETWEEN {1} AND {2}"
                        , mainSql.ToString()
                        , (pageIndex - 1) * pageSize + 1
                        , pageIndex * pageSize
                        );
                }

                db.SetCommand(sql, param.ToArray());
                return db.ExecuteDataTable();

            }

        }

        public static DataTable QueryBaseGameHistory(long gameID)
        {
            using (DbManager db = new DbManager())
            {
                string sql = "";
                if (db.DatabaseType == DatabaseType.MySQL)
                {
                    sql = @"SELECT * FROM CeCasinoGameBaseHistory WHERE CasinoGameBaseID = @gameID  ORDER BY Ins ASC";
                }
                else if (db.DatabaseType == DatabaseType.MSSQL)
                {
                    sql = @"SELECT * FROM CeCasinoGameBaseHistory WITH(NOLOCK) WHERE CasinoGameBaseID = @gameID  ORDER BY Ins ASC";
                }
                if (string.IsNullOrWhiteSpace(sql))
                    return null;

                List<IDbDataParameter> param = new List<IDbDataParameter>();
                param.Add(db.Parameter("@gameID", gameID));

                db.SetCommand(sql, param.ToArray());
                return db.ExecuteDataTable();
            }
        }

        public static DataTable QueryNearestBaseGameHistory(long gameID, DateTime time)
        {
            using (DbManager db = new DbManager())
            {
                string sql = "";
                if (db.DatabaseType == DatabaseType.MySQL)
                {
                    sql = @"SELECT * FROM CeCasinoGameBaseHistory WHERE CasinoGameBaseID = @gameID 
AND INS < @time ORDER BY Ins DESC LIMIT 1";
                }
                else if (db.DatabaseType == DatabaseType.MSSQL)
                {
                    sql = @"SELECT TOP 1 * FROM CeCasinoGameBaseHistory WITH(NOLOCK) WHERE CasinoGameBaseID = @gameID 
AND INS < @time ORDER BY Ins DESC";
                }
                if (string.IsNullOrWhiteSpace(sql))
                    return null;

                List<IDbDataParameter> param = new List<IDbDataParameter>();
                param.Add(db.Parameter("@gameID", gameID));
                param.Add(db.Parameter("@time", time));

                db.SetCommand(sql, param.ToArray());
                return db.ExecuteDataTable();
            }
        }

        public static DataTable QueryDomainGameHistory(long domainID, long gameID)
        {
            using (DbManager db = new DbManager())
            {
                string sql = "";
                if (db.DatabaseType == DatabaseType.MySQL)
                {
                    sql = @"SELECT * FROM CeCasinoGameHistory WHERE CasinoGameBaseID = @gameID AND DomainID=@domainID ORDER BY Ins ASC";
                }
                else if (db.DatabaseType == DatabaseType.MSSQL)
                {
                    sql = @"SELECT * FROM CeCasinoGameHistory WITH(NOLOCK) WHERE DomainID = @domainID AND CasinoGameBaseID = @gameID ORDER BY Ins ASC";
                }
                if (string.IsNullOrWhiteSpace(sql))
                    return null;

                List<IDbDataParameter> param = new List<IDbDataParameter>();
                param.Add(db.Parameter("@domainID", domainID));
                param.Add(db.Parameter("@gameID", gameID));

                db.SetCommand(sql, param.ToArray());
                return db.ExecuteDataTable();
            }
        }
    }
}
