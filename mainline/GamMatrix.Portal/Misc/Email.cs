using System.Collections.Generic;
using System.Globalization;
using System.Net.Mail;
using System.Text;
using System.Text.RegularExpressions;
using System.Web;
using CM.Content;

/// <summary>
/// Summary description for Email
/// </summary>
public class Email
{
    private Dictionary<string, string> m_ReplaceDirectory = new Dictionary<string,string>();

    private string EmailType { get; set; }
    public string Subject { get; set; }
    public string BodyTemplate { get; set; }
    public string Culture { get; set; }

    public Dictionary<string, string> ReplaceDirectory
    {
        get{ return m_ReplaceDirectory; }
    }

	public Email()
	{
        this.Culture = "en";
	}

    public void LoadFromMetadata(string name, string lang)
    {
        EmailType = name;
        Subject = Metadata.Get(string.Format("/Metadata/Email/{0}.Subject", name), lang);
        BodyTemplate = Metadata.Get(string.Format("/Metadata/Email/{0}.Body", name), lang);
    }

    public string GetBody()
    {
        CultureInfo cultureInfo = new CultureInfo(this.Culture);

        string body = this.BodyTemplate.DefaultIfNullOrEmpty(string.Empty);
        foreach (KeyValuePair<string, string> item in this.ReplaceDirectory)
        {
            if (item.Key.Equals("ACTIVELINK", System.StringComparison.InvariantCultureIgnoreCase))
            {
                string emailDomainHost = string.IsNullOrEmpty(Metadata.Get("/Metadata/Email.LinkDomain")) ? HttpContext.Current.Request.Url.Host : Metadata.Get("/Metadata/Email.LinkDomain");
                string IsCustomLinkReplace = Metadata.Get("/Metadata/Email.IsCustomLinkReplace").DefaultIfNullOrEmpty("NO");
                string[] CustomLinkReplaceFrom = Metadata.Get("/Metadata/Email.CustomLinkReplaceFrom").Split(',');
                string[] CustomLinkReplaceTo = Metadata.Get("/Metadata/Email.CustomLinkReplaceTo").Split(',');
                string newUrl = item.Value;
                if (!string.IsNullOrEmpty(Metadata.Get("/Metadata/Email.LinkDomain")))
                {
                    newUrl = newUrl.Replace(HttpContext.Current.Request.Url.Host, emailDomainHost);
                }
                if (IsCustomLinkReplace.Equals("YES", System.StringComparison.InvariantCultureIgnoreCase) && CustomLinkReplaceFrom.Length > 0)
                {
                    for (int i = 0; i < CustomLinkReplaceFrom.Length && i < CustomLinkReplaceTo.Length; i++)
                    {
                        newUrl = newUrl.Replace(CustomLinkReplaceFrom[i], CustomLinkReplaceTo[i]);
                    }
                }
                body = body.Replace(string.Format("${0}$", item.Key), newUrl);
            }
            else
            {
                body = body.Replace(string.Format("${0}$", item.Key), item.Value);
            }
        }

        body = Regex.Replace(body
                    , "[^\\x00-\\x7F]"
                    , new MatchEvaluator(delegate(Match m) { string x = m.ToString(); return string.Format("&#{0};", (int)x[0]); })
                    , RegexOptions.ECMAScript | RegexOptions.Compiled
                    );
        body = string.Format(@"<!DOCTYPE html PUBLIC ""-//W3C//DTD XHTML 1.0 Transitional//EN"" ""http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"">
<html xmlns=""http://www.w3.org/1999/xhtml"" lang=""{4}"">
<head>
<meta http-equiv=""content-type"" content=""text/html; charset=utf-8"" />
<base href=""http://{0}:{1}/"" />
</head>
<body dir=""{2}"">
{3}
</body>
</html>"
            , HttpContext.Current.Request.Url.Host
            , HttpContext.Current.Request.Url.Port
            , cultureInfo.TextInfo.IsRightToLeft ? "rtl" : "ltr"
            , body
            , this.Culture
            );
        return body;
    }

    public void Send(string emailAddress)
    {
        
        using( MailMessage message = new MailMessage() )
        {
            message.ReplyToList.Add(new MailAddress(Settings.Email_SupportAddress));
            message.Subject = this.Subject.Replace("\r","").Replace("\n","");
            message.SubjectEncoding = Encoding.UTF8;
            message.To.Add( new MailAddress(emailAddress) );
            message.IsBodyHtml = true;
            message.From = new MailAddress(Settings.Email_NoReplyAddress);
            message.BodyEncoding = Encoding.UTF8;
            message.Body = GetBody();

            SmtpClient client = new SmtpClient( Settings.Email_SMTP, Settings.Email_Port);
            client.Send(message);
            Logger.Information("Email", "Email sent to {0} via {1}:{2}", emailAddress, Settings.Email_SMTP, Settings.Email_Port);
            Logger.Email(EmailType, Settings.Email_NoReplyAddress, Settings.Email_SupportAddress, emailAddress, message.Subject, message.Body);
        }
    }
}