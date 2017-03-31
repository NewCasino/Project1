using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using System.Net;
using System.Net.Http;
using System.Web;
using System.Text;
using System.IO;
using System.Text.RegularExpressions;

using log4net;

namespace CmsSanityCheck
{
    using Misc;
    using Model;

    public partial class MonitorService
    {
        private static readonly ILog log = LogManager.GetLogger(typeof(MainEntry));
        private readonly CancellationTokenSource _tokenSource = new CancellationTokenSource();
        //for C#, should use \r\n to match the new line
        //but for JS, should use \n to match the new line
        //regular expression tool site: http://www.regexr.com/
        //private const string _pattern = @"(<!--\r\n)(?<message>(.|\r|\n)*?)(\r\nStack Track:\r\n)(?<stacktrace>(.|\r|\n)*?)(--><\/head><body>\r\n)(<h3 style=""color:red"">)((.|\r|\n)*)(<\/h3>)(<h5 style=""color:red"">)((.|]r|\n)*)(<\/h5>)";
        //private readonly Regex _regex = new Regex(_pattern, RegexOptions.Compiled);

        private readonly Dictionary<int, string> _statusCodeMapping = new Dictionary<int, string>()
        {
            {400, "Bad Request"},
            {401, "Unauthorized"},
            {402, "Payment Required"},
            {403, "Forbidden"},
            {404, "Not Found"},
            {405, "Method Not Allowed"},
            {406, "Not Acceptable"},
            {407, "Proxy Authentication Required"},
            {408, "Request Timeout"},
            {409, "Conflict"},
            {410, "Gone"},
            {411, "Length Required"},
            {412, "Precondition Failed"},
            {413, "Request Entity Too Large"},
            {414, "Request-URI Too Long"},
            {415, "Unsupported Media Type"},
            {416, "Requested Range Not Satisfiable"},
            {417, "Expectation Failed"},
            {418, "I'm a teapot (RFC 2324)"},
            {419, "Authentication Timeout (not in RFC 2616)"},
            {420, "Method Failure (Spring Framework) / Enhance Your Calm (Twitter)"},
            {422, "Unprocessable Entity (WebDAV; RFC 4918)"},
            {423, "Locked (WebDAV; RFC 4918)"},
            {424, "Failed Dependency (WebDAV; RFC 4918)"},
            {426, "Upgrade Required"},
            {428, "Precondition Required (RFC 6585)"},
            {429, "Too Many Requests (RFC 6585)"},
            {431, "Request Header Fields Too Large (RFC 6585)"},
            {440, "Login Timeout (Microsoft)"},
            {444, "No Response (Nginx)"},
            {449, "Retry With (Microsoft)"},
            {450, "Blocked by Windows Parental Controls (Microsoft)"},
            {451, "Unavailable For Legal Reasons (Internet draft) / Redirect (Microsoft)"},
            {494, "Request Header Too Large (Nginx)"},
            {495, "Cert Error (Nginx)"},
            {496, "No Cert (Nginx)"},
            {497, "HTTP to HTTPS (Nginx)"},
            {498, "Token expired/invalid (Esri)"},
            {499, "Client Closed Request (Nginx) / Token required (Esri)"},
            {500, "Internal Server Error"},
            {501, "Not Implemented"},
            {502, "Bad Gateway"},
            {503, "Service Unavailable"},
            {504, "Gateway Timeout"},
            {505, "HTTP Version Not Supported"},
            {506, "Variant Also Negotiates (RFC 2295)"},
            {507, "Insufficient Storage (WebDAV; RFC 4918)"},
            {508, "Loop Detected (WebDAV; RFC 5842)"},
            {509, "Bandwidth Limit Exceeded (Apache bw/limited extension)[28]"},
            {510, "Not Extended (RFC 2774)"},
            {511, "Network Authentication Required (RFC 6585)"},
            {598, "Network read timeout error (Unknown)"},
            {599, "Network connect timeout error (Unknown)"},
        };

        public void Start()
        {
            Task.Factory.StartNew(Run, _tokenSource.Token);
        }

        public void Stop()
        {
            _tokenSource.Cancel();
        }

        private void Run()
        {
            while (true)
            {
                try
                {
                    log.Info(string.Format("Check started at : {0}", DateTime.Now));
                    long start = DateTime.Now.Ticks;
                    var services = Config.LoadServices();
                    foreach (var service in services)
                    {
                        if (service.Name.StartsWith("CE", StringComparison.InvariantCultureIgnoreCase))
                        {
                            CheckCasinoEngine(service);
                        }
                        else if (service.Name.StartsWith("CMS", StringComparison.InvariantCultureIgnoreCase))
                        {
                            CheckCms(service);
                        }
                        else
                            continue;
                    }
                    long end = DateTime.Now.Ticks;
                    double seconds = (int)((end - start) / 10.0 / 1000.0 / 1000.0);
                    log.Info(string.Format("Check ended at : {0}", DateTime.Now));
                    log.Info(string.Format("Total Seconds: {0}", seconds));

                    Task.Delay(60000 * Config.Interval).Wait();
                }
                catch (Exception ex)
                {
                    log.Error("Run", ex);
                    Task.Delay(60000 * Config.Interval).Wait();
                }
            }
        }

        private void CheckCasinoEngine(Service service)
        {
            log.Info(string.Format("Check CE service: {0} Started", service.Name));
            try
            {
                //IP Address -> Check Items
                Dictionary<string, List<CheckItem>> dict = new Dictionary<string, List<CheckItem>>();
                foreach (var ipAddress in service.IPAddresses)
                {
                    List<CheckItem> items = new List<CheckItem>();
                    foreach (var testUrl in service.TestUrls)
                    {
                        CheckItem checkItem = new CheckItem()
                        {
                            Url = string.Format(testUrl, ipAddress),
                            FriendlyUrl = string.Format(testUrl, service.Host),
                        };
                        checkItem.SiteAndHost = new SiteAndHost()
                        {
                            SiteID = 1,
                            DisplayName = "Casino Engine",
                            DomainID = service.DomainID,
                            HostNames = new string[] { service.Host }.ToList(),
                        };
                        items.Add(checkItem);
                    }
                    dict.Add(ipAddress, items);
                }

                CheckService(service, dict);
            }
            catch (Exception ex)
            {
                log.Error("Check CE", ex);
            }
            log.Info(string.Format("Check CE service: {0} Ended", service.Name));
        }

        private void CheckCms(Service service)
        {
            log.Info(string.Format("Check CMS service: {0} Started", service.Name));
            try
            {
                var siteAndHosts = SiteManager.GetAll(service);
                siteAndHosts = OrderByWeight(siteAndHosts);
#if DEBUG
                var allowDomainIDs = new int[] { 24 };
                var allowSiteIDs = new int[] { 2083, 2039 };
                //var allowDomainIDs = new int[] { 7018 };
                //var allowSiteIDs = new int[] { 2052 };
                siteAndHosts = siteAndHosts.Where(sh => allowDomainIDs.Contains(sh.DomainID) && allowSiteIDs.Contains(sh.SiteID)).ToList();
#endif
                log.Info(string.Format("total sites: {0}", siteAndHosts.Count));

                //IP Address -> Check Items
                Dictionary<string, List<CheckItem>> dict = new Dictionary<string, List<CheckItem>>();
                foreach (var ipAddress in service.IPAddresses)
                {
                    List<CheckItem> items = new List<CheckItem>();
                    foreach (var siteAndHost in siteAndHosts)
                    {
                        foreach (var testUrl in service.TestUrls)
                        {
                            items.Add(new CheckItem()
                            {
                                Url = string.Format(testUrl, ipAddress),
                                FriendlyUrl = string.Format(testUrl, siteAndHost.Host),
                                SiteAndHost = siteAndHost,
                            });
                        }
                    }
                    dict.Add(ipAddress, items);
                }

                CheckService(service, dict);
            }
            catch (Exception ex)
            {
                log.Error("Check CMS", ex);
            }
            log.Info(string.Format("Check CMS service: {0} Ended", service.Name));
        }

        private List<SiteAndHost> OrderByWeight(List<SiteAndHost> siteAndHosts)
        {
            var weightConfigs = (from a in Config.Weights
                                 select new
                                 {
                                     DomainID = a.Key,
                                     Weight = a.Value,
                                 }).ToList();
            weightConfigs = weightConfigs.OrderByDescending(wc => wc.Weight).ToList();

            List<SiteAndHost> list = new List<SiteAndHost>();

            foreach (var weightConfig in weightConfigs)
                list.AddRange(siteAndHosts.Where(sh => sh.DomainID == weightConfig.DomainID).ToList());

            list.AddRange(siteAndHosts.Where(sh => !weightConfigs.Select(wc => wc.DomainID).Contains(sh.DomainID)).ToList());

            return list;
        }

        /// <summary>
        /// Check Service
        /// </summary>
        /// <param name="service">service</param>
        /// <param name="dict">IP Address -> Check Items</param>
        private void CheckService(Service service, Dictionary<string, List<CheckItem>> dict)
        {
            StringBuilder sbLogs = new StringBuilder();
            sbLogs.AppendLine(string.Format("Check service: {0}", service.Name));

            //IP Address -> Check results
            Dictionary<string, List<CheckResult>> results = new Dictionary<string, List<CheckResult>>();
            //IP Address -> Check items
            Dictionary<string, List<CheckItem>> items = new Dictionary<string, List<CheckItem>>();

            //for the first time, add all items to the items to be check dictionary
            foreach (var ipAddress in dict.Keys)
                items.Add(ipAddress, dict[ipAddress]);

            int retryTimes = 1;

            while (true)
            {
                //IP Address -> Check Results
                Dictionary<string, List<CheckResult>> temp = new Dictionary<string, List<CheckResult>>();
                foreach (var ipAddress in items.Keys)
                {
                    var checkItems = items[ipAddress];
                    var checkResults = CheckIPAddress(ipAddress, checkItems).Result;
                    temp.Add(ipAddress, checkResults);
                }

                //string path = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "logs", service.Name.Replace(" ", "") + ".xml");
                //string json = ObjectHelper.JsonSerialize(resultDictionary);
                //FileSystemHelper.WriteWithoutLock(path, json);
                //string path = Path.Combine("G:", service.Name.Replace(" ", "") + ".xml");
                //string json = FileSystemHelper.ReadWithoutLock(path);
                //resultDictionary = ObjectHelper.JsonDeserialize<Dictionary<string, List<CheckResult>>>(json);

                //log the results
                LogCheckResults(sbLogs, temp);

                //parse results
                //clear the items to be check dictionary
                //only add the failed items to the next check item dictionary
                items.Clear();
                foreach (var ipAddress in temp.Keys)
                {
                    List<CheckItem> checkItems = new List<CheckItem>();
                    List<CheckResult> checkResults = temp[ipAddress];
                    var siteIDs = checkResults.Select(cr => cr.Item.SiteAndHost.SiteID).Distinct().ToList();
                    foreach (var siteID in siteIDs)
                    {
                        var siteResults = checkResults.Where(cr => cr.Item.SiteAndHost.SiteID == siteID).ToList();
                        var successes = siteResults.Where(sr => sr.ResultType == ResultType.Success).ToList();
                        var failures = siteResults.Where(sr => sr.ResultType != ResultType.Success).ToList();

                        //for success results, add it to the global results dictionary
                        if (successes.Any())
                        {
                            if (!results.ContainsKey(ipAddress))
                                results.Add(ipAddress, new List<CheckResult>());
                            results[ipAddress].AddRange(successes);
                        }

                        //only add the failure items to the next check list
                        if (failures.Any())
                        {
                            checkItems.AddRange(failures.Select(f => f.Item).ToList());
                        }
                    }
                    if (checkItems.Any())
                        items.Add(ipAddress, checkItems);
                }

                //all sites are good
                if (items.Count == 0)
                    break;

                //Reach the maximum retry times
                if (retryTimes >= Config.RetryTimes)
                {
                    foreach (var ipAddress in temp.Keys)
                    {
                        if (!results.ContainsKey(ipAddress))
                            results.Add(ipAddress, new List<CheckResult>());

                        //only add the failure results, the success results already added to the results dictionary
                        var failures = temp[ipAddress].Where(t => t.ResultType != ResultType.Success).ToList();
                        results[ipAddress].AddRange(failures);
                    }
                    break;
                }

                retryTimes++;
            }

            bool isSuccessful = AnalyseCheckResults(service, results);

            log.Info(string.Format("Check service: {0} Ended", service.Name));
            log.Info("");

            string subject = string.Format("{0} - Sanity Check ({1}): Logs", isSuccessful ? "+OK" : "-ERR", service.Name);
            string body = HttpUtility.HtmlEncode(sbLogs.ToString());
            EmailHelper.Send(Config.LogEmail, subject, body);
        }

        /// <summary>
        /// Check by items
        /// </summary>
        /// <param name="ipAddress">IP Address</param>
        /// <param name="items">items to be check</param>
        /// <returns></returns>
        private async Task<List<CheckResult>> CheckIPAddress(string ipAddress, List<CheckItem> items)
        {
#if DEBUG
            return CreateFakeCheckResult(items);
#endif

            log.Info(string.Format("IP Address: {0}, items count: {1}", ipAddress, items.Count));

            var pageSize = Config.Threads;
            var pageCount = items.Count / pageSize;
            if (items.Count % pageSize > 0)
                pageCount++;

            log.Info(string.Format("Page size: {0}, Page count: {1}", pageSize, pageCount));

            List<CheckResult> results = new List<CheckResult>();
            for (var pageIndex = 0; pageIndex < pageCount; pageIndex++)
            {
                var pagedItems = items.Skip(pageIndex * pageSize).Take(pageSize).ToList();

                // ***Create a query that, when executed, returns a collection of tasks.
                IEnumerable<Task<CheckResult>> downloadTasksQuery = from item in pagedItems select ProcessItem(item);

                // ***Use ToList to execute the query and start the tasks. 
                List<Task<CheckResult>> downloadTasks = downloadTasksQuery.ToList();

                // ***Add a loop to process the tasks one at a time until none remain.
                while (downloadTasks.Count > 0)
                {
                    // Identify the first task that completes.
                    Task<CheckResult> firstFinishedTask = await Task.WhenAny(downloadTasks);

                    // ***Remove the selected task from the list so that you don't
                    // process it more than once.
                    downloadTasks.Remove(firstFinishedTask);

                    // Await the completed task.
                    CheckResult result = firstFinishedTask.Result;

                    log.Info(string.Format("Host: {0}, Url: {1}, Result Type: {2}, Status Code: {3}, Elapsed Seconds: {4}, Error Message: {5}", result.Item.SiteAndHost.Host, result.Item.Url, result.ResultType.ToString(), result.StatusCode, result.ElapsedSeconds, result.ErrorMessage));

                    results.Add(result);
                }

                int score = results.Sum(r => GetWeight(r.ResultType, r.Item.SiteAndHost.DomainID));

                //reach the critical weight, break the check
                if (score >= Config.CriticalWeight)
                {
                    log.Info(string.Format("{0} reach the critical weight, break the check", ipAddress));

                    //for all pages that are not started, marked the status to Skip
                    for (var i = (pageIndex + 1) * pageSize; i < items.Count; i++)
                    {
                        results.Add(new CheckResult()
                        {
                            Item = items[i],
                            StatusCode = 0,
                            ResponseText = null,
                            ElapsedSeconds = 0,
                            ResultType = ResultType.Unknown,
                            ErrorMessage = null,
                        });
                    }
                    break;
                }
            }

            return results;
        }

        private async Task<CheckResult> ProcessItem(CheckItem item)
        {
            CheckResult result = new CheckResult()
            {
                Item = item,
            };

            var start = DateTime.Now.Ticks;
            WebRequestHandler handler = new WebRequestHandler();
            handler.AllowAutoRedirect = false;
            HttpClient client = new HttpClient(handler)
            {
                Timeout = TimeSpan.FromSeconds(Config.Timeout),
            };
            client.DefaultRequestHeaders.Host = item.SiteAndHost.Host;

            try
            {
                HttpResponseMessage response = await client.GetAsync(item.Url);
                result.StatusCode = (int)response.StatusCode;
                result.ResponseText = await response.Content.ReadAsStringAsync();

                //http://en.wikipedia.org/wiki/List_of_HTTP_status_codes
                if (result.StatusCode >= 100 && result.StatusCode <= 399)//1xx Informational, 2xx Success, 3xx Redirection
                    result.ResultType = ResultType.Success;
                else if (result.StatusCode >= 400 && result.StatusCode <= 499)//4xx Client Error
                    result.ResultType = ResultType.ClientError;
                else if (result.StatusCode >= 500 && result.StatusCode <= 599)//5xx Server Error
                    result.ResultType = ResultType.ServerError;
                else
                    result.ResultType = ResultType.Unknown;
            }
            catch (Exception ex)
            {
                int loop = 0;
                while (ex.InnerException != null && loop < 10)
                {
                    ex = ex.InnerException;
                    loop++;
                }
                result.ErrorMessage = ex.Message;
                result.ResultType = ResultType.NoResponse;
            }
            long end = DateTime.Now.Ticks;
            result.ElapsedSeconds = (int)((end - start) / 10000000.0);//10 * 1000 * 1000

            if (result.ResultType == ResultType.Success)
            {
                if (result.ElapsedSeconds > Config.CriticalElapsedSeconds)
                    result.ResultType = ResultType.Slow;

                //MatchCollection matches = _regex.Matches(result.ResponseText);
                //if (matches.Count > 0)
                //{
                //    Match match = matches[0];
                //    result.ResultType = ResultType.Exception;
                //    result.ErrorMessage = match.Groups["message"].Value;
                //}
            }

            return result;
        }

        private int GetWeight(ResultType resultType, int domainID)
        {
            if (resultType == ResultType.Success)
                return 0;

            int weight;
            if (Config.Weights.TryGetValue(domainID, out weight))
                return weight;

            return 1;
        }

        private void LogCheckResults(StringBuilder sbLogs, Dictionary<string, List<CheckResult>> dict)
        {
            foreach (var ipAddress in dict.Keys)
            {
                var results = dict[ipAddress];

                sbLogs.AppendLine("");
                sbLogs.AppendLine(string.Format("IP Address: {0}", ipAddress));

                var failures = results.Where(r => r.ResultType != ResultType.Success).ToList();
                var successes = results.Where(r => r.ResultType == ResultType.Success).ToList();
                log.Info(string.Format("{0}, failures: {1}, successes: {2}", ipAddress, failures.Count, successes.Count));
                sbLogs.AppendLine(string.Format("{0}, failures: {1}, successes: {2}", ipAddress, failures.Count, successes.Count));

                foreach (var result in failures)
                {
                    string responseText = result.ResponseText;
                    if (!string.IsNullOrWhiteSpace(responseText) && responseText.Length > 15)
                        responseText = responseText.Trim().Substring(0, 15);
                    sbLogs.AppendLine(string.Format("{0} <==> {1}, Result Type: {2}, Error Message: {3}, Response Text: {4}", (int)result.StatusCode, result.Item.FriendlyUrl, result.ResultType.ToString(), result.ErrorMessage, responseText));
                }

                //foreach (var result in successes)
                //{
                //    string responseText = result.ResponseText;
                //    if (!string.IsNullOrWhiteSpace(responseText) && responseText.Length > 15)
                //        responseText = responseText.Trim().Substring(0, 15);
                //    sbLogs.AppendLine(string.Format("{0} <==> {1}, {2}", (int)result.StatusCode, result.Item.FriendlyUrl, responseText));
                //}
            }
        }

        private Dictionary<string, List<CheckResult>> MergeCheckResults(Dictionary<string, List<CheckResult>> dict1, Dictionary<string, List<CheckResult>> dict2)
        {
            Dictionary<string, List<CheckResult>> dict = new Dictionary<string, List<CheckResult>>();

            foreach (var ipAddress in dict1.Keys)
            {
                if (!dict.ContainsKey(ipAddress))
                    dict.Add(ipAddress, new List<CheckResult>());

                dict[ipAddress].AddRange(dict1[ipAddress]);
            }

            foreach (var ipAddress in dict2.Keys)
            {
                if (!dict.ContainsKey(ipAddress))
                    dict.Add(ipAddress, new List<CheckResult>());

                dict[ipAddress].AddRange(dict2[ipAddress]);
            }

            return dict;
        }

        private bool AnalyseCheckResults(Service service, Dictionary<string, List<CheckResult>> dict)
        {
            List<PageResult> lastResults = ObjectHelper.LoadPageResults(service);
            List<PageResult> results = new List<PageResult>();

            foreach (string ipAddress in dict.Keys)
            {
                List<CheckResult> checkResults = dict[ipAddress];
                results.AddRange(checkResults.Select(cr => new PageResult()
                {
                    FriendlyUrl = cr.Item.FriendlyUrl,
                    IPAddress = ipAddress,
                    SiteID = cr.Item.SiteAndHost.SiteID,
                    DomainID = cr.Item.SiteAndHost.DomainID,
                    ResultType = cr.ResultType,
                    StatusCode = cr.StatusCode,
                }).ToList());
            }

            ObjectHelper.SavePageResults(service, results);

            #region Analyse page results
            var slowlyPages = results.Where(r => r.ResultType == ResultType.Slow).ToList();
            var lastSlowlyPages = lastResults.Where(r => r.ResultType == ResultType.Slow).ToList();

            var noResponsePages = results.Where(r => r.ResultType == ResultType.NoResponse).ToList();
            var lastNoResponsePages = lastResults.Where(r => r.ResultType == ResultType.NoResponse).ToList();

            List<ResultType> errorResultTypes = new List<ResultType>()
            {
                ResultType.ClientError,
                ResultType.ServerError,
                ResultType.Unknown,
            };
            var errorPages = results.Where(r => errorResultTypes.Contains(r.ResultType)).ToList();
            var lastErrorPages = lastResults.Where(r => errorResultTypes.Contains(r.ResultType)).ToList();

            var pagesRespondingSlowly = slowlyPages.Where(sp => !lastSlowlyPages.Select(lsp => lsp.UniqueID).Contains(sp.UniqueID)).ToList();
            var pagesRecoveredFromSlowly = lastSlowlyPages.Where(lsp => !slowlyPages.Select(sp => sp.UniqueID).Contains(lsp.UniqueID)).ToList();

            var pagesNoResponding = noResponsePages.Where(sp => !lastNoResponsePages.Select(lsp => lsp.UniqueID).Contains(sp.UniqueID)).ToList();
            var pagesRecoveredFromNoResponding = lastNoResponsePages.Where(lsp => !noResponsePages.Select(sp => sp.UniqueID).Contains(lsp.UniqueID)).ToList();

            var pagesHaveErrors = errorPages.Where(sp => !lastErrorPages.Select(lsp => lsp.UniqueID).Contains(sp.UniqueID)).ToList();
            var pagesRecoveredFromErrors = lastErrorPages.Where(lsp => !errorPages.Select(sp => sp.UniqueID).Contains(lsp.UniqueID)).ToList();

            //send down emails
            SendRespondingSlowlyEmail(service, pagesRespondingSlowly);
            SendNoRespondingEmail(service, pagesNoResponding);
            SendHaveErrorsEmail(service, pagesHaveErrors);

            //send recovered emails
            SendRecoveredFromSlowlyEmail(service, pagesRecoveredFromSlowly);
            SendRecoveredFromNoRespondingEmail(service, pagesRecoveredFromNoResponding);
            SendRecoveredFromErrorsEmail(service, pagesRecoveredFromErrors);
            #endregion

            #region Analyse site results
            var lastDownSiteIDs = lastResults.GroupBy(r => r.SiteID).Where(g => g.Count(n => n.ResultType != ResultType.Success) == g.Count()).Select(g => g.Key).ToList();
            var downSiteIDs = results.GroupBy(r => r.SiteID).Where(g => g.Count(n => n.ResultType != ResultType.Success) == g.Count()).Select(g => g.Key).ToList();

            var siteIDsHaveProblem = downSiteIDs.Where(s => !lastDownSiteIDs.Contains(s)).ToList();
            var siteIDsRecovered = lastDownSiteIDs.Where(s => !downSiteIDs.Contains(s)).ToList();

            SendSitesDownEmail(service, siteIDsHaveProblem, results);
            SendSitesRecoveredEmail(service, siteIDsRecovered, lastResults, results);
            #endregion

            #region Analyse server results
            var lastDownServers = lastResults.GroupBy(r => r.IPAddress).Where(g => g.Sum(n => GetWeight(n.ResultType, n.DomainID)) > Config.CriticalWeight).Select(g => g.Key).ToList();
            var downServers = results.GroupBy(r => r.IPAddress).Where(g => g.Sum(n => GetWeight(n.ResultType, n.DomainID)) > Config.CriticalWeight).Select(g => g.Key).ToList();

            var serversHaveProblem = downServers.Where(s => !lastDownServers.Contains(s)).ToList();
            var serversRecovered = lastDownServers.Where(s => !downServers.Contains(s)).ToList();

            SendServersDownEmail(service, serversHaveProblem, results);
            SendServersRecoveredEmail(service, serversRecovered, lastResults);
            #endregion

            if (pagesRespondingSlowly.Any() || pagesNoResponding.Any() || pagesHaveErrors.Any())
                return false;

            if (pagesRecoveredFromSlowly.Any() || pagesRecoveredFromNoResponding.Any() || pagesRecoveredFromErrors.Any())
                return false;

            if (siteIDsHaveProblem.Any() || siteIDsRecovered.Any())
                return false;

            if (serversHaveProblem.Any() || serversRecovered.Any())
                return false;

            return true;

            #region unused comment
            //if (service.Name.StartsWith("CE", StringComparison.InvariantCultureIgnoreCase))
            //{
            //    //CE only need to report the server state
            //    return AnalyseServerStatuses(service, dict);
            //}
            //else
            //{
            //    //CMS need to report the page state, site state, server state
            //    var anyPageDown = AnalysePageStatuses(service, dict);
            //    var anySiteDown = AnalyseSiteStatuses(service, dict);
            //    var anyServerDown = AnalyseServerStatuses(service, dict);

            //    if (anyPageDown || anySiteDown || anyServerDown)
            //        return false;
            //    else
            //        return true;
            //}

            //foreach (var ipAddress in service.IPAddresses)
            //    sbLogs.AppendLine(string.Format("Score ({0}): {1}", ipAddress, serverScores[ipAddress]));

            //if (serverScores.Count(s => s.Value > Config.CriticalWeight) == 0)
            //{
            //    //all good, enable all servers in the load balance
            //    sbLogs.AppendLine("");
            //    sbLogs.AppendLine("all good, enable all servers in the load balance");
            //    var ipAddresses = service.IPAddresses.ToDictionary(ipAddress => ipAddress, ipAddress => true);
            //    LoadBalanceHelper.Update(service, ipAddresses);
            //    success = true;

            //    AnalyseSiteResults(service, allResults);

            //    //break the current check
            //    break;
            //}

            //retryTimes++;
            //if (retryTimes < Config.RetryTimes)
            //    continue;

            //if (serverScores.Count(s => s.Value > Config.CriticalWeight) == service.IPAddresses.Count)
            //{
            //    //all bad, send the warning email
            //    sbLogs.AppendLine("");
            //    sbLogs.AppendLine("all bad, send the warning email");
            //    SendAllBadEmail(service);

            //    AnalyseSiteResults(service, allResults);
            //}
            //else
            //{
            //    //some bad, remove from the load balance and send the email
            //    sbLogs.AppendLine("");
            //    sbLogs.AppendLine("some bad, remove from the load balance and send the email");
            //    var ipAddresses = serverScores.ToDictionary(s => s.Key, s => s.Value < Config.CriticalWeight);
            //    LoadBalanceHelper.Update(service, ipAddresses);

            //    AnalyseSiteResults(service, allResults);
            //}
            #endregion
        }

        private bool AnalysePageStatuses(Service service, Dictionary<string, List<CheckResult>> resultDictionary)
        {
            List<string> friendlyUrls = new List<string>();
            foreach (var ipAddress in resultDictionary.Keys)
            {
                var results = resultDictionary[ipAddress];
                var items = results.Select(r => r.Item).ToList();
                foreach (var friendlyUrl in items.Select(i => i.FriendlyUrl).Distinct())
                {
                    if (friendlyUrls.Contains(friendlyUrl))
                        continue;

                    friendlyUrls.Add(friendlyUrl);
                }
            }

            //Page Results, Friendly Url -> IP Address -> Check Result
            Dictionary<string, Dictionary<string, CheckResult>> pageResults = new Dictionary<string, Dictionary<string, CheckResult>>();
            //Page Statuses, Friendly Url -> IP Address -> Result Type
            Dictionary<string, Dictionary<string, ResultType>> pageStatuses = new Dictionary<string, Dictionary<string, ResultType>>();
            foreach (var friendlyUrl in friendlyUrls)
            {
                Dictionary<string, CheckResult> ipResults = new Dictionary<string, CheckResult>();
                Dictionary<string, ResultType> ipStatuses = new Dictionary<string, ResultType>();
                foreach (var ipAddress in resultDictionary.Keys)
                {
                    var results = resultDictionary[ipAddress];
                    var pageResult = results.FirstOrDefault(r => r.Item.FriendlyUrl == friendlyUrl);
                    ipResults.Add(ipAddress, pageResult);
                    ipStatuses.Add(ipAddress, pageResult.ResultType);
                }
                pageResults.Add(friendlyUrl, ipResults);
                pageStatuses.Add(friendlyUrl, ipStatuses);
            }

            List<PageInfo> recoveredPages, downPages;
            GetPageChanges(service, pageResults, out recoveredPages, out downPages);

            if (recoveredPages.Any() || downPages.Any())
            {
                ObjectHelper.SavePageStatuses(service, pageStatuses);

                if (service.Name.StartsWith("CMS", StringComparison.InvariantCultureIgnoreCase))
                {
                    if (recoveredPages.Any())
                    {
                        #region recovered from Slowly
                        {
                            var recoveredFromSlowly = recoveredPages.Where(rp => rp.LastResultType == ResultType.Slow).ToList();
                            log.Info("recoveredFromSlowly: " + recoveredFromSlowly.Count);
                            if (recoveredFromSlowly.Any())
                            {
                                string subject = string.Format("{0} Sanity Check: pages recovered", service.Name);
                                StringBuilder body = new StringBuilder();
                                body.AppendLine("Hi,");
                                body.AppendLine("Previously reported malfunction:");
                                body.AppendLine("");

                                foreach (var page in recoveredFromSlowly)
                                    body.AppendLine(string.Format("{0} ({1})", page.FriendlyUrl, page.IPAddress));

                                body.AppendLine("");
                                body.AppendLine("Responding very slow  WAS RECOVERED.");
                                body.AppendLine("");
                                body.AppendLine("Thanks");

                                EmailHelper.Send(Config.SiteAlertReceiver, subject, body.ToString());
                            }
                        }
                        #endregion

                        #region recovered from no response
                        {
                            var recoveredFromNoResponse = recoveredPages.Where(rp => rp.LastResultType == ResultType.NoResponse).ToList();
                            log.Info("recoveredFromNoResponse: " + recoveredFromNoResponse.Count);
                            if (recoveredFromNoResponse.Any())
                            {
                                string subject = string.Format("{0} Sanity Check: pages recovered", service.Name);
                                StringBuilder body = new StringBuilder();
                                body.AppendLine("Hi,");
                                body.AppendLine("Previously reported malfunction:");
                                body.AppendLine("");

                                foreach (var page in recoveredFromNoResponse)
                                    body.AppendLine(string.Format("{0} ({1})", page.FriendlyUrl, page.IPAddress));

                                body.AppendLine("");
                                body.AppendLine("no response  WAS RECOVERED.");
                                body.AppendLine("");
                                body.AppendLine("Thanks");

                                EmailHelper.Send(Config.SiteAlertReceiver, subject, body.ToString());
                            }
                        }
                        #endregion

                        #region recovered from errors
                        {
                            var recoveredFromErrors = recoveredPages.Where(rp => rp.LastResultType == ResultType.ClientError || rp.LastResultType == ResultType.ServerError).ToList();
                            log.Info("recoveredFromErrors: " + recoveredFromErrors.Count);
                            if (recoveredFromErrors.Any())
                            {
                                string subject = string.Format("{0} Sanity Check: pages recovered", service.Name);
                                StringBuilder body = new StringBuilder();
                                body.AppendLine("Hi,");
                                body.AppendLine("Previously reported malfunction:");
                                body.AppendLine("");

                                foreach (var page in recoveredFromErrors)
                                    body.AppendLine(string.Format("{0} ({1})", page.FriendlyUrl, page.IPAddress));

                                body.AppendLine("");
                                body.AppendLine("Page down WAS RECOVERED.");
                                body.AppendLine("");
                                body.AppendLine("Thanks");

                                EmailHelper.Send(Config.SiteAlertReceiver, subject, body.ToString());
                            }
                        }
                        #endregion

                        //string subject = string.Format("{0} Sanity Check: pages recovered", service.Name);

                        //foreach (var page in recoveredPages)
                        //    body.AppendLine(string.Format("{0} ({1})", page.FriendlyUrl, page.IPAddress));

                        //body.AppendLine("Was recovered after it was down/slow");

                        //EmailHelper.Send(Config.SiteAlertReceiver, subject, body.ToString());
                    }

                    if (downPages.Any())
                    {
                        #region slowly
                        {
                            var slowlyPages = downPages.Where(dp => dp.ResultType == ResultType.Slow).ToList();
                            log.Info("Slowly Page: " + slowlyPages.Count);
                            if (slowlyPages.Any())
                            {
                                string subject = string.Format("{0} Sanity Check: pages have problem", service.Name);

                                StringBuilder body = new StringBuilder();
                                body.AppendLine("Hi,");
                                body.AppendLine("Checks revealed following malfunction");
                                body.AppendLine("");

                                foreach (var page in slowlyPages)
                                    body.AppendLine(string.Format("{0} ({1})", page.FriendlyUrl, page.IPAddress));

                                body.AppendLine("");
                                body.AppendLine("Is responding very slow.");
                                body.AppendLine("");
                                body.AppendLine("Thanks");

                                EmailHelper.Send(Config.SiteAlertReceiver, subject, body.ToString());
                            }
                        }
                        #endregion

                        #region no response
                        {
                            var noResponsePages = downPages.Where(dp => dp.ResultType == ResultType.NoResponse).ToList();
                            log.Info("noResponsePages: " + noResponsePages.Count);
                            if (noResponsePages.Any())
                            {
                                string subject = string.Format("{0} Sanity Check: pages have problem", service.Name);

                                StringBuilder body = new StringBuilder();
                                body.AppendLine("Hi,");
                                body.AppendLine("Checks revealed following malfunction");
                                body.AppendLine("");

                                foreach (var page in noResponsePages)
                                    body.AppendLine(string.Format("{0} ({1})", page.FriendlyUrl, page.IPAddress));

                                body.AppendLine("");
                                body.AppendLine("Is not responding.");
                                body.AppendLine("");
                                body.AppendLine("Thanks");

                                EmailHelper.Send(Config.SiteAlertReceiver, subject, body.ToString());
                            }
                        }
                        #endregion

                        #region got errors
                        {
                            var errorPages = downPages.Where(dp => dp.ResultType == ResultType.ClientError || dp.ResultType == ResultType.ServerError).ToList();
                            log.Info("errorPages: " + errorPages.Count);
                            if (errorPages.Any())
                            {
                                string subject = string.Format("{0} Sanity Check: pages have problem", service.Name);

                                StringBuilder body = new StringBuilder();
                                body.AppendLine("Hi,");
                                body.AppendLine("Checks revealed following malfunction");
                                body.AppendLine("");

                                foreach (var page in errorPages)
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
                        }
                        #endregion
                        //string subject = string.Format("{0} Sanity Check: pages have problem", service.Name);
                        //StringBuilder body = new StringBuilder();

                        //foreach (var page in downPages)
                        //{
                        //    switch (page.ResultType)
                        //    {
                        //        //case ResultType.ClientError:
                        //        //    body.AppendLine(string.Format("{0} ({1}) unable to parse the url", tuple.FriendlyUrl, tuple.IPAddress));
                        //        //    break;
                        //        //case ResultType.ServerError:
                        //        //    body.AppendLine(string.Format("{0} ({1}) got internal server error", tuple.FriendlyUrl, tuple.IPAddress));
                        //        //    break;
                        //        case ResultType.ClientError:
                        //        case ResultType.ServerError:
                        //            string error;
                        //            if (_statusCodeMapping.TryGetValue(page.StatusCode, out error))
                        //                body.AppendLine(string.Format("{0} ({1}) got {2} error ({3})", page.FriendlyUrl, page.IPAddress, page.StatusCode, error));
                        //            else
                        //                body.AppendLine(string.Format("{0} ({1}) got {2} error", page.FriendlyUrl, page.IPAddress, page.StatusCode));
                        //            break;
                        //        case ResultType.NoResponse:
                        //            body.AppendLine(string.Format("{0} ({1}) doesn't response", page.FriendlyUrl, page.IPAddress));
                        //            break;
                        //        case ResultType.Slow:
                        //            body.AppendLine(string.Format("{0} ({1}) is very slowly", page.FriendlyUrl, page.IPAddress));
                        //            break;
                        //        case ResultType.Exception:
                        //            body.AppendLine(string.Format("{0} ({1}) got exception", page.FriendlyUrl, page.IPAddress));
                        //            break;
                        //        case ResultType.Skip:
                        //            body.AppendLine(string.Format("{0} ({1}) should have problem", page.FriendlyUrl, page.IPAddress));
                        //            break;
                        //        default:
                        //            continue;
                        //    }
                        //}

                        //EmailHelper.Send(Config.SiteAlertReceiver, subject, body.ToString());
                    }
                }
            }

            return downPages.Any();
        }

        private bool AnalyseSiteStatuses(Service service, Dictionary<string, List<CheckResult>> resultDictionary)
        {
            List<SiteAndHost> siteAndHosts = new List<SiteAndHost>();
            foreach (var ipAddress in resultDictionary.Keys)
            {
                var results = resultDictionary[ipAddress];
                var items = results.Select(r => r.Item).ToList();
                foreach (var siteAndHost in items.Select(i => i.SiteAndHost).Distinct())
                {
                    if (siteAndHosts.Any(sh => sh.SiteID == siteAndHost.SiteID))
                        continue;

                    siteAndHosts.Add(siteAndHost);
                }
            }

            //Site Statuses, Site ID -> IP Address -> UP / DOWN (bool)
            Dictionary<int, Dictionary<string, bool>> siteStatuses = new Dictionary<int, Dictionary<string, bool>>();
            foreach (var siteAndHost in siteAndHosts)
            {
                var siteID = siteAndHost.SiteID;
                Dictionary<string, bool> ipStatuses = new Dictionary<string, bool>();
                foreach (var ipAddress in resultDictionary.Keys)
                {
                    var results = resultDictionary[ipAddress];
                    var siteResults = results.Where(r => r.Item.SiteAndHost.SiteID == siteID).ToList();

                    //if any urls success, then it is ok
                    bool isOk = siteResults.Any(sr => sr.ResultType == ResultType.Success);
                    ipStatuses.Add(ipAddress, isOk);
                }
                siteStatuses.Add(siteID, ipStatuses);
            }

            List<Tuple<string, string>> recoveredSites, downSites;
            GetSiteChanges(service, siteStatuses, siteAndHosts, out recoveredSites, out downSites);

            if (recoveredSites.Any() || downSites.Any())
            {
                ObjectHelper.SaveSiteStatuses(service, siteStatuses);

                if (service.Name.StartsWith("CMS", StringComparison.InvariantCultureIgnoreCase))
                {
                    if (recoveredSites.Any())
                    {
                        string subject = string.Format("{0} Sanity Check: sites recovered", service.Name);
                        StringBuilder body = new StringBuilder();

                        foreach (var tuple in recoveredSites)
                            body.AppendLine(string.Format("{0} {1}", tuple.Item1, tuple.Item2));

                        EmailHelper.Send(Config.SiteAlertReceiver, subject, body.ToString());
                    }

                    if (downSites.Any())
                    {
                        string subject = string.Format("{0} Sanity Check: sites have problem", service.Name);
                        StringBuilder body = new StringBuilder();

                        foreach (var tuple in downSites)
                            body.AppendLine(string.Format("{0} {1}", tuple.Item1, tuple.Item2));

                        EmailHelper.Send(Config.SiteAlertReceiver, subject, body.ToString());
                    }
                }
            }

            return downSites.Any();
        }

        private bool AnalyseServerStatuses(Service service, Dictionary<string, List<CheckResult>> resultDictionary)
        {
            //Server Statuses, IP Address -> UP / DOWN (bool)
            Dictionary<string, bool> serverStatuses = new Dictionary<string, bool>();
            foreach (var ipAddress in resultDictionary.Keys)
            {
                var results = resultDictionary[ipAddress];
                int score = results.Sum(r => GetWeight(r.ResultType, r.Item.SiteAndHost.DomainID));
                //if the score don't reachs the critical weight, then it is ok
                bool isOk = (score < Config.CriticalWeight);
                serverStatuses.Add(ipAddress, isOk);
            }

            List<string> recoveredServers, downServers;
            GetServerChanges(service, serverStatuses, out recoveredServers, out downServers);

            if (recoveredServers.Any() || downServers.Any())
            {
                ObjectHelper.SaveServerStatuses(service, serverStatuses);

                if (recoveredServers.Any())
                {
                    string subject = string.Format("{0} Sanity Check: servers recovered", service.Name);
                    StringBuilder body = new StringBuilder();

                    foreach (var ipAddress in recoveredServers)
                        body.AppendLine(ipAddress);

                    EmailHelper.Send(Config.ServerAlertReceiver, subject, body.ToString());
                }

                if (downServers.Any())
                {
                    string subject = string.Format("{0} Sanity Check: servers have problem", service.Name);
                    StringBuilder body = new StringBuilder();

                    foreach (var ipAddress in downServers)
                        body.AppendLine(ipAddress);

                    EmailHelper.Send(Config.ServerAlertReceiver, subject, body.ToString());
                }
            }

            return downServers.Any();
        }

        private void SendAllBadEmail(Service service)
        {
            string subject = string.Format("Warning - Sanity Check ({0}): All servers are timeout", service.Name);
            StringBuilder body = new StringBuilder();
            body.AppendLine(string.Format("Name: {0}", service.Name));
            body.AppendLine("IP Addresses:");
            foreach (var ipAddress in service.IPAddresses)
                body.AppendLine(ipAddress);
            EmailHelper.Send(Config.ServerAlertReceiver, subject, body.ToString());
        }

        private void GetServerChanges(Service service, Dictionary<string, bool> serverStatuses,
            out List<string> recovered, out List<string> down)
        {
            Dictionary<string, bool> oldServerStatuses = ObjectHelper.LoadServerStatuses(service);
            //recoverd servers / down servers, string
            recovered = new List<string>();
            down = new List<string>();
            foreach (var ipAddress in serverStatuses.Keys)
            {
                bool newValue = serverStatuses[ipAddress];
                bool oldValue;
                if (!oldServerStatuses.TryGetValue(ipAddress, out oldValue))
                    oldValue = true;
                if (newValue != oldValue)
                {
                    //status changed
                    if (newValue)
                    {
                        //server is recovered
                        recovered.Add(ipAddress);
                    }
                    else
                    {
                        //server is down
                        down.Add(ipAddress);
                    }
                }
            }
        }

        private void GetSiteChanges(Service service, Dictionary<int, Dictionary<string, bool>> siteStatuses,
            List<SiteAndHost> siteAndHosts, out List<Tuple<string, string>> recovered, out List<Tuple<string, string>> down)
        {
            Dictionary<int, Dictionary<string, bool>> oldSiteStatuses = ObjectHelper.LoadSiteStatuses(service);

            //recover sites / down sites, display name -> IP Address
            recovered = new List<Tuple<string, string>>();
            down = new List<Tuple<string, string>>();

            foreach (var siteID in siteStatuses.Keys)
            {
                SiteAndHost siteAndHost = siteAndHosts.FirstOrDefault(sh => sh.SiteID == siteID);
                var newIPStatuses = siteStatuses[siteID];
                Dictionary<string, bool> oldIPStatuses;
                if (!oldSiteStatuses.TryGetValue(siteID, out oldIPStatuses))
                    oldIPStatuses = new Dictionary<string, bool>();
                foreach (var ipAddress in newIPStatuses.Keys)
                {
                    bool newValue = newIPStatuses[ipAddress];
                    bool oldValue;
                    if (!oldIPStatuses.TryGetValue(ipAddress, out oldValue))
                        oldValue = true;

                    if (newValue != oldValue)
                    {
                        //status changed
                        if (newValue)
                        {
                            //site is recovered
                            recovered.Add(new Tuple<string, string>(siteAndHost.DisplayName, ipAddress));
                        }
                        else
                        {
                            //site is down
                            down.Add(new Tuple<string, string>(siteAndHost.DisplayName, ipAddress));
                        }
                    }
                }
            }
        }

        private void GetPageChanges(Service service, Dictionary<string, Dictionary<string, CheckResult>> pageResults,
            out List<PageInfo> recovered, out List<PageInfo> down)
        {
            Dictionary<string, Dictionary<string, ResultType>> oldPageStatuses = ObjectHelper.LoadPageStatuses(service);

            recovered = new List<PageInfo>();
            down = new List<PageInfo>();

            foreach (var friendlyUrl in pageResults.Keys)
            {
                var newIPResults = pageResults[friendlyUrl];
                Dictionary<string, ResultType> oldIPResults;
                if (!oldPageStatuses.TryGetValue(friendlyUrl, out oldIPResults))
                    oldIPResults = new Dictionary<string, ResultType>();
                foreach (var ipAddress in newIPResults.Keys)
                {
                    ResultType newValue = newIPResults[ipAddress].ResultType;
                    int newStatusCode = newIPResults[ipAddress].StatusCode;
                    ResultType oldValue;
                    if (!oldIPResults.TryGetValue(ipAddress, out oldValue))
                        oldValue = ResultType.Success;

                    if (newValue != oldValue)
                    {
                        PageInfo pageInfo = new PageInfo()
                        {
                            FriendlyUrl = friendlyUrl,
                            IPAddress = ipAddress,
                            ResultType = newValue,
                            StatusCode = newStatusCode,
                            LastResultType = oldValue,
                        };
                        //status changed
                        if (newValue == ResultType.Success)
                        {
                            //page is recovered
                            recovered.Add(pageInfo);
                        }
                        else
                        {
                            //page is down
                            down.Add(pageInfo);
                        }
                    }
                }
            }
        }

#if DEBUG
        private List<CheckResult> CreateFakeCheckResult(List<CheckItem> items)
        {
            List<CheckResult> results = new List<CheckResult>();

            for (var i = 0; i < items.Count; i++)
            {
                var item = items[i];
                var result = new CheckResult()
                {
                    Item = item,
                    StatusCode = 500,
                    ResponseText = "<html></html>",
                    ElapsedSeconds = 10,
                    ResultType = ResultType.Success,
                    ErrorMessage = "HAHAHA",//(i % 5 == 0) ? HttpStatusCode.InternalServerError.ToString() : null,
                };

                switch (i % 3)
                {
                    case 1 :
                        result.ResultType = ResultType.NoResponse;
                        break;
                    case 2:
                        result.ResultType = ResultType.Slow;
                        break;
                    default:
                        result.ResultType = ResultType.ServerError;
                        break;
                }

                result.ResultType = ResultType.Success;

                results.Add(result);
            }

            return results;
        }
#endif

    }
}
