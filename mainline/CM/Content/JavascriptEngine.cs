using System;
using System.Runtime.InteropServices;
using System.Text;

namespace CM.Content
{
    /// <summary>
    /// Javascript Engine
    /// </summary>
    public static class JavascriptEngine
    {
        [DllImport("GoogleV8Engine_x86.dll", EntryPoint = "ExecuteJavascript", CharSet = CharSet.Unicode, ExactSpelling = true, SetLastError = true)]
        private static extern bool ExecuteJavascript_x86([MarshalAs(UnmanagedType.LPWStr)] string wszJavascript
            , out IntPtr pOutBuffer
            , [MarshalAs(UnmanagedType.U4)] out int dwOutBufferLength
            );

        [DllImport("GoogleV8Engine_x64.dll", EntryPoint = "ExecuteJavascript", CharSet = CharSet.Unicode, ExactSpelling = true, SetLastError = true)]
        private static extern bool ExecuteJavascript_x64([MarshalAs(UnmanagedType.LPWStr)] string wszJavascript
            , out IntPtr pOutBuffer
            , [MarshalAs(UnmanagedType.U4)] out int dwOutBufferLength
            );

        /// <summary>
        /// Execute the javascript in Google V8 Engine
        /// </summary>
        /// <param name="js"></param>
        /// <returns></returns>
        public static string Execute(string js)
        {
            IntPtr pOutBuffer = IntPtr.Zero;
            try
            {
                string resp;
                int dwOutBufferLength = 0;
                bool bRet = false;
                //if( IntPtr.Size == 8 )
                if (Environment.Is64BitOperatingSystem)
                    bRet = ExecuteJavascript_x64(js, out pOutBuffer, out dwOutBufferLength);
                else
                    bRet = ExecuteJavascript_x86(js, out pOutBuffer, out dwOutBufferLength);
                if (dwOutBufferLength > 0 && pOutBuffer != IntPtr.Zero)
                {
                    byte[] buffer = new byte[dwOutBufferLength];
                    Marshal.Copy(pOutBuffer, buffer, 0, dwOutBufferLength);
                    resp = Encoding.Unicode.GetString(buffer);
                    if (!bRet)
                        throw new Exception(string.Format("Server Side Javascript Error [{0}]", resp + ";js content:") + js);
                    return resp;
                }
                else if (!bRet)
                    throw new Exception("Failed to execute server-side JS.");
                else
                    return string.Empty;
            }
            finally
            {
                if (pOutBuffer != IntPtr.Zero)
                    Marshal.FreeCoTaskMem(pOutBuffer);
            }
        }
    }
}
