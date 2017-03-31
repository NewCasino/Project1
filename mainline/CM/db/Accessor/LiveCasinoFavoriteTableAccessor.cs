using System.Collections.Generic;
using BLToolkit.DataAccess;

namespace CM.db.Accessor
{
    public abstract class LiveCasinoFavoriteTableAccessor : DataAccessor<string>
    {
        [SqlQuery(@"
INSERT cmLiveCasinoFavoriteTable ( DomainID, UserID, TableID, Ins)
SELECT DomainID, @userID, TableID, Ins 
FROM cmLiveCasinoFavoriteTable a
WHERE @userID > 0 
AND @clientIdentity < 0 
AND a.DomainID = @domainID 
AND a.UserID = @clientIdentity
AND NOT EXISTS
(
	SELECT TableID FROM cmLiveCasinoFavoriteTable b
	WHERE b.DomainID = @domainID AND b.UserID = @userID AND b.TableID = a.TableID
);

SELECT DISTINCT TableID FROM cmLiveCasinoFavoriteTable
WHERE DomainID = @domainID AND
(
	UserID = @userID
	OR UserID = @clientIdentity
) 
")]
        public abstract List<string> GetByUser(long domainID, long userID, long clientIdentity);

        [SqlQuery(@"
DELETE FROM cmLiveCasinoFavoriteTable WHERE @userID > 0 AND DomainID = domainID AND UserID = @userID AND TableID = @tableID;
DELETE FROM cmLiveCasinoFavoriteTable WHERE @clientIdentity < 0 AND DomainID = domainID AND UserID = @clientIdentity AND TableID = @tableID;
")]
        public abstract void DeleteByUserID(long domainID, long userID, long clientIdentity, string tableID);


        [SqlQuery(@"
SELECT CASE COUNT(*) WHEN 0 THEN 0 ELSE 1 END
FROM cmLiveCasinoFavoriteTable 
WHERE DomainID = @domainID
AND TableID = @tableID 
AND UserID IN ( @userID , @clientIdentity )
")]
        public abstract bool IsFavoriteGame(long domainID, long userID, long clientIdentity, string tableID);
    }
}