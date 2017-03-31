using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Diagnostics;
using System.Linq;
using System.ServiceProcess;
using System.Text;
using System.Configuration;
using System.Threading.Tasks;
using System.Web.Http.SelfHost;
using System.Web.Http;

namespace CmsAgent
{
    public partial class MainSvc : ServiceBase
    {
        
        private static TcpFileServer s_TcpFileServer = new TcpFileServer();
        private static MySqlAgent s_MySqlAgent = new MySqlAgent();

        private static HttpSelfHostServer _server;
        private readonly HttpSelfHostConfiguration _config;

        

        public MainSvc()
        {
            _config = new HttpSelfHostConfiguration(ConfigurationManager.AppSettings["Http.ListeningURL"]);
            _config.MaxBufferSize = 1024 * 1024 * 100;
            _config.MaxReceivedMessageSize = 1024 * 1024 * 100;
          
            _config.Routes.MapHttpRoute("FileManagerController", "FileManager/{action}", new { controller = "FileManager" });
            Trace.Listeners.Add(new ConsoleTraceListener());
            TaskScheduler.UnobservedTaskException += (sender, args) =>
            {
                args.SetObserved();

                AggregateException ae = args.Exception as AggregateException;
                if (ae != null)
                {
                    foreach (var ex in ae.InnerExceptions)
                    {
                        Logger.Get().Append(ex);
                    }
                }
                else
                {
                    Logger.Get().Append(args.Exception);
                }
            };

            InitializeComponent();
        }

        protected override void OnStart(string[] args)
        {
            //s_MySqlAgent.Start();
            //s_TcpFileServer.Start();

            _server = new HttpSelfHostServer(_config);
           
            _server.OpenAsync().Wait();
        }

        protected override void OnStop()
        {
            //s_TcpFileServer.Stop();

            if (_server != null)
            {
                _server.CloseAsync().Wait();
                _server.Dispose();
            }
        }


#if DEBUG
        public void TestRun()
        {
            OnStart(null);
            System.Threading.Thread.Sleep(99999999);
        }
#endif
    }
}
