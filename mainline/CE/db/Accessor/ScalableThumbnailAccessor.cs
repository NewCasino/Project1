using System.Collections.Generic;
using BLToolkit.DataAccess;

namespace CE.db.Accessor
{
    public abstract class ScalableThumbnailAccessor : DataAccessor<ceScalableThumbnail>
    {
       
        [SqlQueryEx( MSSqlText = @"
SELECT
	DISTINCT
    d.ScalableThumbnailWidth AS 'Width',
    d.ScalableThumbnailHeight AS 'Height',
    f.FilePath,
    f.OrginalFileName
FROM CeCasinoGameBase b WITH(NOLOCK) 
INNER JOIN CeDomainConfig d WITH(NOLOCK) ON d.EnableScalableThumbnail = 1
LEFT JOIN CeCasinoGame a WITH(NOLOCK) ON a.CasinoGameBaseID = b.ID AND a.DomainID = d.DomainID
LEFT JOIN CeScalableThumbnail c WITH(NOLOCK) ON ISNULL( a.ScalableThumbnail, b.ScalableThumbnail) = c.OrginalFileName AND c.Width = d.ScalableThumbnailWidth AND c.Height = d.ScalableThumbnailHeight
OUTER APPLY
(
	SELECT TOP 1 * FROM CeScalableThumbnail e WITH(NOLOCK)
	WHERE e.OrginalFileName = ISNULL( a.ScalableThumbnail, b.ScalableThumbnail)
	ORDER BY e.Height DESC
) AS f
WHERE 
( 
	( b.ScalableThumbnail IS NOT NULL ) 
	OR 
	( a.ScalableThumbnail IS NOT NULL )
)
AND c.FilePath IS NULL
",
        MySqlText = @"
SELECT
	DISTINCT
    d.ScalableThumbnailWidth AS 'Width',
    d.ScalableThumbnailHeight AS 'Height',
    f.FilePath,
    f.OrginalFileName
FROM CeCasinoGameBase b
INNER JOIN CeDomainConfig d ON d.EnableScalableThumbnail = 1
LEFT JOIN CeCasinoGame a ON a.CasinoGameBaseID = b.ID AND a.DomainID = d.DomainID
LEFT JOIN CeScalableThumbnail c ON IFNULL( a.ScalableThumbnail, b.ScalableThumbnail) = c.OrginalFileName AND c.Width = d.ScalableThumbnailWidth AND c.Height = d.ScalableThumbnailHeight
LEFT JOIN (
	SELECT t1.OrginalFileName, t1.FilePath
	FROM CeScalableThumbnail AS t1
	LEFT JOIN CeScalableThumbnail AS t2
		ON t1.OrginalFileName = t2.OrginalFileName AND t1.Height > t2.Height
	WHERE t2.OrginalFileName IS NULL ) AS f
	ON f.OrginalFileName = IFNULL( a.ScalableThumbnail, b.ScalableThumbnail)
WHERE 
( 
	( b.ScalableThumbnail IS NOT NULL ) 
	OR 
	( a.ScalableThumbnail IS NOT NULL )
)
AND c.FilePath IS NULL
AND f.FilePath IS NOT NULL")]
        public abstract List<ceScalableThumbnail> GetUnscaledThumbnail();

        [SqlQuery( @"
SELECT (CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END) FROM CeScalableThumbnail
WHERE OrginalFileName = @orginalFilename
AND Width = @width
AND Height = @height")]
        public abstract bool IsThumbnailExist(string orginalFilename, int width, int height);
    }
}
