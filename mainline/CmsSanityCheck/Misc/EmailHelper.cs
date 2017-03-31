using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Mail;
using System.Text;
using System.Threading.Tasks;
using System.Globalization;

using log4net;

namespace CmsSanityCheck.Misc
{
    public class EmailHelper
    {
        private static readonly ILog log = LogManager.GetLogger(typeof(MainEntry));

        public static void Send(string receiver, string subject, string body)
        {
            System.Diagnostics.Debug.WriteLine(subject);
            System.Diagnostics.Debug.WriteLine(body);
            string culture = "en";
            CultureInfo cultureInfo = new CultureInfo(culture);
            body = string.Format(@"<!DOCTYPE html>
<html lang=""{2}"">
<head>
<meta http-equiv=""content-type"" content=""text/html; charset=utf-8"" />
</head>
<body dir=""{0}"">
{1}
</body>
</html>"
                , cultureInfo.TextInfo.IsRightToLeft ? "rtl" : "ltr"
                , body.Replace("\r\n", "<br />")
                , culture
                );
            if (string.IsNullOrWhiteSpace(receiver))
                return;
            try
            {
                using (MailMessage message = new MailMessage())
                {
                    message.Subject = subject.Replace("\r", "").Replace("\n", "");
                    message.SubjectEncoding = Encoding.UTF8;
                    foreach (string to in receiver.Split(";".ToCharArray(), StringSplitOptions.RemoveEmptyEntries))
                        message.To.Add(new MailAddress(to));
                    message.IsBodyHtml = true;
                    message.From = new MailAddress(Config.FromEmail);
                    message.BodyEncoding = Encoding.UTF8;
                    message.Body = body;

                    Send(message);
                }
            }
            catch (Exception ex)
            {
                log.Error("Send Email", ex);
            }
        }

        private static void Send(MailMessage message)
        {
            int index = 0;
            while (index < 10)
            {
                try
                {
                    SmtpClient client = new SmtpClient(Config.EmailSmtpServer, Config.EmailSmtpPort);
                    if (Config.EmailSmtpRequireAuthentication)
                    {
                        NetworkCredential credentials = new NetworkCredential(Config.EmailSmtpUsername, Config.EmailSmtpPassword);
                        client.Credentials = credentials;
                    }
                    client.Send(message);
                    break;
                }
                catch (Exception ex)
                {
                    log.Error("Send Email", ex);
                    index++;
                    Task.Delay(1000).Wait();
                }
            }
        }
    }
}
