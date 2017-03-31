using System;
using System.IO;
using System.IO.Compression;
using System.Runtime.Serialization.Formatters.Binary;
using BLToolkit.DataAccess;
using CM.db.Accessor;

namespace CM.db
{
    /// <summary>
    /// Stores a hostname that is related to a domain.
    /// </summary>
    public class cmTransParameter
    {
        private const int MASKLENGTH = 4;
        [PrimaryKey, NonUpdatable]
        public string SID { get; set; }

        public string ParameterName { get; set; }

        public string ParameterValue { get; set; }

        /// <summary>
        /// Save the object with parameter
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="sid"></param>
        /// <param name="parameterName"></param>
        /// <param name="obj"></param>
        public static void SaveObject<T>(string sid, string parameterName, T obj)
        {
            obj = Mask<T>(sid, parameterName, obj);
            string base64Encoded = null;
            if (typeof(T) == typeof(int) ||
                typeof(T) == typeof(long) ||
                typeof(T) == typeof(decimal) ||
                typeof(T) == typeof(float) ||
                typeof(T) == typeof(double) ||
                typeof(T) == typeof(bool))
            {
                base64Encoded = obj.ToString();
            }
            else if (typeof(T) != typeof(string))
            {
                using (MemoryStream ms = new MemoryStream())
                {
                    BinaryFormatter bf = new BinaryFormatter();
                    bf.Serialize(ms, obj);

                    using (MemoryStream dest = new MemoryStream())
                    {
                        byte[] buffer = ms.ToArray();
                        using (GZipStream zipStream = new GZipStream(dest, CompressionMode.Compress))
                        {                           
                            zipStream.Write(buffer, 0, buffer.Length);
                            zipStream.Close();
                        }
                        base64Encoded = string.Format("{0:X4}{1}", buffer.Length, Convert.ToBase64String( dest.ToArray()));
                    }
                }
            }
            else
                base64Encoded = obj as string;

            TransParameterAccessor tpa = DataAccessor.CreateInstance<TransParameterAccessor>();
            tpa.SetParameter(sid, parameterName, base64Encoded); 
        }


        /// <summary>
        /// Read the object from parameter
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="sid"></param>
        /// <param name="parameterName"></param>
        /// <returns></returns>
        public static T ReadObject<T>(string sid, string parameterName)
        {
            try
            {
                TransParameterAccessor tpa = DataAccessor.CreateInstance<TransParameterAccessor>();
                string base64Encoded = tpa.GetParameterBySidAndName(sid, parameterName);

                base64Encoded = Unmask(sid, parameterName, base64Encoded);

                if (typeof(T) != typeof(int) &&
                    typeof(T) != typeof(long) &&
                    typeof(T) != typeof(decimal) &&
                    typeof(T) != typeof(float) &&
                    typeof(T) != typeof(double) &&
                    typeof(T) != typeof(bool) &&
                    typeof(T) != typeof(string) )
                {
                    int length = Convert.ToInt32(base64Encoded.Substring(0,4), 16);
                    base64Encoded = base64Encoded.Substring(4);
                    using (MemoryStream input = new MemoryStream(Convert.FromBase64String(base64Encoded)))
                    {
                        using (GZipStream zipStream = new GZipStream(input, CompressionMode.Decompress))
                        {
                            byte[] uncompressed = new byte[length];
                            int read = zipStream.Read(uncompressed, 0, uncompressed.Length);
                            if (read == uncompressed.Length)
                            {
                                BinaryFormatter bf = new BinaryFormatter();
                                using (MemoryStream ms = new MemoryStream(uncompressed))
                                {
                                    return (T)bf.Deserialize(ms);
                                }
                            }
                        }
                    }
                }                
                return (T)Convert.ChangeType( base64Encoded, typeof(T));
            }
            catch
            {
                return default(T);
            }
        }

        public static void DeleteSecurityKey(string sid)
        {
            TransParameterAccessor tpa = DataAccessor.CreateInstance<TransParameterAccessor>();
            tpa.DeleteSecurityKey(sid); 
        }

        public static T Mask<T>(string sid, string parameterName, T obj)
        {
            if (obj == null || typeof(T) != typeof(string))
                return obj;

            string str = null;
            switch (parameterName.ToLowerInvariant())
            {
                case "securitykey":
                case "inputvalue1":
                case "inputvalue2":
                    str = obj.ToString();
                    break;
                default :
                    return obj;
            }

            if (!string.IsNullOrWhiteSpace(str))
            {
                string[] chars = new string[] { "A", "B", "C", "D", "E", "F", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9" };
                string c = "Z"; // Extra prefix "Z"
                int r = -1;
                Random rand = new Random(unchecked((int)DateTime.Now.Ticks));
                for (int i = 0; i < MASKLENGTH; i++)
                {
                    r = rand.Next(0, chars.Length - 1);
                    c += chars[r];
                }

                str = c.ToUpperInvariant() + str;
            }

            return (T)Convert.ChangeType(str, typeof(T));
        }

        public static T Unmask<T>(string sid, string parameterName, T obj)
        {
            if (obj == null || typeof(T) != typeof(string))
                return obj;

            string str = null;
            switch (parameterName.ToLowerInvariant())
            {
                case "securitykey":
                case "inputvalue1":
                case "inputvalue2":
                    str = obj.ToString();
                    break;
                default:
                    return obj;
            }
            if (!string.IsNullOrWhiteSpace(str) && str.StartsWith("Z"))
            {
                int l = MASKLENGTH + 1;
                if (str.Length < l)
                    str = "";
                else
                    str = str.Substring(l, str.Length - l);
            }
            else
            {
                return obj;
            }

            return (T)Convert.ChangeType(str, typeof(T));
        }
    }
}
