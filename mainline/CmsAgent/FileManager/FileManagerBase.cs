using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Configuration;

namespace CmsAgent.FileManager
{
    public abstract class FileManagerBase
    {
        public StaticFileHostConfigElement Config { get; set; }

        private static List<FileManagerBase> _allManagers;
        private static Func<List<FileManagerBase>> _getAllManagers = () =>
        {
            List<FileManagerBase> clients = new List<FileManagerBase>();
            StaticFileHostSection section = ConfigurationManager.GetSection("staticFileHost") as StaticFileHostSection;
            for (int i = 0; i < section.Collection.Count; i++)
            {
                var elem = section.Collection[i];
                FileManagerBase client;
                switch (elem.Protocol.ToLowerInvariant())
                {
                    case "ftp":
                        client = new FtpManager();
                        break;

                    case "sftp":
                        client = new SftpManager();
                        break;

                    default:
                        throw new NotSupportedException("the protocol is not supported");
                }
                client.Config = elem;
                clients.Add(client);
            }
            return clients;
        };

        private static int _init = 0;
        private static List<FileManagerBase> AllManagers
        {
            get
            {
                if (_allManagers == null)
                {
                    if (_init == 0)
                    {
                        Interlocked.Increment(ref _init);
                        _allManagers = _getAllManagers();
                    }
                }
                return _allManagers;
            }
        }
        public static List<FileManagerBase> GetAllManagers(string distinctName = null,int domainID = 0)
        {
            /*
             when domainid is 1000, it's [CMS Console] so return all .
             */
            if (domainID == 1000)
                return AllManagers;


            return AllManagers.Where(f =>
                (string.IsNullOrEmpty(f.Config.DistinctName) && f.Config.DomainID == 0)
                ||
                (distinctName != null && distinctName.Equals(f.Config.DistinctName)
                ||
                (domainID != 0 && domainID.Equals(f.Config.DomainID))
            )).ToList();

        }


        public static FileManagerBase GetPrimaryManager(string distinctName = null,int domainID = 0)
        {
            FileManagerBase client = null;
            if (distinctName != null)
            {
                client = AllManagers.FirstOrDefault(f => distinctName.Equals(f.Config.DistinctName, StringComparison.InvariantCultureIgnoreCase));
            }
            else if (domainID != 0)
            {
                client = AllManagers.FirstOrDefault(f => domainID.Equals(f.Config.DomainID));
            }
            if (client == null)
                client = AllManagers.FirstOrDefault(f => f.Config.IsPrimary && string.IsNullOrEmpty(f.Config.DistinctName));


            if (client != null)
                return client;

            throw new Exception("No primary host is found");
        }


        public abstract Task Upload(string path, string name, byte[] buffer, bool allowCreateDirectory = true);


        public abstract Task PrepareUpload(string path, string name, int size);

        public abstract Task PartialUpload(string path, string name, int offset, byte[] buffer);

        /// <summary>
        /// Get the list within certain directory
        /// </summary>
        /// <param name="path">the directory path</param>
        /// <returns>a list of the files and directories, the boolean indicates if it is a directory, the string represents the filename</returns>
        public abstract Task<List<Tuple<bool, string>>> GetList(string path);


        /// <summary>
        /// Delete a specific file or folder
        /// </summary>
        /// <param name="path"></param>
        /// <returns></returns>
        public abstract Task Delete(string path);

        public abstract Task CreateFolder(string path);
    }
}
