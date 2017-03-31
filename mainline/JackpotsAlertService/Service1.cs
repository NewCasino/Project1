using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Diagnostics;
using System.Linq;
using System.ServiceProcess;
using System.Text;
using System.Threading.Tasks;

namespace JackpotsAlertService
{
    public partial class Service1 : ServiceBase
    {
        private System.Timers.Timer timer;
        public Service1()
        {
            InitializeComponent();
        }

        protected override void OnStart(string[] args)
        {
            timer = new System.Timers.Timer(10 * 60 * 1000);
            timer.Enabled = true;
            timer.Elapsed += this.Process;
        }

        private void Process(object sender, EventArgs e)
        {
            JackpotAlert.Start();
        }

        protected override void OnStop()
        {
        }
    }
}
