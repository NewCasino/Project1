using System;
using System.Collections.Generic;
using BLToolkit.DataAccess;

namespace CM.db.Accessor
{
    public abstract class RevisionAccessor : DataAccessor<cmRevision>
    {
        [SqlQueryEx( MSSqlText = "SELECT TOP 1 * FROM cmRevision WITH(NOLOCK) WHERE [SiteID] = @siteID AND [RelativePath] = @relativePath ORDER BY [ID] DESC",
            MySqlText = "SELECT * FROM cmRevision WHERE `SiteID` = @siteID AND `RelativePath` = @relativePath ORDER BY `ID` DESC LIMIT 1")]
        public abstract cmRevision GetLastRevision(int siteID, string relativePath);

        [SqlQuery(@"
SELECT cmRevision.*, cmUser.Username 
FROM cmRevision
LEFT JOIN cmUser ON cmRevision.UserID = cmUser.ID 
WHERE cmRevision.SiteID = @siteID 
AND cmRevision.RelativePath LIKE @relativePath 
ORDER BY cmRevision.ID DESC")]
        public abstract List<cmRevision> GetLastRevisions( int siteID, string relativePath);

        [SqlQuery(@"SELECT cmRevision.*, cmUser.Username, cmSite.DistinctName AS 'DomainDistinctName'
FROM cmRevision 
LEFT JOIN cmUser ON cmRevision.UserID = cmUser.ID
INNER JOIN cmSite ON cmRevision.SiteID = cmSite.SiteID
WHERE cmRevision.ID = @ID")]
        public abstract cmRevision GetByID(int id);

        [SqlQuery(@"
SELECT cmRevision.*, cmUser.Username 
FROM cmRevision
LEFT JOIN cmUser ON cmRevision.UserID = cmUser.ID 
WHERE cmRevision.ID IN 
(
SELECT TOP {0} MAX(ID)
FROM cmRevision
WHERE SiteID = @siteID
AND RelativePath NOT LIKE '/.config/%' AND RelativePath NOT LIKE '/.changes/%' AND FilePath IS NOT NULL
AND RelativePath LIKE @relativePath
AND Ins BETWEEN @startTime AND @endTime
GROUP BY RelativePath
ORDER BY RelativePath
)
AND cmRevision.RelativePath LIKE @relativePath 
ORDER BY cmRevision.Ins DESC")]
        public abstract List<cmRevision> GetChangeFiles(int siteID, string relativePath, DateTime startTime, DateTime endTime, [Format] int pageSize);

        [SqlQuery(@"
SELECT cmRevision.*, cmUser.Username 
FROM cmRevision
LEFT JOIN cmUser ON cmRevision.UserID = cmUser.ID 
WHERE SiteID = @siteID 
AND cmRevision.Ins >= @time 
ORDER BY cmRevision.Ins DESC")]
        public abstract List<cmRevision> GetChanges(int siteID, DateTime time);
    }
}
