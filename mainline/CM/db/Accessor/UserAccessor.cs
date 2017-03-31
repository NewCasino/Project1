using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Text;
using BLToolkit.Data;
using BLToolkit.DataAccess;

namespace CM.db.Accessor
{
    /// <summary>
    /// Accessor of database cmUser table
    /// </summary>
    public abstract class UserAccessor : DataAccessor<cmUser>
    {
        /// <summary>
        /// Get users by domain id and usernames
        /// </summary>
        /// <param name="domain2UsernameMap">map of domain id == username pair</param>
        /// <returns>List&lt;cmUser&gt;</returns>
        public static List<cmUser> GetUsersByUsername(List<KeyValuePair<long, string>> domain2UsernameMap)
        {
            if (domain2UsernameMap == null || domain2UsernameMap.Count == 0)
                return new List<cmUser>();

            using (DbManager db = new DbManager())
            {
                List<IDbDataParameter> param = new List<IDbDataParameter>();

                StringBuilder sql = new StringBuilder();
                sql.Append("SELECT * FROM cmUser WHERE ");
                int index = 0;
                foreach (KeyValuePair<long, string> domain2UsernamePair in domain2UsernameMap)
                {
                    string p1 = string.Format("@DomainID{0}", index);
                    string p2 = string.Format("@Username{0}", index);
                    index++;
                    param.Add(new SqlParameter(p1, domain2UsernamePair.Key));
                    param.Add(new SqlParameter(p2, domain2UsernamePair.Value));
                    sql.AppendFormat(" (DomainID={0} AND Username={1}) OR"
                        , p1
                        , p2
                        );
                }
                sql.Remove( sql.Length - 2, 2);
                db.SetCommand(sql.ToString(), param.ToArray());
                return db.ExecuteList<cmUser>();
            }
        }

        /// <summary>
        /// Get user by ID
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        [SqlQuery("SELECT * FROM cmUser WHERE ID = @id")]
        public abstract cmUser GetByID(long id);

        /// <summary>
        /// Get user by username
        /// </summary>
        /// <param name="domainID">site id</param>
        /// <param name="username">username</param>
        /// <returns>cmUser</returns>
        [SqlQuery("SELECT * FROM cmUser WHERE DomainID = @domainID AND Username = @username")]
        public abstract cmUser GetByUsername(int domainID, string username);

        /// <summary>
        /// Get user by email address
        /// </summary>
        /// <param name="domainID">site id</param>
        /// <param name="email">email address</param>
        /// <returns>cmUser</returns>
        [SqlQuery("SELECT * FROM cmUser WHERE DomainID = @domainID AND Email = @email")]
        public abstract cmUser GetByEmail(int domainID, string email);

        /// <summary>
        /// Get user by username or email address
        /// </summary>
        /// <param name="domainID">site id</param>
        /// <param name="username">username</param>
        /// <param name="email">email address</param>
        /// <returns></returns>
        [SqlQuery("SELECT * FROM cmUser WHERE DomainID = @domainID AND (Username = @username OR Email = @email)")]
        public abstract cmUser GetByUsernameOrEmail(int domainID, string username, string email);

        /// <summary>
        /// Get user by personalID/CPR or email address
        /// </summary>
        /// <param name="domainID">site id</param>
        /// <param name="personalID">personalID</param> 
        /// <returns></returns>
        [SqlQuery("SELECT * FROM cmUser WHERE DomainID = @domainID AND PersonalID = @personalID ")]
        public abstract cmUser GetByPersonalID(int domainID, string personalID);
        /// <summary>
        /// Determine if the email address exists
        /// </summary>
        /// <param name="domainID">site id</param>
        /// <param name="userID">user ID</param>
        /// <param name="personalID">personal ID</param>
        /// <returns>true if the email address already exists</returns>
        [SqlQuery("SELECT (CASE COUNT(*) WHEN 0 THEN 0 ELSE 1 END) FROM cmUser WHERE DomainID = @domainID AND PersonalID = @personalID AND ID <> @userID")]
        public abstract bool IsPersonalIDExist(long domainID, long userID, string personalID);

        /// <summary>
        /// Determine if the email address exists
        /// </summary>
        /// <param name="domainID">site id</param>
        /// <param name="userID">user ID</param>
        /// <param name="email">email address</param>
        /// <returns>true if the email address already exists</returns>
        [SqlQuery("SELECT (CASE COUNT(*) WHEN 0 THEN 0 ELSE 1 END) FROM cmUser WHERE DomainID = @domainID AND Email = @email AND ID <> @userID")]
        public abstract bool IsEmailExist(long domainID, long userID, string email);

        /// <summary>
        /// Determine if the username exists
        /// </summary>
        /// <param name="domainID">site id</param>
        /// <param name="username">uaername</param>
        /// <returns>true if the username already exists</returns>
        [SqlQuery("SELECT (CASE COUNT(*) WHEN 0 THEN 0 ELSE 1 END) FROM cmUser WHERE DomainID = @domainID AND Username = @username")]
        public abstract bool IsUsernameExist(int domainID, string username);

        /// <summary>
        /// Determine if the email mobile exists
        /// </summary>
        /// <param name="domainID">site id</param>
        /// <param name="userID">user ID</param>
        /// <param name="mobilePrefix">mobile prefix</param>
        /// <param name="mobile">mobile</param>
        /// <returns>true if the mobile number already exists</returns>
        [SqlQuery("SELECT (CASE COUNT(*) WHEN 0 THEN 0 ELSE 1 END) FROM cmUser WHERE DomainID = @domainID AND MobilePrefix = @mobilePrefix AND Mobile = @mobile AND ID <> @userID")]
        public abstract bool IsMobileExist(long domainID, long userID, string mobilePrefix, string mobile);

        /// <summary>
        /// Determine if the username exists
        /// </summary>
        /// <param name="domainID">site id</param>
        /// <param name="firstname">firstname</param>
        /// <param name="surname">surname</param>
        /// <param name="birth">birth</param>
        /// <returns>true if the username already exists</returns>
        [SqlQueryEx( MSSqlText = @"
SELECT (CASE COUNT(*) WHEN 0 THEN 0 ELSE 1 END) FROM cmUser 
WITH(NOLOCK)
WHERE DomainID = @domainID
AND DATEDIFF( day, Birth, @birth) = 0
AND ActiveStatus <> 1
AND ActiveStatus <> 2
AND RTRIM(LTRIM(FirstName)) = RTRIM(LTRIM(@firstname))
AND RTRIM(LTRIM(Surname)) = RTRIM(LTRIM(@surname))"
            , MySqlText = @"
SELECT (CASE COUNT(*) WHEN 0 THEN 0 ELSE 1 END) FROM cmUser 
WHERE DomainID = @domainID
AND DATEDIFF(Birth, @birth) = 0
AND ActiveStatus <> 1
AND ActiveStatus <> 2
AND RTRIM(LTRIM(FirstName)) = RTRIM(LTRIM(@firstname))
AND RTRIM(LTRIM(Surname)) = RTRIM(LTRIM(@surname))")]
        public abstract bool IsDunplicateUserExist(int domainID, string firstname, string surname, DateTime birth);


        /// <summary>
        /// Get the registration times from the same IP within 24 hours
        /// </summary>
        /// <param name="domainID">site</param>
        /// <param name="ip">ip address</param>
        /// <returns>the number of the registration times from the given IP.</returns>
        [SqlQueryEx( MSSqlText = "SELECT COUNT(*) FROM cmUser WITH(NOLOCK) WHERE SignupIP = @ip AND DomainID = @domainID AND DATEDIFF( day, Ins, GETDATE()) = 0",
            MySqlText = @"SELECT COUNT(*) FROM cmUser WHERE SignupIP = @ip AND DomainID = @domainID AND DATEDIFF(Ins, NOW()) = 0")]
        public abstract int GetRegistrationNumberTodayFromIP(int domainID, [ParamSize(15), ParamDbType(DbType.AnsiString)] string ip);

        /// <summary>
        /// Set the IsExported = 1 for given user
        /// </summary>
        /// <param name="userID">user id</param>
        /// <returns>the number of rows affacted</returns>
        [SqlQuery("UPDATE cmUser SET Modified=GETDATE(), IsExported = 1 WHERE ID = @userID")]
        public abstract int SetExported(long userID);

        /// <summary>
        /// Set the IsEmailVerified = 1 for given user
        /// </summary>
        /// <param name="userID">userid</param>
        [SqlQuery(@"UPDATE cmUser SET Modified=GETDATE(), IsEmailVerified=1 WHERE ID=@userID")]
        public abstract void VerifyEmail(long userID);

        /// <summary>
        /// Get the hashed password
        /// </summary>
        /// <param name="userID">userid</param>
        /// <returns>hash password</returns>
        [SqlQuery(@"SELECT Password FROM cmUser WHERE ID = @userID")]
        public abstract string GetHashedPassword(long userID);

        /// <summary>
        /// Increase the count of the failed login attempts
        /// </summary>
        /// <param name="userid">user id</param>
        /// <param name="now">current DateTime</param>
        /// <returns>is locked</returns>
        [SqlQuery(@"
UPDATE cmUser
SET Modified=GETDATE(), RecentLockTime = (CASE WHEN FailedLoginAttempts >= @failedLoginAttemptsLockUser THEN @now ELSE NULL END),
FailedLoginAttempts=(CASE WHEN FailedLoginAttempts >= @failedLoginAttemptsLockUser THEN 0 ELSE (FailedLoginAttempts+1) END)
WHERE Type=0 AND ID=@userid;
SELECT (CASE WHEN FailedLoginAttempts = 0 THEN @failedLoginAttemptsLockUser ELSE FailedLoginAttempts END) FROM cmUser WHERE ID=@userid")]
        public abstract int IncreaseFailedLoginAttempts(int userid, DateTime now, int failedLoginAttemptsLockUser);

        /// <summary>
        /// Update the fields after user login successfully
        /// </summary>
        /// <param name="guid">guid</param>
        /// <param name="userid">userid</param>
        /// <param name="now">current time</param>
        /// <returns>the number of row affected</returns>
        [SqlQueryEx( MSSqlText = @"
UPDATE TOP(1) cmUser  SET Modified=@now, FailedLoginAttempts=0, LastLogin=@now, LoginCount=LoginCount+1 WHERE ID=@userid;

DECLARE @temp TABLE ( [Guid] VARCHAR(64) );

INSERT INTO @temp
SELECT [Guid] FROM cmSession WITH(NOLOCK)
WHERE UserID = @userid  
AND [Guid] <> @guid
AND IsExpired = 0
AND IsAuthenticated = 1
AND [ID] < 
(
SELECT TOP 1 ID FROM cmSession WITH(NOLOCK) WHERE [Guid] = @guid
);

UPDATE s
SET s.Modified = @now, s.ExitReason = 3, s.IsExpired = 1, s.Logout = @now
FROM cmSession s 
INNER JOIN @temp t ON t.Guid = s.Guid;

SELECT * FROM @temp;",


                     MySqlText = @"
UPDATE cmUser SET Modified=@now, FailedLoginAttempts=0, LastLogin=@now, LoginCount=LoginCount+1 WHERE ID=@userid LIMIT 1;

DROP TEMPORARY TABLE IF EXISTS _table_variable;
CREATE TEMPORARY TABLE _table_variable (Guid varchar(64)) ENGINE=MEMORY; 

INSERT INTO _table_variable
SELECT Guid FROM cmSession
WHERE UserID = @userid  
AND Guid <> @guid
AND IsExpired = 0
AND IsAuthenticated = 1
AND ID < 
(
    SELECT ID FROM cmSession WHERE Guid = @guid LIMIT 1
);

UPDATE cmSession, _table_variable
SET  cmSession.Modified = @now, cmSession.ExitReason = 3, cmSession.IsExpired = 1, cmSession.Logout = @now
WHERE cmSession.Guid = _table_variable.Guid;

SELECT * FROM _table_variable;
")]
        public abstract List<string> LoginSucceed([ParamSize(36), ParamDbType(DbType.AnsiString)] string guid, long userid, DateTime now);

        /// <summary>
        /// Get user by username and email address
        /// </summary>
        /// <param name="domainID">site</param>
        /// <param name="username">username</param>
        /// <param name="email">email address</param>
        /// <returns>cmUser</returns>
        [SqlQuery("SELECT * FROM cmUser WHERE DomainID = @domainID AND Username = @username AND Email = @email")]
        public abstract cmUser GetByUsernameAndEmail(int domainID, string username, string email);


        /// <summary>
        /// Get user by logged-in session guid
        /// </summary>
        /// <param name="domainID">domain id</param>
        /// <param name="sessionGuid">session guid</param>
        /// <returns>cmUser</returns>
        [SqlQuery(@"SELECT cmUser.* FROM cmUser
INNER JOIN cmSession ON cmUser.ID = cmSession.UserID AND cmSession.Guid = @sessionGuid AND cmSession.DomainID = @domainID AND cmSession.IsAuthenticated = 1 AND cmSession.IsExpired = 0
WHERE cmSession.Guid = @sessionGuid AND cmSession.DomainID = @domainID AND cmSession.IsAuthenticated = 1 AND cmSession.IsExpired = 0")]
        public abstract cmUser GetByLoggedInSessionGuid(int domainID, [ParamSize(36), ParamDbType(DbType.AnsiString)] string sessionGuid);

        /// <summary>
        /// Get user by username and hashed password
        /// </summary>
        /// <param name="domainID">site id</param>
        /// <param name="username">username</param>
        /// <param name="passwordHash">hashed password</param>
        /// <returns>cmUser</returns>
        [SqlQuery(@"SELECT * FROM cmUser WHERE DomainID = @domainID AND Username = @username AND Password = @passwordHash")]
        public abstract cmUser GetByUsernameAndHashedPassword(int domainID, string username, string passwordHash);

        /// <summary>
        /// Set AcceptBonusByDefault field, add the flag
        /// </summary>
        /// <param name="userID">userid</param>
        /// <param name="flag">flag</param>
        /// <returns></returns>
        [SqlQuery(@"UPDATE cmUser SET Modified=GETDATE(), AcceptBonusByDefault = AcceptBonusByDefault | @flag WHERE ID = @userID")]
        public abstract int AddAcceptBonusByDefaultFlag(long userID, AcceptBonusByDefault flag);

        /// <summary>
        /// Set AcceptBonusByDefault field, re,pve the flag
        /// </summary>
        /// <param name="userID">userid</param>
        /// <param name="flag">flag</param>
        /// <returns></returns>
        [SqlQuery(@"UPDATE cmUser SET Modified=GETDATE(), AcceptBonusByDefault = AcceptBonusByDefault & ~@flag WHERE ID = @userID")]
        public abstract int RemoveAcceptBonusByDefaultFlag(long userID, AcceptBonusByDefault flag);

        /// <summary>
        /// Clear the terms conditions flag
        /// </summary>
        /// <param name="userID"></param>
        /// <param name="flag"></param>
        /// <returns></returns>
        [SqlQuery(@"UPDATE cmUser SET Modified=GETDATE(), IsTCAcceptRequired = IsTCAcceptRequired & ~@flag WHERE ID = @userID AND @flag=2;
UPDATE cmUser SET Modified=GETDATE(), IsTCAcceptRequired = 0, IsGeneralTCAccepted=1 WHERE ID = @userID AND @flag=1; ")]
        public abstract int ClearTermsConditionsFlag(long userID, TermsConditionsChange flag);

        [SqlQuery(@"UPDATE cmUser SET Modified=GETDATE(), IsTCAcceptRequired = 0 WHERE DomainID = @domainID;")]
        public abstract int ClearTermsConditionsFlagForDomain(long domainID);

        /// <summary>
        /// Set the terms conditions flag for all users in a domain
        /// </summary>
        /// <param name="domainID"></param>
        /// <param name="flag"></param>
        /// <returns></returns>
        [SqlQuery(@"UPDATE cmUser SET Modified=GETDATE(), IsTCAcceptRequired = IsTCAcceptRequired | @flag WHERE DomainID = @domainID;
UPDATE cmUser SET Modified=GETDATE(), IsGeneralTCAccepted=0 WHERE DomainID = @domainID AND @flag = 1;")]
        public abstract int SetTermsConditionsFlag(long domainID, TermsConditionsChange flag);

        [SqlQuery(@"UPDATE cmUser SET Modified=GETDATE(), IsTCAcceptRequired = IsTCAcceptRequired | @flag WHERE ID = @userID;")]
        public abstract int SetTermsConditionsFlagByUserID(long userID, TermsConditionsChange flag);

        private sealed class DynamicQuery_InsertUser : SqlQueryEx
        {
            protected override string GetSqlText(DatabaseType dbType)
            {
                StringBuilder sql = new StringBuilder();
                sql.AppendLine(@"
INSERT INTO cmUser(
Title  ,FirstName  ,Surname ,DisplayName ,PersonalID ,Alias ,Avatar ,Gender ,Username ,Password ,PasswordEncMode ,Email ,IsEmailVerified ,IsBlocked,SecurityQuestion ,SecurityAnswer ,TimeZoneID,CountryID ,RegionID ,SignupIP ,SignupCountryID ,SignupLocationID,SignupHostID,LoginCount,IsExported,Address1 ,Address2 ,StreetName , StreetNumber , Zip ,City ,Birth ,Currency ,PreferredCurrency,MobilePrefix ,Mobile ,PhonePrefix ,Phone ,DomainID ,Language ,AffiliateMarker ,AllowNewsEmail ,AllowSmsOffer ,TaxCode ,IsTCAcceptRequired, Ins , CompleteProfile,IntendedVolume,DOBPlace, IsMobileSignup, Preferences)
VALUES(
@title ,@firstName ,@surname,@displayName,@personalID,@alias,@avatar,@gender,@username,@password,@passwordEncMode,@email,@isEmailVerified,0        ,@securityQuestion,@securityAnswer,0         ,@countryID,@regionID,@signupIP,@signupCountryID,0               ,0           ,0         ,0         ,@address1,@address2,@streetName, @streetNumber, @zip,@city,@birth,@currency,@currency        ,@mobilePrefix,@mobile,@phonePrefix,@phone,@domainID,@language,@affiliateMarker,@allowNewsEmail,@allowSmsOffer,@taxCode,0                 , @now, @completeProfile,@intendedVolume,@dOBPlace, @IsMobileSignup, @Preferences);"
);
                switch (dbType)
                {
                    case DatabaseType.MSSQL:
                        {
                            sql.AppendLine("SELECT CONVERT(bigint, @@IDENTITY)");
                            break;
                        }

                    case DatabaseType.MySQL:
                        {
                            sql.AppendLine("SELECT LAST_INSERT_ID()");
                            break;
                        }

                    default:
                        throw new NotSupportedException();
                }
                return sql.ToString();
            }
        }

        /// <summary>
        /// add a user
        /// </summary>
        /// <param name="title">title</param>
        /// <param name="firstName">firstname</param>
        /// <param name="surname">surname</param>
        /// <param name="displayName">display name</param>
        /// <param name="personalID">personal ID of User</param>
        /// <param name="alias">alias</param>
        /// <param name="avatar">avatar</param>
        /// <param name="gender">gender</param>
        /// <param name="username">username</param>
        /// <param name="password">password</param>
        /// <param name="passwordEncMode">password encode mode</param>
        /// <param name="email">email</param>
        /// <param name="isEmailVerified">email Verification status</param>
        /// <param name="securityQuestion">security question</param>
        /// <param name="securityAnswer">security answer</param>
        /// <param name="countryID">country id</param>
        /// <param name="regionID">region id</param>
        /// <param name="signupIP">signup ip</param>
        /// <param name="signupCountryID">signup country id</param>
        /// <param name="address1">address1</param>
        /// <param name="address2">address2</param>
        /// <param name="streetname">streetname</param>
        /// <param name="streetnumber">streetnumber</param>
        /// <param name="zip">zip</param>
        /// <param name="city">city</param>
        /// <param name="birth">birth date</param>
        /// <param name="currency">currency</param>
        /// <param name="mobilePrefix">mobile prefix</param>
        /// <param name="mobile">mobile</param>
        /// <param name="phonePrefix">phone prefix</param>
        /// <param name="phone">phone</param>
        /// <param name="domainID">site id</param>
        /// <param name="language">language</param>
        /// <param name="affiliateMarker">affiliate marker</param>
        /// <param name="allowNewsEmail">accept news email</param>
        /// <param name="allowSmsOffer">allow Sms Offers to be sent to User</param>
        /// <param name="taxCode">tax Code</param>
        /// <param name="now">current DateTime</param>
        /// <param name="completeProfile">Profile completion status</param>
        /// <param name="intendedVolume">Intended gambling volume</param>
        /// <param name="dOBPlace">birth place</param>
        /// <param name="IsMobileSignup">mobile signup or not</param>
        /// <param name="Preferences">Preferences</param>
        /// <returns>ID of the new create user</returns>
        [DynamicQuery_InsertUser]
        public abstract long Create(string title
                , string firstName
                , string surname
                , string displayName
                , string personalID
                , string alias
                , string avatar
                , char gender
                , string username
                , string password
                , PasswordEncryptionMode passwordEncMode
                , string email
                , bool isEmailVerified
                , string securityQuestion
                , string securityAnswer
                , int countryID
                , int? regionID
                , string signupIP
                , int signupCountryID
                , string address1
                , string address2
                , string streetname
                , string streetnumber
                , string zip
                , string city
                , DateTime? birth
                , string currency
                , string mobilePrefix
                , string mobile
                , string phonePrefix
                , string phone
                , int domainID
                , string language
                , string affiliateMarker
                , bool allowNewsEmail
                , bool allowSmsOffer
                , string taxCode
                , DateTime now
                , DateTime? completeProfile
                , int intendedVolume
            ,string dOBPlace
            , bool IsMobileSignup
            , string Preferences = null
            );

        [SqlQuery(@"
UPDATE cmUser
SET Modified=GETDATE(), IsSecondFactorVerified = 0, SecondFactorType = 0, SecondFactorSecretKey = '' 
WHERE ID=@userid")]
        public abstract void ResetSecondFactorAuth(long userid);


        /// <summary>
        /// Set the second factor as verified
        /// </summary>
        /// <param name="userid">user id</param>
        [SqlQuery(@"
UPDATE cmUser
SET Modified=GETDATE(), IsSecondFactorVerified = @isSecondFactorVerified
WHERE ID=@userid")]
        public abstract void SetSecondFactorVerified(long userid, bool isSecondFactorVerified);


        /// <summary>
        /// Set the second factor as verified
        /// </summary>
        /// <param name="userid">user id</param>
        /// <param name="secondFactorSecretKey">second factor auth key</param>
        [SqlQuery(@"
UPDATE cmUser
SET Modified=GETDATE(), SecondFactorSecretKey = @secondFactorSecretKey, SecondFactorType = @secondFactorType
WHERE ID=@userid")]
        public abstract void SetSecondFactorSecretKey(long userid, string secondFactorSecretKey, int secondFactorType);

        [SqlQuery(@"
UPDATE cmUser
SET Modified=GETDATE(), SecondFactorType = @secondFactorType
WHERE ID=@userid")]
        public abstract void SetSecondFactorType(long userid, int secondFactorType);

        /// <summary>
        /// Set the imageID for given user
        /// </summary>
        /// <param name="userID">user id</param>
        /// <returns>the number of rows affacted</returns>
        [SqlQuery("UPDATE cmUser SET Modified=GETDATE(), PassportID = @imageID WHERE ID = @userID")]
        public abstract int SetImageID(long userID, long imageID);
    }
}
