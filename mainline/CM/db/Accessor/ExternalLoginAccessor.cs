using System;
using System.Collections.Generic;
using System.Text;
using BLToolkit.Data;
using BLToolkit.DataAccess;

namespace CM.db.Accessor
{
    public abstract class ExternalLoginAccessor : DataAccessor<cmExternalLogin>
    {
        [SqlQuery("SELECT * FROM cmExternalLogin WHERE ExternalID=@ExternalID AND DomainID=@domainID AND AuthParty=@authParty")]
        public abstract cmExternalLogin GetUserByKey(string ExternalID, int domainID, int authParty);

        [SqlQuery("SELECT * FROM cmExternalLogin cme inner join cmUser cm on cm.ID=cme.UserID where cm.UserName=@userName and cm.DomainID=@domainID")]
        public abstract IList<cmExternalLogin> GetAuthPartyByUserName(int domainID, string userName);

        [SqlQuery("SELECT count(*) FROM cmExternalLogin cme inner join cmUser cm on cm.ID=cme.UserID where cme.AuthParty=@authParty and cm.UserName=@userName and cm.DomainID=@domainID")]
        public abstract int ExistAuthPartyExternalUserByUserName(int domainID, string userName, int authParty);

        [SqlQuery("delete cmExternalLogin where DomainID=@domainID and UserID=userID and AuthParty=authParty;select 'ok';")]
        public abstract string DeleteExternalUserByUserID(int domainID, int authParty, long userID);

        private sealed class DynamicQuery_InsertExternalUser : SqlQueryEx
        {
            protected override string GetSqlText(DatabaseType dbType)
            {
                StringBuilder sql = new StringBuilder();
                sql.AppendLine(@"
INSERT INTO cmExternalLogin(
DomainID,UserID,AuthParty,ExternalID
)
VALUES(
@domainID,@userID,@authParty,@externalID
);"
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
        [DynamicQuery_InsertExternalUser]
        public abstract long Create(
                int domainID
                , long userID
                , int authParty
                , string externalID
        );
    }
}
