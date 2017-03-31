using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;
using Renci.SshNet;
using Renci.SshNet.Common;
using Renci.SshNet.Sftp;
namespace CmsAgent.FileManager
{
    public class SftpManager : FileManagerBase
    {
        private string _abKeyFilePath;
        private string KeyFileAbPath
        {
            get
            {
                if (_abKeyFilePath == null)
                {
                    if (Path.IsPathRooted(base.Config.PrivateKeyFileName))
                        _abKeyFilePath = base.Config.PrivateKeyFileName;
                    else
                    {
                        _abKeyFilePath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, base.Config.PrivateKeyFileName);
                    }
                    Logger.Get().AppendFormat("name:{0},privateKeyFilePath:{1}", Config.Name, _abKeyFilePath);
                }
                return _abKeyFilePath;
            }    
        }

        private byte[] _keyFileBytes;
        private Stream NewKeyStream()
        {
            if (_keyFileBytes == null)
            {
               
                using (FileStream stream = new FileStream(KeyFileAbPath, FileMode.Open, FileAccess.Read))
                {
                    _keyFileBytes = new byte[stream.Length];
                    stream.Read(_keyFileBytes, 0, (int)stream.Length);
                }
            }

            return new MemoryStream(_keyFileBytes);
        }

        private bool? _keyFileExists;
        private bool KeyFileExists
        {
            get
            {
                if (_keyFileExists == null)
                {
                    _keyFileExists = File.Exists(KeyFileAbPath);
                    if (!_keyFileExists.Value)
                        Logger.Get().AppendFormat("privateKeyFile:{0} is not exsits", KeyFileAbPath);
                }
                return _keyFileExists.Value;
            }
        }
        private SftpClient GetClient()
        {
            Func<SftpClient> _default = () => new SftpClient(base.Config.Server, base.Config.Port, base.Config.Username, base.Config.Password);
            if (string.IsNullOrEmpty(base.Config.PrivateKeyFileName) || !KeyFileExists)
            {
                return _default();
            }

            if (!string.IsNullOrEmpty(Config.PrivateKeyPassword))
            {
                return new SftpClient(Config.Server, Config.Port, Config.Username, new PrivateKeyFile(NewKeyStream(), Config.PrivateKeyPassword));
            }
            else
            {
                return new SftpClient(Config.Server, Config.Port, Config.Username, new PrivateKeyFile(NewKeyStream()));
            }


        }

        public override async Task Upload(string path, string name, byte[] buffer, bool allowCreateDirectory = true)
        {
            if (base.Config.Folder != "/")
                path = base.Config.Folder + path.TrimStart('/');

            using (var sftp = GetClient())
            using( MemoryStream stream = new MemoryStream(buffer) )
            {
                sftp.Connect();
                try
                {
                    sftp.ChangeDirectory(path);
                }
                catch (SftpPathNotFoundException)
                {
                    string tempPath = "/";
                    string [] parts = path.Split(new char[] { '/' }, StringSplitOptions.RemoveEmptyEntries);
                    for( int i = 0; i < parts.Length; i++){
                        tempPath = string.Format( "{0}{1}/", tempPath, parts[i]);

                        try
                        {
                            sftp.CreateDirectory(tempPath);
                        }
                        catch (SshException)
                        {
                        }
                    }
                    sftp.ChangeDirectory(path);
                }
                sftp.UploadFile(stream, name, true);
                sftp.Disconnect();
            }
        }

       

        public override async Task<List<Tuple<bool, string>>> GetList(string path)
        {
            if (base.Config.Folder != "/")
                path = base.Config.Folder + path.TrimStart('/');

            using (var sftp = GetClient())
            {
                sftp.Connect();
                try
                {
                    var files = sftp.ListDirectory(path);
                    sftp.Disconnect();
                    return files.Where(f => !f.IsDirectory || f.Name != "." && f.Name != "..")
                        .Select(f => new Tuple<bool, string>(f.IsDirectory, f.Name))
                        .ToList();
                }
                catch (SftpPathNotFoundException)
                {
                    return new List<Tuple<bool, string>>();
                }
            }
        }

        public override async Task Delete(string path)
        {
            if (base.Config.Folder != "/")
                path = base.Config.Folder + path.TrimStart('/');

            using (var sftp = GetClient())
            {
                sftp.Connect();
                try
                {
                    sftp.Delete(path);
                }
                catch (SftpPathNotFoundException)
                {
                    
                }
                sftp.Disconnect();
            }
        }


        public override async Task CreateFolder(string path)
        {
            if (base.Config.Folder != "/")
                path = base.Config.Folder + path.TrimStart('/');

            using (var sftp = GetClient())
            {
                sftp.Connect();
                string tempPath = "/";
                string[] parts = path.Split(new char[] { '/' }, StringSplitOptions.RemoveEmptyEntries);
                for (int i = 0; i < parts.Length; i++)
                {
                    tempPath = string.Format("{0}{1}/", tempPath, parts[i]);
                    try
                    {
                        sftp.CreateDirectory(tempPath);
                    }
                    catch (SshException)
                    {
                    }
                }
                sftp.Disconnect();
            }
        }

        public override async Task PrepareUpload(string path, string name, int size)
        {
            if (base.Config.Folder != "/")
                path = base.Config.Folder + path.TrimStart('/');

            using (var sftp = GetClient())
            {
                sftp.Connect();

                try
                {
                    sftp.ChangeDirectory(path);
                }
                catch (SftpPathNotFoundException)
                {
                    string tempPath = "/";
                    string[] parts = path.Split(new char[] { '/' }, StringSplitOptions.RemoveEmptyEntries);
                    for (int i = 0; i < parts.Length; i++)
                    {
                        tempPath = string.Format("{0}{1}/", tempPath, parts[i]);

                        try
                        {
                            sftp.CreateDirectory(tempPath);
                        }
                        catch (SshException)
                        {
                        }
                    }
                    sftp.ChangeDirectory(path);
                }

                try
                {
                    sftp.DeleteFile(name);
                }
                catch (SftpPathNotFoundException)
                {
                }

                sftp.Disconnect();
            }
        }

        public override async Task PartialUpload(string path, string name, int offset, byte[] buffer)
        {
            if (base.Config.Folder != "/")
                path = base.Config.Folder + path.TrimStart('/');

            using (var sftp = GetClient())
            {
                sftp.Connect();

                sftp.ChangeDirectory(path);

                if (offset == 0)
                {
                    using (MemoryStream ms = new MemoryStream(buffer))
                    {
                        sftp.UploadFile(ms, name);
                    }
                }
                else
                {
                    path = path.TrimEnd('/');
                    path = string.Format("{0}/{1}", path, name);
                    using (SftpFileStream stream = sftp.Open(path, FileMode.Append, FileAccess.Write))
                    {
                        await stream.WriteAsync(buffer, 0, buffer.Length);
                        await stream.FlushAsync();
                    }
                }
                
                sftp.Disconnect();
            }
        }
    }
}
