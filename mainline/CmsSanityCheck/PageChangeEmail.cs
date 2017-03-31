using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CmsSanityCheck
{
    using Model;
    using Misc;

    public partial class MonitorService
    {
        private void SendRespondingSlowlyEmail(Service service, List<PageResult> pages)
        {
            if (!pages.Any())
                return;

            string subject = string.Format("{0} Sanity Check: pages have problem", service.Name);

            StringBuilder body = new StringBuilder();
            body.AppendLine("Hi,");
            body.AppendLine("Checks revealed following malfunction");
            body.AppendLine("");

            foreach (var page in pages)
                body.AppendLine(string.Format("{0} ({1})", page.FriendlyUrl, page.IPAddress));

            body.AppendLine("");
            body.AppendLine("Is responding very slow.");
            body.AppendLine("");
            body.AppendLine("Thanks");

            EmailHelper.Send(Config.SiteAlertReceiver, subject, body.ToString());
        }

        private void SendRecoveredFromSlowlyEmail(Service service, List<PageResult> pages)
        {
            if (!pages.Any())
                return;

            string subject = string.Format("{0} Sanity Check: pages recovered", service.Name);
            StringBuilder body = new StringBuilder();
            body.AppendLine("Hi,");
            body.AppendLine("Previously reported malfunction:");
            body.AppendLine("");

            foreach (var page in pages)
                body.AppendLine(string.Format("{0} ({1})", page.FriendlyUrl, page.IPAddress));

            body.AppendLine("");
            body.AppendLine("Responding very slow  WAS RECOVERED.");
            body.AppendLine("");
            body.AppendLine("Thanks");

            EmailHelper.Send(Config.SiteAlertReceiver, subject, body.ToString());
        }

        private void SendNoRespondingEmail(Service service, List<PageResult> pages)
        {
            if (!pages.Any())
                return;

            string subject = string.Format("{0} Sanity Check: pages have problem", service.Name);

            StringBuilder body = new StringBuilder();
            body.AppendLine("Hi,");
            body.AppendLine("Checks revealed following malfunction");
            body.AppendLine("");

            foreach (var page in pages)
                body.AppendLine(string.Format("{0} ({1})", page.FriendlyUrl, page.IPAddress));

            body.AppendLine("");
            body.AppendLine("Is not responding.");
            body.AppendLine("");
            body.AppendLine("Thanks");

            EmailHelper.Send(Config.SiteAlertReceiver, subject, body.ToString());
        }

        private void SendRecoveredFromNoRespondingEmail(Service service, List<PageResult> pages)
        {
            if (!pages.Any())
                return;

            string subject = string.Format("{0} Sanity Check: pages recovered", service.Name);
            StringBuilder body = new StringBuilder();
            body.AppendLine("Hi,");
            body.AppendLine("Previously reported malfunction:");
            body.AppendLine("");

            foreach (var page in pages)
                body.AppendLine(string.Format("{0} ({1})", page.FriendlyUrl, page.IPAddress));

            body.AppendLine("");
            body.AppendLine("no response  WAS RECOVERED.");
            body.AppendLine("");
            body.AppendLine("Thanks");

            EmailHelper.Send(Config.SiteAlertReceiver, subject, body.ToString());
        }

        private void SendHaveErrorsEmail(Service service, List<PageResult> pages)
        {
            if (!pages.Any())
                return;

            string subject = string.Format("{0} Sanity Check: pages have problem", service.Name);

            StringBuilder body = new StringBuilder();
            body.AppendLine("Hi,");
            body.AppendLine("Checks revealed following malfunction");
            body.AppendLine("");

            foreach (var page in pages)
            {
                string error;
                if (_statusCodeMapping.TryGetValue(page.StatusCode, out error))
                    body.AppendLine(string.Format("{0} ({1}) got {2} error ({3})", page.FriendlyUrl, page.IPAddress, page.StatusCode, error));
                else
                    body.AppendLine(string.Format("{0} ({1}) got {2} error", page.FriendlyUrl, page.IPAddress, page.StatusCode));
            }

            body.AppendLine("");
            body.AppendLine("Is down.");
            body.AppendLine("");
            body.AppendLine("Thanks");

            EmailHelper.Send(Config.SiteAlertReceiver, subject, body.ToString());
        }

        private void SendRecoveredFromErrorsEmail(Service service, List<PageResult> pages)
        {
            if (!pages.Any())
                return;

            string subject = string.Format("{0} Sanity Check: pages recovered", service.Name);
            StringBuilder body = new StringBuilder();
            body.AppendLine("Hi,");
            body.AppendLine("Previously reported malfunction:");
            body.AppendLine("");

            foreach (var page in pages)
                body.AppendLine(string.Format("{0} ({1})", page.FriendlyUrl, page.IPAddress));

            body.AppendLine("");
            body.AppendLine("Page down WAS RECOVERED.");
            body.AppendLine("");
            body.AppendLine("Thanks");

            EmailHelper.Send(Config.SiteAlertReceiver, subject, body.ToString());
        }

        

    }
}
