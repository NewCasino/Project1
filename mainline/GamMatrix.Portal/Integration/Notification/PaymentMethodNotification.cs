using System;
using System.Collections.Generic;
using System.Configuration;
using System.Linq;
using System.Net.Mail;
using System.Text;
using CM.db;
using CM.State;
using Finance;

namespace Notification
{
    public class PaymentMethodNotification
    {
        public static void SendVisibilityAndOrderChangeEmail(cmSite domain, List<PaymentMethod> oldPaymentMethods, List<PaymentMethod> newPaymentMethods)
        {
            var template = @"<tr>
                    <td style=""padding: 5px 10px;"">{0}
                    </td>
                    <td style=""padding: 5px 10px;"">{1}
                    </td>
                    <td style=""padding: 5px 10px;"">{2}
                    </td>
                </tr>";
            var sb = new StringBuilder();

            var sbChanges = new StringBuilder();

            #region Visibility
            sbChanges.Clear();
            foreach (var oldPaymentMethod in oldPaymentMethods)
            {
                var newPaymentMethod = newPaymentMethods.FirstOrDefault(pm => pm.UniqueName == oldPaymentMethod.UniqueName);
                if (newPaymentMethod.IsVisible != oldPaymentMethod.IsVisible)
                {
                    sbChanges.AppendFormat(template
                                           , oldPaymentMethod.UniqueName
                                           , oldPaymentMethod.IsVisible ? "Visible" : "Invisible"
                                           , newPaymentMethod.IsVisible ? "Visible" : "Invisible");
                }
            }

            if (sbChanges.Length > 0)
            {
                sb.AppendLine(string.Format("<b>{0}</b> changed <b>[Visibility]</b> for [{1}].<br /><br />", CustomProfile.Current.UserName, domain.DistinctName));
                sb.AppendLine(@"<table border=""1"" bordercolor=""#000000"" cellpadding=""2"" cellspacing=""0"">");
                sb.AppendLine(@"<thead>");
                sb.AppendLine(@"<tr>");
                sb.AppendLine(@"<th style=""padding: 5px 10px;""></th>");
                sb.AppendLine(@"<th style=""padding: 5px 10px;"">From</th>");
                sb.AppendLine(@"<th style=""padding: 5px 10px;"">To</th>");
                sb.AppendLine(@"</tr>");
                sb.AppendLine(@"</thead>");
                sb.AppendLine(@"<tbody>");
                sb.AppendLine(@"</tbody>");
                sb.AppendLine(sbChanges.ToString());
                sb.AppendLine(@"</table>");
                sb.AppendLine(@"<br />");
                sb.Append(@"");
            }
            #endregion

            #region Order
            var categories = PaymentMethodManager.GetCategories(domain, "en");
            foreach (var category in categories)
            {
                sbChanges.Clear();

                var oldList = oldPaymentMethods.Where(pm => pm.Category == category).OrderBy(pm => pm.Ordinal).ToList();
                for (var i = 0; i < oldList.Count; i++)
                    oldList[i].Ordinal = i + 1;
                var newList = newPaymentMethods.Where(pm => pm.Category == category).OrderBy(pm => pm.Ordinal).ToList();
                for (var i = 0; i < newList.Count; i++)
                    newList[i].Ordinal = i + 1;

                foreach (var oldItem in oldList)
                {
                    var newItem = newList.FirstOrDefault(pm => pm.UniqueName == oldItem.UniqueName);

                    if (newItem == null)
                        continue;

                    if (oldItem.Ordinal == newItem.Ordinal)
                        continue;

                    sbChanges.AppendFormat(template
                                           , oldItem.UniqueName
                                           , oldItem.Ordinal.ToString()
                                           , newItem.Ordinal.ToString());
                }

                if (sbChanges.Length > 0)
                {
                    sb.AppendLine(string.Format("<b>{0}</b> changed <b>[Order]</b> of <b>[{1}]</b> for [{2}].<br /><br />", CustomProfile.Current.UserName, category, domain.DistinctName));
                    sb.AppendLine(@"<table border=""1"" bordercolor=""#000000"" cellpadding=""2"" cellspacing=""0"">");
                    sb.AppendLine(@"<thead>");
                    sb.AppendLine(@"<tr>");
                    sb.AppendLine(@"<th style=""padding: 5px 10px;""></th>");
                    sb.AppendLine(@"<th style=""padding: 5px 10px;"">From</th>");
                    sb.AppendLine(@"<th style=""padding: 5px 10px;"">To</th>");
                    sb.AppendLine(@"</tr>");
                    sb.AppendLine(@"</thead>");
                    sb.AppendLine(@"<tbody>");
                    sb.AppendLine(@"</tbody>");
                    sb.AppendLine(sbChanges.ToString());
                    sb.AppendLine(@"</table>");
                    sb.AppendLine(@"<br />");
                    sb.Append(@"");
                }
            }

            #endregion

            SendNotificationEmail(sb.ToString());
        }

        public static void SendFallbackVisibilityChangeEmail(cmSite domain, List<PaymentMethod> oldPaymentMethods, List<PaymentMethod> newPaymentMethods)
        {
            var template = @"<tr>
                    <td style=""padding: 5px 10px;"">{0}
                    </td>
                    <td style=""padding: 5px 10px;"">{1}
                    </td>
                    <td style=""padding: 5px 10px;"">{2}
                    </td>
                </tr>";
            var sb = new StringBuilder();

            var sbChanges = new StringBuilder();
            
            sbChanges.Clear();
            foreach (var oldPaymentMethod in oldPaymentMethods)
            {
                var newPaymentMethod = newPaymentMethods.FirstOrDefault(pm => pm.UniqueName == oldPaymentMethod.UniqueName);
                if (newPaymentMethod.IsVisibleDuringFallback != oldPaymentMethod.IsVisibleDuringFallback)
                {
                    sbChanges.AppendFormat(template
                                           , oldPaymentMethod.UniqueName
                                           , oldPaymentMethod.IsVisible ? "Visible" : "Invisible"
                                           , newPaymentMethod.IsVisible ? "Visible" : "Invisible");
                }
            }

            if (sbChanges.Length > 0)
            {
                sb.AppendLine(string.Format("<b>{0}</b> changed <b>[Fallback visibility]</b> for [{1}].<br /><br />", CustomProfile.Current.UserName, domain.DistinctName));
                sb.AppendLine(@"<table border=""1"" bordercolor=""#000000"" cellpadding=""2"" cellspacing=""0"">");
                sb.AppendLine(@"<thead>");
                sb.AppendLine(@"<tr>");
                sb.AppendLine(@"<th style=""padding: 5px 10px;""></th>");
                sb.AppendLine(@"<th style=""padding: 5px 10px;"">From</th>");
                sb.AppendLine(@"<th style=""padding: 5px 10px;"">To</th>");
                sb.AppendLine(@"</tr>");
                sb.AppendLine(@"</thead>");
                sb.AppendLine(@"<tbody>");
                sb.AppendLine(@"</tbody>");
                sb.AppendLine(sbChanges.ToString());
                sb.AppendLine(@"</table>");
                sb.AppendLine(@"<br />");
                sb.Append(@"");
            }
            
            SendNotificationEmail(sb.ToString());
        }

        public static void SendBankWithdrawalChangeEmail(cmSite domain, Dictionary<long, BankWithdrawalCountryConfig> oldConfigs, Dictionary<long, BankWithdrawalCountryConfig> newConfigs)
        {
            var template = @"<tr>
                    <td style=""padding: 5px 10px;"">{0}
                    </td>
                    <td style=""padding: 5px 10px;"">{1}
                    </td>
                    <td style=""padding: 5px 10px;"">{2}
                    </td>
                </tr>";

            var sb = new StringBuilder();
            var sbChanges = new StringBuilder();

            List<CountryInfo> countries = CountryManager.GetAllCountries().Where(c => c.InternalID > 0).ToList();

            foreach (CountryInfo country in countries)
            {
                BankWithdrawalCountryConfig oldConfig;
                if (!oldConfigs.TryGetValue(country.InternalID, out oldConfig))
                {
                    oldConfig = new BankWithdrawalCountryConfig
                    {
                        InternalID = country.InternalID,
                        Type = BankWithdrawalType.None
                    };
                }
                BankWithdrawalCountryConfig newConfig;
                if (!newConfigs.TryGetValue(country.InternalID, out newConfig))
                {
                    newConfig = new BankWithdrawalCountryConfig
                    {
                        InternalID = country.InternalID,
                        Type = BankWithdrawalType.None
                    };
                }

                if (oldConfig.Type != newConfig.Type)
                    sbChanges.AppendFormat(template, country.EnglishName, oldConfig.Type, newConfig.Type);
            }

            if (sbChanges.Length > 0)
            {
                sb.AppendLine(string.Format("<b>{0}</b> changed <b>[Bank Withdrawal]</b> for [{1}].<br /><br />", CustomProfile.Current.UserName, domain.DistinctName));
                sb.AppendLine(@"<table border=""1"" bordercolor=""#000000"" cellpadding=""2"" cellspacing=""0"">");
                sb.AppendLine(@"<thead>");
                sb.AppendLine(@"<tr>");
                sb.AppendLine(@"<th style=""padding: 5px 10px;"">Country</th>");
                sb.AppendLine(@"<th style=""padding: 5px 10px;"">From</th>");
                sb.AppendLine(@"<th style=""padding: 5px 10px;"">To</th>");
                sb.AppendLine(@"</tr>");
                sb.AppendLine(@"</thead>");
                sb.AppendLine(@"<tbody>");
                sb.AppendLine(@"</tbody>");
                sb.AppendLine(sbChanges.ToString());
                sb.AppendLine(@"</table>");
                sb.AppendLine(@"<br />");
                sb.Append(@"");
            }

            SendNotificationEmail(sb.ToString());
        }

        private static void SendNotificationEmail(string body)
        {
            if (string.IsNullOrWhiteSpace(body))
                return;

            using (MailMessage message = new MailMessage())
            {
                string[] addresses = ConfigurationManager.AppSettings["PaymentMethod.ChangeNotification.EmailAddress"].Split(new char[] { ',' }, StringSplitOptions.RemoveEmptyEntries);

                if (addresses.Length == 0)
                    return;

                message.Subject = "Payment method change notification";
                message.SubjectEncoding = Encoding.UTF8;
                foreach (string address in addresses)
                    message.To.Add(new MailAddress(address));
                message.IsBodyHtml = true;
                message.From = new MailAddress("noreply@everymatrix.com");
                message.BodyEncoding = Encoding.UTF8;
                message.Body = body;

                SmtpClient client = new SmtpClient("10.0.10.7", 25);
                client.Send(message);
            }
        }
    }
}
