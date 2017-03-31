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
    public class CasinoJackpotAccessor : DataAccessor
    {
        private static StringBuilder GetPrimarySQL(DatabaseType dbType)
        { 
            string isNull = dbType == DatabaseType.MySQL ? "IFNULL" : "ISNULL";

            StringBuilder sql = new StringBuilder();
            sql.AppendFormat(CultureInfo.InvariantCulture, @"
            SELECT
                jackpotBase.ID AS 'BaseID',
                {0}( jackpot.ID, 0) AS 'JackpotID',
                {0}( jackpot.Name, jackpotBase.Name) AS 'Name',
                @domainID AS 'DomainID',
                {0}( jackpot.VendorID, jackpotBase.VendorID) AS 'VendorID',
                {0}( jackpot.GameIDs, jackpotBase.GameIDs) AS 'GameIDs',
                {0}( jackpot.IsFixedAmount, jackpotBase.IsFixedAmount) AS 'IsFixedAmount',
                {0}( jackpot.BaseCurrency, jackpotBase.BaseCurrency) AS 'BaseCurrency',
                {0}( jackpot.Amount, jackpotBase.Amount) AS 'Amount',
                {0}( jackpot.MappedJackpotID, jackpotBase.MappedJackpotID) AS 'MappedJackpotID',
                {0}( jackpot.SessionUserID, jackpotBase.SessionUserID) AS 'SessionUserID',
                {0}( jackpot.Ins, jackpotBase.Ins) AS 'Ins',
                {0}( jackpot.IsDeleted, jackpotBase.IsDeleted) AS 'IsDeleted',
                {0}( jackpot.HiddenGameIDs, jackpotBase.HiddenGameIDs) AS 'HiddenGameIDs',
                {0}( jackpot.CustomVendorConfig, jackpotBase.CustomVendorConfig) AS 'CustomVendorConfig'
            FROM CeCasinoJackpotBase jackpotBase
            LEFT JOIN ceCasinoJackpot jackpot ON jackpot.CasinoJackpotBaseID = jackpotBase.ID AND jackpot.DomainID = @domainID
            UNION ALL 
            SELECT
                0 AS 'BaseID',
                jackpot.ID AS 'JackpotID',
                jackpot.Name AS 'Name',
                @domainID AS 'DomainID',
                jackpot.VendorID AS 'VendorID',
                jackpot.GameIDs AS 'GameIDs',
                jackpot.IsFixedAmount AS 'IsFixedAmount',
                jackpot.BaseCurrency AS 'BaseCurrency',
                jackpot.Amount AS 'Amount',
                jackpot.MappedJackpotID AS 'MappedJackpotID',
                jackpot.SessionUserID AS 'SessionUserID',
                jackpot.Ins AS 'Ins',
                jackpot.IsDeleted AS 'IsDeleted',
                jackpot.HiddenGameIDs AS 'HiddenGameIDs',
                jackpot.CustomVendorConfig AS 'CustomVendorConfig'
            FROM ceCasinoJackpot jackpot
            WHERE jackpot.DomainID = @domainID AND (jackpot.CasinoJackpotBaseID IS NULL OR jackpot.CasinoJackpotBaseID = 0) "
                , isNull
                );
            return sql;
        }

        public static ceCasinoJackpotBaseEx GetByKey(long domainID, long baseId, long jackpotId)
        {
            List<ceCasinoJackpotBaseEx> jackpots = new List<ceCasinoJackpotBaseEx>();

            jackpots = SearchJackpots(domainID, null, baseId, jackpotId);
            if (jackpots.Count > 0) { return jackpots[0]; }
            else { return null; }
        }

        public static List<ceCasinoJackpotBaseEx> SearchJackpots(long domainID, VendorID[] vendorIDs = null, long baseId = 0, long jackpotId = 0)
        {
            using (DbManager db = new DbManager())
            {

                StringBuilder mainSql = GetPrimarySQL(db.DatabaseType);
                List<IDbDataParameter> param = new List<IDbDataParameter>();
                Dictionary<string, object> parameters = new Dictionary<string, object>();
                parameters.Add("VendorID", vendorIDs);
                if (baseId != 0 || jackpotId != 0)
                {
                    parameters.Add("baseId", baseId);
                    parameters.Add("jackpotId", jackpotId);
                }
                StringBuilder whereClause = GetWhereClause(parameters, db, out param);
                param.Add(db.Parameter("@domainID", domainID));

                string sql = "";

                if (db.DatabaseType == DatabaseType.MySQL)
                {
                    sql = string.Format(CultureInfo.InvariantCulture
                        , "SELECT YYYYY.* FROM ({0}) AS YYYYY {1}"
                        , mainSql.ToString()
                        , whereClause.ToString()
                        );
                }
                else if (db.DatabaseType == DatabaseType.MSSQL)
                {
                    sql = string.Format(CultureInfo.InvariantCulture
                        , "SELECT * FROM (SELECT ROW_NUMBER() OVER(ORDER BY BASEID DESC) AS row_index, YYYYY.* FROM ({0}) AS YYYYY {1}) AS XXXXX "
                        , mainSql.ToString()
                        , whereClause.ToString()
                        );
                }

                db.SetCommand(sql, param.ToArray());
                return db.ExecuteList<ceCasinoJackpotBaseEx>();
            }
        }

        private static StringBuilder GetWhereClause(Dictionary<string, object> parameters, DbManager db, out List<IDbDataParameter> param)
        {
            StringBuilder whereClause = new StringBuilder();

            int pIndex = 0;
            string paramName;
            param = new List<IDbDataParameter>();
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
            if (whereClause.Length > 0)
                whereClause.Insert(0, "\nWHERE 1=1 AND ( IsDeleted = 0 OR IsDeleted IS NULL) ");
            else
                whereClause.Insert(0, "\nWHERE IsDeleted = 0 OR IsDeleted IS NULL ");
            return whereClause;

        }

        public static ceCasinoJackpot QueryDomainJackpot(long domainID, long id)
        {
            using (DbManager db = new DbManager())
            {
                StringBuilder mainSql = new StringBuilder();
                if (db.DatabaseType == DatabaseType.MySQL)
                {
                    mainSql.AppendFormat(CultureInfo.InvariantCulture, @"SELECT * FROM ceCasinoJackpot WHERE CasinoJackpotBaseID=@id AND DomainID=@domainID AND ( IsDeleted = 0 OR IsDeleted IS NULL) LIMIT 0,1");
                }
                else if (db.DatabaseType == DatabaseType.MSSQL)
                {
                    mainSql.AppendFormat(CultureInfo.InvariantCulture, @"SELECT TOP 1 * FROM ceCasinoJackpot WITH(NOLOCK) WHERE CasinoJackpotBaseID=@id AND DomainID=@domainID AND ( IsDeleted = 0 OR IsDeleted IS NULL)");
                }
                
                List<IDbDataParameter> param = new List<IDbDataParameter>();
                param.Add(db.Parameter("@domainID", domainID));
                param.Add(db.Parameter("@id", id));

                db.SetCommand(mainSql.ToString(), param.ToArray());
                return db.ExecuteObject<ceCasinoJackpot>();
            } 
        }
    }
}
