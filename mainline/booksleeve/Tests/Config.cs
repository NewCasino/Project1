using System;
using System.Net.Sockets;
using BookSleeve;
using NUnit.Framework;
using System.Threading;
using System.Diagnostics;
using System.Threading.Tasks;
using System.IO;

namespace Tests
{
    [TestFixture(Description="Validates that the test environment is configured and responding")]
    public class Config
    {
        public static string CreateUniqueName()
        {
            return Guid.NewGuid().ToString("N");
        }
        static Config()
        {
            RedisConnectionBase.DefaultCompletionMode = ResultCompletionMode.ConcurrentIfContinuation;
            TaskScheduler.UnobservedTaskException += (sender, args) =>
            {
                Trace.WriteLine(args.Exception,"UnobservedTaskException");
                args.SetObserved();
            };
        }

        public const string LocalHost = "127.0.0.1";
        public const string RemoteHost = "192.168.0.6";
        
        const int unsecuredPort = 6379, securedPort = 6381,
            clusterPort0 = 6400, clusterPort1 = 6401, clusterPort2 = 6402;


#if CLUSTER
        internal static RedisCluster GetCluster(TextWriter log = null)
        {
            string clusterConfiguration =
                RemoteHost + ":" + clusterPort0 + "," +
                RemoteHost + ":" + clusterPort1 + "," +
                RemoteHost + ":" + clusterPort2;
            return RedisCluster.Connect(clusterConfiguration, log);
        }
#endif

        //const int unsecuredPort = 6380, securedPort = 6381;

        internal static RedisConnection GetRemoteConnection(bool open = true, bool allowAdmin = false, bool waitForOpen = false, int syncTimeout = 5000, int ioTimeout = 5000)
        {
            return GetConnection(RemoteHost, unsecuredPort, open, allowAdmin, waitForOpen, syncTimeout, ioTimeout);
        }
        private static RedisConnection GetConnection(string host, int port, bool open = true, bool allowAdmin = false, bool waitForOpen = false, int syncTimeout = 5000, int ioTimeout = 5000)
        {
            var conn = new RedisConnection(host, port, syncTimeout: syncTimeout, ioTimeout: ioTimeout, allowAdmin: allowAdmin);
            conn.Error += (s, args) =>
            {
                Trace.WriteLine(args.Exception.Message, args.Cause);
            };
            if (open)
            {
                var openAsync = conn.Open();
                if (waitForOpen) conn.Wait(openAsync);
            }
            return conn;
        }
        internal static RedisConnection GetUnsecuredConnection(bool open = true, bool allowAdmin = false, bool waitForOpen = false, int syncTimeout = 5000, int ioTimeout = 5000)
        {
            return GetConnection(LocalHost, unsecuredPort, open, allowAdmin, waitForOpen, syncTimeout, ioTimeout);
        }

        internal static RedisSubscriberConnection GetSubscriberConnection()
        {
            var conn = new RedisSubscriberConnection(LocalHost, unsecuredPort);
            conn.Error += (s, args) =>
            {
                Trace.WriteLine(args.Exception.Message, args.Cause);
            };
            conn.Open();
            return conn;
        }
        internal static RedisConnection GetSecuredConnection(bool open = true)
        {
            var conn = new RedisConnection(LocalHost, securedPort, password: "changeme", syncTimeout: 60000, ioTimeout: 5000);
            conn.Error += (s, args) =>
            {
                Trace.WriteLine(args.Exception.Message, args.Cause);
            };
            if (open) conn.Open();
            return conn;
        }

        [Test]
        public void CanOpenUnsecuredConnection()
        {
            using (var conn = GetUnsecuredConnection(false))
            {
                Assert.IsNull(conn.ServerVersion);
                conn.Wait(conn.Open());
                Assert.IsNotNull(conn.ServerVersion);
            }
        }

        [Test]
        public void CanOpenSecuredConnection()
        {
            using (var conn = GetSecuredConnection(false))
            {
                Assert.IsNull(conn.ServerVersion);
                conn.Wait(conn.Open());
                Assert.IsNotNull(conn.ServerVersion);
            }
        }

        [Test, ExpectedException(typeof(SocketException))]
        public void CanNotOpenNonsenseConnection_IP()
        {
            using (var conn = new RedisConnection(Config.LocalHost, 6500))
            {
                conn.Wait(conn.Open());
            }
        }
        [Test, ExpectedException(typeof(SocketException))]
        public void CanNotOpenNonsenseConnection_DNS()
        {
            using (var conn = new RedisConnection("doesnot.exist.ds.aasd981230d.com", 6500))
            {
                conn.Wait(conn.Open());
            }
        }

        internal static void AssertNearlyEqual(double x, double y)
        {
            if (Math.Abs(x - y) > 0.00001) Assert.AreEqual(x, y);
        }
    }
}