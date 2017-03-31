
using BookSleeve;
using System;
using System.Threading.Tasks;
namespace Async
{
    class Program
    {
        // note: this requires the C# 5 async CTP (or later)
        static void Main()
        {
            // just so we don't exit too early
            AsyncRedisUsage().Wait();

            Console.WriteLine("press any key");
            Console.ReadKey();

        }

        // could also be void; only a Task here so I can Wait on
        // completion from my Main method, which is not declared
        // as async
        async static Task AsyncRedisUsage()
        {
            const int db = 4; // no reason

            using(var conn = new RedisConnection("127.0.0.1"))
            {
                // let's wait until all handshakes have happened
                await conn.Open();
                var existed = conn.Keys.Remove(db, "some-key");
                for (int i = 0; i < 100; i++)
                {   // this are also tasks, but I don't
                    // need to wait on them in this case
#pragma warning disable 4014
                    conn.Strings.Increment(db, "some-key");
#pragma warning restore 4014
                }
                // at this point, some messages are flying around
                // from a background queue, with responses being
                // handled by IOCP; let's add a GET onto the
                // bottom of the queue, and let other stuff
                // happen until we have the answer (obviously
                // we could make much more subtle use here, by
                // awaiting multiple things requested much earlier,
                // or by doing some SQL Server work etc before
                // calling await, essentially acting as a "join")
                string result = await conn.Strings.GetString(db, "some-key");
                Console.WriteLine(await existed
                    ? "(it already existed; we removed it)"
                    : "(it didn't exist)");
                Console.WriteLine(result);
            }
        }
    }
}
