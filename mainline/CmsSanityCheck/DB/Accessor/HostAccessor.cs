using System.Collections.Generic;
using Insight.Database;

namespace CmsSanityCheck.DB.Accessor
{
    using Model;
    using DB.Tool;

    public static class HostAccessor
    {
        public static IList<cmHost> GetAll(Service service)
        {
            const string sql = "SELECT SiteID, HostName FROM cmHost WITH (NOLOCK)";
            using (var conn = DbConnection.Open(service))
            {
                return conn.QuerySql<cmHost>(sql);
            }
        }
    }
}
