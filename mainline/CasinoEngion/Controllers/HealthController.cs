using System;
using System.Configuration;
using System.Globalization;
using System.Text;
using System.Web.Mvc;
using CE.db;
using CE.Utils;
using EveryMatrix.SessionAgent;
using EveryMatrix.SessionAgent.Protocol;
using GamMatrixAPI;

namespace CasinoEngine.Controllers
{
    public class HealthController : ServiceControllerBase
    {
        // GET: /health
        [HttpGet]
        public ActionResult Index()
        {
            string component = "CasinoEngine";
            string service = HttpContext.Server.MachineName;
            string status = "OK";
            string message = string.Empty;
            string action = "HealthCheck";
            string json = string.Format(@"{{
   ""component"": ""{0}"",
   ""service"": ""{1}"",
   ""status"": ""{2}"",
   ""message"": ""{3}"",
   ""action"": ""{4}""
}}", component, service, status, message, action);
            return this.Content(json, "application/json");
        }
        
    }
}
