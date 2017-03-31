using BLToolkit.DataAccess;

namespace CM.db.Accessor
{
    public abstract class TransParameterAccessor : DataAccessor<cmTransParameter>
    {
        [SqlQuery("SELECT ParameterValue FROM cmTransParameter WHERE SID = @sid AND ParameterName = @parameterName")]
        public abstract string GetParameterBySidAndName(string sid, string parameterName);

        [SqlQueryEx( MSSqlText = @"
BEGIN TRY
    INSERT cmTransParameter ( [SID], [ParameterName], [ParameterValue])
    VALUES( @sid, @parameterName, @parameterValue)
END TRY
BEGIN CATCH
    UPDATE cmTransParameter SET [ParameterValue] = @parameterValue
    WHERE [SID] = @sid AND [ParameterName] = @parameterName
END CATCH
",
    MySqlText = @"
DELETE FROM cmTransParameter WHERE SID = @sid AND ParameterName = @parameterName;
INSERT cmTransParameter ( SID, ParameterName, ParameterValue)
VALUES( @sid, @parameterName, @parameterValue);
")]
        public abstract cmTransParameter SetParameter(string sid, string parameterName, string parameterValue);

        [SqlQuery("DELETE FROM cmTransParameter WHERE SID = @sid AND ParameterName = 'SecurityKey'")]
        public abstract void DeleteSecurityKey(string sid);
        
    }
}
