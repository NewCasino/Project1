using System;
using System.Collections;
using System.ComponentModel;
using System.Configuration;
using System.ServiceProcess;

namespace CmsSanityCheck
{
    [RunInstaller(true)]
    public partial class SvcInstaller : System.Configuration.Install.Installer
    {
        private string m_ServiceName;

        public SvcInstaller()
        {
            Configuration config = ConfigurationManager.OpenExeConfiguration(this.GetType().Assembly.Location);
            m_ServiceName = config.AppSettings.Settings["Service.Name"].Value;
            if (string.IsNullOrEmpty(m_ServiceName))
                throw new Exception("Invalid settings(Service.Name) in app.config!");

            Installers.Clear();

            ServiceInstaller serviceInstaller = new ServiceInstaller();
            serviceInstaller.ServicesDependedOn = new string[] { "LanmanServer" };
            serviceInstaller.StartType = ServiceStartMode.Automatic;
            serviceInstaller.ServiceName = m_ServiceName;
            serviceInstaller.DisplayName = config.AppSettings.Settings["Service.DisplayName"].Value;
            serviceInstaller.Description = config.AppSettings.Settings["Service.Description"].Value;

            Installers.Add(serviceInstaller);

            ServiceProcessInstaller processInstaller = new ServiceProcessInstaller();
            processInstaller.Account = ServiceAccount.LocalSystem;
            processInstaller.Password = null;
            processInstaller.Username = null;

            Installers.Add(processInstaller);
        }

        protected override void OnAfterInstall(IDictionary savedState)
        {
            base.OnAfterInstall(savedState);

        }
    }
}
