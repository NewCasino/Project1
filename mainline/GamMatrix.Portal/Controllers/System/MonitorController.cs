using System;
using System.Collections.Generic;
using System.Globalization;
using System.Text;
using System.Text.RegularExpressions;
using System.Web.Mvc;
using BLToolkit.Data;
using CM.db;
using CM.db.Accessor;
using CM.Sites;
using CM.Web;

namespace GamMatrix.CMS.Controllers.System
{

    [HandleError]
    [ControllerExtraInfo(DefaultAction = "Index")]
    [SystemAuthorize(Roles = "CMS System Admin")]
    public class MonitorController : ControllerEx
    {
        [HttpGet]
        public ActionResult Index()
        {
            return View("Index");
        }


        public ContentResult QueryStatistics(string operatorName, string server, string date)
        {
            if (operatorName == null)
                operatorName = string.Empty;
            if (server == null)
                server = string.Empty;
            string content;
            try
            {
                DateTime dtBase = new DateTime(1970,1,1,0,0,0,0, DateTimeKind.Utc);

                long dayStamp = 0L;
                Match m = Regex.Match(date, @"^(?<year>\d{4,4})\-(?<month>\d{1,2})\-(?<day>\d{1,2})$", RegexOptions.Singleline);
                if (m.Success)
                {
                    try
                    {
                        DateTime day = new DateTime( int.Parse(m.Groups["year"].Value)
                        , int.Parse(m.Groups["month"].Value)
                        , int.Parse(m.Groups["day"].Value)
                        , 0, 0, 0, 0, DateTimeKind.Utc);
                        dayStamp = (long)day.Subtract(dtBase).TotalSeconds + 3600 * 24;
                    }
                    catch
                    {
                    }
                }

                using (DbManager db = new DbManager("Log"))
                {
                    LogAccessor la = LogAccessor.CreateInstance<LogAccessor>(db);
                    long endStamp = la.GetCurrentTimestamp();
                    
                    DateTime dtDateTime = dtBase.AddSeconds(endStamp);
                    endStamp -= dtDateTime.Second;

                    if (endStamp > dayStamp && dayStamp > 0)
                        endStamp = dayStamp;

                    long startStamp = endStamp - 3600 * 24;

                    Dictionary<long, MinuteStatistics> dic = la.QueryStatistics(startStamp
                        , endStamp
                        , operatorName
                        , server
                        );

                    StringBuilder reqNumJson = new StringBuilder();
                    StringBuilder avgExeSecJson = new StringBuilder();
                    StringBuilder eightyPercentAvgExeSecJson = new StringBuilder();
                    StringBuilder ninetyPercentAvgExeSecJson = new StringBuilder();
                    StringBuilder standardDeviationJson = new StringBuilder();

                    reqNumJson.Append("[");
                    avgExeSecJson.Append("[");
                    eightyPercentAvgExeSecJson.Append("[");
                    ninetyPercentAvgExeSecJson.Append("[");
                    standardDeviationJson.Append("[");

                    for (long stamp = startStamp; stamp < endStamp; stamp += 60)
                    {
                        MinuteStatistics stat;
                        if (dic.TryGetValue(stamp, out stat))
                        {
                            reqNumJson.AppendFormat( CultureInfo.InvariantCulture, "[{0},{1}],"
                                , stamp * 1000
                                , stat.TotalRequestNumber
                                );
                            avgExeSecJson.AppendFormat(CultureInfo.InvariantCulture, "[{0},{1:F2}],"
                                , stamp * 1000
                                , stat.AvgExecutionSeconds
                                );
                            eightyPercentAvgExeSecJson.AppendFormat(CultureInfo.InvariantCulture, "[{0},{1:F2}],"
                                , stamp * 1000
                                , stat.EightyPercentAvgExecutionSeconds
                                );
                            ninetyPercentAvgExeSecJson.AppendFormat(CultureInfo.InvariantCulture, "[{0},{1:F2}],"
                                , stamp * 1000
                                , stat.NinetyPercentAvgExecutionSeconds
                                );
                            standardDeviationJson.AppendFormat(CultureInfo.InvariantCulture, "[{0},{1:F2}],"
                                , stamp * 1000
                                , stat.StandardDeviation
                                );
                        }
                        else
                        {
                            reqNumJson.AppendFormat(CultureInfo.InvariantCulture, "[{0},0],", stamp * 1000);
                            avgExeSecJson.AppendFormat(CultureInfo.InvariantCulture, "[{0},0.00]," , stamp * 1000);
                            eightyPercentAvgExeSecJson.AppendFormat(CultureInfo.InvariantCulture, "[{0},0.00],", stamp * 1000);
                            ninetyPercentAvgExeSecJson.AppendFormat(CultureInfo.InvariantCulture, "[{0},0.00],", stamp * 1000);
                            standardDeviationJson.AppendFormat(CultureInfo.InvariantCulture, "[{0},0.00],", stamp * 1000);
                        }
                    }

                    if (reqNumJson[reqNumJson.Length - 1] == ',')
                        reqNumJson.Remove(reqNumJson.Length - 1, 1);
                    if (avgExeSecJson[avgExeSecJson.Length - 1] == ',')
                        avgExeSecJson.Remove(avgExeSecJson.Length - 1, 1);
                    if (eightyPercentAvgExeSecJson[eightyPercentAvgExeSecJson.Length - 1] == ',')
                        eightyPercentAvgExeSecJson.Remove(eightyPercentAvgExeSecJson.Length - 1, 1);
                    if (ninetyPercentAvgExeSecJson[ninetyPercentAvgExeSecJson.Length - 1] == ',')
                        ninetyPercentAvgExeSecJson.Remove(ninetyPercentAvgExeSecJson.Length - 1, 1);
                    if (standardDeviationJson[standardDeviationJson.Length - 1] == ',')
                        standardDeviationJson.Remove(standardDeviationJson.Length - 1, 1);
                    reqNumJson.Append("]");
                    avgExeSecJson.Append("]");
                    eightyPercentAvgExeSecJson.Append("]");
                    ninetyPercentAvgExeSecJson.Append("]");
                    standardDeviationJson.Append("]");

                    content = string.Format(CultureInfo.InvariantCulture
                        , "{{ \"success\":true, \"requestNumber\":{0}, \"avgExecutionSeconds\":{1}, \"eightyPercentAvgExecutionSeconds\":{2}, \"ninetyPercentAvgExecutionSeconds\":{3}, \"standardDeviation\":{4}, \"operatorName\":\"{5}\", \"server\":\"{6}\" }}"
                        , reqNumJson.ToString()
                        , avgExeSecJson.ToString()
                        , eightyPercentAvgExeSecJson.ToString()
                        , ninetyPercentAvgExeSecJson.ToString()
                        , standardDeviationJson.ToString()
                        , operatorName.SafeJavascriptStringEncode()
                        , server.SafeJavascriptStringEncode()
                        );
                }                
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                content = string.Format( CultureInfo.InvariantCulture
                    , "{{ \"success\":false, \"error\":\"{0}\" }}"
                    , ex.Message
                    );
            }

            return this.Content(content, "application/json");
        }
        
    }



}
