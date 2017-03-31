using System;
using BLToolkit.DataAccess;

namespace CM.db.Accessor
{
    /// <summary>
    /// 
    /// </summary>
    public abstract class UserPasswordHistoryAccessor : DataAccessor<cmUserPasswordHistory>
    {
        /// <summary>
        /// 
        /// </summary>
        /// <param name="domainID"></param>
        /// <param name="userID"></param>
        /// <param name="password"></param>
        /// <returns></returns>
        [SqlQuery("SELECT (CASE COUNT(*) WHEN 0 THEN 0 ELSE 1 END) FROM cmUserPasswordHistory WHERE DomainID=@domainID and UserID=@userID and [Password]=@password ")]
        public abstract bool Exists(long domainID, long userID, string password);

        [SqlQuery("SELECT (CASE COUNT(*) WHEN 0 THEN 0 ELSE 1 END) FROM cmUserPasswordHistory WHERE DomainID=@domainID and UserID=@userID")]
        public abstract bool Exists(long domainID, long userID);

        /// <summary>
        /// 
        /// </summary>
        /// <param name="domainID"></param>
        /// <param name="userID"></param>
        /// <param name="password"></param>
        /// <param name="now"></param>
        [SqlQuery("INSERT INTO cmUserPasswordHistory( DomainID, UserID, Password, Ins) VALUES ( @domainID, @userID, @password, @now)")]
        public abstract void Create(long domainID, long userID, string password, DateTime now);

    }
}
