#if CLUSTER
using BookSleeve;
using NUnit.Framework;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Text;
using System.Threading.Tasks;

namespace Tests
{
    [TestFixture]
    public class Cluster
    {
        [Test]
        public void HashingAlgo()
        {  // this example taken from Appendix A of the specification
            Assert.AreEqual(0x31C3, RedisCluster.HashSlot(Encoding.UTF8.GetBytes("123456789")));
        }
        [Test]
        public void Connect()
        {
            var log = new StringWriter();
            using (var conn = Config.GetCluster(log))
            {
                Console.WriteLine(log.ToString());
                Assert.IsNotNull(conn);
            }
        }

        const int LOOP = 10000;
        [Test]
        public void TimeSlotHashing_Cluster()
        {
            int total = 0;
            var watch = Stopwatch.StartNew();
            unchecked
            {
                for (int i = 0; i < LOOP; i++)
                {
                    total += RedisCluster.HashSlot("GetSetValues" + i);
                }
            }
            watch.Stop();
            Console.WriteLine("Time to hash {0}: {1}ms ({2})", LOOP, watch.ElapsedMilliseconds, total);
        }

        [Test]
        public void TimeGetConnection_Cluster()
        {
            RedisConnection last = null;
            using (var conn = Config.GetCluster())
            {
                var watch = Stopwatch.StartNew();

                unchecked
                {
                    for (int i = 0; i < LOOP; i++)
                    {
                        last = conn.GetConnection("GetSetValues" + i);
                    }
                }
                watch.Stop();
                Console.WriteLine("Time to resolve {0}: {1}ms ({2})", LOOP, watch.ElapsedMilliseconds, last.Host);
            }
        }

        private const bool suspendFlush = true;

        [Test]
        public void GetSetValues_Cluster()
        {
            using (var conn = Config.GetCluster())
            {
                if(suspendFlush) conn.SuspendFlush();
                var watch = Stopwatch.StartNew();
                var set = new List<Task>();
                for (int i = 0; i < LOOP; i++)
                {
                    set.Add(conn.Strings.Set("GetSetValues" + i, "value" + i));
                }
                var get = new List<Task<string>>();
                for (int i = 0; i < LOOP; i++)
                {
                    get.Add(conn.Strings.GetString("GetSetValues" + i));
                }
                if(suspendFlush) conn.ResumeFlush();
                for (int i = 0; i < LOOP; i++)
                {
                    var t = get[i];
                    if (!t.Wait(500)) throw new TimeoutException();
                    Assert.AreEqual("value" + i, t.Result);
                }
                watch.Stop();
                Console.WriteLine("cluster:" + watch.ElapsedMilliseconds);
            }
        }

        [Test]
        public void GetSetValues_Single()
        {
            using (var conn = Config.GetRemoteConnection(waitForOpen:true))
            {
                var watch = Stopwatch.StartNew();
                if (suspendFlush) conn.SuspendFlush();
                var set = new List<Task>();
                for (int i = 0; i < LOOP; i++)
                {
                    set.Add(conn.Strings.Set(0, "GetSetValues" + i, "value" + i));
                }
                var get = new List<Task<string>>();
                for (int i = 0; i < LOOP; i++)
                {
                    get.Add(conn.Strings.GetString(0, "GetSetValues" + i));
                }
                if (suspendFlush) conn.ResumeFlush();
                for (int i = 0; i < LOOP; i++)
                {
                    var t = get[i];
                    if (!t.Wait(500)) throw new TimeoutException();
                    Assert.AreEqual("value" + i, t.Result);
                }
                watch.Stop();
                Console.WriteLine("single: " + watch.ElapsedMilliseconds);
            }
        }
    }
}
#endif