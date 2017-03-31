using System;
using System.Linq;
using System.Web;
using System.Configuration;
using System.Text;
using System.Security.Cryptography;
using System.IO;

using CE.db;

using EveryMatrix.SessionAgent;
using EveryMatrix.SessionAgent.Protocol;

using GamMatrixAPI;

using Newtonsoft.Json;

namespace CasinoEngine.HttpHandlers
{
    /// <summary>
    /// Summary description for query_balance_change
    /// </summary>
    public class query_balance_change : IHttpHandler
    {
        //private static NonBlockingRedisClient _redisClient
        //    = new NonBlockingRedisClient(ConfigurationManager.AppSettings["SessionAgent.RedisServer"] ?? "10.0.10.38:6379");
        private static readonly NonBlockingRedisClient _redisClient = string.Equals(ConfigurationManager.AppSettings["SessionAgent.UseSentinel"], "true", StringComparison.InvariantCultureIgnoreCase)
            ? new NonBlockingRedisClient(ConfigurationManager.AppSettings["SessionAgent.SentinelAddress"].Split(";".ToCharArray(), StringSplitOptions.RemoveEmptyEntries), ConfigurationManager.AppSettings["SessionAgent.SentinelMasterName"])
            : new NonBlockingRedisClient(ConfigurationManager.AppSettings["SessionAgent.RedisServer"] ?? "10.0.10.38:6379");

        private static AgentClient _agentClient = new AgentClient(
            ConfigurationManager.AppSettings["SessionAgent.ZooKeeperConnectionString"],
            ConfigurationManager.AppSettings["SessionAgent.ClusterName"],
            ConfigurationManager.AppSettings["SessionAgent.UseProtoBuf"] == "1"
            );

        public void ProcessRequest(HttpContext context)
        {
            if (string.IsNullOrWhiteSpace(context.Request.QueryString["domainid"]) ||
                string.IsNullOrWhiteSpace(context.Request.QueryString["_sid64"]))
                return;

            context.Response.ContentType = "application/json";
            context.Response.ContentEncoding = Encoding.UTF8;

            try
            {
                long domainID;
                string _sid64;
                if (!long.TryParse(context.Request.QueryString["domainid"], out domainID))
                    return;
                _sid64 = context.Request.QueryString["_sid64"];

                ceDomainConfigEx domain = DomainManager.GetDomains().FirstOrDefault(d => d.DomainID == domainID);
                if (domain == null)
                    return;

                string userAgentInfo = context.Request.GetRealUserAddress() + context.Request.UserAgent;
                string _sid = System.Web.HttpUtility.UrlDecode(Decrypt(_sid64, userAgentInfo, true));

                if (string.IsNullOrWhiteSpace(_sid))
                    throw new Exception("Invalid sid");

                SessionPayload session = _agentClient.GetSessionByGuid(_sid);
                long userID;
                if (session == null ||
                    session.IsAuthenticated != true ||
                    session.DomainID != domain.DomainID)
                {
                    if (!long.TryParse(context.Request.QueryString["userID"], out userID))
                        throw new Exception("Invalid session");
                }
                else
                {
                    userID = session.UserID;
                }

                string text = _redisClient.GetByUserID(userID, "reload_balance");

                bool reloadBalance = string.Equals(text, "true", StringComparison.InvariantCultureIgnoreCase);
                if (reloadBalance)
                    _redisClient.SetByUserID(userID, "reload_balance", null).Wait();

                context.Response.Write(CreateJsonResult(true, reloadBalance: reloadBalance));    
            }
            catch (Exception ex)
            {
                context.Response.Write(CreateJsonResult(false, error: ex.ToString()));
            }
        }

        public bool IsReusable
        {
            get
            {
                return false;
            }
        }

        private static string Decrypt(string toDecrypt, string key, bool useHashing)
        {
            try
            {
                byte[] keyArray;
                byte[] toEncryptArray = Convert.FromBase64String(toDecrypt);

                if (useHashing)
                {
                    MD5CryptoServiceProvider hashmd5 = new MD5CryptoServiceProvider();
                    keyArray = hashmd5.ComputeHash(UTF8Encoding.UTF8.GetBytes(key));
                }
                else
                    keyArray = UTF8Encoding.UTF8.GetBytes(key);

                TripleDESCryptoServiceProvider tdes = new TripleDESCryptoServiceProvider();
                tdes.Key = keyArray;
                tdes.Mode = CipherMode.ECB;
                tdes.Padding = PaddingMode.PKCS7;

                ICryptoTransform cTransform = tdes.CreateDecryptor();
                byte[] resultArray = cTransform.TransformFinalBlock(toEncryptArray, 0, toEncryptArray.Length);

                return UTF8Encoding.UTF8.GetString(resultArray);

            }
            catch (Exception ex)
            {
                return System.Web.HttpUtility.UrlEncode(ex.ToString());
            }

        }

        private static string CreateJsonResult(bool success, bool reloadBalance = false, string error = null)
        {
            using (StringWriter sw = new StringWriter())
            using (JsonTextWriter writer = new JsonTextWriter(sw))
            {
                writer.WriteStartObject();

                writer.WritePropertyName("success");
                writer.WriteValue(success);

                if (success)
                {
                    writer.WritePropertyName("reloadBalance");
                    writer.WriteValue(reloadBalance ? "true" : "false");
                }
                else
                {
                    writer.WritePropertyName("error");
                    writer.WriteValue(error);
                }

                writer.WriteEndObject();

                return sw.ToString();
            }
        }

    }
}