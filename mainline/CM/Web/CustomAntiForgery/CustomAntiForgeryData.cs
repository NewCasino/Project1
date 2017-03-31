using System;
using System.Security.Cryptography;
using System.Security.Principal;
using System.Text;

namespace CM.Web
{
    public sealed class CustomAntiForgeryData
    {         
        private const string AntiForgeryTokenFieldName = "__RequestVerificationToken";
        private const int TokenLength = 16;
        private static readonly RNGCryptoServiceProvider _prng = new RNGCryptoServiceProvider();
        private DateTime _creationDate = DateTime.UtcNow;
        private string _salt;
        private string _username;
        private string _value;
        public DateTime CreationDate
        {
            get
            {
                return this._creationDate;
            }
            set
            {
                this._creationDate = value;
            }
        }
        public string Salt
        {
            get
            {
                return this._salt ?? string.Empty;
            }
            set
            {
                this._salt = value;
            }
        }
        public string Username
        {
            get
            {
                return this._username ?? string.Empty;
            }
            set
            {
                this._username = value;
            }
        }
        public string Value
        {
            get
            {
                return this._value ?? string.Empty;
            }
            set
            {
                this._value = value;
            }
        }
        public CustomAntiForgeryData()
        {
        }
        public CustomAntiForgeryData(CustomAntiForgeryData token)
        {
            if (token == null)
            {
                throw new ArgumentNullException("token");
            }
            this.CreationDate = token.CreationDate;
            this.Salt = token.Salt;
            this.Username = token.Username;
            this.Value = token.Value;
        }
        private static string Base64EncodeForCookieName(string s)
        {
            byte[] bytes = Encoding.UTF8.GetBytes(s);
            string text = Convert.ToBase64String(bytes);
            return text.Replace('+', '.').Replace('/', '-').Replace('=', '_');
        }
        private static string GenerateRandomTokenString()
        {
            byte[] array = new byte[16];
            CustomAntiForgeryData._prng.GetBytes(array);
            return Convert.ToBase64String(array);
        }
        internal static string GetAntiForgeryTokenName(string appPath)
        {
            if (string.IsNullOrEmpty(appPath))
            {
                return "__RequestVerificationToken";
            }
            return "__RequestVerificationToken_" + CustomAntiForgeryData.Base64EncodeForCookieName(appPath);
        }
        internal static string GetUsername(IPrincipal user)
        {
            if (user != null)
            {
                IIdentity identity = user.Identity;
                if (identity != null && identity.IsAuthenticated)
                {
                    return identity.Name;
                }
            }
            return string.Empty;
        }
        public static CustomAntiForgeryData NewToken()
        {
            string value = CustomAntiForgeryData.GenerateRandomTokenString();
            return new CustomAntiForgeryData
            {
                Value = value
            };
        }
    }
}
