using System;
using System.Collections.Generic;
using System.IO;
using System.Web;
using System.Web.Caching;
using System.Web.Hosting;

namespace GamMatrix.Infrastructure
{
    public sealed class CacheDependencyEx : CacheDependency
    {
        public CacheDependencyEx(string[] paths, bool isVirtualPath)
            : base(ConvertPath(paths, isVirtualPath))
        {
        }

        private static string[] ConvertPath(string[] paths, bool isVirtualPath)
        {

            if (isVirtualPath)
            {
                for (int i = 0; i < paths.Length; i++)
                {
                    paths[i] = HostingEnvironment.MapPath(paths[i]);
                    paths[i] = GetExistingPath(paths[i]);
                }
            }
            else
            {
                for (int i = 0; i < paths.Length; i++)
                {
                    paths[i] = GetExistingPath(paths[i]);
                }
            }

            return paths;
        }

        private static string GetExistingPath(string path)
        {
            FileInfo fl = new FileInfo(path);
            if ((int)fl.Attributes != -1)
                return path;

            return GetExistingPath(Path.GetDirectoryName(path));
        }
    }
}

