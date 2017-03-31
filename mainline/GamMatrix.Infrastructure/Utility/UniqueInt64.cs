using System;
using System.Collections.Generic;
using System.Threading;
using System.Text;


public static class UniqueInt64
{
    private static Random s_Rand = new Random();
    private static long s_Counter;

    static UniqueInt64()
    {
        s_Counter = s_Rand.Next(32767);
    }

    /// <summary>
    /// Generate a unique int64 id
    /// </summary>
    /// <returns></returns>
    public static long Generate()
    {
        long ret = 0;

        DateTime dtStart = new DateTime(2010, 1, 1, 0, 0, 0);
        long secondMask = 0x1FFFFFFFF;
        long randNum1 = Interlocked.Increment(ref s_Counter) % 32767;
        long randNum2 = s_Rand.Next(32767);
        ret = (((long)DateTime.Now.Subtract(dtStart).TotalSeconds & secondMask) << 30)
            | (randNum1 << 15)
            | randNum2
            ;
        return ret;
    }
}
