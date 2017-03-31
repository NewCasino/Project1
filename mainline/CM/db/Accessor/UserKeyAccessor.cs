using System;
using BLToolkit.DataAccess;

namespace CM.db.Accessor
{
    /// <summary>
    /// Accessor of table cmUserKey
    /// </summary>
    public abstract class UserKeyAccessor : DataAccessor<cmUserKey>
    {
        /// <summary>
        /// Get special user key by given parameter
        /// </summary>
        /// <param name="domainID">domain id</param>
        /// <param name="key">key</param>
        /// <param name="email">email address</param>
        /// <returns>cmUserKey</returns>
        [SqlQuery(@"
SELECT * FROM cmUserKey
INNER JOIN cmUser ON cmUser.ID = cmUserKey.UserID
WHERE cmUserKey.KeyType = 'Verification' AND cmUserKey.KeyValue = @key AND cmUser.Email = @email AND cmUser.DomainID = @domainID")]
        public abstract cmUserKey Get( int domainID, string key, string email);


        /// <summary>
        /// Get reset password user key
        /// </summary>
        /// <param name="domainID">domain id</param>
        /// <param name="key">key</param>
        /// <param name="now">current time</param>
        /// <returns>cmUserKey</returns>
        [SqlQuery(@"
SELECT * FROM cmUserKey
WHERE KeyType = 'ResetPassword' AND DomainID = @domainID AND KeyValue = @key AND Expiration > @now")]
        public abstract cmUserKey GetResetPasswordKey(int domainID, string key, DateTime now);

        /// <summary>
        /// Mark the given key as deleted
        /// </summary>
        /// <param name="domainID">domain id</param>
        /// <param name="key">key</param>
        [SqlQuery(@"UPDATE cmUserKey SET IsDeleted = 1 WHERE DomainID = @domainID AND KeyValue = @key")]
        public abstract void DeleteKey(int domainID, string key);

        [SqlQuery(@"
SELECT * FROM cmUserKey
WHERE KeyType = 'ChangeEmail' AND DomainID = @domainID AND KeyValue = @key AND Expiration > @now")]
        public abstract cmUserKey GetChangeEmailKey(int domainID, string key, DateTime now);

        [SqlQuery(@"
SELECT COUNT(*) FROM cmUserKey
WHERE KeyType = @keyType AND DomainID = @domainID AND UserID = @userID")]
        public abstract int GetKeyCount(int domainID, int userID, string keyType);
    }
}
