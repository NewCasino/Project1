using System;
using BLToolkit.DataAccess;

namespace CE.db.Accessor
{
    public abstract class ChangeNotificationAccessor : DataAccessor<ceChangeNotification>
    {
        [SqlQueryEx(
            MSSqlText = @"SELECT TOP 1 * FROM ceChangeNotification WHERE DomainID = @domainID AND Type=@type AND Ins > @recentTime ORDER BY Ins DESC;",
            MySqlText = @"SELECT * FROM ceChangeNotification WHERE DomainID = @domainID AND Type=@type AND Ins > @recentTime ORDER BY Ins DESC LIMIT 0, 1"
            )]
        public abstract ceChangeNotification GetLastSuccessfulChangeNotification(long domainID, string type, DateTime recentTime);
    }
}
