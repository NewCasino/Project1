using System;
using System.Collections.Generic;
using System.Text;
using System.Collections;
using System.Configuration;
using System.ComponentModel;
using System.ServiceProcess;
using System.Configuration.Install;
using System.Windows.Forms;

using Microsoft.Win32;


namespace CmsAgent
{
    [RunInstaller(true)]
    public class SvcInstaller : Installer
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
            /*
            try
            {
                ServiceController controller = null;
                ServiceController[] controllers = ServiceController.GetServices();
                for (int i = 0; i < controllers.Length; i++)
                {
                    if (controllers[i].ServiceName == m_ServiceName)
                    {
                        controller = controllers[i];
                        break;
                    }
                }
                if (controller == null)
                {
                    return;
                }

                // if the service is not active, start it
                if (controller.Status != ServiceControllerStatus.Running)
                {
                    string[] args = { "-install" };
                    controller.Start(args);
                }
            }
            catch (Exception ex)
            {
                Logger.Get().Append(ex);
                throw;
            }
             * */
        }

    }
}
