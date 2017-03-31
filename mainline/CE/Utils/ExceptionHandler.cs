using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Configuration;
using System.Net.Mail;
using System.Text;
using System.Threading;

namespace CE.Utils
{
    public static class ExceptionHandler
    {        
        private static int s_ErrorCounter = 0;
        private static object s_LockObject = new object();
        private static ConcurrentQueue<string> s_LogQueue = new ConcurrentQueue<string>();
        private static DateTime s_LastSendTime = new DateTime(2011, 01, 01);
        private static List<string> MailAddresses;
        static ExceptionHandler()
        {
            try
            {
                MailAddresses = new List<string>();
                foreach (string email in ConfigurationManager.AppSettings["Monitor.Alerting.Emails"].DefaultIfNullOrWhiteSpace(",").Split(new char[] { ',' }, StringSplitOptions.RemoveEmptyEntries))
                {
                    MailAddresses.Add(email);
                }
            }
            catch { }
        }

        internal static void AppendToEmail(string log)
        {
            if (MailAddresses == null || MailAddresses.Count == 0)
                return;

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
                            foreach (string email in MailAddresses)
                            {
                                message.To.Add(email);    
                            }
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
}
