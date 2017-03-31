using System;
using System.Globalization;
using System.IO;
using System.Runtime.CompilerServices;

namespace CE.Integration.Metadata
{
    public static class MetadataFileCache
    {
        public static string GetPath<T>(string domainName, [CallerMemberName] string property = null)
        {
            string dir = Path.Combine(AppDomain.CurrentDomain.BaseDirectory
                , "metadatacache"
                , domainName
                );
            //if (!Directory.Exists(dir))
            //    Directory.CreateDirectory(dir);

            return Path.Combine(dir, string.Format("{0}.{1}", typeof(T).FullName, property));
        }

        public static string GetPathWithRegion<T>(string domainName, string region, [CallerMemberName] string property = null)
        {
            string dir = Path.Combine(AppDomain.CurrentDomain.BaseDirectory
                , "metadatacache"
                , domainName
                );
            //if (!Directory.Exists(dir))
            //    Directory.CreateDirectory(dir);

            return Path.Combine(dir, string.Format("{0}.{1}.{2}", typeof(T).FullName, property, region));
        }

        public static void ClearCache(long domainID)
        {
            if (domainID == Constant.SystemDomainID)
            {
                string cacheFile = Path.Combine(AppDomain.CurrentDomain.BaseDirectory
                    , "metadatacache"
                    );
                CacheManager.ClearCache(cacheFile);
            }
            else
            {
                string cacheFile = Path.Combine(AppDomain.CurrentDomain.BaseDirectory
                    , "metadatacache"
                    , domainID.ToString(CultureInfo.InvariantCulture)
                    );
                CacheManager.ClearCache(cacheFile);
            }
        }

        public static string GetCachePrefixKey(long domainID)
        {
            if (domainID == Constant.SystemDomainID)
            {
                string cacheFile = Path.Combine(AppDomain.CurrentDomain.BaseDirectory
                    , "metadatacache"
                    );
                return cacheFile;
            }
            else
            {
                string cacheFile = Path.Combine(AppDomain.CurrentDomain.BaseDirectory
                    , "metadatacache"
                    , domainID.ToString(CultureInfo.InvariantCulture)
                    );
                return cacheFile;
            }
        }

    }
}
