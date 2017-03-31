using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Diagnostics;
using System.Linq;
using System.ServiceProcess;
using System.Text;
using System.Threading.Tasks;

using log4net;

namespace CmsSanityCheck
{
    public partial class MainEntry : ServiceBase
    {
        private static ILog log = LogManager.GetLogger(typeof(MainEntry));
        private MonitorService _service = new MonitorService();

        public MainEntry()
        {
            InitializeComponent();
        }

        protected override void OnStart(string[] args)
        {
            ILog log = LogManager.GetLogger(typeof(MainEntry));
            log.Warn("Service starting...");
            _service.Start();
        }

        protected override void OnStop()
        {
            ILog log = LogManager.GetLogger(typeof(MainEntry));
            log.Warn("Service is stopping...");
            _service.Stop();
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
