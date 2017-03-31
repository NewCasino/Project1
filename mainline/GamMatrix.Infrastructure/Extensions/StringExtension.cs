using System;
using System.Collections.Generic;
using System.Collections.Concurrent;
using System.Linq;
using System.Web;
using System.Web.Caching;
using System.IO;
using System.IO.Compression;
using System.Text;
using System.Text.RegularExpressions;
using System.Security.Cryptography;
using System.Globalization;
using System.Runtime.Serialization.Formatters.Binary;
using System.Net;
using System.Numerics;

public static class StringExtension
{
    private static byte[] TRIPLE_DES_KEY192 = {42, 16, 93, 156, 78, 4, 218, 32,15, 167,
    44,80, 26, 250, 155, 112,2, 94, 11, 204, 119, 35, 184, 197};
    private static byte[] TRIPLE_DES_IV192 = {55, 103, 246, 79, 36, 99, 167, 3,42,
    5, 62,83, 184, 7, 209, 13,145, 23, 200, 58, 173, 10, 121, 222};
    /// <summary>
    /// Encode the string to javascript string
    /// </summary>
    /// <param name="str"></param>
    /// <returns></returns>
    public static string SafeJavascriptStringEncode(this string str)
    {
        if (string.IsNullOrEmpty(str)) return string.Empty;

        string cacheKey = string.Format("StringExtension.SafeJavascriptStringEncode.{0}", str);
        string cached = HttpRuntime.Cache[cacheKey] as string;
        if (cached != null)
            return cached;

        StringBuilder sb = new StringBuilder();
        foreach( char c in str)
        {
            int code = (int)c;
            if (code > 0 && c < 0x7F)
            {
                if (c > 0x1F)
                {
                    switch (code)
                    {
                        case 0x26: // &
                        case 0x22: // "
                        case 0x27: // '
                        case 0x5c: // \
                        case 0x3c: // <
                        case 0x3E: // >
                            {
                                sb.AppendFormat("\\u{0:X4}", code);
                                break;
                            }

                        default:
                            sb.Append(c);
                            break;
                    }
                }
                else
                {
                    switch (code)
                    {
                        case 0x0A: // \r
                        case 0x0D: // \n
                            {
                                sb.AppendFormat("\\u{0:X4}", code);
                                break;
                            }

                        default:
                            break;
                    }
                }
            }
            else
                sb.AppendFormat("\\u{0:X4}", code);
        }

        cached = sb.ToString();
        HttpRuntime.Cache.Insert( cacheKey, cached, null, Cache.NoAbsoluteExpiration, Cache.NoSlidingExpiration, CacheItemPriority.NotRemovable, null);

        return cached;
    }



    /// <summary>
    /// Html Encode string, support all charactoers in the world
    /// </summary>
    /// <param name="str"></param>
    /// <returns></returns>
    public static string SafeHtmlEncode(this string str)
    {
        if (string.IsNullOrEmpty(str)) return string.Empty;

        string cacheKey = string.Format("StringExtension.SafeHtmlEncode.{0}", str);
        string cached = HttpRuntime.Cache[cacheKey] as string;
        if (cached != null)
            return cached;

        StringBuilder sb = new StringBuilder();
        foreach (char c in str)
        {
            uint code = (uint)c;
            if (c < 0x7F)
            {
                if (c > 0x1F)
                {
                    switch (code)
                    {
                        case 0x26: // &
                            sb.Append("&amp;");
                            break;

                        case 0x22: // "
                            sb.Append("&quot;");
                            break;

                        case 0x3c: // <
                            sb.Append("&lt;");
                            break;

                        case 0x3E: // >
                            sb.Append("&gt;");
                            break;

                        case 0x27: // '
                        case 0x5c: // \
                            {
                                sb.AppendFormat("&#{0};", code);
                                break;
                            }

                        default:
                            sb.Append(c);
                            break;
                    }
                }
                else
                {
                    switch (code)
                    {
                        case 0x0A: // \r
                        case 0x0D: // \n
                            {
                                sb.AppendFormat("&#{0};", code);
                                break;
                            }

                        default:
                            break;
                    }
                }
            }
            else
                sb.AppendFormat("&#{0};", code);
        }

        cached = sb.ToString();
        HttpRuntime.Cache.Insert(cacheKey, cached, null, Cache.NoAbsoluteExpiration, Cache.NoSlidingExpiration, CacheItemPriority.NotRemovable, null);

        return cached;
    }

    /// <summary>
    /// Html Encode string, support all charactoers in the world
    /// </summary>
    /// <param name="str"></param>
    /// <returns></returns>
    public static string HtmlEncodeSpecialCharactors(this string str)
    {
        if (string.IsNullOrEmpty(str)) return string.Empty;

        string cacheKey = string.Format("StringExtension.HtmlEncodeSpecialCharactors.{0}", str);
        string cached = HttpRuntime.Cache[cacheKey] as string;
        if (cached != null)
            return cached;

        StringBuilder sb = new StringBuilder();
        foreach (char c in str)
        {
            uint code = (uint)c;
            if (c <= 0x7F)
            {
                sb.Append(c);
            }
            else
                sb.AppendFormat("&#{0};", code);
        }

        cached = sb.ToString();
        HttpRuntime.Cache.Insert(cacheKey, cached, null, Cache.NoAbsoluteExpiration, Cache.NoSlidingExpiration, CacheItemPriority.NotRemovable, null);

        return cached;
    }

    /// <summary>
    /// Return the default value if the string is null or empty
    /// </summary>
    /// <param name="src"></param>
    /// <param name="def"></param>
    /// <returns></returns>
    public static string DefaultIfNullOrEmpty(this string src, string def)
    {
        return string.IsNullOrEmpty(src) ? def : src;
    }

    /// <summary>
    /// Return the default value if the string is null or white space
    /// </summary>
    /// <param name="src"></param>
    /// <param name="def"></param>
    /// <returns></returns>
    public static string DefaultIfNullOrWhiteSpace(this string src, string def)
    {
        return string.IsNullOrWhiteSpace(src) ? def : src;
    }

    private static ConcurrentDictionary<string, string> _defaultEncryptCache = new ConcurrentDictionary<string, string>();
    private static ConcurrentDictionary<string, string> _defaultDecryptCache = new ConcurrentDictionary<string, string>();

    /// <summary>
    /// default encrypt
    /// </summary>
    /// <param name="src"></param>
    /// <param name="encoding"></param>
    /// <returns></returns>
    public static string DefaultEncrypt(this string src, Encoding encoding = null)
    {
        var key = src;
        if (encoding == null) encoding = Encoding.UTF8;
        else
        {
            key += (encoding.Equals(Encoding.UTF8) ? string.Empty : encoding.ToString());
        }

        var value = string.Empty;
        while (!_defaultEncryptCache.TryGetValue(key, out value))
        {
            value = _defaultEncryptCache.GetOrAdd(key, k =>
            {
                using (TripleDESCryptoServiceProvider tripeDES = new TripleDESCryptoServiceProvider())
                {
                    using (MemoryStream ms = new MemoryStream())
                    {
                        using (CryptoStream cs = new CryptoStream(ms, tripeDES.CreateEncryptor(TRIPLE_DES_KEY192, TRIPLE_DES_IV192), CryptoStreamMode.Write))
                        {
                            using (StreamWriter sw = new StreamWriter(cs))
                            {
                                var bts = encoding.GetBytes(src);
                                sw.BaseStream.Write(bts, 0, bts.Length);
                                sw.Flush();
                                cs.FlushFinalBlock();
                                ms.Flush();
                            }
                        }
                        return Regex.Replace(BitConverter.ToString(ms.ToArray()), "\\-", string.Empty);
                    }
                }
            });

            var deKey = value + (encoding.Equals(Encoding.UTF8) ? string.Empty : encoding.ToString());
            //only once here
            _defaultDecryptCache.TryAdd(deKey, src);
        }
        return value;

    }


    public static string ShortEncrypt(this string src, Encoding encoding = null)
    {
        if (encoding == null) encoding = Encoding.UTF8;

        using (TripleDESCryptoServiceProvider tripeDES = new TripleDESCryptoServiceProvider())
        {
            using (MemoryStream ms = new MemoryStream())
            {
                using (CryptoStream cs = new CryptoStream(ms, tripeDES.CreateEncryptor(TRIPLE_DES_KEY192, TRIPLE_DES_IV192), CryptoStreamMode.Write))
                {
                    using (StreamWriter sw = new StreamWriter(cs))
                    {
                        sw.Write(src);
                        sw.Flush();
                        cs.FlushFinalBlock();
                        ms.Flush();
                    }
                }

                byte[] buffer = ms.ToArray();

                using (MemoryStream dest = new MemoryStream())
                {
                    using (GZipStream zipStream = new GZipStream(dest, CompressionMode.Compress))
                    {
                        zipStream.Write(buffer, 0, buffer.Length);
                        zipStream.Close();
                    }
                    return string.Format("{0:X4}{1}", buffer.Length, Convert.ToBase64String(dest.ToArray()));
                }
            }
        }
    }

    public static string ShortDecrypt(this string base64Encoded, Encoding encoding = null)
    {
        if (encoding == null) encoding = Encoding.UTF8;

        try
        {
            using (TripleDESCryptoServiceProvider tripeDES = new TripleDESCryptoServiceProvider())
            {
                int length = Convert.ToInt32(base64Encoded.Substring(0, 4), 16);
                base64Encoded = base64Encoded.Substring(4);
                using (MemoryStream input = new MemoryStream(Convert.FromBase64String(base64Encoded)))
                {
                    using (GZipStream zipStream = new GZipStream(input, CompressionMode.Decompress))
                    {
                        byte[] uncompressed = new byte[length];
                        int read = zipStream.Read(uncompressed, 0, uncompressed.Length);
                        if (read == uncompressed.Length)
                        {
                            using (ICryptoTransform transform = tripeDES.CreateDecryptor(TRIPLE_DES_KEY192, TRIPLE_DES_IV192))
                            {
                                byte[] result = transform.TransformFinalBlock(uncompressed, 0, uncompressed.Length);
                                return encoding.GetString(result);
                            }
                        }
                    }
                }
            }
        }
        catch
        {
            
        }
        return base64Encoded;
    }

    /// <summary>
    /// Default decrypt
    /// </summary>
    /// <param name="src"></param>
    /// <param name="encoding"></param>
    /// <returns></returns>
    public static string DefaultDecrypt(this string src, Encoding encoding = null, bool ignoreException = false)
    {
        string key = src;
        if (encoding == null) encoding = Encoding.UTF8;
        else
        {
            key += (encoding.Equals(Encoding.UTF8) ? string.Empty : encoding.ToString());
        }
        var value = string.Empty;
        while (!_defaultDecryptCache.TryGetValue(key, out value))
        {
            value = _defaultDecryptCache.GetOrAdd(key, k =>
            {
                try
                {
                    if (string.IsNullOrEmpty(src)) return string.Empty;
                    if (!Regex.IsMatch(src, "([0-9]|[a-z]|[A-Z])?"))
                        throw new ArgumentException("incorrect argument.");
                    try
                    {
                        byte[] inputBytes = new byte[src.Length / 2];
                        for (int i = 0; i < src.Length; i += 2)
                            inputBytes[i / 2] = (byte)Convert.ToInt32(src[i].ToString() + src[i + 1].ToString(), 16);

                        using (TripleDESCryptoServiceProvider tripeDES = new TripleDESCryptoServiceProvider())
                        {
                            using (ICryptoTransform transform = tripeDES.CreateDecryptor(TRIPLE_DES_KEY192, TRIPLE_DES_IV192))
                            {
                                byte[] result = transform.TransformFinalBlock(inputBytes, 0, inputBytes.Length);
                                return encoding.GetString(result);
                            }
                        }
                    }
                    catch
                    {
                        throw new Exception("Decrypt failed, invalid ciphertext.");
                    }
                }
                catch
                {
                    if (ignoreException)
                        return src;
                    throw;
                }
            });
        }
        return value;
    }

    public static string MD5Hash(this string src, Encoding encoding = null)
    {
        using( MD5 md5 = MD5.Create() )
        {
            byte[] bytes = (encoding ?? Encoding.ASCII).GetBytes(src);
            return BitConverter.ToString(md5.ComputeHash(bytes)).ToLower(CultureInfo.InvariantCulture).Replace("-", string.Empty);
        }
    }

    public static string ToBase36String(this string src)
    {
        string Alphabet = "0123456789abcdefghijklmnopqrstuvwxyz";
        byte[] bytes = Encoding.UTF8.GetBytes(src);
        BigInteger dividend = new BigInteger(bytes);
        var builder = new StringBuilder();
        while (dividend != 0)
        {
            BigInteger remainder;
            dividend = BigInteger.DivRem(dividend, 36, out remainder);
            builder.Insert(0, Alphabet[Math.Abs((int)remainder)]);
        }

        return builder.ToString();
    }

    public static string Truncate(this string s, int length)
    {
        if (string.IsNullOrEmpty(s) || s.Length <= length)
            return s;
        return s.Substring(0, length);
    }
    
    private static Regex containSpecialCharactersRegex = new Regex(@"[\u2012-\u266F]|[\u02B0-\u036E]|[\u0021-\u002F]|[\u003A-\u0040]|[\u005B-\u0060]|[\u007B-\u007E]|[\u00A1-\u00BF]"
            , RegexOptions.Compiled);
    public static bool ContainSpecialCharactors(this string src)
    {
        Match m = containSpecialCharactersRegex.Match(src);
        return m.Success;
    }

    public static bool IsValidIpAddress(this string s)
    {
        IPAddress ip;
        return !string.IsNullOrEmpty(s) && System.Net.IPAddress.TryParse(s, out ip);
    }

    private static readonly HashSet<string> TrueString = new HashSet<string>(new string[] { "YES", "ON", "OK", "TRUE", "1" });
    private static readonly HashSet<string> FalseString = new HashSet<string>(new string[] { "NO", "OFF", "FALSE", "0" });
    public static bool ParseToBool(this string s, bool defValue)
    {
        if (string.IsNullOrWhiteSpace(s))
            return defValue;
        string formattedInput = s.Trim().ToUpperInvariant();

        if (TrueString.Contains(formattedInput))
        {
            return true;
        }
        else if (FalseString.Contains(formattedInput))
        {
            return false;
        }
        else
        {
            return defValue;
        }
    }

    public static List<string> SplitToList(this string s, string delimiter)
    {
        if (s.Contains(delimiter))
        {
            string[] vals = s.Split(delimiter.ToCharArray());
            return new List<string>(vals);
        }
        else
        {
            return new List<string>(new []{s});
        }
    }

    public static bool ContainsIgnoreCase(this string source, string toCheck)
    {
        return source.IndexOf(toCheck, StringComparison.OrdinalIgnoreCase) >= 0;
    }
    

    public static string DesEncryptWithKey(this string s, string secretKey)
    {
        if (string.IsNullOrEmpty(s))
        {
            throw new ArgumentNullException("The string which needs to be encrypted can not be null.");
        }

        using (DESCryptoServiceProvider cryptoProvider = new DESCryptoServiceProvider())
        {
            MemoryStream memoryStream = new MemoryStream();

            byte[] passwordBytes = UTF8Encoding.UTF8.GetBytes(secretKey);

            cryptoProvider.Key = passwordBytes;
            cryptoProvider.Mode = CipherMode.ECB;

            CryptoStream cryptoStream = new CryptoStream(memoryStream,
                cryptoProvider.CreateEncryptor(), CryptoStreamMode.Write);
            StreamWriter writer = new StreamWriter(cryptoStream);
            writer.Write(s);
            writer.Flush();
            cryptoStream.FlushFinalBlock();
            writer.Flush();
            return Convert.ToBase64String(memoryStream.GetBuffer(), 0, (int)memoryStream.Length);
        }
    }
}
