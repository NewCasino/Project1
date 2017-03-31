using System;
using System.Collections.Generic;
using System.Data;
using BLToolkit.Data;
using BLToolkit.DataAccess;
using BLToolkit.Mapping;

using CM.db;
using GamMatrix.Infrastructure;

namespace CM.db.Accessor
{
    /// <summary>
    /// The accessor of the cmSession table
    /// </summary>
    public abstract class SessionAccessor : DataAccessor<cmSession>
    {
        /// <summary>
        /// Get cmSession bu GUID
        /// </summary>
        /// <param name="guid">session guid</param>
        /// <returns>cmSession</returns>
        [SqlQuery(@"SELECT cmSession.*, cmUser.Username, cmUser.Firstname, cmUser.Surname, cmUser.CountryID as 'UserCountryID', cmUser.Currency as 'UserCurrency', cmUser.AffiliateMarker, cmUser.IsEmailVerified,cmUser.Alias
FROM cmSession
INNER JOIN cmUser ON cmUser.ID = cmSession.UserID AND cmSession.UserID <> 0 AND cmSession.Guid = @guid
WHERE cmSession.Guid = @guid")]
        public abstract cmSession GetByGuid([ParamSize(36), ParamDbType(DbType.AnsiString)] string guid);

        [SqlQueryEx(MSSqlText = @"SELECT TOP 1 [Guid] FROM cmSession WITH(NOLOCK) WHERE IsAuthenticated = 1 AND IsExpired = 0 AND UserID = @userID ORDER BY ID DESC",
            MySqlText = @"SELECT Guid FROM cmSession WHERE IsAuthenticated = 1 AND IsExpired = 0 AND UserID = @userID ORDER BY ID DESC LIMIT 1;")]
        public abstract string GetByUserID(long userID);

        [SqlQueryEx(MSSqlText = @"select top 1 * from 
(select top 1 ID,Guid,UserID,DomainID,IP,RoleString,Ins,LastAccess,Culture,Url,UrlReferrer,Browser,CookiesSupported,IsAuthenticated,
Login,Logout,IsExpired,CountryID,UserLanguages,TimeZoneAddMinutes,LocationID,Latitude,Longitude,ExitReason,SessionLimitSeconds from cmSession
where userid = @userID
order by ins desc
union 
select top 1 ID,Guid,UserID,DomainID,IP,RoleString,Ins,LastAccess,Culture,Url,UrlReferrer,Browser,CookiesSupported,IsAuthenticated,
Login,Logout,IsExpired,CountryID,UserLanguages,TimeZoneAddMinutes,LocationID,Latitude,Longitude,ExitReason,SessionLimitSeconds from cmSessionArchive
where userid = @userID
order by ins desc) l
order by ins desc",
            MySqlText = @"select * from 
(select ID,Guid,UserID,DomainID,IP,RoleString,Ins,LastAccess,Culture,Url,UrlReferrer,Browser,CookiesSupported,IsAuthenticated,
Login,Logout,IsExpired,CountryID,UserLanguages,TimeZoneAddMinutes,LocationID,Latitude,Longitude,ExitReason,SessionLimitSeconds from cmSession
where userid = @userID
order by ins desc limit 1
union 
select ID,Guid,UserID,DomainID,IP,RoleString,Ins,LastAccess,Culture,Url,UrlReferrer,Browser,CookiesSupported,IsAuthenticated,
Login,Logout,IsExpired,CountryID,UserLanguages,TimeZoneAddMinutes,LocationID,Latitude,Longitude,ExitReason,SessionLimitSeconds from cmSessionArchive
where userid = @userID
order by ins desc  limit 1) l
order by ins desc
limit 1;")]
        public abstract cmSession GetLatestSessionByUserID(long userID);



        /// <summary>
        /// Update last access time
        /// </summary>
        /// <param name="guid">session guid</param>
        /// <param name="lastAccess">last access time</param>
        [SqlQuery(@"UPDATE cmSession  SET Modified=GETDATE(), LastAccess=@lastAccess WHERE Guid=@guid AND IsExpired = 0")]
        public abstract void UpdateLastAccess([ParamSize(36), ParamDbType(DbType.AnsiString)] string guid, DateTime lastAccess);

        [SqlQuery(@"UPDATE cmSession  SET Modified=GETDATE(), RoleString=@roleString WHERE Guid=@guid")]
        public abstract void UpdateRoleString([ParamSize(36), ParamDbType(DbType.AnsiString)] string guid, string roleString);

        /// <summary>
        /// Logoff session
        /// </summary>
        /// <param name="guid">session guid</param>
        /// <param name="now">current time</param>
        /// <param name="exitReason">session exit reason</param>
        [SqlQuery(@"UPDATE cmSession  SET Modified=GETDATE(), LastAccess=@now, Logout=@now, IsExpired=1, ExitReason=@exitReason WHERE Guid=@guid")]
        public abstract void Logoff([ParamSize(36), ParamDbType(DbType.AnsiString)] string guid, DateTime now, EveryMatrix.SessionAgent.Protocol.SessionExitReason exitReason);


        [SqlQuery(@"
INSERT INTO cmSession
           (Guid
           ,UserID
           ,IP
           ,RoleString
           ,Ins
           ,DomainID
           ,TimeZoneAddMinutes
           ,Culture
           ,Url
           ,UrlReferrer
           ,Browser
           ,AffiliateCode
           ,IsAuthenticated
           ,Login
           ,Logout
           ,IsExpired
           ,CountryID
           ,LocationID
           ,Latitude
           ,Longitude
           ,UserLanguages
           ,LastAccess
           ,Properties
           ,CookiesSupported
           ,IsExternal
           ,SessionLimitSeconds
            )
     VALUES
           (@guid
           ,@userID
           ,@ip
           ,@roleString
           ,@now
           ,@domainID
           ,0
           ,@culture
           ,''
           ,''
           ,@browser
           ,@affiliateCode
           ,1
           ,@now
           ,NULL
           ,0
           ,@countryID
           ,@locationID
           ,@latitude
           ,@longitude
           ,@userLanguages
           ,@now
           ,''
           ,1
           ,@isExternal
           ,@sessionLimitSeconds
           )")]
        public abstract void Insert([ParamSize(36), ParamDbType(DbType.AnsiString)] string guid
            , long userID
            , [ParamSize(15), ParamDbType(DbType.AnsiString)] string ip
            , [ParamSize(256), ParamDbType(DbType.AnsiString)] string roleString
            , DateTime now
            , int domainID
            , [ParamSize(10), ParamDbType(DbType.AnsiString)] string culture
            , [ParamSize(256), ParamDbType(DbType.AnsiString)] string browser
            , [ParamSize(64), ParamDbType(DbType.AnsiString)] string affiliateCode
            , int countryID
            , int locationID
            , float latitude
            , float longitude
            , [ParamSize(256), ParamDbType(DbType.AnsiString)] string userLanguages
            , bool isExternal
            , int sessionLimitSeconds
            );

        public static void CreateSession(cmSession session)
        {
            SessionAccessor sa = SessionAccessor.CreateInstance<SessionAccessor>();
            sa.Insert(session.Guid
                , session.UserID
                , session.IP.Truncate(15)
                , session.RoleString.Truncate(256)
                , DateTime.Now
                , session.DomainID
                , session.Culture.Truncate(10)
                , session.Browser.Truncate(255)
                , session.AffiliateMarker.Truncate(64)
                , session.CountryID
                , session.LocationID
                , session.Latitude
                , session.Longitude
                , session.UserLanguages.Truncate(256)
                , session.IsExternal
                , session.SessionLimitSeconds
                );
        }
    }
}
