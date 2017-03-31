using System;
using System.Threading;
using System.IO;
using System.Net;
using System.Net.Sockets;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Text;

namespace CmsAgent
{
    [StructLayout(LayoutKind.Sequential, Pack = 2, CharSet = CharSet.Unicode)]
    internal struct PackageHeader
    {
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst=50)]
        public string Command;       
    }

    internal sealed class RcvPackageItem
    {
        public PackageHeader PackageHeader { get; private set; }
        public byte[] PackageHeaderBuffer { get; private set; }
        public int AvailableHeaderSize { get; set; }
        public byte[] PackageBodyBuffer { get; private set; }
        public int AvailableBodySize { get; set; }

        public static int PackageHeaderSize
        {
            get
            {
                return Marshal.SizeOf(typeof(PackageHeader));
            }
        }

        public RcvPackageItem()
        {
            
            PackageHeaderBuffer = new byte[PackageHeaderSize];
        }

        public void ParseHead()
        {
            IntPtr ptr = Marshal.AllocHGlobal(PackageHeaderSize);
            try
            {
                Marshal.Copy(PackageHeaderBuffer, 0, ptr, PackageHeaderSize);
                this.PackageHeader = (PackageHeader)Marshal.PtrToStructure(ptr, typeof(PackageHeader));
            }
            catch (Exception ex)
            {
                Logger.Get().Append(ex);
            }
            finally
            {
                Marshal.FreeHGlobal(ptr);
            }
        }

        
    }

    public sealed class SocketContext
    {
        internal Socket ClientSocket { get; private set; }
        internal RcvPackageItem RcvPackage { get; private set; }

        public SocketContext(Socket socket)
        {
            RcvPackage = new RcvPackageItem();
            ClientSocket = socket;
        }

        public string RemoteIpAddress
        {
            get
            {
                IPEndPoint endPoint = ClientSocket.RemoteEndPoint as IPEndPoint;
                return endPoint.Address.ToString();
            }
        }
        public int RemotePort
        {
            get
            {
                IPEndPoint endPoint = ClientSocket.RemoteEndPoint as IPEndPoint;
                return endPoint.Port;
            }
        }

        public void Dispose()
        {
            try
            {
                if (ClientSocket != null)
                    ClientSocket.Close();
            }
            catch { }
            finally
            {
                ClientSocket = null;
            }
        }

        
    }
}
