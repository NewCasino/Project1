using System;
using System.Collections.Generic;
using System.Data;
using System.Globalization;
using System.Text;
using BLToolkit.Data;
using BLToolkit.DataAccess;
using GamMatrixAPI;

namespace CE.db.Accessor
{
    public abstract class LiveCasinoTableAccessor : DataAccessor
    {
        private static StringBuilder GetPrimarySQL(DatabaseType dbType)
        {
            string isNull = dbType == DatabaseType.MySQL ? "IFNULL" : "ISNULL";

            StringBuilder sql = new StringBuilder();

            sql.AppendFormat(CultureInfo.InvariantCulture, @"
SELECT
    b.ID,
    a.Ins ,
    b.CasinoGameBaseID,
    b.OpenHoursTimeZone,
    b.OpenHoursStart,
    b.OpenHoursEnd,
    c.GameID,
    c.VendorID,
    {0}( a.NewTable, b.NewTable) AS 'NewTable',
    {0}( a.NewTableExpirationDate, b.NewTableExpirationDate) AS 'NewTableExpirationDate',
    {0}( a.VIPTable, b.VIPTable) AS 'VIPTable',
    {0}( a.TurkishTable, b.TurkishTable) AS 'TurkishTable',
    {0}( a.BetBehindAvailable, b.BetBehindAvailable) AS 'BetBehindAvailable',
    {0}( a.ExcludeFromRandomLaunch, b.ExcludeFromRandomLaunch) AS 'ExcludeFromRandomLaunch',
    {0}( a.SeatsUnlimited, b.SeatsUnlimited) AS 'SeatsUnlimited',
    {0}( a.DealerGender, b.DealerGender) AS 'DealerGender',
    {0}( a.DealerOrigin, b.DealerOrigin) AS 'DealerOrigin',
    {0}( a.TableName, b.TableName) AS 'TableName',
    {0}( a.ShortName, b.ShortName) AS 'ShortName',
    {0}( a.Category, b.Category) AS 'Category',
    {0}( a.Logo, b.Logo) AS 'Logo',
    {0}( a.Thumbnail, b.Thumbnail) AS 'Thumbnail',
    {0}( a.BackgroundImage, b.BackgroundImage) AS 'BackgroundImage',
    {0}( a.ExtraParameter1, b.ExtraParameter1) AS 'ExtraParameter1',
    {0}( a.ExtraParameter2, b.ExtraParameter2) AS 'ExtraParameter2',
    {0}( a.ExtraParameter3, b.ExtraParameter3) AS 'ExtraParameter3',
    {0}( a.ExtraParameter4, b.ExtraParameter4) AS 'ExtraParameter4',
    {0}( a.LaunchParams, b.LaunchParams) AS 'LaunchParams',
    {0}( a.Enabled, b.Enabled) AS 'Enabled',
    {0}({0}( a.ClientCompatibility, b.ClientCompatibility), {0}(f.ClientCompatibility, c.ClientCompatibility)) AS 'ClientCompatibility',
    {0}( a.LimitationXml, b.LimitationXml) AS 'LimitationXml',
     a.OpVisible ,
    @domainID AS 'DomainID',
    ISNULL(a.TableStudioUrl, b.TableStudioUrl) as 'TableStudioUrl'
FROM CeLiveCasinoTableBase b with(nolock)
INNER JOIN CeCasinoGameBase c with(nolock) ON b.CasinoGameBaseID = c.ID
INNER JOIN CeCasinoVendor e with(nolock) ON c.VendorID = e.VendorID AND e.DomainID = @domainID AND e.Enabled = 1 AND e.HasLiveCasino = 1 
LEFT JOIN CeLiveCasinoTable a with(nolock) ON a.LiveCasinoTableBaseID = b.ID AND a.DomainID = @domainID 
LEFT JOIN CeCasinoGame f with(nolock) ON f.CasinoGameBaseID = c.ID AND f.DomainID = @domainID
"
                , isNull
                );

            return sql;
        }        

        public static List<ceLiveCasinoTableBaseEx> SearchTables(int pageIndex, int pageSize
            , long domainID
            , VendorID[] vendors
            , out int total
            , bool excludeDisabledTables = false
            , bool excludeOperatorInvisible = true
            , string gameID = null
            , string slug = null
            , string tableName = null
            , string clientType = null  
            , string[] categories = null
            , string tableType = null
            , string openingHour = null
            )
        {
            

            using (DbManager db = new DbManager())
            {
                List<IDbDataParameter> param = new List<IDbDataParameter>();
                param.Add(db.Parameter("@domainID", domainID));

                StringBuilder mainSql = GetPrimarySQL(db.DatabaseType);

                string paramName = string.Empty;

                mainSql.AppendLine("\nWHERE 1=1");
                if (vendors != null)
                {
                    mainSql.Append("\nAND c.VendorID IN ( ");
                    foreach (VendorID vendor in vendors)
                    {
                        mainSql.AppendFormat("{0:D},", (int)vendor);
                    }
                    mainSql.Remove(mainSql.Length - 1, 1);
                    mainSql.AppendLine(")");
                }

                
                if (!string.IsNullOrWhiteSpace(gameID))
                {
                    long gid = 0L;
                    long.TryParse(gameID, out gid);
                    mainSql.Append("\nAND b.CasinoGameBaseID = @gameID");
                    param.Add(db.Parameter("@gameID", gid));
                }

                if (!string.IsNullOrWhiteSpace(slug))
                {
                    mainSql.Append("\nAND c.Slug = @slug");
                    param.Add(db.Parameter("@slug", slug));
                }

                if (!string.IsNullOrWhiteSpace(tableName))
                {
                    mainSql.AppendFormat("\nAND {0}( a.TableName, b.TableName) LIKE @tableName", db.DatabaseType == DatabaseType.MySQL ? "IFNULL" : "ISNULL");
                    param.Add(db.Parameter("@tableName", string.Format("%{0}%", tableName.Replace("[","[[")) ));
                }

                if (!string.IsNullOrWhiteSpace(clientType))
                {
                    mainSql.AppendFormat("\nAND {0}( a.ClientCompatibility, b.ClientCompatibility) LIKE @clientCompatibility", db.DatabaseType == DatabaseType.MySQL ? "IFNULL" : "ISNULL");
                    param.Add(db.Parameter("@clientCompatibility", string.Format("%,{0},%", clientType)));
                }

                if (categories != null && categories.Length > 0)
                {

                    mainSql.Append("\nAND (");
                    for (int i = 0; i < categories.Length; i++)
                    {
                        if (i > 0)
                            mainSql.Append(" OR ");

                        if (string.Equals("Uncategorized", categories[i], StringComparison.InvariantCultureIgnoreCase))
                        {
                            mainSql.AppendFormat("({0}( a.Category, b.Category) IS NULL OR {0}( a.Category, b.Category) = '' OR {0}( a.Category, b.Category) = ',')", db.DatabaseType == DatabaseType.MySQL ? "IFNULL" : "ISNULL");
                        }
                        else
                        {
                            paramName = string.Format(CultureInfo.InvariantCulture, "@category_{0:D}", i);
                            mainSql.AppendFormat(CultureInfo.InvariantCulture, "{0}( a.Category, b.Category) = {1}", db.DatabaseType == DatabaseType.MySQL ? "IFNULL" : "ISNULL", paramName);
                            param.Add(db.Parameter(paramName, string.Format(CultureInfo.InvariantCulture, "{0}", categories[i])));
                        }
                    }
                    mainSql.Append(")");

                    //param.Add(db.Parameter("@clientCompatibility", string.Format("%,{0},%", clientType)));
                }

                if (!string.IsNullOrWhiteSpace(tableType))
                {
                    switch (tableType.ToLowerInvariant())
                    {
                        case "viptable":
                            mainSql.AppendFormat("\nAND {0}( a.VIPTable, b.VIPTable) = 1 ", db.DatabaseType == DatabaseType.MySQL ? "IFNULL" : "ISNULL");
                            break;
                        case "newtable":
                            mainSql.Append("\nAND   a.NewTable  = 1 " );
                            break;
                        case "turkishtable":
                            mainSql.Append("\nAND   a.TurkishTable  = 1 " );
                            break;
                        case "betbehindavailable":
                            mainSql.Append("\nAND  a.BetBehindAvailable  = 1 " );
                            break;
                        case "excludefromrandomlaunch":
                            mainSql.Append("\nAND  a.ExcludeFromRandomLaunch  = 1 " );
                            break;
                        case "seatsunlimited":
                            mainSql.Append("\nAND   a.SeatsUnlimited  = 1 ");
                            break;
                        default:
                            break;
                    }
                }


                if (!string.IsNullOrWhiteSpace(openingHour))
                {
                    switch (openingHour.ToLowerInvariant())
                    {
                        case "24x7":
                            mainSql.Append("\nAND (b.OpenHoursStart = b.OpenHoursEnd)");
                            break;
                        case "non24x7":
                            mainSql.Append("\nAND (b.OpenHoursStart <> b.OpenHoursEnd)");
                            break;
                        default:
                            break;
                    }
                }

                if (excludeDisabledTables)
                {
                    mainSql.AppendFormat("\nAND {0}( a.Enabled, b.Enabled) = 1", db.DatabaseType == DatabaseType.MySQL ? "IFNULL" : "ISNULL");
                }

                if (excludeOperatorInvisible)
                {
                    mainSql.Append("AND (a.OpVisible=1 OR (a.OpVisible IS NULL AND b.OpVisible=1)) ");
                }

                string sql = string.Format(CultureInfo.InvariantCulture
                    , "SELECT COUNT(*) FROM ({0}) AS YYYYY"
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

                db.SetCommand(sql.ToString()
                    , param.ToArray()
                    );
                return db.ExecuteList<ceLiveCasinoTableBaseEx>();
            }
        }

        public static List<ceLiveCasinoTableBaseEx> GetDomainTables(long domainID, VendorID[] vendors, bool excludeDisabledTables = false,  bool excludeOperatorInvisible = false)
        {
            return InternalGetDomainTables(domainID, vendors, excludeDisabledTables, excludeOperatorInvisible);
        }

        private static List<ceLiveCasinoTableBaseEx> InternalGetDomainTables(long domainID, VendorID[] vendors, bool excludeDisabledTables = false, bool excludeOperatorInvisible = false)
        {
            using (DbManager db = new DbManager())
            {
                StringBuilder sql = GetPrimarySQL(db.DatabaseType);


                sql.AppendLine("\nWHERE 1 = 1");

                if (vendors != null)
                {
                    sql.Append("\nAND c.VendorID IN ( ");
                    foreach (VendorID vendor in vendors)
                    {
                        sql.AppendFormat("{0:D},", (int)vendor);
                    }
                    sql.Remove(sql.Length - 1, 1);
                    sql.AppendLine(")");
                }

                if (excludeDisabledTables)
                {
                    sql.AppendFormat("\nAND {0}( a.Enabled, b.Enabled) = 1", db.DatabaseType == DatabaseType.MySQL ? "IFNULL" : "ISNULL");
                }

                if (excludeOperatorInvisible)
                {
                    sql.AppendFormat("\nAND {0}( a.OpVisible, b.OpVisible) = 1", db.DatabaseType == DatabaseType.MySQL ? "IFNULL" : "ISNULL");
                }

                db.SetCommand(sql.ToString()
                    , db.Parameter("@domainID", domainID)
                    );
                return db.ExecuteList<ceLiveCasinoTableBaseEx>();
            }
        }

        public static ceLiveCasinoTableBaseEx GetDomainTable(long domainID, long id)
        {
            using (DbManager db = new DbManager())
            {
                StringBuilder sql = GetPrimarySQL(db.DatabaseType);

               

                sql.AppendLine("\nWHERE b.ID = @id");

                db.SetCommand(sql.ToString()
                    , db.Parameter("@domainID", domainID)
                    , db.Parameter("@id", id)
                    );
                return db.ExecuteObject<ceLiveCasinoTableBaseEx>();
            }
        }


        [SqlQuery(@"SELECT * FROM CeLiveCasinoTable WHERE DomainID = @domainID AND LiveCasinoTableBaseID = @tableID")]
        public abstract ceLiveCasinoTable GetTable(long domainID, long tableID);


        public static void InsertNewTableWithSpecificProperty(long domainID
            , long liveCasinoTableBaseID
            , string userSessionID
            , long sessionUserID
            , string column
            , object value
            , bool baseTableEnabled
            , bool baseTableOpVisible
            )
        {

            bool isEnabledColumn = string.Equals(column, "Enabled", StringComparison.InvariantCultureIgnoreCase);
            bool isOpVisibleColumn = string.Equals(column, "OpVisible", StringComparison.InvariantCultureIgnoreCase);
            string sql = string.Format(@"
INSERT INTO CeLiveCasinoTable 
(
DomainID, Ins, HID, LiveCasinoTableBaseID, SessionUserID, SessionID, {0} {1} {2}
) 
VALUES 
(
@domainID, @ins, 0, @liveCasinoTableBaseID, @sessionUserID, @sessionID, @value {3} {4}
)"
                , column
                , isEnabledColumn ? string.Empty : ",Enabled"
                , isOpVisibleColumn ? string.Empty : ",OpVisible"
                , isEnabledColumn ? string.Empty : (baseTableEnabled ? ",1" : ",0")
                , isOpVisibleColumn ? string.Empty : (baseTableOpVisible ? ",1" : ",0")
                );

            using (DbManager db = new DbManager())
            {
                db.SetCommand(sql
                    , db.Parameter("@domainID", domainID)
                    , db.Parameter("@ins", DateTime.Now)
                    , db.Parameter("@liveCasinoTableBaseID", liveCasinoTableBaseID)
                    , db.Parameter("@sessionUserID", sessionUserID)
                    , db.Parameter("@sessionID", sessionUserID)
                    , db.Parameter("@value", value ?? DBNull.Value)
                    );
                db.ExecuteNonQuery();
            }
        }

        public static void UpdateChildTablesProperties(Dictionary<string, object> properties, long baseTableId)
        {
            if (properties.Count > 0)
            {
                using (DbManager db = new DbManager())
                {
                    var dbParams = new List<IDbDataParameter>();
                    StringBuilder sql = new StringBuilder("UPDATE CeLiveCasinoTable SET ");
                    int i = 0;

                    foreach (KeyValuePair<string, object> property in properties)
                    {
                        sql.AppendFormat("{0} = @value{1} ", property.Key, (i + 1 < properties.Count) ? i + "," : i.ToString());
                        dbParams.Add(db.Parameter("@value" + i, property.Value ?? DBNull.Value));
                        i++;
                    }

                    sql.Append("WHERE LiveCasinoTableBaseID = @baseTableId");
                    dbParams.Add(db.Parameter("@baseTableId", baseTableId));
                    db.SetCommand(sql.ToString(), dbParams.ToArray());
                    db.ExecuteNonQuery();
                }
            }
        }
        
        public static void UpdateTableProperty(string column, object value, long id)
        {
            using (DbManager db = new DbManager())
            {
                string sql = string.Format(CultureInfo.InvariantCulture, "UPDATE CeLiveCasinoTable SET {0} = @value WHERE ID = @id", column);
                db.SetCommand(sql
                    , db.Parameter("@value", value ?? DBNull.Value)
                    , db.Parameter("@id", id)
                    );
                db.ExecuteNonQuery();
            }
        }


        public static void UpdateTableBaseProperty(string column, object value, long id)
        {
            using (DbManager db = new DbManager())
            {
                string sql = string.Format(CultureInfo.InvariantCulture, "UPDATE CeLiveCasinoTableBase SET {0} = @value WHERE ID = @id", column);
                db.SetCommand(sql
                    , db.Parameter("@value", value ?? DBNull.Value)
                    , db.Parameter("@id", id)
                    );
                db.ExecuteNonQuery();
            }
        }
    }
}
