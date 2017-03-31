using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.IO;
using System.Diagnostics;
using System.Threading;
using System.Reflection;

namespace CmsAgent
{
    public sealed class Logger
    {
        private static Logger s_Instance;

        /// <summary>
        /// Retrieve the single instance
        /// </summary>
        /// <returns></returns>
        public static Logger Get()
        {
            try
            {
                if (s_Instance == null)
                    s_Instance = new Logger();
            }
            catch
            {
            }

            return s_Instance;
        }

        private FileStream m_FileStream;

        private Logger()
        {
            DateTime now = DateTime.Now;

            string dir = typeof(Logger).Assembly.Location;
            dir = dir.Substring(0, dir.LastIndexOf('\\'));

            StringBuilder sb = new StringBuilder();
            sb.AppendFormat("{0}\\logs\\", dir);
            if (!Directory.Exists(sb.ToString()))
                Directory.CreateDirectory(sb.ToString());

            sb.AppendFormat("{0}-{1}\\", now.Year, now.Month);
            if (!Directory.Exists(sb.ToString()))
                Directory.CreateDirectory(sb.ToString());

            sb.AppendFormat("{0:D4}-{1:D2}-{2:D2} {3:D2}.{4:D2}.{5:D2}.txt", now.Year, now.Month, now.Day, now.Hour, now.Minute, now.Second);
            m_FileStream = new FileStream(sb.ToString(), FileMode.CreateNew, FileAccess.Write, FileShare.ReadWrite | FileShare.Delete);

            lock (m_FileStream)
            {
                byte[] header = { 0xFF, 0xFE };
                m_FileStream.Write(header, 0, header.Length);
                m_FileStream.Flush();
            }
        }

        /// <summary>
        /// Close the log file
        /// </summary>
        public void Close()
        {
            if (m_FileStream != null)
            {
                lock (m_FileStream)
                {
                    m_FileStream.Flush();
                    m_FileStream.Close();
                    m_FileStream.Dispose();
                }
                s_Instance = null;
            }
        }

        /// <summary>
        /// Append an message to log
        /// </summary>
        /// <param name="msg"></param>
        public void Append(string msg)
        {
            if (m_FileStream != null)
            {
                DateTime now = DateTime.Now;
                string text = string.Format("\r\n[{0:D4}-{1:D2}-{2:D2} {3:D2}:{4:D2}:{5:D2} PID={6:D4} TID={7:D4}]\t{8}"
                    , now.Year
                    , now.Month
                    , now.Day
                    , now.Hour
                    , now.Minute
                    , now.Second
                    , Process.GetCurrentProcess().Id
                    , Thread.CurrentThread.ManagedThreadId
                    , msg
                    );
                byte[] buffer = Encoding.Unicode.GetBytes(text);
                lock (m_FileStream)
                {
                    m_FileStream.Write(buffer, 0, buffer.Length);
                    m_FileStream.Flush();
                }
            }
        }

        /// <summary>
        /// Append and format a message to log
        /// </summary>
        /// <param name="format"></param>
        /// <param name="args"></param>
        public void AppendFormat(string format, params object[] args)
        {
            this.Append(string.Format(format, args));
        }

        /// <summary>
        /// Append an exception
        /// </summary>
        /// <param name="exception"></param>
        public void Append(Exception exception)
        {
            StringBuilder sb = new StringBuilder();
            sb.AppendFormat("{0}\r\n", exception.Message);
            sb.AppendFormat("Stack Trace:\r\n{0}\r\n", exception.StackTrace);

            if (exception.InnerException != null)
            {
                sb.AppendFormat("Inner Exception:{0}\r\n", exception.InnerException.Message);
                sb.AppendFormat("Inner Exception Stack Trace:\r\n{0}\r\n", exception.InnerException.StackTrace);
            }
            this.Append(sb.ToString());
        }
    }
}
