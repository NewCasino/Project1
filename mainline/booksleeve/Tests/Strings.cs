using System.Collections.Generic;
using NUnit.Framework;
using System.Text;
using System;
using System.Linq;
namespace Tests
{
    [TestFixture]
    public class Strings // http://redis.io/commands#string
    {
        [Test]
        public void Append()
        {
            using(var conn = Config.GetUnsecuredConnection(waitForOpen:true))
            {
                conn.Keys.Remove(2, "append");
                var l0 = conn.Features.StringLength ? conn.Strings.GetLength(2, "append") : null;

                var s0 = conn.Strings.GetString(2, "append");

                conn.Strings.Set(2, "append", "abc");
                var s1 = conn.Strings.GetString(2, "append");
                var l1 = conn.Features.StringLength ? conn.Strings.GetLength(2, "append") : null;

                var result = conn.Strings.Append(2, "append", Encode("defgh"));
                var s3 = conn.Strings.GetString(2, "append");
                var l2 = conn.Features.StringLength ? conn.Strings.GetLength(2, "append") : null;

                Assert.AreEqual(null, conn.Wait(s0));
                Assert.AreEqual("abc", conn.Wait(s1));
                Assert.AreEqual(8, conn.Wait(result));
                Assert.AreEqual("abcdefgh", conn.Wait(s3));

                if (conn.Features.StringLength)
                {
                    Assert.AreEqual(0, conn.Wait(l0));
                    Assert.AreEqual(3, conn.Wait(l1));
                    Assert.AreEqual(8, conn.Wait(l2));
                }
            }
        }
        [Test]
        public void Set()
        {
            using(var conn = Config.GetUnsecuredConnection())
            {
                conn.Keys.Remove(2, "set");

                conn.Strings.Set(2, "set", "abc");
                var v1 = conn.Strings.GetString(2, "set");

                conn.Strings.Set(2, "set", Encode("def"));
                var v2 = conn.Strings.Get(2, "set");

                Assert.AreEqual("abc", conn.Wait(v1));
                Assert.AreEqual("def", Decode(conn.Wait(v2)));
            }
        }

        [Test]
        public void SetNotExists()
        {
            using (var conn = Config.GetUnsecuredConnection())
            {
                conn.Keys.Remove(2, "set");
                conn.Keys.Remove(2, "set2");
                conn.Keys.Remove(2, "set3");
                conn.Strings.Set(2, "set", "abc");

                var x0 = conn.Strings.SetIfNotExists(2, "set", "def");
                var x1 = conn.Strings.SetIfNotExists(2, "set", Encode("def"));
                var x2 = conn.Strings.SetIfNotExists(2, "set2", "def");
                var x3 = conn.Strings.SetIfNotExists(2, "set3", Encode("def"));

                var s0 = conn.Strings.GetString(2, "set");
                var s2 = conn.Strings.GetString(2, "set2");
                var s3 = conn.Strings.GetString(2, "set3");

                Assert.IsFalse(conn.Wait(x0));
                Assert.IsFalse(conn.Wait(x1));
                Assert.IsTrue(conn.Wait(x2));
                Assert.IsTrue(conn.Wait(x3));
                Assert.AreEqual("abc", conn.Wait(s0));
                Assert.AreEqual("def", conn.Wait(s2));
                Assert.AreEqual("def", conn.Wait(s3));
            }
        }
        
        [Test]
        public void Ranges()
        {
            using (var conn = Config.GetUnsecuredConnection(waitForOpen:true))
            {
                if (conn.Features.StringSetRange)
                {
                    conn.Keys.Remove(2, "range");

                    conn.Strings.Set(2, "range", "abcdefghi");
                    conn.Strings.Set(2, "range", 2, "xy");
                    conn.Strings.Set(2, "range", 4, Encode("z"));

                    var val = conn.Strings.GetString(2, "range");

                    Assert.AreEqual("abxyzfghi", conn.Wait(val));
                }
            }
        }

        [Test]
        public void IncrDecr()
        {
            using (var conn = Config.GetUnsecuredConnection())
            {
                conn.Keys.Remove(2, "incr");

                conn.Strings.Set(2, "incr", "2");
                var v1 = conn.Strings.Increment(2, "incr");
                var v2 = conn.Strings.Increment(2, "incr", 5);
                var v3 = conn.Strings.Increment(2, "incr", -2);
                var v4 = conn.Strings.Decrement(2, "incr");
                var v5 = conn.Strings.Decrement(2, "incr", 5);
                var v6 = conn.Strings.Decrement(2, "incr", -2);
                var s = conn.Strings.GetString(2, "incr");

                Assert.AreEqual(3, conn.Wait(v1));
                Assert.AreEqual(8, conn.Wait(v2));
                Assert.AreEqual(6, conn.Wait(v3));
                Assert.AreEqual(5, conn.Wait(v4));
                Assert.AreEqual(0, conn.Wait(v5));
                Assert.AreEqual(2, conn.Wait(v6));
                Assert.AreEqual("2", conn.Wait(s));
            }
        }
        [Test]
        public void IncrDecrFloat()
        {
            using (var conn = Config.GetUnsecuredConnection(waitForOpen:true))
            {
                if (conn.Features.IncrementFloat)
                {
                    conn.Keys.Remove(2, "incr");

                    conn.Strings.Set(2, "incr", "2");
                    var v1 = conn.Strings.Increment(2, "incr", 1.1);
                    var v2 = conn.Strings.Increment(2, "incr", 5.0);
                    var v3 = conn.Strings.Increment(2, "incr", -2.0);
                    var v4 = conn.Strings.Increment(2, "incr", -1.0);
                    var v5 = conn.Strings.Increment(2, "incr", -5.0);
                    var v6 = conn.Strings.Increment(2, "incr", 2.0);

                    var s = conn.Strings.GetString(2, "incr");

                    Config.AssertNearlyEqual(3.1, conn.Wait(v1));
                    Config.AssertNearlyEqual(8.1, conn.Wait(v2));
                    Config.AssertNearlyEqual(6.1, conn.Wait(v3));
                    Config.AssertNearlyEqual(5.1, conn.Wait(v4));
                    Config.AssertNearlyEqual(0.1, conn.Wait(v5));
                    Config.AssertNearlyEqual(2.1, conn.Wait(v6));
                    Assert.AreEqual("2.1", conn.Wait(s));
                }
            }
        }
        
        [Test]
        public void GetRange()
        {
            using (var conn = Config.GetUnsecuredConnection(waitForOpen:true))
            {   
                conn.Keys.Remove(2, "range");

                conn.Strings.Set(2, "range", "abcdefghi");
                var s = conn.Strings.GetString(2, "range", 2, 4);
                var b = conn.Strings.Get(2, "range", 2, 4);

                Assert.AreEqual("cde", conn.Wait(s));
                Assert.AreEqual("cde", Decode(conn.Wait(b)));
            }
        }

        [Test]
        public void BitCount()
        {
            using (var conn = Config.GetUnsecuredConnection(waitForOpen:true))
            {
                if (conn.Features.BitwiseOperations)
                {
                    conn.Strings.Set(0, "mykey", "foobar");
                    var r1 = conn.Strings.CountSetBits(0, "mykey");
                    var r2 = conn.Strings.CountSetBits(0, "mykey", 0, 0);
                    var r3 = conn.Strings.CountSetBits(0, "mykey", 1, 1);

                    Assert.AreEqual(26, conn.Wait(r1));
                    Assert.AreEqual(4, conn.Wait(r2));
                    Assert.AreEqual(6, conn.Wait(r3));
                }
            }
        }

        [Test]
        public void BitOp()
        {
            using (var conn = Config.GetUnsecuredConnection(waitForOpen: true))
            {
                if (conn.Features.BitwiseOperations)
                {
                    conn.Strings.Set(0, "key1", new byte[] { 3 });
                    conn.Strings.Set(0, "key2", new byte[] { 6 });
                    conn.Strings.Set(0, "key3", new byte[] { 12 });

                    var len_and = conn.Strings.BitwiseAnd(0, "and", new[] { "key1", "key2", "key3" });
                    var len_or = conn.Strings.BitwiseOr(0, "or", new[] { "key1", "key2", "key3" });
                    var len_xor = conn.Strings.BitwiseXOr(0, "xor", new[] { "key1", "key2", "key3" });
                    var len_not = conn.Strings.BitwiseNot(0, "not", "key1");

                    Assert.AreEqual(1, conn.Wait(len_and));
                    Assert.AreEqual(1, conn.Wait(len_or));
                    Assert.AreEqual(1, conn.Wait(len_xor));
                    Assert.AreEqual(1, conn.Wait(len_not));

                    var r_and = conn.Wait(conn.Strings.Get(0, "and")).Single();
                    var r_or = conn.Wait(conn.Strings.Get(0, "or")).Single();
                    var r_xor = conn.Wait(conn.Strings.Get(0, "xor")).Single();
                    var r_not = conn.Wait(conn.Strings.Get(0, "not")).Single();

                    Assert.AreEqual((byte)(3 & 6 & 12), r_and);
                    Assert.AreEqual((byte)(3 | 6 | 12), r_or);
                    Assert.AreEqual((byte)(3 ^ 6 ^ 12), r_xor);
                    Assert.AreEqual(unchecked((byte)(~3)), r_not);
                }

            }

        }

        [Test]
        public void RangeString()
        {
            using (var conn = Config.GetUnsecuredConnection())
            {
                conn.Strings.Set(0, "my key", "hello world");
                var result = conn.Strings.GetString(0, "my key", 2, 6);
                Assert.AreEqual("llo w", conn.Wait(result));
            }
        }
        static byte[] Encode(string value) { return Encoding.UTF8.GetBytes(value); }
        static string Decode(byte[] value) { return Encoding.UTF8.GetString(value); }
    }
}
