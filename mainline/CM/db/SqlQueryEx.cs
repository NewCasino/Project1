using System;
using BLToolkit.Data;
using BLToolkit.DataAccess;

namespace CM.db
{
    public class SqlQueryEx : SqlQueryAttribute
    {


        public SqlQueryEx()
        {
            IsDynamic = true;
        }

        public string MSSqlText { get; set; }
        public string MySqlText { get; set; }

        public override string GetSqlText(DataAccessor accessor, DbManager dbManager)
        {
            string sql = GetSqlText(dbManager.DatabaseType);
            return sql;
        }

        protected virtual string GetSqlText(DatabaseType dbType)
        {
            switch (dbType)
            {
                case DatabaseType.MySQL:
                    {
                        if (this.MySqlText != null)
                            return this.MySqlText;
                        else
                            throw new ArgumentNullException("No SQL is found for MySQL database");
                    }

                case DatabaseType.MSSQL:
                    {
                        if (this.MSSqlText != null)
                            return this.MSSqlText;
                        else
                            throw new ArgumentNullException("No SQL is found for SQL Server database");
                    }

                default:
                    break;
            }
            throw new NotSupportedException();
        }
    }
}
