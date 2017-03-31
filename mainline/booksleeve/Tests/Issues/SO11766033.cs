using System;
using NUnit.Framework;

namespace Tests.Issues
{
    [TestFixture]
    public class SO11766033
    {
        [Test, ExpectedException(typeof(ArgumentNullException))]
        public void TestNullString()
        {
            const int db = 3;
            using (var redis = Config.GetUnsecuredConnection(true))
            {
                string expectedTestValue = null;
                var uid = Config.CreateUniqueName();

                redis.Strings.Set(db, uid, expectedTestValue);
            }
        }
        [Test]
        public void TestEmptyString()
        {
            const int db = 3;
            using (var redis = Config.GetUnsecuredConnection(true))
            {
                string expectedTestValue = "";
                var uid = Config.CreateUniqueName();

                redis.Wait(redis.Strings.Set(db, uid, expectedTestValue));
                var testValue = redis.Wait(redis.Strings.GetString(db, uid));

                Assert.AreEqual(expectedTestValue, testValue);
            }
        }
    }
}
