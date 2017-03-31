using System.Collections.Generic;
using Insight.Database;

namespace CmsSanityCheck.DB.Accessor
{
    using Model;
    using DB.Tool;

    public static class SiteAccessor
    {
        public static IList<cmSite> GetAll(Service service)
        {
            string sql = @"SELECT SiteID, DomainID, DisplayName FROM cmSite WITH (NOLOCK)
                           WHERE DomainID IN (SELECT ID FROM cmDomain WITH (NOLOCK) WHERE IsDeleted = 0)";
            using (var conn = DbConnection.Open(service))
            {
                return conn.QuerySql<cmSite>(sql);
            }
        }
    }
}
