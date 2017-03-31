using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Configuration;
using System.Xml;
using System.Xml.Linq;
using System.Net;
using System.Globalization;
using System.Threading;
using System.ComponentModel;
using System.IO;
using System.Threading.Tasks;
using System.Net.Mail;
using System.Text;

using GamMatrixAPI;

namespace JackpotsAlertService
{
    public class JackpotAlert
    {
        private static Dictionary<string, string> GameDic = null;
        private static Dictionary<string, decimal> PrevAmountsDic = new Dictionary<string, decimal>();
        private static decimal AlertThresholdAmount = 0.00m;
        static JackpotAlert()
        {
            GameDic = new Dictionary<string, string>();
            foreach (string g in ConfigurationManager.AppSettings["CE.Jackpot.Alert.Game.IDs"].Split(new char[]{','}, StringSplitOptions.RemoveEmptyEntries))
            {
                string[] idname = g.Split(new char[] { '|' }, StringSplitOptions.RemoveEmptyEntries);
                {
                    if (idname != null && idname.Length > 0)
                        GameDic.Add(idname[0].Trim(), idname[1].Trim());
                }
            }
            if (GameDic.Keys.Count == 0)
                GameDic = null;
            else
            {
                decimal.TryParse(ConfigurationManager.AppSettings["CE.Jackpot.Alert.Amount"], out AlertThresholdAmount);   
            }
        }

        public static void Start()
        {
            if (GameDic == null)
                return;

            CheckFeeds();
        }

        private static void CheckFeeds()
        {
            string url = ConfigurationManager.AppSettings["CE.Jackpot.Url"];

            XDocument xDoc = XDocument.Load(url);

            if (!string.Equals(xDoc.Root.GetElementValue("result"), "Success", StringComparison.InvariantCultureIgnoreCase))
                throw new Exception(xDoc.Root.GetElementValue("errorMessage"));

            VendorID vendorID;
            Dictionary<string, decimal> dicAmount = new Dictionary<string, decimal>();

            IEnumerable<XElement> elements = xDoc.Root.Element("jackpots").Elements("jackpot");

            StringBuilder sbContent = new StringBuilder();

            foreach (XElement element in elements)
            {
                vendorID = (VendorID)Enum.Parse(typeof(VendorID), element.GetElementValue("vendor"));
                if (vendorID != VendorID.NetEnt)
                    continue;

                dicAmount = new Dictionary<string, decimal>();
                IEnumerable<XElement> children = element.Elements("amount");
                foreach (XElement child in children)
                {
                    dicAmount.Add(child.Attribute("currency").Value, decimal.Parse(child.Value, CultureInfo.InvariantCulture));
                }

                children = element.Element("games").Elements("game");
                foreach (XElement child in children)
                {
                    string id = child.GetElementValue("id");
                    if (GameDic.Keys.Contains(id))
                    {
                        if (CheckAmount(id, dicAmount))
                        {
                            sbContent = new StringBuilder();
                            sbContent.AppendFormat(@"Game: {0}<br/>Jackpot value: {1}<br/>Date: {2}<br/><br/>",
                                                    GameDic[id],
                                                    string.Format("EUR {0}m", (dicAmount["EUR"] / 1000000).ToString("0.00")),
                                                    DateTime.Now.ToString("dd/MM/yyyy")
                                                    );
                            Task t = new Task(() => SendAlertEmail(sbContent.ToString()));
                            t.Start();
                        }
                    }
                }
            }

            //if (sbContent.Length > 0)
            //{
            //    Task t = new Task(() => SendAlertEmail(sbContent.ToString()));
            //    t.Start();
            //}

        }

        private static bool CheckAmount(string gameID, Dictionary<string, decimal> dicAmount)
        {
            bool result = false;
            decimal prevAmount = 0.00m;
            if (PrevAmountsDic.ContainsKey(gameID))
                prevAmount = PrevAmountsDic[gameID];
            else
                PrevAmountsDic[gameID] = 0.00m;


            if (dicAmount.ContainsKey("EUR"))
            {
                if (dicAmount["EUR"] >= AlertThresholdAmount && prevAmount < AlertThresholdAmount)
                {
                    result =  true;
                }
                PrevAmountsDic[gameID] = dicAmount["EUR"];
            }

            return result;
        }

        private static void SendAlertEmail(string content)
        {
            string smtp = ConfigurationManager.AppSettings["Email.SMTP"].DefaultIfNullOrWhiteSpace("10.0.10.7");
            int port = 25;
            int.TryParse(ConfigurationManager.AppSettings["Email.Port"].DefaultIfNullOrWhiteSpace("25"), out port);

            using (MailMessage message = new MailMessage())
            {
                message.Subject = "Netent Global Jackpot level alert";
                message.SubjectEncoding = Encoding.UTF8;
                message.From = new MailAddress("noreply@everymatrix.com");

                foreach (string email in ConfigurationManager.AppSettings["CE.Jackpot.Alert.Emails"].DefaultIfNullOrWhiteSpace(",").Split(new char[] { ',' }, StringSplitOptions.RemoveEmptyEntries))
                {
                    message.To.Add(email);
                }
                if (message.To.Count == 0)
                    return;
                message.BodyEncoding = Encoding.UTF8;
                message.IsBodyHtml = true;
                message.Body = string.Format(@"{0}<br/> EveryMatrix CasinoEngine Team",
                    content);

                SmtpClient client = new SmtpClient(smtp, port);
                client.Send(message);
            }
        }

        //private static void SendAlertEmail(string gameName, string amountCurreny)
        //{
        //    string smtp = ConfigurationManager.AppSettings["Email.SMTP"].DefaultIfNullOrWhiteSpace("10.0.10.7");
        //    int port = 25;
        //    int.TryParse(ConfigurationManager.AppSettings["Email.Port"].DefaultIfNullOrWhiteSpace("25"), out port);

        //    using (MailMessage message = new MailMessage())
        //    {
        //        //message.ReplyToList.Add(new MailAddress("bz@everymatrix.com"));
        //        message.Subject = "Netent Global Jackpot level alert";
        //        message.SubjectEncoding = Encoding.UTF8;
        //        message.From = new MailAddress("noreply@everymatrix.com");

        //        foreach (string email in ConfigurationManager.AppSettings["CE.Jackpot.Alert.Emails"].DefaultIfNullOrWhiteSpace(",").Split(new char[] { ',' }, StringSplitOptions.RemoveEmptyEntries))
        //        {
        //            message.To.Add(email);
        //        }
        //        if (message.To.Count == 0)
        //            return;
        //        message.BodyEncoding = Encoding.UTF8;
        //        message.IsBodyHtml = true;
        //        message.Body = string.Format(@"Game: {0}<br/>Jackpot value: {1}<br/>Time: {2}<br/><br/> From EveryMatrix CasinoEngine Team.",
        //            gameName,
        //            amountCurreny,
        //            DateTime.Now.ToString("dd/mm/yyyy")
        //            );

        //        SmtpClient client = new SmtpClient(smtp, port);
        //        client.Send(message);
        //    }
        //}
    }
}
