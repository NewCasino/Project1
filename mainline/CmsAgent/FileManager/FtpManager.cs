using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using System.Net;
using System.IO;
using System.Net.FtpClient;

namespace CmsAgent.FileManager
{
    public class FtpManager : FileManagerBase
    {
        public override async Task Upload(string path, string name, byte[] buffer, bool allowCreateDirectory = true)
        {
            Exception exception = null;
            bool directoryNotExist = false;
            try
            {
                if (base.Config.Folder != "/")
                    path = base.Config.Folder + path.TrimStart('/');

                string url = string.Format("{0}://{1}:{2}/{3}/{4}"
                    , base.Config.Protocol
                    , base.Config.Server
                    , base.Config.Port
                    , path.Trim('/')
                    , name
                    );

                FtpWebRequest request = (FtpWebRequest)WebRequest.Create(url);
                request.UseBinary = true;
                request.Method = WebRequestMethods.Ftp.UploadFile;
                request.ContentLength = buffer.Length;
                request.Credentials = new NetworkCredential(base.Config.Username, base.Config.Password);
                Stream requestStream = await request.GetRequestStreamAsync();
                await requestStream.WriteAsync(buffer, 0, buffer.Length);
                requestStream.Close();
                await request.GetResponseAsync();
                return;
            }
            catch (WebException ex)
            {
                exception = ex;
                FtpWebResponse response = ex.Response as FtpWebResponse;
                if( response != null )
                {
                    if (response.StatusCode == FtpStatusCode.ActionNotTakenFilenameNotAllowed)
                    {
                        // directory not exist
                        directoryNotExist = true;
                    }
                }
            }

            if (directoryNotExist && allowCreateDirectory)
            {
                await CreateDir(path);
                await Upload(path, name, buffer);
            }
            else
            {
                throw exception;
            }
        }

        private async Task CreateDir(string path)
        {
            if (base.Config.Folder != "/")
                path = base.Config.Folder + path.TrimStart('/');

            string url = string.Format("{0}://{1}:{2}/"
                , base.Config.Protocol
                , base.Config.Server
                , base.Config.Port
                );

            string[] parts = path.Split(new char[] { '/' }, StringSplitOptions.RemoveEmptyEntries);
            for (int i = 0; i < parts.Length; i++)
            {
                try
                {
                    url += parts[i] + "/";
                    FtpWebRequest request = (FtpWebRequest)WebRequest.Create(url);
                    request.Method = WebRequestMethods.Ftp.MakeDirectory;
                    request.Credentials = new NetworkCredential(base.Config.Username, base.Config.Password);
                    await request.GetResponseAsync();
                }
                catch (WebException ex)
                {
                    FtpWebResponse response = ex.Response as FtpWebResponse;
                    if (response != null)
                    {
                        // Direcotry already exist
                        if (response.StatusCode == FtpStatusCode.ActionNotTakenFileUnavailable)
                        {
                            continue;
                        }
                    }
                    throw;
                }
            }
        }


        public override async Task<List<Tuple<bool, string>>> GetList(string path)
        {
            if (base.Config.Folder != "/")
                path = base.Config.Folder + path.TrimStart('/');

            using (FtpClient client = new FtpClient())
            {
                client.Host = base.Config.Server;
                client.Port = base.Config.Port;
                client.Credentials = new NetworkCredential(base.Config.Username, base.Config.Password);
                client.Connect();

                FtpListItem[] files = client.GetListing(path, FtpListOption.AllFiles);
                client.Disconnect();
                return files
                    .Where(f => f.Name != "." && f.Name != "..")
                    .Select(f => new Tuple<bool, string>(f.Type == FtpFileSystemObjectType.Directory, f.Name))
                    .ToList();
            }
        }


        public override async Task Delete(string path)
        {
            if (base.Config.Folder != "/")
                path = base.Config.Folder + path.TrimStart('/');

            using (FtpClient client = new FtpClient())
            {
                client.Host = base.Config.Server;
                client.Port = base.Config.Port;
                client.Credentials = new NetworkCredential(base.Config.Username, base.Config.Password);
                client.Connect();

                try
                {
                    client.DeleteFile(path);
                }
                catch (FtpCommandException)
                {
                }

                try
                {
                    client.DeleteDirectory(path);
                }
                catch (FtpCommandException)
                {
                }
                client.Disconnect();
            }
        }

        public override async Task CreateFolder(string path)
        {
            if (base.Config.Folder != "/")
                path = base.Config.Folder + path.TrimStart('/');

            using (FtpClient client = new FtpClient())
            {
                client.Host = base.Config.Server;
                client.Port = base.Config.Port;
                client.Credentials = new NetworkCredential(base.Config.Username, base.Config.Password);
                client.Connect();

                client.CreateDirectory(path);
                client.Disconnect();
            }
        }


        public override async Task PrepareUpload(string path, string name, int size)
        {
            if (base.Config.Folder != "/")
                path = base.Config.Folder + path.TrimStart('/');

            using (FtpClient client = new FtpClient())
            {
                client.Host = base.Config.Server;
                client.Port = base.Config.Port;
                client.Credentials = new NetworkCredential(base.Config.Username, base.Config.Password);
                client.Connect();

                if (!client.DirectoryExists(path))
                {
                    string [] parts = path.Split(new char[] { '/' }, StringSplitOptions.RemoveEmptyEntries);
                    string temp = "/";
                    for( int i = 0; i < parts.Length; i++){
                        temp += parts[i] + "/";
                        client.CreateDirectory(temp);
                    }
                }

                client.SetWorkingDirectory(path);

                if (client.FileExists(name))
                {
                    client.DeleteFile(name);
                }

                client.Disconnect();
            }
        }

        public override async Task PartialUpload(string path, string name, int offset, byte[] buffer)
        {
            if (base.Config.Folder != "/")
                path = base.Config.Folder + path.TrimStart('/');

            using (FtpClient client = new FtpClient())
            {
                client.Host = base.Config.Server;
                client.Port = base.Config.Port;
                client.Credentials = new NetworkCredential(base.Config.Username, base.Config.Password);
                client.Connect();

                path = path.TrimEnd('/');
                path = string.Format("{0}/{1}", path, name);

                Stream stream;
                if (offset > 0)
                {
                    if (client.GetFileSize(path) != offset)
                        throw new Exception("Incorrect file offset");
                    stream = client.OpenAppend(path, FtpDataType.Binary);
                }
                else
                {
                    if (client.FileExists(path))
                        throw new Exception("File already exists");
                    stream = client.OpenWrite(path, FtpDataType.Binary);
                }

                using (stream)
                {
                    stream.Write(buffer, 0, buffer.Length);
                    stream.Flush();
                    stream.Close();
                }

                client.Disconnect();
            }
        }
    }
}
