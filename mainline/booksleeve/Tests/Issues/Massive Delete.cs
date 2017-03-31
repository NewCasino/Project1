using System;
using System.Diagnostics;
using System.Threading;
using System.Threading.Tasks;
using NUnit.Framework;

namespace Tests.Issues
{
    [TestFixture]
    public class Massive_Delete
    {
        [TestFixtureSetUp]
        public void Init()
        {
            using(var conn = Config.GetUnsecuredConnection(allowAdmin:true))
            {
                conn.Server.FlushDb(db);
                Task last = null;
                for(int i = 0 ; i < 100000 ; i++)
                {
                    string key = "key" + i;
                    conn.Strings.Set(db, key, key);
                    last = conn.Sets.Add(db, todoKey, key);
                }
                conn.Wait(last);
            }
        }

        const int db = 4;
        const string todoKey = "todo";

        [Test]
        public void ExecuteMassiveDelete()
        {
            var watch = Stopwatch.StartNew();
            using (var conn = Config.GetUnsecuredConnection())
            using (var throttle = new SemaphoreSlim(1))
            {
                var originallyTask = conn.Sets.GetLength(db, todoKey);
                int keepChecking = 1;
                Task last = null;
                while (Thread.VolatileRead(ref keepChecking) == 1)
                {
                    throttle.Wait(); // acquire
                    conn.Sets.RemoveRandomString(db, todoKey).ContinueWith(task =>
                    {
                        throttle.Release();
                        if (task.IsCompleted)
                        {
                            if (task.Result == null)
                            {
                                Thread.VolatileWrite(ref keepChecking, 0);
                            }
                            else
                            {
                                last = conn.Keys.Remove(db, task.Result);
                            }
                        }
                    });
                }
                if (last != null)
                {
                    conn.Wait(last);
                }
                watch.Stop();
                long originally = conn.Wait(originallyTask),
                    remaining = conn.Wait(conn.Sets.GetLength(db, todoKey));
                Console.WriteLine("From {0} to {1}; {2}ms", originally, remaining,
                    watch.ElapsedMilliseconds);

                var counters = conn.GetCounters();
                Console.WriteLine("Callbacks: {0} sync, {1} async", counters.SyncCallbacks, counters.AsyncCallbacks);
            }
        }
    }
}
