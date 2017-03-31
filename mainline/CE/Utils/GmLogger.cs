using System;
using System.Configuration;
using GmGaming.Infrastructure.Logging;
using GmGaming.WebApi;

namespace CE.Utils
{
    public class GmLogger
    {
        private static DefaultLogger _instance;

        private GmLogger() { }

        public static DefaultLogger Instance
        {
            get
            {
                if (_instance == null)
                {
                    string apiHost = ConfigurationManager.AppSettings["GmLogging.ApiHost"];
                    string apiUrl = ConfigurationManager.AppSettings["GmLogging.ApiUrl"];
                    string appName = ConfigurationManager.AppSettings["GmLogging.AppName"];
                    string serverName = ConfigurationManager.AppSettings["GmLogging.ServerName"];
                    LogLevels logLevel;
                    if (!Enum.TryParse(ConfigurationManager.AppSettings["GmLogging.LogLevel"], out logLevel))
                        logLevel = LogLevels.Error;
                    _instance = new DefaultLogger(apiHost + apiUrl, appName, true, true, logLevel, serverName);
                }
                return _instance;
            }
        }
    }
}