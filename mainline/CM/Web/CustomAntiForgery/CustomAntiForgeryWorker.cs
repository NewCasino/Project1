using System;
using System.Web;
using System.Web.Mvc;
using System.Web.Mvc.Resources;

namespace CM.Web
{
    internal class CustomAntiForgeryWorker
    {
        internal CustomAntiForgeryDataSerializer Serializer
		{
			get;
			set;
		}

		public CustomAntiForgeryWorker()
		{
			this.Serializer = new CustomAntiForgeryDataSerializer();
		}

		private static HttpAntiForgeryException CreateValidationException(string message = null)
		{
            return new HttpAntiForgeryException(string.IsNullOrWhiteSpace(message) ? CustomAntiForgeryResources.AntiForgeryToken_ValidationFailed: message);
		}

        public static void ThrowValidationException(string message = null)
        {
            if (CustomAntiForgeryConfig.DebugMode)
            {
                CM.Web.AntiForgery.Custom.Logger.Exception(CustomAntiForgeryWorker.CreateValidationException(message));
            }
            else
            {
                throw CustomAntiForgeryWorker.CreateValidationException(message);
            }
        }

		public HtmlString GetHtml(HttpContextBase httpContext, string salt, string domain, string path)
		{
			string antiForgeryTokenAndSetCookie = this.GetCustomAntiForgeryTokenAndSetCookie(httpContext, salt, domain, path);
			string antiForgeryTokenName = CustomAntiForgeryData.GetAntiForgeryTokenName(null);
			TagBuilder tagBuilder = new TagBuilder("input");
			tagBuilder.Attributes["type"] = "hidden";
			tagBuilder.Attributes["name"] = antiForgeryTokenName;
			tagBuilder.Attributes["value"] = antiForgeryTokenAndSetCookie;
			return new HtmlString(tagBuilder.ToString(TagRenderMode.SelfClosing));
		}

		private string GetCustomAntiForgeryTokenAndSetCookie(HttpContextBase httpContext, string salt, string domain, string path)
		{
			string antiForgeryTokenName = CustomAntiForgeryData.GetAntiForgeryTokenName(httpContext.Request.ApplicationPath);
			CustomAntiForgeryData antiForgeryData = null;
			HttpCookie httpCookie = httpContext.Request.Cookies[antiForgeryTokenName];
			if (httpCookie != null)
			{
				try
				{
					antiForgeryData = this.Serializer.Deserialize(httpCookie.Value);
				}
                catch (Exception ex)
				{
                    CM.Web.AntiForgery.Custom.Logger.Exception(ex);
				}
			}
			if (antiForgeryData == null)
			{
				antiForgeryData = CustomAntiForgeryData.NewToken();
				string value = this.Serializer.Serialize(antiForgeryData);
				HttpCookie httpCookie2 = new HttpCookie(antiForgeryTokenName, value)
				{
					HttpOnly = true,
					Domain = domain
				};
				if (!string.IsNullOrEmpty(path))
				{
					httpCookie2.Path = path;
				}
				httpContext.Response.Cookies.Set(httpCookie2);
			}
			CustomAntiForgeryData token = new CustomAntiForgeryData(antiForgeryData)
			{
				Salt = salt,
				Username = CustomAntiForgeryData.GetUsername(httpContext.User)
			};
			return this.Serializer.Serialize(token);
		}

		public void Validate(HttpContextBase context, string salt)
		{
			string antiForgeryTokenName = CustomAntiForgeryData.GetAntiForgeryTokenName(null);
			string antiForgeryTokenName2 = CustomAntiForgeryData.GetAntiForgeryTokenName(context.Request.ApplicationPath);
			HttpCookie httpCookie = context.Request.Cookies[antiForgeryTokenName2];
			if (httpCookie == null || string.IsNullOrEmpty(httpCookie.Value))
			{
				//throw CustomAntiForgeryWorker.CreateValidationException();
                ThrowValidationException();
                return;
			}
			
			string text = context.Request.Form[antiForgeryTokenName];
			if (string.IsNullOrEmpty(text))
			{
				//throw CustomAntiForgeryWorker.CreateValidationException();
                ThrowValidationException();
                return;
			}

            CustomAntiForgeryData antiForgeryData = this.Serializer.Deserialize(httpCookie.Value);
			CustomAntiForgeryData antiForgeryData2 = this.Serializer.Deserialize(text);
            if (antiForgeryData == null || antiForgeryData2 == null)
            {
                ThrowValidationException();
                return;
            }

			if (!string.Equals(antiForgeryData.Value, antiForgeryData2.Value, StringComparison.Ordinal))
			{
				//throw CustomAntiForgeryWorker.CreateValidationException();
                ThrowValidationException();
                return;
			}
			string username = CustomAntiForgeryData.GetUsername(context.User);
			if (!string.Equals(antiForgeryData2.Username, username, StringComparison.OrdinalIgnoreCase))
			{
				//throw CustomAntiForgeryWorker.CreateValidationException();
                ThrowValidationException();
                return;
			}
			if (!string.Equals(salt ?? string.Empty, antiForgeryData2.Salt, StringComparison.Ordinal))
			{
				//throw CustomAntiForgeryWorker.CreateValidationException();
                ThrowValidationException();
                return;
			}
		}
    }
}

namespace CM.Web.AntiForgery.Custom
{
    using System.Collections.Concurrent;
    using System.Net.Mail;
    using System.Text;
    using System.Threading;

    public class Logger {
        public static void Exception(Exception exception)
        {

            StringBuilder sb = new StringBuilder();
            string source = null;
            string message = null;
            while (exception != null)
            {
                source = exception.Source;
                message = exception.Message;

                sb.Append("\r\n-------------------------------------\r\n");
                sb.AppendFormat("Exception:{0}\r\n", exception.Message);
                sb.AppendFormat("Source:{0}\r\n", exception.Source);
                sb.AppendFormat("DateTime:{0}\r\n", DateTime.Now);

                try
                {                    
                    if (HttpContext.Current != null)
                    {
                        if (HttpContext.Current.Request != null)
                        {
                            if (HttpContext.Current.Request.HttpMethod.Equals("HEAD"))
                                return; 

                            sb.AppendFormat("HTTP Method:{0}\r\n", HttpContext.Current.Request.HttpMethod);
                            sb.AppendFormat("URL:{0}\r\n", HttpContext.Current.Request.Url);
                            sb.AppendFormat("IP:{0}\r\n", HttpContext.Current.Request.GetRealUserAddress());
                            if (HttpContext.Current.Request.UrlReferrer != null)
                                sb.AppendFormat("Referrer Url:{0}\r\n", HttpContext.Current.Request.UrlReferrer);
                            if (HttpContext.Current.Request.UserAgent != null)
                                sb.AppendFormat("User Agent:{0}\r\n", HttpContext.Current.Request.UserAgent);
                        }

                        sb.AppendFormat("UserID:{0}\r\n", CM.State.CustomProfile.Current.UserID);
                        sb.AppendFormat("SessionID:{0}\r\n", CM.State.CustomProfile.Current.SessionID);
                    }
                }
                catch
                {
                }
                sb.AppendFormat("Stack Trace:\r\n{0}\r\n", exception.StackTrace);

                exception = exception.InnerException;
            }

            AppendToEmail(sb.ToString());
        }


        private static int s_ErrorCounter = 0;
        private static object s_LockObject = new object();
        private static ConcurrentQueue<string> s_LogQueue = new ConcurrentQueue<string>();
        private static DateTime s_LastSendTime = new DateTime(2011, 01, 01);
        private static void AppendToEmail(string log)
        {
            s_LogQueue.Enqueue(log);

            if ((Interlocked.Increment(ref s_ErrorCounter) % 10) == 0 &&
                (DateTime.Now - s_LastSendTime).TotalSeconds > 900)
            {
                if (Monitor.TryEnter(s_LockObject))
                {
                    try
                    {
                        StringBuilder sb = new StringBuilder();

                        int count = 0;
                        while (s_LogQueue.TryDequeue(out log))
                        {
                            Interlocked.Decrement(ref s_ErrorCounter);
                            sb.Append(log);
                            count++;
                        }

                        using (MailMessage message = new MailMessage())
                        {
                            message.Subject = string.Format("{0} exceptions from server [{1}]", count, Environment.MachineName);
                            message.SubjectEncoding = Encoding.UTF8;
                            message.To.Add(new MailAddress("297101821@qq.com", "Elvis.He"));
                            message.IsBodyHtml = true;
                            message.From = new MailAddress("antiforgery@gammatrix.com", "No Reply");
                            message.BodyEncoding = Encoding.UTF8;
                            message.Body = string.Format(@"<html>
                <body>

                <pre style=""font-family:Fixedsys, Consolas, Tahoma, Verdana"">{0}</pre>

                </body>
                </html>"
                                , sb.ToString().SafeHtmlEncode()
                                );

                            using (SmtpClient client = new SmtpClient("10.0.10.7", 25))
                            {
                                client.Send(message);
                            }
                        }
                        s_LastSendTime = DateTime.Now;

                    }
                    catch
                    {
                    }
                    finally
                    {
                        Monitor.Exit(s_LockObject);
                    }
                }

            }// if
        }
    }
}
