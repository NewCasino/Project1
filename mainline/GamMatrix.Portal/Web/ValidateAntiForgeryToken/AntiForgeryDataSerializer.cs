using System;
using System.IO;
using System.Security.Cryptography;
using System.Security.Principal;
using System.Text;
using System.Web;
using System.Web.Mvc;
using System.Web.UI;

namespace GamMatrix.CMS.Web.ValidateAntiForgeryToken
{
    internal sealed class AntiForgeryData
    {
        private DateTime _creationDate;
        private static readonly RNGCryptoServiceProvider _prng = new RNGCryptoServiceProvider();
        private string _salt;
        private string _username;
        private string _value;
        private const string AntiForgeryTokenFieldName = "__RequestVerificationToken";
        private const int TokenLength = 0x10;

        public AntiForgeryData()
        {
            this._creationDate = DateTime.UtcNow;
        }

        public AntiForgeryData(AntiForgeryData token)
        {
            this._creationDate = DateTime.UtcNow;
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
            return Convert.ToBase64String(Encoding.UTF8.GetBytes(s)).Replace('+', '.').Replace('/', '-').Replace('=', '_');
        }

        private static string GenerateRandomTokenString()
        {
            byte[] data = new byte[0x10];
            _prng.GetBytes(data);
            return Convert.ToBase64String(data);
        }

        internal static string GetAntiForgeryTokenName(string appPath)
        {
            if (string.IsNullOrEmpty(appPath))
            {
                return "__RequestVerificationToken";
            }
            return ("__RequestVerificationToken_" + Base64EncodeForCookieName(appPath));
        }

        internal static string GetUsername(IPrincipal user)
        {
            if (user != null)
            {
                IIdentity identity = user.Identity;
                if ((identity != null) && identity.IsAuthenticated)
                {
                    return identity.Name;
                }
            }
            return string.Empty;
        }

        public static AntiForgeryData NewToken()
        {
            string str = GenerateRandomTokenString();
            return new AntiForgeryData { Value = str };
        }

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
                return (this._salt ?? string.Empty);
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
                return (this._username ?? string.Empty);
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
                return (this._value ?? string.Empty);
            }
            set
            {
                this._value = value;
            }
        }
    }

    internal class AntiForgeryDataSerializer
    {
        private IStateFormatter _formatter;

        private static HttpAntiForgeryException CreateValidationException(Exception innerException)
        {
            return new HttpAntiForgeryException("AntiForgeryToken_ValidationFailed", innerException);
        }

        public virtual AntiForgeryData Deserialize(string serializedToken)
        {
            AntiForgeryData data2;
            if (string.IsNullOrEmpty(serializedToken))
            {
                throw new ArgumentException("Common_NullOrEmpty", "serializedToken");
            }
            IStateFormatter formatter = this.Formatter;
            try
            {
                object[] objArray = (object[])formatter.Deserialize(serializedToken);
                data2 = new AntiForgeryData
                {
                    Salt = (string)objArray[0],
                    Value = (string)objArray[1],
                    CreationDate = (DateTime)objArray[2],
                    Username = (string)objArray[3]
                };
            }
            catch (Exception exception)
            {
                throw CreateValidationException(exception);
            }
            return data2;
        }

        public virtual string Serialize(AntiForgeryData token)
        {
            if (token == null)
            {
                throw new ArgumentNullException("token");
            }
            object[] state = new object[] { token.Salt, token.Value, token.CreationDate, token.Username };
            return this.Formatter.Serialize(state);
        }

        protected internal IStateFormatter Formatter
        {
            get
            {
                if (this._formatter == null)
                {
                    this._formatter = FormatterGenerator.GetFormatter();
                }
                return this._formatter;
            }
            set
            {
                this._formatter = value;
            }
        }

        private static class FormatterGenerator
        {
            public static readonly Func<IStateFormatter> GetFormatter = TokenPersister.CreateFormatterGenerator();

            private sealed class TokenPersister : PageStatePersister
            {
                private TokenPersister(Page page)
                    : base(page)
                {
                }

                public static Func<IStateFormatter> CreateFormatterGenerator()
                {
                    HttpResponse response = new HttpResponse(TextWriter.Null);
                    HttpRequest request = new HttpRequest("DummyFile.aspx", HttpContext.Current.Request.Url.ToString(), "__EVENTTARGET=true&__VIEWSTATEENCRYPTED=true");
                    HttpContext context = new HttpContext(request, response);
                    Page page = new Page
                    {
                        EnableViewStateMac = true,
                        ViewStateEncryptionMode = ViewStateEncryptionMode.Always
                    };
                    page.ProcessRequest(context);
                    return () => new AntiForgeryDataSerializer.FormatterGenerator.TokenPersister(page).StateFormatter;
                }

                public override void Load()
                {
                    throw new NotImplementedException();
                }

                public override void Save()
                {
                    throw new NotImplementedException();
                }
            }
        }
    }
}
