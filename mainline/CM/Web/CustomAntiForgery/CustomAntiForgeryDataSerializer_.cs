using System;
using System.IO;
using System.Web;
using System.Web.Mvc;
using System.Web.Mvc.Resources;
using System.Web.UI;

namespace CM.Web
{
    internal class CustomAntiForgeryDataSerializer_
    {
        private static class FormatterGenerator
        {
            private sealed class TokenPersister : PageStatePersister
            {
                private TokenPersister(Page page)
                    : base(page)
                {
                }
                public static Func<IStateFormatter> CreateFormatterGenerator()
                {
                    TextWriter @null = TextWriter.Null;
                    HttpResponse response = new HttpResponse(@null);
                    //HttpRequest request = new HttpRequest("DummyFile.aspx", HttpContext.Current.Request.Url.ToString(), "__EVENTTARGET=true&__VIEWSTATEENCRYPTED=true");
                    HttpRequest request = new HttpRequest("DummyFile.aspx", HttpContext.Current.Request.Url.ToString(), string.Empty);
                    HttpContext context = new HttpContext(request, response);
                    Page page = new Page
                    {
                        EnableViewStateMac = false,
                        ViewStateEncryptionMode = ViewStateEncryptionMode.Always
                    };
                    page.ProcessRequest(context);
                    return () => new CustomAntiForgeryDataSerializer_.FormatterGenerator.TokenPersister(page).StateFormatter;
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
            public static readonly Func<IStateFormatter> GetFormatter;
            static FormatterGenerator()
            {
                CustomAntiForgeryDataSerializer_.FormatterGenerator.GetFormatter = CustomAntiForgeryDataSerializer_.FormatterGenerator.TokenPersister.CreateFormatterGenerator();
            }
        }
        private IStateFormatter _formatter;
        protected internal IStateFormatter Formatter
        {
            get
            {
                if (this._formatter == null)
                {
                    this._formatter = CustomAntiForgeryDataSerializer_.FormatterGenerator.GetFormatter();
                }
                return this._formatter;
            }
            set
            {
                this._formatter = value;
            }
        }
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
            IStateFormatter formatter = this.Formatter;
            CustomAntiForgeryData result;
            try
            {
                object[] array = (object[])formatter.Deserialize(serializedToken);
                result = new CustomAntiForgeryData
                {
                    Salt = (string)array[0],
                    Value = (string)array[1],
                    CreationDate = (DateTime)array[2],
                    Username = (string)array[3]
                };
            }
            catch (Exception innerException)
            {
                if (CustomAntiForgeryConfig.DebugMode)
                {
                    CM.Web.AntiForgery.Custom.Logger.Exception(CustomAntiForgeryDataSerializer_.CreateValidationException(innerException));
                    result = null;
                }
                else
                {
                    throw CustomAntiForgeryDataSerializer_.CreateValidationException(innerException);                    
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
            object[] state = new object[]
			{
				token.Salt,
				token.Value,
				token.CreationDate,
				token.Username
			};
            return this.Formatter.Serialize(state);
        }
    }
}
