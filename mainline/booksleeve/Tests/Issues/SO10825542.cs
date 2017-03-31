using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using NUnit.Framework;

namespace Tests.Issues
{
    [TestFixture]
    public class SO10825542
    {
        [Test]
        public void Execute()
        {
            using (var con = Config.GetUnsecuredConnection())
            {
                var key = "somekey1";

                // set the field value and expiration
                con.Hashes.Set(1, key, "field1", Encoding.UTF8.GetBytes("hello world"));
                con.Keys.Expire(1, key, 7200);
                con.Hashes.Set(1, key, "field2", "fooobar");
                var task = con.Hashes.GetAll(1, key);
                con.Wait(task);

                Assert.AreEqual(2, task.Result.Count);
                Assert.AreEqual("hello world", Encoding.UTF8.GetString(task.Result["field1"]));
                Assert.AreEqual("fooobar", Encoding.UTF8.GetString(task.Result["field2"]));
            }
        }
    }
}
