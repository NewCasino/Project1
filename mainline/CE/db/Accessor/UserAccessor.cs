using System;

using BLToolkit.DataAccess;

namespace CE.db.Accessor
{
    public abstract class UserAccessor : DataAccessor
    {
        [SqlQueryEx( 
            MSSqlText = @"SELECT TOP 1 [Firstname], [Surname],[DomainID] FROM cm..cmUser WITH(NOLOCK) WHERE ID = @userID",
            MySqlText = @"SELECT `Firstname`, `Surname`,`DomainID` FROM cm.cmUser WHERE ID = @userID LIMIT 0, 1"
            )]
        public abstract dwWinner GetWinnerName(long userID);


        [SqlQueryEx(
            MSSqlText = @"SELECT TOP 1 [Username] FROM cm..cmUser WITH(NOLOCK) WHERE ID = @userID",
            MySqlText = @"SELECT `Username` FROM cm.cmUser WHERE ID = @userID LIMIT 0, 1"
            )]
        public abstract string GetUsername(long userID);

        [SqlQueryEx(
            MSSqlText = @"SELECT TOP 1 [Gender] FROM cm..cmUser WITH(NOLOCK) WHERE ID = @userID",
            MySqlText = @"SELECT `Gender` FROM cm.cmUser WHERE ID = @userID LIMIT 0, 1"
            )]
        public abstract string GetGender(long userID);

        [SqlQueryEx(
            MSSqlText = @"SELECT TOP 1 [Birth] FROM cm..cmUser WITH(NOLOCK) WHERE ID = @userID",
            MySqlText = @"SELECT `Birth` FROM cm.cmUser WHERE ID = @userID LIMIT 0, 1"
            )]
        public abstract DateTime? GetBirthday(long userID);

        [SqlQueryEx(
            MSSqlText = @"SELECT TOP 1 [Alias] FROM cm..cmUser WITH(NOLOCK) WHERE ID = @userID",
            MySqlText = @"SELECT `Alias` FROM cm.cmUser WHERE ID = @userID LIMIT 0, 1"
            )]
        public abstract string GetUserAlias(long userID);
    }
}
