using System;
using System.Globalization;
using System.Configuration;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using BookSleeve;

namespace GamMatrix.Infrastructure
{
    public class RedisConnectionEx : RedisConnection
    {
        private static readonly string _server = ConfigurationManager.AppSettings["Redis.Server"];
        private static readonly int _port = int.Parse(ConfigurationManager.AppSettings["Redis.Port"], CultureInfo.InvariantCulture);

        public RedisConnectionEx()
            : base ( _server, _port)
        {
            base.SetKeepAlive(0);
            base.SetServerVersion(  new Version("2.6.16"), BookSleeve.ServerType.Master);
        }
    }
}
