using System.Collections.Generic;
using BLToolkit.DataAccess;

namespace CM.db.Accessor
{
    public abstract class HostAccessor : DataAccessor<cmHost>
    {
        [SqlQuery("SELECT * FROM cmHost")]
        public abstract List<cmHost> GetAll();

        [SqlQuery("SELECT * FROM cmHost WHERE SiteID = @siteID")]
        public abstract List<cmHost> GetBySiteID(int siteID);

        [SqlQuery("DELETE FROM cmHost WHERE SiteID = @siteID")]
        public abstract List<cmHost> RemoveBySiteID(int siteID);
    }
}
