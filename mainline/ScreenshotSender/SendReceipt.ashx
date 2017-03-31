<%@ WebHandler Language="C#" Class="SendReceipt" %>

using System;
using System.IO;
using System.Web;
using System.Threading;
using System.Threading.Tasks;
using System.Diagnostics;
using System.Net.Mail;
using System.Text;
using System.Text.RegularExpressions;
using System.Configuration;
using System.Collections.Generic;
using System.Collections.Concurrent;
using System.Linq;

public sealed class TaskInfo
{
    public string ExeFile { get; set; }
    public string Url { get; set; }
    public string Sid { get; set; }
    public string Sender { get; set; }
    public string Receiver { get; set; }
    public string ReplyTo { get; set; }
    public string Subject { get; set; }
    public string Body { get; set; }
    public string Email_SMTP { get; set; }
    public string Email_Port { get; set; }
}

public sealed class Logger
{
    public static void Info(string message)
    {
        try
        {
            var path = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "logs");
            if (!Directory.Exists(path))
                Directory.CreateDirectory(path);
            var filename = Path.Combine(path, DateTime.Now.ToString("yyyyMMdd") + ".log");
            StreamWriter writer = null;
            try
            {
                writer = new StreamWriter(filename, true, Encoding.UTF8);
                writer.WriteLine(DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss") + " " + message);
            }
            finally
            {
                if (writer != null)
                    writer.Close();
            }
        }
        catch
        {
        }
    }
}

public sealed class TaskPool
{
    private static ConcurrentQueue<TaskInfo> _queue = new ConcurrentQueue<TaskInfo>();
    private static Task _task = null;
    private static int _running = 0;
    private static int _maxPool = 5;

    public static void Add(TaskInfo ti)
    {
        _queue.Enqueue(ti);

        if (_task == null)
            _task = Task.Factory.StartNew(Run);
    }

    private static void Run()
    {
        while (true)
        {
            if (_running >= _maxPool)
            {
                Task.Delay(500).Wait();
                continue;
            }

            TaskInfo ti;
            if (!_queue.TryDequeue(out ti))
            {
                Task.Delay(500).Wait();
                continue;
            }

            _running++;
            Task.Factory.StartNew(() =>
            {
                try
                {
                    TaskProc(ti);
                }
                catch (Exception ex)
                {
                    Logger.Info(ex.Message);
                }
                finally
                {
                    _running--;
                }
            });
        }
    }

    private static void TaskProc(TaskInfo ti)
    {
        string destFile = Path.Combine(Path.GetDirectoryName(ti.ExeFile), DateTime.Now.ToString("yyyyMM"));
        if (!Directory.Exists(destFile))
            Directory.CreateDirectory(destFile);
        destFile = Path.Combine(destFile, ti.Sid + ".png");
        if (File.Exists(destFile) && new FileInfo(destFile).Length > 0)
            return;
        try
        {
            using (Process process = new Process())
            {
                string url = Regex.Replace(ti.Url, @"^(https\:\/\/)", "http://", RegexOptions.IgnoreCase | RegexOptions.Compiled | RegexOptions.CultureInvariant);
                process.StartInfo.FileName = ti.ExeFile;
                process.StartInfo.ErrorDialog = false;
                process.StartInfo.CreateNoWindow = true;
                process.StartInfo.WindowStyle = ProcessWindowStyle.Hidden;
                process.StartInfo.WorkingDirectory = Path.GetDirectoryName(ti.ExeFile);
                process.StartInfo.UseShellExecute = false;
                process.StartInfo.Arguments = string.Format(@"--min-width=1024 --delay=1500 --javascript=off --auto-load-images=on --plugins=off --java=off --url={0} --out={1}"
                    , url
                    , destFile
                    );
                process.Start();

                process.WaitForExit();
                process.Close();
            }
        }
        catch
        {
        }
        FileInfo fi = new FileInfo(destFile);
        if (!fi.Exists || fi.Length < 1024 * 10)
            return;

        Attachment att = new Attachment(destFile);
        att.ContentId = ti.Sid;

        string body = ti.Body.Replace("$SCREENSHOT$", string.Format("<img src=\"cid:{0}\" />", ti.Sid));
        MailMessage mailMessage = new MailMessage();
        mailMessage.From = new MailAddress(ti.Sender);
        mailMessage.To.Add(ti.Receiver);
        mailMessage.Subject = ti.Subject;
        mailMessage.BodyEncoding = Encoding.UTF8;
        mailMessage.IsBodyHtml = true;
        mailMessage.ReplyToList.Add(ti.ReplyTo);
        mailMessage.Attachments.Add(att);
        mailMessage.Body = body;

        string server = ConfigurationManager.AppSettings["SmtpServer"];
        int port = 25;

        if (!string.IsNullOrWhiteSpace(ti.Email_SMTP))
            server = ti.Email_SMTP;
        else if (string.IsNullOrWhiteSpace(server))
            server = "109.205.92.7";

        if (!string.IsNullOrWhiteSpace(ti.Email_Port))
        {
            if (!int.TryParse(ti.Email_Port, out port))
                port = 25;
        }

        using (SmtpClient client = new SmtpClient(server, port))
        {
            client.Send(mailMessage);
        }
    }

}

public class SendReceipt : IHttpHandler
{

    public void ProcessRequest(HttpContext context)
    {
        context.Response.ContentType = "text/plain";

        string body = string.Empty;
        using (StreamReader sr = new StreamReader(context.Request.InputStream))
        {
            body = sr.ReadToEnd();
        }

        TaskInfo ti = new TaskInfo()
        {
            ExeFile = context.Server.MapPath("~/App_Data/CutyCapt.exe"),
            Subject = context.Request.Headers["Subject"],
            Receiver = context.Request.Headers["Receiver"],
            Sender = context.Request.Headers["Sender"],
            ReplyTo = context.Request.Headers["ReplyTo"],
            Sid = context.Request.Headers["Sid"],
            Url = context.Request.Headers["Url"],
            Body = body,
            Email_SMTP = context.Request.Headers["Email_SMTP"],
            Email_Port = context.Request.Headers["Email_Port"],
        };

        string destFile = Path.Combine(Path.GetDirectoryName(ti.ExeFile), DateTime.Now.ToString("yyyyMM"));
        if (!Directory.Exists(destFile))
            Directory.CreateDirectory(destFile);
        destFile = Path.Combine(destFile, ti.Sid + ".png");
        if (File.Exists(destFile))
        {
            context.Response.Write("-ERR");
            return;
        }

        string sourceFile = Path.Combine(Path.GetDirectoryName(ti.ExeFile), "blank.png");
        File.Copy(sourceFile, destFile);
        //ThreadPool.QueueUserWorkItem(new WaitCallback(ThreadProc), ti);
        TaskPool.Add(ti);

        context.Response.Write(string.Format(@"Subject:{0}
Receiver:{1}
Sender:{2}
ReplyTo:{3}
Sid:{4}
Url:{5}"
            , ti.Subject
            , ti.Receiver
            , ti.Sender
            , ti.ReplyTo
            , ti.Sid
            , ti.Url
            , ti.Body
            ));
    }

    public bool IsReusable
    {
        get
        {
            return true;
        }
    }


    private static void ThreadProc(Object stateInfo)
    {
        TaskInfo ti = stateInfo as TaskInfo;


        string destFile = Path.Combine(Path.GetDirectoryName(ti.ExeFile), DateTime.Now.ToString("yyyyMM"));
        if (!Directory.Exists(destFile))
            Directory.CreateDirectory(destFile);
        destFile = Path.Combine(destFile, ti.Sid + ".png");
        if (File.Exists(destFile) && new FileInfo(destFile).Length > 0)
            return;
        try
        {
            using (Process process = new Process())
            {
                string url = Regex.Replace(ti.Url, @"^(https\:\/\/)", "http://", RegexOptions.IgnoreCase | RegexOptions.Compiled | RegexOptions.CultureInvariant);
                process.StartInfo.FileName = ti.ExeFile;
                process.StartInfo.ErrorDialog = false;
                process.StartInfo.CreateNoWindow = true;
                process.StartInfo.WindowStyle = ProcessWindowStyle.Hidden;
                process.StartInfo.WorkingDirectory = Path.GetDirectoryName(ti.ExeFile);
                process.StartInfo.UseShellExecute = false;
                process.StartInfo.Arguments = string.Format(@"--min-width=1024 --delay=1500 --javascript=off --auto-load-images=on --plugins=off --java=off --url={0} --out={1}"
                    , url
                    , destFile
                    );
                process.Start();

                process.WaitForExit();
                process.Close();
            }
        }
        catch (Exception ex)
        {
            Logger.Info(ex.Message);
        }
        FileInfo fi = new FileInfo(destFile);
        if (!fi.Exists || fi.Length < 1024 * 10)
            return;

        Attachment att = new Attachment(destFile);
        att.ContentId = ti.Sid;

        string body = ti.Body.Replace("$SCREENSHOT$", string.Format("<img src=\"cid:{0}\" />", ti.Sid));
        MailMessage mailMessage = new MailMessage();
        mailMessage.From = new MailAddress(ti.Sender);
        mailMessage.To.Add(ti.Receiver);
        mailMessage.Subject = ti.Subject;
        mailMessage.BodyEncoding = Encoding.UTF8;
        mailMessage.IsBodyHtml = true;
        mailMessage.ReplyToList.Add(ti.ReplyTo);
        mailMessage.Attachments.Add(att);
        mailMessage.Body = body;

        string server = ConfigurationManager.AppSettings["SmtpServer"];
        int port = 25;

        if (!string.IsNullOrWhiteSpace(ti.Email_SMTP))
            server = ti.Email_SMTP;
        else if (string.IsNullOrWhiteSpace(server))
            server = "10.0.10.7";

        if (!string.IsNullOrWhiteSpace(ti.Email_Port))
        {
            if (!int.TryParse(ti.Email_Port, out port))
                port = 25;
        }

        using (SmtpClient client = new SmtpClient(server, port))
        {
            client.Send(mailMessage);
        }
    }

}