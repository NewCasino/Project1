using System;
using System.Linq;
using System.Web;
using System.Configuration;
using System.Collections.Generic;

using CE.db;

using EveryMatrix.SessionAgent;

using GamMatrixAPI;

namespace CasinoEngine.HttpHandlers
{
    /// <summary>
    /// Summary description for notify_balance_change
    /// </summary>
    public class notify_balance_change : IHttpHandler
    {
        //private static NonBlockingRedisClient _redisClient
        //    = new NonBlockingRedisClient(ConfigurationManager.AppSettings["SessionAgent.RedisServer"] ?? "10.0.10.38:6379");
        private static readonly NonBlockingRedisClient _redisClient = string.Equals(ConfigurationManager.AppSettings["SessionAgent.UseSentinel"], "true", StringComparison.InvariantCultureIgnoreCase)
            ? new NonBlockingRedisClient(ConfigurationManager.AppSettings["SessionAgent.SentinelAddress"].Split(";".ToCharArray(), StringSplitOptions.RemoveEmptyEntries), ConfigurationManager.AppSettings["SessionAgent.SentinelMasterName"])
            : new NonBlockingRedisClient(ConfigurationManager.AppSettings["SessionAgent.RedisServer"] ?? "10.0.10.38:6379");

        public void ProcessRequest(HttpContext context)
        {
            if (string.IsNullOrWhiteSpace(context.Request.QueryString["domainid"])
                || string.IsNullOrWhiteSpace(context.Request.QueryString["vendor"])
                || string.IsNullOrWhiteSpace(context.Request.QueryString["uid"])
                || string.IsNullOrWhiteSpace(context.Request.QueryString["aid"])
                || string.IsNullOrWhiteSpace(context.Request.QueryString["type"])
                //|| string.IsNullOrWhiteSpace(context.Request.QueryString["realMoney"])
                //|| string.IsNullOrWhiteSpace(context.Request.QueryString["bonusMoney"])
                )
                return;

            long domainID;
            VendorID vendorID;
            long uid;
            long aid;
            TransType transType;
            //decimal realMoney;
            //decimal bonusMoney;
            if (!long.TryParse(context.Request.QueryString["domainid"], out domainID))
                return;
            if (!Enum.TryParse<VendorID>(context.Request.QueryString["vendor"], out vendorID))
                return;
            if (!long.TryParse(context.Request.QueryString["uid"], out uid))
                return;
            if (!long.TryParse(context.Request.QueryString["aid"], out aid))
                return;
            if (!Enum.TryParse<TransType>(context.Request.QueryString["type"], out transType))
                return;
            //if (!decimal.TryParse(context.Request.QueryString["realMoney"], out realMoney))
            //    return;
            //if (!decimal.TryParse(context.Request.QueryString["bonusMoney"], out bonusMoney))
            //    return;

            ceDomainConfigEx domain = DomainManager.GetDomains().FirstOrDefault(d => d.DomainID == domainID);
            if (domain == null)
                return;

            _redisClient.SetByUserID(uid, "reload_balance", "true").Wait();

            context.Response.Write("OK");
        }

        public bool IsReusable
        {
            get
            {
                return false;
            }
        }
    }



}