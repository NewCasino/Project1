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
        private void SendServersDownEmail(Service service, List<string> servers, List<PageResult> results)
        {
            if (!servers.Any())
                return;

            string subject = string.Format("{0} Sanity Check: servers have problem", service.Name);
            StringBuilder body = new StringBuilder();
            
            body.AppendLine("Hi ,");
            body.AppendLine("Check results:");
            body.AppendLine("");

            foreach (var server in servers)
                body.AppendLine(server);

            body.AppendLine("");
            body.AppendLine("Is down.");
            body.AppendLine("");
            body.AppendLine("Thanks");

            EmailHelper.Send(Config.ServerAlertReceiver, subject, body.ToString());
        }

        private void SendServersRecoveredEmail(Service service, List<string> servers, List<PageResult> results)
        {
            if (!servers.Any())
                return;

            string subject = string.Format("{0} Sanity Check: servers recovered", service.Name);
            StringBuilder body = new StringBuilder();

            body.AppendLine("Hi ,");
            body.AppendLine("Check results:");
            body.AppendLine("");

            foreach (var server in servers)
                body.AppendLine(server);

            body.AppendLine("");
            body.AppendLine("Is recovered.");
            body.AppendLine("");
            body.AppendLine("Thanks");

            EmailHelper.Send(Config.ServerAlertReceiver, subject, body.ToString());
        }
    }
}
