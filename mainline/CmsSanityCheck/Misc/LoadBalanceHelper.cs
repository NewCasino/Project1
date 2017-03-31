using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;

using Newtonsoft.Json;

namespace CmsSanityCheck.Misc
{
    using Model;

    public class LoadBalanceHelper
    {
        public static void Update(Service service, Dictionary<string, bool> settings)
        {
            Dictionary<string, bool> oldSettings = ReadFromFile(service);

            List<string> ipAddressesToBeEnabled = new List<string>();
            foreach (string ipAddress in service.IPAddresses)
            {
                if (!settings[ipAddress])
                    continue;

                if (settings[ipAddress] != oldSettings[ipAddress])
                    ipAddressesToBeEnabled.Add(ipAddress);
            }

            List<string> ipAddressesToBeDisabled = new List<string>();
            foreach (string ipAddress in service.IPAddresses)
            {
                if (settings[ipAddress])
                    continue;

                if (settings[ipAddress] != oldSettings[ipAddress])
                    ipAddressesToBeDisabled.Add(ipAddress);
            }

            if (ipAddressesToBeEnabled.Any() || ipAddressesToBeDisabled.Any())
            {
                SaveToFile(service, settings);

                //string subject = string.Format("Info - Sanity Check ({0}): Load balance updated", service.Name);
                string subject = string.Format("Info - Sanity Check ({0}): Please change the server status in load balance", service.Name);
                StringBuilder body = new StringBuilder();
                body.AppendLine(string.Format("Name: {0}", service.Name));

                if (ipAddressesToBeEnabled.Any())
                {
                    body.AppendLine("");
                    body.AppendLine("Please enable the below servers:");
                    foreach (string ipAddress in ipAddressesToBeEnabled)
                        body.AppendLine(ipAddress);
                }

                if (ipAddressesToBeDisabled.Any())
                {
                    body.AppendLine("");
                    body.AppendLine("Please disable the below servers:");
                    foreach (string ipAddress in ipAddressesToBeDisabled)
                        body.AppendLine(ipAddress);
                }

                EmailHelper.Send(Config.ServerAlertReceiver, subject, body.ToString());
            }
        }

        private static Dictionary<string, bool> ReadFromFile(Service service)
        {
            //return service.IPAddresses.ToDictionary(ipAddress => ipAddress, ipAddress => true);
            try
            {
                string path = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "settings", service.Name + ".json");
                string json = FileSystemHelper.ReadWithoutLock(path);
                if (string.IsNullOrWhiteSpace(json))
                    return service.IPAddresses.ToDictionary(ipAddress => ipAddress, ipAddress => true);

                Dictionary<string, bool> settings = JsonConvert.DeserializeObject<Dictionary<string, bool>>(json);
                if (settings == null)
                    return service.IPAddresses.ToDictionary(ipAddress => ipAddress, ipAddress => true);

                Dictionary<string, bool> ret = new Dictionary<string, bool>();

                foreach (string ipAddress in service.IPAddresses)
                {
                    bool status;
                    if (settings.TryGetValue(ipAddress, out status))
                        ret.Add(ipAddress, status);
                    else
                        ret.Add(ipAddress, true);
                }

                return ret;
            }
            catch
            {
                return service.IPAddresses.ToDictionary(ipAddress => ipAddress, ipAddress => true);
            }
        }

        private static void SaveToFile(Service service, Dictionary<string, bool> settings)
        {
            string path = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "settings");
            if (!Directory.Exists(path))
                Directory.CreateDirectory(path);
            path = Path.Combine(path, service.Name + ".json");
            string json = JsonConvert.SerializeObject(settings);
            FileSystemHelper.WriteWithoutLock(path, json);
        }
    }


}
