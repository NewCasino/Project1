using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Security.Cryptography;

public class StringHelper
{
    private static readonly char[] CHARS = { '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z' };

    private static Random random = new Random();

    public static string GetRandomString(int len)
    {
        return new string(Enumerable.Repeat(CHARS, len).Select(s => s[random.Next(s.Length)]).ToArray());
    }

    public static string GetStrongRandomString(int len)
    {
        byte[] rndBytes = new byte[4];
        RNGCryptoServiceProvider rng = new RNGCryptoServiceProvider();
        rng.GetBytes(rndBytes);
        int seed = BitConverter.ToInt32(rndBytes, 0);

        Random rnd = new Random(seed);
        StringBuilder str = new StringBuilder();

        while (str.Length < len)
        {
            str.Append(CHARS[rnd.Next(0, CHARS.Length)]);
        }

        return str.ToString();
    }
}
