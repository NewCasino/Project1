using System;
using System.Collections.Concurrent;
using System.Diagnostics;
using System.Net.Mail;
using System.Reflection;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using System.Web;
using System.Web.Mvc;
using CM.State;

namespace GamMatrix.CMS.Web.ValidateAntiForgeryToken
{
    [AttributeUsage(AttributeTargets.Method | AttributeTargets.Class, AllowMultiple = false, Inherited = true)]
    public sealed class ValidateAntiForgeryTokenAttribute : FilterAttribute, IAuthorizationFilter
    {
        private string _salt;
        private AntiForgeryDataSerializer _serializer;

        private static HttpAntiForgeryException CreateValidationException(string additionalMessage)
        {
            return new HttpAntiForgeryException("AntiForgeryToken_ValidationFailed" + additionalMessage);
        }

        public void OnAuthorization(AuthorizationContext filterContext)
        {
            bool isOpenValidateAntiForgeryToken = Settings.IsValidateAntiForgeryToken;
            string additionalMessage = string.Empty;

            additionalMessage += "\r\nIsOpenValidateAntiForgeryToken: " + isOpenValidateAntiForgeryToken;
            additionalMessage += "\r\nActionName: " + filterContext.ActionDescriptor.ActionName;
            additionalMessage += "\r\nControllerName: " + filterContext.ActionDescriptor.ControllerDescriptor.ControllerType.FullName;
            if (filterContext == null)
            {
                throw new ArgumentNullException("filterContext");
            }
            string antiForgeryTokenName = AntiForgeryData.GetAntiForgeryTokenName(null);
            string str2 = AntiForgeryData.GetAntiForgeryTokenName(filterContext.HttpContext.Request.ApplicationPath);
            HttpCookie cookie = filterContext.HttpContext.Request.Cookies[str2];
            if ((cookie == null) || string.IsNullOrEmpty(cookie.Value))
            {
                try
                {
                    throw CreateValidationException(additionalMessage);
                }
                catch (Exception ex)
                {
                    AntiForgeryExceptionHandler.Exception(ex);
                    if (isOpenValidateAntiForgeryToken)
                    {
                        throw ex;
                    }
                }
            }
            else
            {
                AntiForgeryData data = this.Serializer.Deserialize(cookie.Value);
                string str3 = filterContext.HttpContext.Request.Form[antiForgeryTokenName];
                if (string.IsNullOrEmpty(str3))
                {
                    try
                    {
                        throw CreateValidationException(additionalMessage);
                    }
                    catch (Exception ex)
                    {
                        AntiForgeryExceptionHandler.Exception(ex);
                        if (isOpenValidateAntiForgeryToken)
                        {
                            throw ex;
                        }
                    }
                }
                else
                {
                    AntiForgeryData token = this.Serializer.Deserialize(str3);
                    if (!string.Equals(data.Value, token.Value, StringComparison.Ordinal))
                    {
                        try
                        {
                            throw CreateValidationException(additionalMessage);
                        }
                        catch (Exception ex)
                        {
                            AntiForgeryExceptionHandler.Exception(ex);
                            if (isOpenValidateAntiForgeryToken)
                            {
                                throw ex;
                            }
                        }
                    }
                    string username = AntiForgeryData.GetUsername(filterContext.HttpContext.User);
                    if (!string.Equals(token.Username, username, StringComparison.OrdinalIgnoreCase))
                    {
                        try
                        {
                            throw CreateValidationException(additionalMessage);
                        }
                        catch (Exception ex)
                        {
                            AntiForgeryExceptionHandler.Exception(ex);
                            if (isOpenValidateAntiForgeryToken)
                            {
                                throw ex;
                            }
                        }
                    }
                    if (!this.ValidateFormToken(token))
                    {
                        try
                        {
                            throw CreateValidationException(additionalMessage);
                        }
                        catch (Exception ex)
                        {
                            AntiForgeryExceptionHandler.Exception(ex);
                            if (isOpenValidateAntiForgeryToken)
                            {
                                throw ex;
                            }
                        }
                    }
                }
            }
        }

        private bool ValidateFormToken(AntiForgeryData token)
        {
            return string.Equals(this.Salt, token.Salt, StringComparison.Ordinal);
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

        internal AntiForgeryDataSerializer Serializer
        {
            get
            {
                if (this._serializer == null)
                {
                    this._serializer = new AntiForgeryDataSerializer();
                }
                return this._serializer;
            }
            set
            {
                this._serializer = value;
            }
        }
    }

    public static class AntiForgeryExceptionHandler
    {
        private static string[] IGNORED_EXCEPTIONS = new string[] {
        "SYS_1111",
        "SYS_1008",
        "SYS_1125",
        "EverleafNetworkProxy error: 2 (No data found)",
        "Attempted to perform an unauthorized operation",
        "A potentially dangerous Request.Path value was detected from the client",
        "Thread was being aborted",
    };

        public static void Exception(Exception exception)
        {

            StringBuilder sb = new StringBuilder();
            string source = null;
            string message = null;
            while (exception != null)
            {
                source = exception.Source;
                message = exception.Message;

                foreach (string ignoredException in IGNORED_EXCEPTIONS)
                {
                    if (message.IndexOf(ignoredException, StringComparison.InvariantCulture) >= 0)
                        return;
                }

                sb.Append("\r\n-------------------------------------\r\n");
                sb.AppendFormat("Exception:{0}\r\n", exception.Message);
                sb.AppendFormat("Source:{0}\r\n", exception.Source);
                try
                {
                    sb.AppendFormat("DateTime:{0}\r\n", DateTime.Now);
                    if (HttpContext.Current != null)
                    {
                        if (HttpContext.Current.Request != null)
                        {
                            if (HttpContext.Current.Request.HttpMethod.Equals("HEAD"))
                                return; // ignore the HEAD request

                            sb.AppendFormat("HTTP Method:{0}\r\n", HttpContext.Current.Request.HttpMethod);
                            sb.AppendFormat("URL:{0}\r\n", HttpContext.Current.Request.Url);
                            sb.AppendFormat("IP:{0}\r\n", HttpContext.Current.Request.GetRealUserAddress());
                            if (HttpContext.Current.Request.UrlReferrer != null)
                                sb.AppendFormat("Referrer Url:{0}\r\n", HttpContext.Current.Request.UrlReferrer);
                            if (HttpContext.Current.Request.UserAgent != null)
                                sb.AppendFormat("User Agent:{0}\r\n", HttpContext.Current.Request.UserAgent);
                        }

                        sb.AppendFormat("UserID:{0}\r\n", CustomProfile.Current.UserID);
                        sb.AppendFormat("UserName:{0}\r\n", CustomProfile.Current.UserName);
                        sb.AppendFormat("SessionID:{0}\r\n", CustomProfile.Current.SessionID);
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
        internal static void AppendToEmail(string log)
        {
            string actionNameRegEx = @"\r\nActionName: .+\r\n";
            string controlNameRegEx = @"\r\nControllerName: .+\r\n";
            string urlRegEx = @"\r\nURL:.+\r\n";
            string newActionName = Regex.Match(log, actionNameRegEx).ToString();
            string newControlName = Regex.Match(log, controlNameRegEx).ToString();
            string newUrl = Regex.Match(log, urlRegEx).ToString();
            /*bool hasLog = false;

            foreach (var loger in s_LogQueue)
            {
                string oldActionName = Regex.Match(loger, actionNameRegEx).ToString();
                string oldControlName = Regex.Match(loger, controlNameRegEx).ToString();
                string oldUrl = Regex.Match(loger, urlRegEx).ToString();
                if (string.Equals(oldActionName, newActionName, StringComparison.InvariantCultureIgnoreCase) && string.Equals(oldControlName, newControlName, StringComparison.InvariantCultureIgnoreCase) &&string.Equals(oldUrl, newUrl, StringComparison.InvariantCultureIgnoreCase))
                {
                    hasLog = true;
                }
            }

            if (hasLog) return;*/

            s_LogQueue.Enqueue(log);

            /*if ((Interlocked.Increment(ref s_ErrorCounter) % 10) == 0 &&
                (DateTime.Now - s_LastSendTime).TotalSeconds > 600)*/
            if (Interlocked.Increment(ref s_ErrorCounter) > 0)
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

                        string emailReceiver = Settings.Email_ValidateAntiForgeryTokenReceiver;
                        if (!string.IsNullOrEmpty(emailReceiver))
                        {
                            using (MailMessage message = new MailMessage())
                            {
                                message.Subject = string.Format("{0} exceptions from server [{1}]", count, Environment.MachineName);
                                message.SubjectEncoding = Encoding.UTF8;
                                foreach (var receiver in emailReceiver.Split(new char[] { ',' }))
                                {
                                    message.To.Add(new MailAddress(receiver, "Validate AntiForgery Token"));
                                }
                                message.IsBodyHtml = true;
                                message.From = new MailAddress(Settings.Email_NoReplyAddress, "No Reply");
                                message.BodyEncoding = Encoding.UTF8;
                                message.Body = string.Format(@"<html>
                <body>
                <pre style=""font-family:Fixedsys, Consolas, Tahoma, Verdana;"">Hi,<br />these are the exceptions from Validate AntiForgery Token below:</pre>
                <pre style=""font-family:Fixedsys, Consolas, Tahoma, Verdana"">{0}</pre>
                </body>
                </html>"
                                    , sb.ToString().SafeHtmlEncode()
                                    );

                                using (SmtpClient client = new SmtpClient(Settings.Email_SMTP, Settings.Email_Port))
                                {
                                    client.Send(message);
                                }
                            }

                            s_LastSendTime = DateTime.Now;
                        }
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
