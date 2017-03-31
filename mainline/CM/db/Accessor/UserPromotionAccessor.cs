using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Text;
using BLToolkit.Data;
using BLToolkit.DataAccess;

namespace CM.db.Accessor
{
    public abstract class UserPromotionAccessor : DataAccessor<cmUserPromotion>
    {
        [SqlQuery(@"INSERT INTO cmUserPromotion ( [UserID], [SiteID],[TargetSource])
    VALUES( @userID, @siteID, @targetSource);
    SELECT CONVERT(bigint, @@IDENTITY)")]
        public abstract long Create(int userID, int siteID, string targetSource);

        [SqlQuery(@"SELECT a.*, b.UserName, b.Email
FROM cmUserPromotion a
INNER JOIN cmUser b ON a.UserID = b.ID
WHERE a.SiteID = @siteID and a.ClickDate >= @startTime and a.ClickDate <= @endTime")]
        public abstract List<cmUserPromotion> Get(int siteID, DateTime startTime, DateTime endTime);

        [SqlQuery(@"SELECT a.*, b.UserName, b.Email
FROM cmUserPromotion a
INNER JOIN cmUser b ON a.UserID = b.ID
WHERE a.SiteID = @siteID")]
        public abstract List<cmUserPromotion> GetAllBySiteID(int siteID);

        
    }
}
