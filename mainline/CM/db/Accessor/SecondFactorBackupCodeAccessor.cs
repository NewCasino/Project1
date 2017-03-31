using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Text;
using BLToolkit.Data;
using BLToolkit.DataAccess;

namespace CM.db.Accessor
{
    public abstract class SecondFactorBackupCodeAccessor : DataAccessor<cmSecondFactorBackupCode>
    {
        [SqlQuery("SELECT (CASE COUNT([ID]) WHEN 0 THEN 0 ELSE 1 END) FROM cmSecondFactorBackupCode WHERE UserID = @userID AND Code = @code")]
        public abstract bool IsCodeExist(long userID, string code);

        [SqlQuery("INSERT INTO cmSecondFactorBackupCode([UserID] ,[Code],[Ins]) VALUES(@userID, @code, getdate())")]
        public abstract void InsertCode(long userID, string code);

        [SqlQuery("SELECT CODE FROM cmSecondFactorBackupCode WHERE userID = @userID")]
        public abstract List<string> GetCodes(long userID);

        [SqlQuery(@"DELETE FROM cmSecondFactorBackupCode WHERE userID = @userID and code = @code;
            SELECT COUNT(ID) FROM cmSecondFactorBackupCode WHERE userID = @userID")]
        public abstract int RemoveCode(long userID, string code);

        [SqlQuery(@"DELETE FROM cmSecondFactorBackupCode WHERE userID = @userID")]
        public abstract int RemoveCodes(long userID);
    }
}
