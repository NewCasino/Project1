using System.IO;
using System.Text.RegularExpressions;
using System.Web;
using System.Web.Hosting;
using CM.db;
using CM.Sites;

namespace CM.Web
{
    /// <summary>
    /// Inherited from VirtualFile, provide the ability to implement url rewritting for different operator
    /// </summary>
    public sealed class VirtualFileEx : VirtualFile
    {
        /// <summary>
        /// Get physical file path
        /// </summary>
        /// <param name="path">path</param>
        /// <returns>physical file path</returns>
        internal static string GetPhysicalFilePath(string path)
        {
            string appRelativePath = VirtualPathUtility.ToAppRelative(path).TrimStart('~');
            if (appRelativePath.StartsWith("/") &&
                !appRelativePath.StartsWith("/Views/") &&
                Regex.IsMatch(appRelativePath, @"(\.\w+)$", RegexOptions.Compiled))
            {
                cmSite domain = SiteManager.Current;
                if (domain != null && HttpContext.Current != null)
                {
                    string newPath = HostingEnvironment.MapPath(string.Format("~/Views/{0}{1}", domain.DistinctName, appRelativePath));
                    if (File.Exists(newPath))
                        return newPath;

                    if (!string.IsNullOrWhiteSpace(domain.TemplateDomainDistinctName))
                    {
                        newPath = HostingEnvironment.MapPath(string.Format("~/Views/{0}{1}", domain.TemplateDomainDistinctName, appRelativePath));
                        if( File.Exists(newPath) )
                            return newPath;
                    }
                }
            }
            return null;
        }


        private string PhysicalFilePath { get; set; }

        /// <summary>
        /// constructor
        /// </summary>
        /// <param name="virtualPath">virtual path</param>
        public VirtualFileEx(string virtualPath)
            : base(virtualPath)
        {
            this.PhysicalFilePath = GetPhysicalFilePath(virtualPath);
        }

        /// <summary>
        /// override the Open method
        /// </summary>
        /// <returns></returns>
        public override Stream Open()
        {
            if (this.PhysicalFilePath == null)
                return null;

            return new MemoryStream(ReadFileToBuffer());
        }

        private byte[] ReadFileToBuffer()
        {
            using (FileStream fs = new FileStream(this.PhysicalFilePath, FileMode.Open, FileAccess.Read, FileShare.ReadWrite | FileShare.Delete))
            {
                byte[] buffer = new byte[fs.Length];
                int total = 0;
                for (; ; )
                {
                    int count = fs.Read(buffer, total, buffer.Length - total);
                    total += count;
                    if (count == 0 || total >= buffer.Length) break;
                    
                }
                return buffer;
            }
        }
    }
}
