using System.Collections.Generic;
using System.Text;
using BLToolkit.Data;
using BLToolkit.DataAccess;

namespace CE.db.Accessor
{
    public abstract class ContentProviderAccessor : DataAccessor
    {
        private static StringBuilder GetMainSQL(DatabaseType dbType)
        {
            string isNull = dbType == DatabaseType.MySQL ? "IFNULL" : "ISNULL";

            StringBuilder sql = new StringBuilder();

            sql.AppendFormat(@"
SELECT
    b.ID,    
    b.Identifying, 
    b.Name,    
    {0}( a.Logo, b.Logo) AS 'Logo',
    {0}( a.[Enabled], b.[Enabled]) AS 'Enabled',    
    a.Ins ,
    @domainID AS 'DomainID'
FROM ceContentProviderBase b
LEFT JOIN ceContentProvider a ON a.ContentProviderBaseID = b.ID AND a.DomainID = @domainID", isNull);

            return sql;
        }


        [SqlQueryEx(MSSqlText = @"SELECT TOP 1 * FROM ceContentProvider WITH(NOLOCK) WHERE ContentProviderBaseID=@id AND DomainID=@domainID"
            , MySqlText = @"SELECT * FROM ceContentProvider WHERE ContentProviderBaseID=@id AND DomainID=@domainID LIMIT 0,1")]
        public abstract ceContentProvider QueryDomainProvider(int id, long domainID);

        public static ceContentProviderBase Get(int id, long domainID)
        {
            using (DbManager db = new DbManager())
            {
                StringBuilder sql = GetMainSQL(db.DatabaseType);

                sql.Append(" where b.ID = @id");

                db.SetCommand(sql.ToString()
                    , db.Parameter("@domainID", domainID)
                    , db.Parameter("@id", id)
                    );

                return db.ExecuteObject<ceContentProviderBase>();
            }
        }

        public static List<ceContentProviderBase> GetAll(long domainID, long systemDomainID)
        {
            using (DbManager db = new DbManager())
            {
                StringBuilder sbSql = GetMainSQL(db.DatabaseType);

                string sql;
                if (domainID != systemDomainID)
                    sql = string.Format("SELECT * FROM ({0}) AS t WHERE [Enabled]=1", sbSql);
                else
                    sql = sbSql.ToString();

                db.SetCommand(sql
                    , db.Parameter("@domainID", domainID)
                    );

                return db.ExecuteList<ceContentProviderBase>();
            }
        }

        public static List<ceContentProviderBase> GetEnabledProviderList(long domainID, long systemDomainID)
        {
            using (DbManager db = new DbManager())
            {
                StringBuilder sql = new StringBuilder();
                StringBuilder sql1 = GetMainSQL(db.DatabaseType);

                sql.AppendFormat("SELECT * FROM ({0}) AS t WHERE [Enabled]=1", sql1);

                db.SetCommand(sql.ToString()
                    , db.Parameter("@domainID", domainID)
                    );

                return db.ExecuteList<ceContentProviderBase>();
            }
        }
    }
}
