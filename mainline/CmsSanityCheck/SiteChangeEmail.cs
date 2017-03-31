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
        private void SendSitesDownEmail(Service service, List<int> siteIDs, List<PageResult> results)
        {
            if (!siteIDs.Any())
                return;

            List<SiteAndHost> siteAndHosts = SiteManager.GetAll(service);

            string subject = string.Format("{0} Sanity Check: sites have problem – we need to resume the problem", service.Name);
            StringBuilder body = new StringBuilder();

            body.AppendLine("Hi ,");
            body.AppendLine("Check results:");
            body.AppendLine("");

            foreach (var siteID in siteIDs)
            {
                SiteAndHost siteAndHost = siteAndHosts.FirstOrDefault(sh => sh.SiteID == siteID);
                if (siteAndHost == null)
                    continue;

                var siteResults = results.Where(r => r.SiteID == siteID).ToList();

                body.AppendLine(string.Format("{0} ({1})", siteAndHost.DisplayName, siteResults.FirstOrDefault().IPAddress));

                foreach (var siteResult in siteResults)
                {
                    switch (siteResult.ResultType)
                    {
                        case ResultType.NoResponse:
                            body.AppendLine(string.Format("{0} ({1}) is not responding.", siteResult.FriendlyUrl, siteResult.IPAddress));
                            break;
                        case ResultType.Slow:
                            body.AppendLine(string.Format("{0} ({1}) is responding very slow.", siteResult.FriendlyUrl, siteResult.IPAddress));
                            break;
                        case ResultType.ClientError:
                        case ResultType.ServerError:
                        case ResultType.Unknown:
                            string error;
                            if (_statusCodeMapping.TryGetValue(siteResult.StatusCode, out error))
                                body.AppendLine(string.Format("{0} ({1}) got {2} error ({3}).", siteResult.FriendlyUrl, siteResult.IPAddress, siteResult.StatusCode, error));
                            else
                                body.AppendLine(string.Format("{0} ({1}) got {2} error.", siteResult.FriendlyUrl, siteResult.IPAddress, siteResult.StatusCode));
                            break;
                    }
                }
                body.AppendLine("");
            }
            body.AppendLine("Is down.");
            body.AppendLine("");
            body.AppendLine("Thanks");

            EmailHelper.Send(Config.ServerAlertReceiver, subject, body.ToString());
        }

        private void SendSitesRecoveredEmail(Service service, List<int> siteIDs, List<PageResult> lastResults, List<PageResult> results)
        {
            if (!siteIDs.Any())
                return;

            List<SiteAndHost> siteAndHosts = SiteManager.GetAll(service);

            string subject = string.Format("{0} Sanity Check: sites recovered", service.Name);
            StringBuilder body = new StringBuilder();

            body.AppendLine("Hi ,");
            body.AppendLine("Check results:");
            body.AppendLine("");

            foreach (var siteID in siteIDs)
            {
                SiteAndHost siteAndHost = siteAndHosts.FirstOrDefault(sh => sh.SiteID == siteID);
                if (siteAndHost == null)
                    continue;

                var lastSiteResults = lastResults.Where(lr => lr.SiteID == siteID).ToList();
                var siteResults = results.Where(r => r.SiteID == siteID).ToList();

                body.AppendLine(string.Format("{0} ({1})", siteAndHost.DisplayName, lastSiteResults.FirstOrDefault().IPAddress));

                foreach (var lastSiteResult in lastSiteResults)
                {
                    var siteResult = siteResults.FirstOrDefault(sr => sr.UniqueID == lastSiteResult.UniqueID);
                    if (siteResult == null || siteResult.ResultType != ResultType.Success)
                        continue;

                    switch (lastSiteResult.ResultType)
                    {
                        case ResultType.Slow:
                            body.AppendLine(string.Format("{0} ({1}) recovered from responding very slow.", siteResult.FriendlyUrl, siteResult.IPAddress));
                            break;
                        case ResultType.NoResponse:
                            body.AppendLine(string.Format("{0} ({1}) recovered from no response.", siteResult.FriendlyUrl, siteResult.IPAddress));
                            break;
                        case ResultType.ClientError:
                        case ResultType.ServerError:
                        case ResultType.Unknown:
                            string error;
                            if (_statusCodeMapping.TryGetValue(lastSiteResult.StatusCode, out error))
                                body.AppendLine(string.Format("{0} ({1}) recovered from {2} error ({3}).", siteResult.FriendlyUrl, siteResult.IPAddress, lastSiteResult.StatusCode, error));
                            else
                                body.AppendLine(string.Format("{0} ({1}) recovered from {2} error.", siteResult.FriendlyUrl, siteResult.IPAddress, lastSiteResult.StatusCode));
                            break;
                    }
                }

                body.AppendLine("");
            }
            body.AppendLine("Is recovered.");
            body.AppendLine("");
            body.AppendLine("Thanks");

            EmailHelper.Send(Config.ServerAlertReceiver, subject, body.ToString());
        }


    }
}
