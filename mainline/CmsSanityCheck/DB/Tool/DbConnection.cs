using System.Data.SqlClient;

namespace CmsSanityCheck.DB.Tool
{
    using Model;

    public static class DbConnection
    {
        public static SqlConnection Open(Service service)
        {
            string connectionString = service.ConnectionString;

            SqlConnection conn = new SqlConnection(connectionString);
            conn.Open();

            using (SqlCommand cmd = conn.CreateCommand())
            {
                cmd.CommandText = "SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;";
                cmd.ExecuteNonQuery();
            }

            return conn;
        }


    }
}
