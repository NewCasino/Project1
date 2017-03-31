using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Net;
using System.Net.Sockets;
using System.IO;
using System.Management;
using System.Runtime.Serialization.Formatters.Binary;
using System.Runtime.InteropServices;

namespace CmsAgent
{
    internal class TcpFileServer
    {
        private Socket m_Socket;

        public void Start()
        {
            try
            {
                // create the socket
                {
                    m_Socket = new Socket(AddressFamily.InterNetwork, SocketType.Stream, ProtocolType.Tcp);
                    IPEndPoint endPoint = new IPEndPoint(IPAddress.Any, 33333);
                    m_Socket.Bind(endPoint);
                    m_Socket.Listen(20);
                }

                for (int i = 0; i < 5; i++)
                {
                    m_Socket.BeginAccept(this.OnClientConnect, null);
                }
            }
            catch(Exception ex)
            {
                Logger.Get().Append(ex);
            }
        }

        public void Stop()
        {
            try
            {
                if (m_Socket != null)
                {
                    m_Socket.Shutdown(SocketShutdown.Send);
                    m_Socket.Close();
                    m_Socket = null;
                }
            }
            catch (Exception e)
            {
                Logger.Get().Append(e);
            }
        }

        private void OnClientConnect(IAsyncResult asyn)
        {
            SocketContext socketContext = null;
            try
            {
                m_Socket.BeginAccept(this.OnClientConnect, null);

                Socket clientSocket = m_Socket.EndAccept(asyn);

                socketContext = new SocketContext(clientSocket);
                clientSocket.BeginReceive(socketContext.RcvPackage.PackageHeaderBuffer
                    , 0
                    , socketContext.RcvPackage.PackageHeaderBuffer.Length
                    , SocketFlags.None
                    , this.OnRcvPackageHeader
                    , socketContext
                    );
            }
            catch (Exception e1)
            {
                Logger.Get().Append(e1);
                try
                {
                    if (socketContext != null)
                        socketContext.Dispose();
                }
                catch (Exception e2)
                {
                    Logger.Get().Append(e2);
                }
            }
        }

        private void OnRcvPackageHeader(IAsyncResult asyn)
        {
            SocketContext socketContext = asyn.AsyncState as SocketContext;
            try
            {
                SocketError socketError;
                int size = socketContext.ClientSocket.EndReceive(asyn, out socketError);
                if (size == 0 && socketError == SocketError.Success)
                {
                    // The client shutdown the socket
                    socketContext.Dispose();
                    return;
                }
                socketContext.RcvPackage.AvailableHeaderSize += size;
                if (socketContext.RcvPackage.AvailableHeaderSize < socketContext.RcvPackage.PackageHeaderBuffer.Length)
                {
                    socketContext.ClientSocket.BeginReceive(socketContext.RcvPackage.PackageHeaderBuffer
                    , socketContext.RcvPackage.AvailableHeaderSize
                    , socketContext.RcvPackage.PackageHeaderBuffer.Length - socketContext.RcvPackage.AvailableHeaderSize
                    , SocketFlags.None
                    , this.OnRcvPackageHeader
                    , socketContext
                    );
                }
                else
                {
                    socketContext.RcvPackage.ParseHead();
                    byte [] buffer  = ParseCommand(socketContext.RcvPackage.PackageHeader.Command);
                    if( buffer != null && buffer.Length > 0 )
                        socketContext.ClientSocket.Send(buffer);
                    socketContext.Dispose();
                }

            }
            catch (Exception e)
            {
                socketContext.Dispose();
                Logger.Get().Append(e);
            }
        }

        private byte [] ParseCommand(string command)
        {
            if (string.IsNullOrWhiteSpace(command))
                return null;

            switch (command.ToLowerInvariant())
            {
                case "iisstatus":
                    return GetIISStatus();

                case "cpuload":
                    return GetCPULoad();

                case "networkstatus":
                    return GetNetworkStatus();

                default: return null;
            }
        }

        private byte[] SerializeList(List<string> list)
        {
            using (MemoryStream ms = new MemoryStream())
            {
                BinaryFormatter bf = new BinaryFormatter();
                bf.Serialize(ms, list);

                byte[] buffer = ms.GetBuffer();

                byte[] bufferWithHeader = new byte[buffer.Length + 8];
                int length = buffer.Length;
                bufferWithHeader[0] = (byte)((length >> 7) & 0x0F);
                bufferWithHeader[1] = (byte)((length >> 6) & 0x0F);
                bufferWithHeader[2] = (byte)((length >> 5) & 0x0F);
                bufferWithHeader[3] = (byte)((length >> 4) & 0x0F);
                bufferWithHeader[4] = (byte)((length >> 3) & 0x0F);
                bufferWithHeader[5] = (byte)((length >> 2) & 0x0F);
                bufferWithHeader[6] = (byte)((length >> 1) & 0x0F);
                bufferWithHeader[7] = (byte)(length & 0x0F);
                buffer.CopyTo(bufferWithHeader, 8);

                return bufferWithHeader;
            }
        }

        private byte[] GetCPULoad()
        {
            try
            {
                ManagementScope managementScope = new ManagementScope(@"\\.\root\CIMV2");
                managementScope.Options.EnablePrivileges = true;
                managementScope.Options.Impersonation = ImpersonationLevel.Impersonate;
                managementScope.Options.Authentication = AuthenticationLevel.Default;
                ObjectQuery query = new ObjectQuery("SELECT * FROM Win32_Processor");
                using (ManagementObjectSearcher managementObjectSearcher = new ManagementObjectSearcher(managementScope, query))
                {
                    using (ManagementObjectCollection coll = managementObjectSearcher.Get())
                    {
                        List<string> cpuLoad = new List<string>();
                        foreach (ManagementObject obj in coll)
                        {
                            cpuLoad.Add(string.Format("{0} x {1} : {2:00}%", obj["DeviceID"], obj["NumberOfCores"], obj["LoadPercentage"]));
                        }
                        return SerializeList(cpuLoad);
                    }
                }

            }
            catch (Exception ex)
            {
                Logger.Get().Append(ex);
            }
            return null;
        }

        private byte[] GetIISStatus()
        {
            List<string> iisStatus = new List<string>();
            try
            {
                {
                    ManagementPath path = new ManagementPath();
                    path.Server = Environment.MachineName;
                    path.NamespacePath = "root\\CIMV2";
                    path.RelativePath = "Win32_PerfFormattedData_W3SVC_WebService.Name='Cms2012'";

                    using (ManagementObject service = new ManagementObject(path))
                    {
                        service.Get();
                        iisStatus.Add(string.Format("Current connections: {0}", service.GetPropertyValue("CurrentConnections")));
                        iisStatus.Add(string.Format("Maximum connections: {0}", service.GetPropertyValue("MaximumConnections")));
                        iisStatus.Add(string.Format("Service up time: {0} seconds", service.GetPropertyValue("ServiceUptime")));
                        iisStatus.Add(string.Format("Total bytes received: {0:N2}MB", (ulong)service.GetPropertyValue("TotalBytesReceived") / 1024.00M / 1024.00M));
                        iisStatus.Add(string.Format("Total bytes sent: {0:N2}MB", (ulong)service.GetPropertyValue("TotalBytesSent") / 1024.00M / 1024.00M));
                    }
                }

                {
                    ManagementScope scope = new ManagementScope("\\\\.\\ROOT\\cimv2");
                    ObjectQuery query = new ObjectQuery("SELECT * FROM Win32_PerfFormattedData_ASPNET4030319_ASPNETv4030319");
                    using (ManagementObjectSearcher searcher = new ManagementObjectSearcher(scope, query))
                    {
                        using (ManagementObjectCollection coll = searcher.Get())
                        {
                            foreach (ManagementObject m in coll)
                            {
                                iisStatus.Add(string.Format("Request execution time: {0} ms", m["RequestExecutionTime"]));
                                iisStatus.Add(string.Format("Request wait time: {0} ms", m["RequestWaitTime"]));
                                iisStatus.Add(string.Format("Current requests : {0}", m["RequestsCurrent"]));
                                iisStatus.Add(string.Format("Queued requests : {0}", m["RequestsQueued"]));
                                iisStatus.Add(string.Format("Rejected requests : {0}", m["RequestsRejected"]));
                                iisStatus.Add(string.Format("Disconnected requests : {0}", m["RequestsDisconnected"]));
                                iisStatus.Add(string.Format("Application restarts: {0}", m["ApplicationRestarts"]));
                                iisStatus.Add(string.Format("Raised error events : {0}", m["ErrorEventsRaised"]));
                                iisStatus.Add(string.Format("Raised request error events : {0}", m["RequestErrorEventsRaised"]));
                                iisStatus.Add(string.Format("Raised infrastructure error events : {0}", m["InfrastructureErrorEventsRaised"]));
                            }
                        }
                    }
                }

                return SerializeList(iisStatus);

            }
            catch (Exception ex)
            {
                Logger.Get().Append(ex);
            }
            return null;
        }

        private byte[] GetNetworkStatus()
        {
            
            try
            {
                ManagementScope managementScope = new ManagementScope(@"\\.\root\CIMV2");
                managementScope.Options.EnablePrivileges = true;
                managementScope.Options.Impersonation = ImpersonationLevel.Impersonate;
                managementScope.Options.Authentication = AuthenticationLevel.Default;
                ObjectQuery query = new ObjectQuery("SELECT * FROM Win32_PerfFormattedData_Tcpip_NetworkInterface");
                using (ManagementObjectSearcher managementObjectSearcher = new ManagementObjectSearcher(managementScope, query))
                {
                    using (ManagementObjectCollection coll = managementObjectSearcher.Get())
                    {
                        List<string> networkStatus = new List<string>();
                        foreach (ManagementObject obj in coll)
                        {
                            networkStatus.Add(string.Format("{0} : Outbound = {1:N2}KB/s; Inbound = {2:N2}KB/s"
                                , obj["Name"]
                                , (ulong)obj["BytesSentPerSec"] / 1024.0M
                                , (ulong)obj["BytesReceivedPerSec"] / 1024.0M)
                                );
                        }
                        return SerializeList(networkStatus);
                    }
                }

            }
            catch (Exception ex)
            {
                Logger.Get().Append(ex);
            }
            return null;
        }

    }
}
