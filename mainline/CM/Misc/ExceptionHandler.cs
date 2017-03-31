using System;
using System.Collections.Concurrent;
using System.Net.Mail;
using System.Text;
using System.Threading;
using System.Web;
using CM.Content;
using CM.State;

public static class ExceptionHandler
{
    public static void Process(Exception ex)
    {
        try
        {
            HttpContext.Current.Server.ClearError();

            Logger.Exception(ex);

            // get the friendly error message
            string friendlyErrorMessage = null;
            {
                Exception error = ex;
                do
                {
                    GmExceptionBase ex1 = error as GmExceptionBase;
                    if (ex1 != null)
                    {
                        friendlyErrorMessage = ex1.TryGetFriendlyErrorMsg();
                        break;
                    }

                    if ((error as UnauthorizedAccessException) != null ||
                        (error as ArgumentException) != null ||
                        (error as ArgumentNullException) != null ||
                        (error as InvalidOperationException) != null )
                    {
                        friendlyErrorMessage = error.Message;
                        break;
                    }
                    error = error.InnerException;
                } while (error != null);

                if (string.IsNullOrEmpty(friendlyErrorMessage))
                    friendlyErrorMessage = "An error occurred, please try again later.";
            }

            // If this is an error in AJAX request, return friendly error message
            if (HttpContext.Current.Request.IsAjaxRequest())
            {
                HttpContext.Current.Response.Clear();
                HttpContext.Current.Response.ClearHeaders();
                HttpContext.Current.Response.ContentType = "application/json";
                HttpContext.Current.Response.Write(string.Format("{{\"success\":false, \"error\":\"{0}\"}}"
                    , friendlyErrorMessage.SafeJavascriptStringEncode())
                    );
                HttpContext.Current.Response.Flush();
                HttpContext.Current.Response.End();
                return;
            }

            // if this is a HTTP 404 error, show friendly 404 page
            HttpException httpException = ex as HttpException;
            if (httpException != null &&
                httpException.GetHttpCode() == 404 &&
                HttpContext.Current.Request.RawUrl.IndexOf("PageNotFound", StringComparison.OrdinalIgnoreCase) < 0)
            {
                HttpContext.Current.Response.StatusCode = 404;
                HttpContext.Current.Response.StatusDescription = "Page Not Found";

                StringBuilder html = new StringBuilder();
                html.AppendFormat(@"<!DOCTYPE html PUBLIC ""-//W3C//DTD XHTML 1.0 Transitional//EN"" ""http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"">
<html xmlns=""http://www.w3.org/1999/xhtml"">
<head data-error=""true"">
<meta http-equiv=""refresh"" content=""0; url=/{0}/PageNotFound"" />
<title></title>
</head>
<body onload=""self.location='/{0}/PageNotFound'"">
<script"
                    , MultilingualMgr.GetCurrentCulture()
                    );
                html.AppendFormat(@" language=""javascript"" type=""text/javascript"">
    self.location = '/{0}/PageNotFound';
<"
                    , MultilingualMgr.GetCurrentCulture()
                    );
                html.Append(@"/script></body></html>");
                HttpContext.Current.Response.Write(html.ToString());
                HttpContext.Current.Response.Flush();
                HttpContext.Current.Response.End();
                return;
            }


            // If this is a generic exception
            

            StringBuilder sb = new StringBuilder();

            string ip = HttpContext.Current.Request.GetRealUserAddress();
            if (ip.StartsWith("10.0.", StringComparison.InvariantCulture) ||
                ip.StartsWith("192.168.", StringComparison.InvariantCulture) ||
                ip.Equals("127.0.0.1", StringComparison.InvariantCulture) ||
                ip.Equals("124.233.3.10", StringComparison.InvariantCulture) ||
                ip.StartsWith("109.205.9", StringComparison.InvariantCulture) ||
                ip.Equals("85.9.28.130", StringComparison.InvariantCulture) )
            {
                sb.AppendLine("<!--");
                do
                {
                    sb.AppendFormat("{0}", ex.Message);
                    sb.AppendFormat("\r\nStack Track:\r\n{0}\r\n\r\n", ex.StackTrace);

                    ex = ex.InnerException;
                } while (ex != null);
                sb.AppendLine("\n--></head><body>");

                sb.AppendFormat("<h3 style=\"color:red\">{0}</h3><h5 style=\"color:red\">If you contact support, please quote this id <u>{1} {2}</u> </h5>"
                    , friendlyErrorMessage.SafeHtmlEncode()
                    , CustomProfile.Current == null ? string.Empty : CustomProfile.Current.SessionID
                    , Environment.MachineName
                    );
            }

            //HttpContext.Current.Response.ClearHeaders();
            //HttpContext.Current.Response.ClearContent();
            HttpContext.Current.Response.Clear();
            HttpContext.Current.Response.ContentType = "text/html";
            //HttpContext.Current.Response.StatusCode = 500;
            HttpContext.Current.Response.Write(sb.ToString());
            HttpContext.Current.Response.Flush();
            HttpContext.Current.Response.End();
        }
        catch
        {
        }

    }

    private static int s_ErrorCounter = 0;
    private static object s_LockObject = new object();
    private static ConcurrentQueue<string> s_LogQueue = new ConcurrentQueue<string>();
    private static DateTime s_LastSendTime = new DateTime(2011, 01, 01);
    internal static void AppendToEmail(string log)
    {
        s_LogQueue.Enqueue(log);

        if ((Interlocked.Increment(ref s_ErrorCounter) % 10) == 0 &&
            (DateTime.Now - s_LastSendTime).TotalSeconds > 900 )
        {
            if (Monitor.TryEnter(s_LockObject))
            {
                try
                {
                    StringBuilder sb = new StringBuilder();

                    int count = 0;
                    while ( s_LogQueue.TryDequeue(out log) )
                    {
                        Interlocked.Decrement(ref s_ErrorCounter);
                        sb.Append(log);
                        count++;
                    }

                    using (MailMessage message = new MailMessage())
                    {
                        message.Subject = string.Format("{0} exceptions from server [{1}]", count, Environment.MachineName);
                        message.SubjectEncoding = Encoding.UTF8;
                        message.To.Add(new MailAddress("wj@everymatrix.com", "Jerry.Wang"));
                        message.To.Add(new MailAddress("allen.tan@everymatrix.com", "Allen.Tan"));
                        message.IsBodyHtml = true;
                        message.From = new MailAddress("noreply@gammatrix.com", "No Reply");
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
