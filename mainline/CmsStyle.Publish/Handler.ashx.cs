using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Script.Serialization;
using System.Configuration;
using System.IO;
using System.IO.Compression;
using System.Diagnostics;

using SharpSvn;

namespace CmsStyle.Publish
{
    /// <summary>
    /// Handler 的摘要说明
    /// </summary>
    public class Handler : IHttpHandler
    {

        public void ProcessRequest(HttpContext context)
        {
            JavaScriptSerializer jss = new JavaScriptSerializer();
            string script = string.Empty;
            try
            {
                string type = context.Request.QueryString["type"] ?? "svn";
                bool isMandatory = !string.IsNullOrWhiteSpace(context.Request["mandatory"]);

                string[] targetDirs = new string[] { };

                if (!string.IsNullOrWhiteSpace(context.Request["target"]))
                {
                    if (context.Request["target"].Equals("all", StringComparison.InvariantCultureIgnoreCase))
                    {
                        targetDirs = new string[] { "" };
                    }
                    else
                        targetDirs = context.Request["target"].Split(new char[] { ',' }, StringSplitOptions.RemoveEmptyEntries);
                }

                if (string.Equals(type, "svn", StringComparison.InvariantCultureIgnoreCase))
                    SvnUpdate(isMandatory, targetDirs);
                else if (string.Equals(type, "git", StringComparison.InvariantCultureIgnoreCase))
                    GitUpdate(isMandatory, targetDirs);
                else
                    throw new Exception("Not supported");

                script = jss.Serialize(new
                {
                    @success = true,
                    @error = string.Empty,
                });
            }
            catch (Exception ex)
            {
                script = jss.Serialize(new
                {
                    @success = false,
                    @error = ex.Message,
                });
            }
            context.Response.ContentType = "application/json";
            context.Response.AddHeader("Access-Control-Allow-Origin", "*");
            context.Response.Write(script);
        }

        private void SvnUpdate(bool isMandatory, string[] targetDirs)
        {
            string workingCopyPath = ConfigurationManager.AppSettings["WorkingCopy.Path"];
            string svnUsername = ConfigurationManager.AppSettings["Svn.Username"];
            string svnPassword = ConfigurationManager.AppSettings["Svn.Password"];

            using (SvnClient client = new SvnClient())
            {

                client.Authentication.ForceCredentials(svnUsername, svnPassword);
                client.LoadConfiguration(Path.Combine(Path.GetTempPath(), "sharpsvn"), true);

                SvnPathTarget local = new SvnPathTarget(workingCopyPath);
                SvnInfoEventArgs clientInfo;
                client.GetInfo(local, out clientInfo);

                SvnLockInfo lockInfo = clientInfo.Lock;
                if (lockInfo != null)
                {
                    client.CleanUp(workingCopyPath);
                    lockInfo = clientInfo.Lock;
                    if (lockInfo != null)
                    {
                        client.Unlock(workingCopyPath);
                    }
                }

                SvnUpdateArgs updateArgs = new SvnUpdateArgs();
                updateArgs.AllowObstructions = false;
                updateArgs.Depth = SvnDepth.Infinity;
                updateArgs.IgnoreExternals = false;
                updateArgs.UpdateParents = true;
                updateArgs.Revision = SvnRevision.Head;
                updateArgs.Conflict += new EventHandler<SvnConflictEventArgs>(UpdateArgs_Conflict);

                foreach (string targetDir in targetDirs)
                {
                    string localPath = workingCopyPath + targetDir;
                    if (isMandatory)
                    {
                        ClearFiles(client, localPath, targetDir, 0);
                    }
                    foreach (string file in Directory.GetFiles(localPath, "*.css"))
                    {
                        File.Delete(file);
                    }

                    client.Update(localPath, updateArgs);
                }
            }
        }

        private void ClearFiles(SvnClient client, string localPath, string target, int depth)
        {
            System.Collections.ObjectModel.Collection<SvnListEventArgs> list;

            if (client.GetList(localPath, out list))
            {
                foreach (SvnListEventArgs args in list)
                {
                    if (args.Entry.NodeKind == SvnNodeKind.Directory)
                    {
                        if (!target.Equals(args.Name, StringComparison.InvariantCultureIgnoreCase) && !args.Name.StartsWith("_files"))
                            ClearFiles(client, Path.Combine(localPath, args.Name), args.Name, depth + 1);
                    }
                    else if (depth > 0)
                    {
                        File.Delete(Path.Combine(localPath, args.Name));
                    }
                }
            }
        }

        private void GitUpdate(bool isMandatory, string[] targetDirs)
        {
            foreach (string targetDir in targetDirs)
            {
                string destPath = Path.Combine(ConfigurationManager.AppSettings["WorkingCopy.Path"], targetDir);
                string tempPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "temp");
                if (!Directory.Exists(tempPath))
                    Directory.CreateDirectory(tempPath);
                string zipFile = Path.Combine(tempPath, targetDir + ".zip");

                if (File.Exists(zipFile))
                    File.Delete(zipFile);

                if (Directory.Exists(Path.Combine(tempPath, targetDir)))
                    Directory.Delete(Path.Combine(tempPath, targetDir), true);

                Process process = new Process();
                process.StartInfo.ErrorDialog = false;
                //process.StartInfo.WindowStyle = ProcessWindowStyle.Hidden;
                process.StartInfo.FileName = ConfigurationManager.AppSettings["Git.ExecutePath"];
                process.StartInfo.Arguments = string.Format("archive --format zip --output {0} --remote={1} {2} {3}", zipFile, ConfigurationManager.AppSettings["Git.Repository"], ConfigurationManager.AppSettings["Git.Branch"], targetDir);
                bool state = process.Start();
                process.WaitForExit();

                FileInfo info = new FileInfo(zipFile);
                if (info.Length == 0)
                    throw new Exception("Can't get the files from git repository");

                ZipFile.ExtractToDirectory(zipFile, tempPath);

                XCopy(Path.Combine(tempPath, targetDir), destPath);

                File.Delete(zipFile);
                Directory.Delete(Path.Combine(tempPath, targetDir), true);
            }
        }

        static void XCopy(string source, string target)
        {
            string[] files = Directory.GetFiles(source);
            foreach (var file in files)
            {
                FileInfo info = new FileInfo(file);
                string targetFile = Path.Combine(target, info.Name);
                File.Copy(file, targetFile, true);
            }

            string[] dirs = Directory.GetDirectories(source);
            foreach (var dir in dirs)
            {
                DirectoryInfo info = new DirectoryInfo(dir);
                string targetDir = Path.Combine(target, info.Name);
                if (!Directory.Exists(targetDir))
                    Directory.CreateDirectory(targetDir);
                XCopy(dir, targetDir);
            }
        }

        static void UpdateArgs_Conflict(object sender, SvnConflictEventArgs e)
        {
            e.Choice = SvnAccept.TheirsFull;
        }

        public bool IsReusable
        {
            get
            {
                return false;
            }
        }
    }
}