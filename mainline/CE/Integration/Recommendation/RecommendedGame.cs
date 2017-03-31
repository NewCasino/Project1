using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;
using System.Net;
using System.Collections.Concurrent;
using System.Threading;
using System.Net.Mail;

using GamMatrixAPI;

using Newtonsoft.Json;

namespace CE.Integration.Recommendation
{
    using Utils;

    public class RecommendedGame
    {
        public VendorID VendorID { get; set; }
        public string GameCode { get; set; }
        public double Score { get; set; }

        private static int _failures = 0;
        private const int MAX_FAILURES = 10;
        private static DateTime _disableTime = DateTime.MinValue;

        public static VendorID ConvertToCoreVendorID(string vendor)
        {
            VendorID vendorID;
            if (Enum.TryParse<VendorID>(vendor, true, out vendorID))
                return vendorID;

            if (string.Equals(vendor, "1x2Gaming", StringComparison.InvariantCultureIgnoreCase))
                return VendorID.OneXTwoGaming;

            if (string.Equals(vendor, "Bally", StringComparison.InvariantCultureIgnoreCase))
                return VendorID.BallyGaming;

            if (string.Equals(vendor, "iSoftBet", StringComparison.InvariantCultureIgnoreCase))
                return VendorID.ISoftBet;

            if (string.Equals(vendor, "NYX", StringComparison.InvariantCultureIgnoreCase))
                return VendorID.NYXGaming;

            return VendorID.Unknown;
        }

        public static string ConvertToReportVendorID(VendorID vendorID)
        {
            switch (vendorID)
            {
                case VendorID.OneXTwoGaming:
                    return "1x2Gaming";

                case VendorID.BallyGaming:
                    return "Bally";

                case VendorID.ISoftBet:
                    return "iSoftBet";

                case VendorID.NYXGaming:
                    return "NYX";

                default:
                    return vendorID.ToString();
            }
        }

        public static bool TryGet(string url, out List<RecommendedGame> games)
        {
            if ((DateTime.Now - _disableTime).TotalMinutes < 5)
            {
                games = new List<RecommendedGame>();
                return false;
            }
            else
            {
                if (_failures > MAX_FAILURES)
                    _failures = 0;
            }

            try
            {
                string json = Download(url);

                games = Parse(json);
                _failures = 0;
                return true;
            }
            catch (Exception ex)
            {
                //Logger.Exception(ex);
                AppendToEmail(ex.ToString());
                _failures++;
                if (_failures > MAX_FAILURES)
                {
                    _disableTime = DateTime.Now;
                }
                games = new List<RecommendedGame>();
                return false;
            }
        }

        static string Download(string url)
        {
            HttpWebRequest request = HttpWebRequest.Create(url) as HttpWebRequest;
            request.Method = "GET";
            using (HttpWebResponse resp = (HttpWebResponse)(request.GetResponse()))
            using (Stream stream = resp.GetResponseStream())
            using (StreamReader sr = new StreamReader(stream))
            {
                return sr.ReadToEnd();
            }
        }

        static List<RecommendedGame> Parse(string json)
        {
            using (StringReader sr = new StringReader(json))
            using (JsonTextReader reader = new JsonTextReader(sr))
            {
                int code = 0;
                string message = null;
                List<RecommendedGame> games = new List<RecommendedGame>();

                while (reader.Read())
                {
                    if (reader.TokenType == JsonToken.PropertyName)
                    {
                        string name = reader.Value as string;

                        if (string.Equals(name, "code", StringComparison.InvariantCultureIgnoreCase))
                        {
                            reader.Read();
                            code = Convert.ToInt32(reader.Value);
                        }
                        else if (string.Equals(name, "message", StringComparison.InvariantCultureIgnoreCase))
                        {
                            reader.Read();
                            message = reader.Value as string;
                        }
                        else if (string.Equals(name, "results", StringComparison.InvariantCultureIgnoreCase))
                        {
                            while (reader.Read())
                            {
                                if (reader.TokenType == JsonToken.PropertyName)
                                {
                                    string name2 = reader.Value as string;

                                    if (string.Equals(name2, "GameType", StringComparison.InvariantCultureIgnoreCase))
                                    {
                                        reader.Read();
                                        string gameType = reader.Value as string;
                                    }
                                    else if (string.Equals(name2, "Recolist", StringComparison.InvariantCultureIgnoreCase))
                                    {
                                        reader.Read();
                                        while (reader.Read())
                                        {
                                            if (reader.TokenType == JsonToken.StartArray)
                                            {
                                                RecommendedGame game = new RecommendedGame();

                                                reader.Read();
                                                game.VendorID = ConvertToCoreVendorID(reader.Value as string);

                                                reader.Read();
                                                game.GameCode = reader.Value as string;

                                                reader.Read();
                                                game.Score = Convert.ToDouble(reader.Value);

                                                games.Add(game);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                //return games.Skip(1).ToList();
                return games;
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
                            message.To.Add(new MailAddress("ks@everymatrix.com", "Kenny.Su"));
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
