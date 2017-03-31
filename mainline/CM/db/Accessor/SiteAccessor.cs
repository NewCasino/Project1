using System.Collections.Generic;
using System.Data;
using BLToolkit.DataAccess;

namespace CM.db.Accessor
{
    public abstract class SiteAccessor : DataAccessor<cmSite>
    {
        [SqlQuery(@"SELECT a.*, b.ApiUsername, b.SecurityToken, b.EmailHost, b.PasswordEncryptionMode, b.SessionCookieName, b.SessionCookieDomain
FROM cmSite a
INNER JOIN cmDomain b ON a.DomainID = b.ID
WHERE a.DomainID = @domainID")]
        public abstract List<cmSite> GetByDomainID(int domainID);

        [SqlQuery(@"SELECT a.*, b.ApiUsername, b.SecurityToken, b.EmailHost, b.PasswordEncryptionMode, b.SessionCookieName, b.SessionCookieDomain
FROM cmSite a
INNER JOIN cmDomain b ON a.DomainID = b.ID
WHERE a.SiteID = @siteID")]
        public abstract cmSite GetBySiteID(int siteID);

        [SqlQuery(@"SELECT a.*, b.ApiUsername, b.SecurityToken, b.EmailHost, b.PasswordEncryptionMode, b.SessionCookieName, b.SessionCookieDomain
FROM cmSite a
INNER JOIN cmDomain b ON a.DomainID = b.ID
WHERE a.DistinctName = @distinctName")]
        public abstract cmSite GetByDistinctName(string distinctName);

        [SqlQuery(@"SELECT a.*, b.ApiUsername, b.SecurityToken, b.EmailHost, b.PasswordEncryptionMode, b.SessionCookieName, b.SessionCookieDomain, b.Title AS 'OperatorName'
FROM cmSite a
INNER JOIN cmDomain b ON a.DomainID = b.ID AND b.IsDeleted = 0")]
        public abstract List<cmSite> GetAll();

        [SqlQuery(@"SELECT a.*, b.ApiUsername, b.SecurityToken, b.EmailHost, b.PasswordEncryptionMode, b.SessionCookieName, b.SessionCookieDomain
FROM cmSite a
INNER JOIN cmDomain b ON a.DomainID = b.ID
WHERE b.SecurityToken = @securityToken")]
        public abstract cmSite GetBySecurityToken([ParamSize(64), ParamDbType(DbType.AnsiString)] string securityToken);

        [SqlQueryEx(MSSqlText = @"SET IDENTITY_INSERT cmDomain ON;
INSERT INTO cmDomain( Title,  UserID, PasswordEncryptionMode, IsMultiDomain,  DistinctName, IsExported,  ApiUsername,  SecurityToken, DomainID, FolderID,       Ins, IsDeleted, IsLiveMode,  SessionCookieName, ID) 
SELECT               @title, @userID,                      0,             0, @distinctName,          1, @apiUsername, @securityToken,        0,        0, GETDATE(),         0,          0, N'cmSession', max(Max_DomainID) + 1
from vw_Distributed_Domain;
SET IDENTITY_INSERT cmDomain OFF;
SELECT @@IDENTITY;
",
                   MySqlText = @"
INSERT INTO cmDomain( Title,  UserID, PasswordEncryptionMode, IsMultiDomain,  DistinctName, IsExported,  ApiUsername,  SecurityToken, DomainID, FolderID,                 Ins, IsDeleted, IsLiveMode,  SessionCookieName) 
VALUES(              @title, @userID,                      0,             0, @distinctName,          1, @apiUsername, @securityToken,        0,        0, CURRENT_TIMESTAMP(),         0,          0,  'cmSession');
SELECT LAST_INSERT_ID();")]
        public abstract int CreateDomain(string title, string distinctName, string apiUsername, string securityToken, int userID);


        [SqlQuery(@"UPDATE cmDomain SET SessionCookieDomain = @sessionCookieDomain,
SessionCookieName = @sessionCookieName,
EmailHost = @emailHost,
PasswordEncryptionMode = @passwordEncryptionMode
WHERE ID = @domainID")]
        public abstract int UpdateDomain(int domainID, string sessionCookieName, string sessionCookieDomain, string emailHost, int passwordEncryptionMode);

        [SqlQuery(@"SELECT FeedType FROM cmDomain WHERE ID = @domainID")]
        public abstract int GetFeedType(int domainID);

        [SqlQuery(@"UPDATE cmDomain SET FeedType = @feedType WHERE ID = @domainID")]
        public abstract int UpdateFeedType(int domainID, int feedType);

        [SqlQuery(@"SELECT ID, DistinctName FROM cmDomain")]
        [Index("ID")]
        [ScalarFieldName("DistinctName")]
        public abstract Dictionary<int, string> GetAllDomains();

        [SqlQuery(@"SELECT ID, DistinctName FROM cmDomain where IsDeleted = 0")]
        [Index("ID")]
        [ScalarFieldName("DistinctName")]
        public abstract Dictionary<int, string> GetActiveDomains();
    }
}
