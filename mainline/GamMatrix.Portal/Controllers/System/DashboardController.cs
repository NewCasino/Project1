using System;
using System.Collections.Generic;
using System.Collections.Specialized;
using System.Configuration;
using System.IO;
using System.Linq;
using System.Management;
using System.Net;
using System.Net.Sockets;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Runtime.Serialization.Formatters.Binary;
using System.Text;
using System.Threading.Tasks;
using System.Web;
using System.Web.Mvc;
using CM.db;
using CM.Sites;
using CM.State;
using CM.Web;

namespace GamMatrix.CMS.Controllers.System
{
    /// <summary>
    /// In the WMIMGMT.msc, you need grant "Enable Account" for IIS_IUSERS
    /// </summary>
    [HandleError]
    [ControllerExtraInfo(DefaultAction = "Index")]
    [SystemAuthorize(Roles = "CMS Domain Admin,CMS System Admin")]
    public class DashboardController : ControllerEx
    {
        

        [HttpGet]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public ActionResult Index()
        {
            try
            {
                NameValueCollection servers = ConfigurationManager.GetSection("servers") as NameValueCollection;
                this.ViewData["servers"] = servers;
                return View("Index");
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                throw;
            }
        }

        

        [HttpGet]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public JsonResult GetSystemInfo(string serverName)
        {
            NameValueCollection servers = ConfigurationManager.GetSection("servers") as NameValueCollection;
            if (servers == null || string.IsNullOrEmpty(servers[serverName] as string) )
                throw new Exception("Error, can not find the server configration.");
            string url = string.Format("http://{0}{1}"
                , servers[serverName]
                , this.Url.RouteUrl("Dashboard", new { @action = "GetLocalSystemInfo" })
                );
            HttpWebRequest request = HttpWebRequest.Create(url) as HttpWebRequest;
            request.KeepAlive = false;
            request.Timeout = 60000;
            request.Method = "POST";
            request.ContentLength = 0;
            request.AutomaticDecompression = DecompressionMethods.GZip | DecompressionMethods.Deflate;
            request.AllowAutoRedirect = true;
            request.CookieContainer = new CookieContainer();
            request.CookieContainer.Add( new Uri(url), new Cookie( SiteManager.Current.SessionCookieName, CustomProfile.Current.SessionID));
            request.Accept = "text/html";
            HttpWebResponse response = request.GetResponse() as HttpWebResponse;
            string base64 = null;
            using (Stream stream = response.GetResponseStream())
            {
                using (StreamReader sr = new StreamReader(stream))
                {
                    base64 = sr.ReadToEnd();
                }
            }
            response.Close();

            SystemInformation si = null;
            try
            {                
                using (MemoryStream ms = new MemoryStream(Convert.FromBase64String(base64)))
                {
                    BinaryFormatter formatter = new BinaryFormatter();
                    si = formatter.Deserialize(ms) as SystemInformation;
                }
            }
            catch
            {
                Logger.Error("Dashboard", base64);
                si = new SystemInformation() { success = false, error = "Failed to get system info from " + servers[serverName] };
            }
            
            return this.Json(si, JsonRequestBehavior.AllowGet);
        }

        [Serializable]
        private sealed class SystemInformation
        {
            public bool success { get; set; }
            public string error { get; set; }
            public string [] cpuLoad { get; set; }
            public string [] memoryUsage { get; set; }
            public string [] iisStatus { get; set; }
            public string [] cacheUsage { get; set; }
            public string [] osInfo { get; set; }
            public string [] networkStatus { get; set; }
        }

        private DateTime ParseCIMTime(string date)
        {
            DateTime parsed = DateTime.MinValue;

            //check date integrity
            if ( !string.IsNullOrWhiteSpace(date) && date.IndexOf('.') != -1)
            {
                //obtain the date with miliseconds
                string newDate = date.Substring(0, date.IndexOf('.') + 4);

                //check the lenght
                if (newDate.Length == 18)
                {
                    //extract each date component
                    int y = Convert.ToInt32(newDate.Substring(0, 4));
                    int m = Convert.ToInt32(newDate.Substring(4, 2));
                    int d = Convert.ToInt32(newDate.Substring(6, 2));
                    int h = Convert.ToInt32(newDate.Substring(8, 2));
                    int mm = Convert.ToInt32(newDate.Substring(10, 2));
                    int s = Convert.ToInt32(newDate.Substring(12, 2));
                    int ms = Convert.ToInt32(newDate.Substring(15, 3));

                    //compose the new datetime object
                    parsed = new DateTime(y, m, d, h, mm, s, ms);
                }
            }

            //return datetime
            return parsed;
        }

        private static void CollectVersion(List<string> osInfo)
        {
            string[] names = new string[] { "GamMatrixAPI.dll", "GamMatrix.Infrastructure.dll", "GamMatrix.CMS.dll", "CM.dll" };
            Assembly[] assemblies = AppDomain.CurrentDomain.GetAssemblies();
            foreach (Assembly assembly in assemblies)
            {
                if (assembly.ManifestModule == null)
                    continue;

                string name = assembly.ManifestModule.Name;
                if (names.FirstOrDefault(n => string.Equals(name, n, StringComparison.InvariantCultureIgnoreCase)) == null)
                    continue;
                
                osInfo.Add(string.Format( "{0} : v{1}", name, assembly.GetName().Version.ToString()));
            }
        }

        [HttpPost]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public ContentResult GetLocalSystemInfo()
        {
            SystemInformation si = new SystemInformation();
            try
            {

                ManagementScope managementScope = new ManagementScope(@"\\.\root\CIMV2");
                managementScope.Options.EnablePrivileges = true;
                managementScope.Options.Impersonation = ImpersonationLevel.Impersonate;
                managementScope.Options.Authentication = AuthenticationLevel.Default;
                {
                    ObjectQuery query = new ObjectQuery("SELECT * FROM Win32_OperatingSystem");
                    using (ManagementObjectSearcher managementObjectSearcher = new ManagementObjectSearcher(managementScope, query))
                    {
                        using (ManagementObjectCollection coll = managementObjectSearcher.Get())
                        {
                            List<string> osInfo = new List<string>();
                            foreach (ManagementObject obj in coll)
                            {
                                osInfo.Add(string.Format("Version : {0}", (obj["Version"] as string).Split('|')[0]));
                                osInfo.Add(string.Format("OS architecture : {0}", obj["OSArchitecture"]));
                                osInfo.Add(string.Format("Up time : {0}", ParseCIMTime(obj["LastBootUpTime"] as string)));
                                osInfo.Add(string.Format("Local data time : {0}", ParseCIMTime(obj["LocalDateTime"] as string)));
                                osInfo.Add(string.Format(".NET Version : {0}", global::System.Environment.Version));
                                osInfo.Add(string.Format("GC Latency Mode : {0}", global::System.Runtime.GCSettings.LatencyMode.ToString()));
                                osInfo.Add(string.Format("GC Edition : {0}", global::System.Runtime.GCSettings.IsServerGC ? "Server" : "Client"));
                            }
                            CollectVersion(osInfo);
                            si.osInfo = osInfo.ToArray();
                        }
                    }
                }
                {
                    List<string> networkStatus = GetWMIInformation("networkstatus");
                    si.networkStatus = networkStatus.ToArray();
                }
                {
                    List<string> cpuLoad = GetWMIInformation("cpuload");
                    si.cpuLoad = cpuLoad.ToArray();
                }
                {
                    ObjectQuery query = new ObjectQuery("SELECT * FROM Win32_OperatingSystem");
                    using (ManagementObjectSearcher managementObjectSearcher = new ManagementObjectSearcher(managementScope, query))
                    {
                        using (ManagementObjectCollection coll = managementObjectSearcher.Get())
                        {
                            foreach (ManagementObject obj in coll)
                            {
                                si.memoryUsage = new string[2];

                                decimal usedPhysicalMemory = ((ulong)obj["TotalVisibleMemorySize"] - (ulong)obj["FreePhysicalMemory"]) / 1024.00M / 1024.00M;
                                decimal totalPhysicalMemory = (ulong)obj["TotalVisibleMemorySize"] / 1024.00M / 1024.00M;
                                si.memoryUsage[0] = string.Format("Physical memory: {0:N2}GB / {1:N2}GB ({2:N2}%)"
                                    , usedPhysicalMemory
                                    , totalPhysicalMemory
                                    , (usedPhysicalMemory / totalPhysicalMemory) * 100.00M
                                    );

                                decimal usedVirtualMemory = ((ulong)obj["TotalVirtualMemorySize"] - (ulong)obj["FreeVirtualMemory"]) / 1024.00M / 1024.00M;
                                decimal totalVirtualMemory = (ulong)obj["TotalVirtualMemorySize"] / 1024.00M / 1024.00M;
                                si.memoryUsage[1] = string.Format("Virtual memory: {0:N2}GB / {1:N2}GB ({2:N2}%)"
                                    , usedVirtualMemory
                                    , totalVirtualMemory
                                    , (usedVirtualMemory / totalVirtualMemory) * 100.00M
                                    );
                                break;
                            }
                        }
                    }
                }


                {
                    List<string> iisStatus = GetWMIInformation("iisstatus");
                    si.iisStatus = iisStatus.ToArray();
                }

                si.cacheUsage = new string[3];
                si.cacheUsage[0] = string.Format("Entry count: {0}", HttpRuntime.Cache.Count);
                si.cacheUsage[1] = string.Format("Effective private bytes limit: {0:N2}MB", HttpRuntime.Cache.EffectivePrivateBytesLimit / 1024.00M / 1024.00M);
                si.cacheUsage[2] = string.Format("Effective percentage physical memory limit: {0}%", HttpRuntime.Cache.EffectivePercentagePhysicalMemoryLimit);

                si.success = true;
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                si.success = false;
                si.error = ex.Message;
            }

            using (MemoryStream ms = new MemoryStream())
            {
                BinaryFormatter formatter = new BinaryFormatter();
                formatter.Serialize(ms, si);
                return this.Content(Convert.ToBase64String(ms.GetBuffer()));                
            }
        }

        [StructLayout(LayoutKind.Sequential, Pack = 2, CharSet = CharSet.Unicode)]
        internal struct PackageHeader
        {
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 50)]
            public string Command;
        }

        private List<string> GetWMIInformation(string command)
        {
            try
            {
                
                using (Socket socket = new Socket(AddressFamily.InterNetwork, SocketType.Stream, ProtocolType.Tcp))
                {
                    IAsyncResult result = socket.BeginConnect(IPAddress.Loopback, 33333, null, null);
                    bool success = result.AsyncWaitHandle.WaitOne(3000, true);
                    if (success)
                    {
                        PackageHeader ph = new PackageHeader() { Command = command };
                        int size = Marshal.SizeOf(ph);
                        IntPtr ptr = Marshal.AllocHGlobal(size);
                        byte[] buffer = new byte[size];
                        if (ptr != IntPtr.Zero)
                        {
                            try
                            {
                                Marshal.StructureToPtr(ph, ptr, false);
                                Marshal.Copy(ptr, buffer, 0, buffer.Length);
                            }
                            catch
                            {
                                throw;
                            }
                            finally
                            {
                                Marshal.FreeHGlobal(ptr);
                            }

                            socket.Send(buffer);
                            buffer = new byte[8];
                            if (socket.Receive(buffer, buffer.Length, SocketFlags.None) == buffer.Length)
                            {
                                int length = 0;
                                length = length | (buffer[0] << 7);
                                length = length | (buffer[1] << 6);
                                length = length | (buffer[2] << 5);
                                length = length | (buffer[3] << 4);
                                length = length | (buffer[4] << 3);
                                length = length | (buffer[5] << 2);
                                length = length | (buffer[6] << 1);
                                length = length | buffer[7];

                                buffer = new byte[length];
                                if (socket.Receive(buffer, buffer.Length, SocketFlags.None) == buffer.Length)
                                {
                                    using (MemoryStream ms = new MemoryStream(buffer))
                                    {
                                        BinaryFormatter bf = new BinaryFormatter();
                                        List<string> list = bf.Deserialize(ms) as List<string>;
                                        if (list != null)
                                            return list;
                                    }
                                    
                                }
                            }
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
            }
            return new List<string>();
        }
        

        [HttpGet]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public JsonResult ReloadCache( string distinctName, string cache )
        {
            CacheManager.CacheType cacheType = (CacheManager.CacheType)Enum.Parse(typeof(CacheManager.CacheType), cache, true);

            cmSite site = SiteManager.GetSiteByDistinctName(distinctName);
            string error = site.ReloadCache(Request.RequestContext, cacheType);
            return this.Json(new { @success = true, @status = error.DefaultIfNullOrEmpty("OK") }, JsonRequestBehavior.AllowGet);
        }



        [OutputCache(Duration = 0, VaryByParam = "None")]
        public ContentResult ReloadLocalCache(string distinctName, CacheManager.CacheType cacheType)
        {
            Logger.Information("Dashboard", "ReloadLocalCache");

            distinctName = distinctName.DefaultDecrypt( Encoding.UTF8, true);

            byte[] buffer = null;
            if (Request.InputStream.Length > 0)
            {
                buffer = new byte[Request.InputStream.Length];
                using (BinaryReader br = new BinaryReader(Request.InputStream))
                {
                    buffer = br.ReadBytes((int)Request.InputStream.Length);
                }
            }

            cmSite site = SiteManager.GetSiteByDistinctName(distinctName);
            Action action = () =>
            {
                try
                {
                    CacheManager.ReloadLocalCache(site, cacheType, buffer);
                }
                catch(Exception ex)
                {
                   Logger.Exception(ex);
                }
            };

            Task task = Task.Factory.StartNew(() => action());            
            
            return this.Content("OK", "text/plain");
        }
    }
}
