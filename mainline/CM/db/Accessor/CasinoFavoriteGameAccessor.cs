using System.Collections.Generic;
using BLToolkit.DataAccess;

namespace CM.db.Accessor
{
    public abstract class CasinoFavoriteGameAccessor : DataAccessor<string>
    {
        [SqlQuery(@"
INSERT cmCasinoFavoriteGame ( DomainID, UserID, GameID, Ins)
SELECT DomainID, @userID, GameID, Ins 
FROM cmCasinoFavoriteGame a
WHERE @userID > 0 
AND @clientIdentity < 0 
AND a.DomainID = @domainID 
AND a.UserID = @clientIdentity
AND NOT EXISTS
(
	SELECT GameID FROM cmCasinoFavoriteGame b
	WHERE b.DomainID = @domainID AND b.UserID = @userID AND b.GameID = a.GameID
);

SELECT DISTINCT GameID FROM cmCasinoFavoriteGame
WHERE DomainID = @domainID AND
(
	UserID = @userID
	OR UserID = @clientIdentity
) 
")]
        public abstract List<string> GetByUser(long domainID, long userID, long clientIdentity);

        [SqlQuery(@"
DELETE FROM cmCasinoFavoriteGame WHERE @userID > 0 AND DomainID = domainID AND UserID = @userID AND GameID = @gameID;
DELETE FROM cmCasinoFavoriteGame WHERE @clientIdentity < 0 AND DomainID = domainID AND UserID = @clientIdentity AND GameID = @gameID;
")]
        public abstract void DeleteByUserID(long domainID, long userID, long clientIdentity, string gameID);


        [SqlQuery(@"
SELECT CASE COUNT(*) WHEN 0 THEN 0 ELSE 1 END
FROM cmCasinoFavoriteGame 
WHERE DomainID = @domainID
AND GameID = @gameID 
AND UserID IN ( @userID , @clientIdentity )
")]
        public abstract bool IsFavoriteGame(long domainID, long userID, long clientIdentity, string gameID);
    }
}
