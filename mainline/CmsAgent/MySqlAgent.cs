using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using System.Threading.Tasks;
using System.Reflection;
using System.Configuration;

using MySql.Data.MySqlClient;

namespace CmsAgent
{
    public sealed class MySqlAgent
    {
        public void Start()
        {
            Task.Factory.StartNew(WorkerThread, TaskCreationOptions.LongRunning);
        }
        
        private async void WorkerThread()
        {
            Configuration config = ConfigurationManager.OpenExeConfiguration(this.GetType().Assembly.Location);
            if (config == null || config.ConnectionStrings == null)
                return;

            var setting = config.ConnectionStrings.ConnectionStrings["Log"];
            if (setting == null)
                return;

            string connectionString = setting.ConnectionString;
            if (string.IsNullOrEmpty(connectionString))
                return;

            Logger.Get().Append("MySqlAgent.WorkerThread() starts");
            for (; ; )
            {
                try
                {
                    using (MySqlConnection conn = new MySqlConnection(connectionString))
                    {
                        using (MySqlCommand cmd = new MySqlCommand("CALL compute_statistics();", conn))
                        {
                            cmd.CommandTimeout = 1200;
                            await conn.OpenAsync();
                            await cmd.ExecuteNonQueryAsync();
                            conn.Close();
                        }
                    }
                    await Task.Delay(1000);
                    continue;
                }
                catch (Exception ex)
                {
                    Logger.Get().Append(ex);
                }
                await Task.Delay(10000);
            }
        }
    }
}
