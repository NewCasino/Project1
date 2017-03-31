using System;
using System.Collections;
using System.Security.Permissions;
using System.Web;
using System.Web.Caching;
using System.Web.Hosting;

namespace CM.Web
{

    [AspNetHostingPermission(SecurityAction.Demand, Level = AspNetHostingPermissionLevel.Medium)]
    [AspNetHostingPermission(SecurityAction.InheritanceDemand, Level = AspNetHostingPermissionLevel.High)]
    public sealed class VirtualPathProviderEx : VirtualPathProvider
    {
        public static void Register()
        {
           // HostingEnvironment.RegisterVirtualPathProvider(new VirtualPathProviderEx());
        }

        public VirtualPathProviderEx() : base() { }

        private bool IsThemeDirectory(string virtualPath)
        {
            String checkPath = VirtualPathUtility.ToAppRelative(virtualPath);
            return checkPath.StartsWith("~/App_Themes", StringComparison.InvariantCultureIgnoreCase);
        }

        public override VirtualDirectory GetDirectory(string virtualDir)
        {
            if (IsThemeDirectory(virtualDir))
            {
                return new ThemeDirectory(Previous.GetDirectory(virtualDir));
            }
            else
            {
                return Previous.GetDirectory(virtualDir);
            }
        }

        
        /// <summary>
        /// if the requested file is not exist, verify if the file /Views/{operator}/{path} exist
        /// </summary>
        /// <param name="virtualPath"></param>
        /// <returns></returns>
        public override bool FileExists(string virtualPath)
        {
            bool isExist = Previous.FileExists(virtualPath);

            if (!isExist )
            {
                isExist = VirtualFileEx.GetPhysicalFilePath(virtualPath) != null;
            }
            return isExist;
        }

        public override VirtualFile GetFile(string virtualPath)
        {
            bool isExist = Previous.FileExists(virtualPath);
            if (isExist)
                return Previous.GetFile(virtualPath);
            return new VirtualFileEx(virtualPath);
        }

        public override CacheDependency GetCacheDependency(string virtualPath, IEnumerable virtualPathDependencies, DateTime utcStart)
        {
            bool isExist = Previous.FileExists(virtualPath);
            if (isExist)
                return Previous.GetCacheDependency(virtualPath, virtualPathDependencies, utcStart);

            // multi domain - same file???
            string physicalFilePath = VirtualFileEx.GetPhysicalFilePath(virtualPath);
            if (!string.IsNullOrEmpty(physicalFilePath))
                return new CacheDependency(physicalFilePath);

            return null;
        }

    }

}
