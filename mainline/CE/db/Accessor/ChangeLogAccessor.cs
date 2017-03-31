using System;
using System.Collections.Generic;
using BLToolkit.DataAccess;
using GamMatrixAPI;

namespace CE.db.Accessor
{
    public abstract class ChangeLogAccessor : DataAccessor
    {
        [SqlQueryEx(MSSqlText = @"
        INSERT INTO CeChangeLog (
        Modified,SessionID,  SessionUserID ,TableName  ,RecordID ,OperateType ,BeforeChange ,AfterChange)
        VALUES (@modified, @sessionID, @sessionUserID, @tableName, @recordID, @operateType, @beforeChange, @afterChange);")]
        public abstract void BackupChangeLog(string sessionID, long sessionUserID, string tableName, long recordID, DateTime modified, string operateType, string beforeChange = null, string afterChange = null);
    }
}
