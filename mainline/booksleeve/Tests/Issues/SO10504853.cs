using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using NUnit.Framework;
using System.Diagnostics;

namespace Tests.Issues
{
    [TestFixture]
    public class SO10504853
    {
        [Test]
        public void LoopLotsOfTrivialStuff()
        {
            Trace.WriteLine("### init");
            using (var conn = Config.GetUnsecuredConnection())
            {
                conn.Wait(conn.Keys.Remove(0, "lots-trivial"));
                conn.Close(false);
            }
            const int COUNT = 2;
            for (int i = 0; i < COUNT; i++)
            {
                Trace.WriteLine("### incr:" + i);
                using (var conn = Config.GetUnsecuredConnection())
                {
                    Assert.AreEqual(i + 1, conn.Wait(conn.Strings.Increment(0, "lots-trivial")));
                    conn.Close(false);
                }
            }
            Trace.WriteLine("### close");
            using (var conn = Config.GetUnsecuredConnection())
            {
                Assert.AreEqual(COUNT, conn.Wait(conn.Strings.GetInt64(0, "lots-trivial")));
                conn.Close(false);
            }


        }
        [Test]
        public void ExecuteWithEmptyStartingPoint()
        {
            using(var conn = Config.GetUnsecuredConnection())
            {
                var task = new {priority = 3};
                conn.Keys.Remove(0, "item:1");
                conn.Hashes.Set(0, "item:1", "something else", "abc");
                conn.Hashes.Set(0, "item:1", "priority", task.priority.ToString());

                var taskResult = conn.Hashes.GetString(0, "item:1", "priority");

                conn.Wait(taskResult);

                var priority = Int32.Parse(taskResult.Result);

                Assert.AreEqual(3, priority);
            }
        }

        [Test, ExpectedException("BookSleeve.RedisException", ExpectedMessage = "ERR Operation against a key holding the wrong kind of value")]
        public void ExecuteWithNonHashStartingPoint()
        {
            using (var conn = Config.GetUnsecuredConnection())
            {
                var task = new { priority = 3 };
                conn.Keys.Remove(0, "item:1");
                conn.Strings.Set(0, "item:1", "not a hash");
                conn.Hashes.Set(0, "item:1", "priority", task.priority.ToString());

                var taskResult = conn.Hashes.GetString(0, "item:1", "priority");

                conn.Wait(taskResult);

                var priority = Int32.Parse(taskResult.Result);

                Assert.AreEqual(3, priority);
            }
        }
    }
}
