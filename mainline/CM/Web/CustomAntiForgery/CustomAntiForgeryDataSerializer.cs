using System;
using System.IO;
using System.Text;
using System.Web.Mvc;
using System.Web.Security;

namespace CM.Web
{
    internal class CustomAntiForgeryDataSerializer
    {
        internal Func<string, byte[]> Decoder = (string value) => MachineKey.Decode(CustomAntiForgeryDataSerializer.Base64ToHex(value), MachineKeyProtection.All);
        
        internal Func<byte[], string> Encoder = (byte[] bytes) => CustomAntiForgeryDataSerializer.HexToBase64(MachineKey.Encode(bytes, MachineKeyProtection.All).ToUpperInvariant());

        private static CustomHttpAntiForgeryException CreateValidationException(Exception innerException)
        {
            return new CustomHttpAntiForgeryException(CustomAntiForgeryResources.AntiForgeryToken_ValidationFailed, innerException);
        }
        public virtual CustomAntiForgeryData Deserialize(string serializedToken)
        {
            if (string.IsNullOrEmpty(serializedToken))
            {
                throw new ArgumentException(CustomAntiForgeryResources.Common_NullOrEmpty, "serializedToken");
            }
            CustomAntiForgeryData result;
            try
            {
                using (MemoryStream memoryStream = new MemoryStream(this.Decoder(serializedToken)))
                {
                    using (BinaryReader binaryReader = new BinaryReader(memoryStream))
                    {
                        result = new CustomAntiForgeryData
                        {
                            Salt = binaryReader.ReadString(),
                            Value = binaryReader.ReadString(),
                            CreationDate = new DateTime(binaryReader.ReadInt64()),
                            Username = binaryReader.ReadString()
                        };
                    }
                }
            }
            catch (Exception innerException)
            {
                if (CustomAntiForgeryConfig.DebugMode)
                {
                    CM.Web.AntiForgery.Custom.Logger.Exception(CustomAntiForgeryDataSerializer.CreateValidationException(innerException));
                    result = null;
                }
                else
                {
                    throw CustomAntiForgeryDataSerializer.CreateValidationException(innerException);
                }
            }
            return result;
        }
        public virtual string Serialize(CustomAntiForgeryData token)
        {
            if (token == null)
            {
                throw new ArgumentNullException("token");
            }
            string result;
            using (MemoryStream memoryStream = new MemoryStream())
            {
                using (BinaryWriter binaryWriter = new BinaryWriter(memoryStream))
                {
                    binaryWriter.Write(token.Salt);
                    binaryWriter.Write(token.Value);
                    binaryWriter.Write(token.CreationDate.Ticks);
                    binaryWriter.Write(token.Username);
                    result = this.Encoder(memoryStream.ToArray());
                }
            }
            return result;
        }
        private static string Base64ToHex(string base64)
        {
            StringBuilder stringBuilder = new StringBuilder(base64.Length * 4);
            byte[] array = Convert.FromBase64String(base64);
            for (int i = 0; i < array.Length; i++)
            {
                byte b = array[i];
                stringBuilder.Append(CustomAntiForgeryDataSerializer.HexDigit(b >> 4));
                stringBuilder.Append(CustomAntiForgeryDataSerializer.HexDigit((int)(b & 15)));
            }
            return stringBuilder.ToString();
        }
        private static char HexDigit(int value)
        {
            return (char)((value > 9) ? (value + 55) : (value + 48));
        }
        private static int HexValue(char digit)
        {
            if (digit <= '9')
            {
                return (int)(digit - '0');
            }
            return (int)(digit - '7');
        }
        private static string HexToBase64(string hex)
        {
            int num = hex.Length / 2;
            byte[] array = new byte[num];
            for (int i = 0; i < num; i++)
            {
                array[i] = (byte)((CustomAntiForgeryDataSerializer.HexValue(hex[i * 2]) << 4) + CustomAntiForgeryDataSerializer.HexValue(hex[i * 2 + 1]));
            }
            return Convert.ToBase64String(array);
        }
    }
}
