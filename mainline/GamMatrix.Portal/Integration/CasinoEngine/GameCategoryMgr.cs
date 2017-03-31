using System.IO;
using System.Runtime.Serialization.Formatters.Binary;
using System.Web;
using System.Web.Caching;
using System.Web.Hosting;
using CM.Content;
using CM.db;
using CM.Sites;
using GamMatrix.Infrastructure;

namespace CasinoEngine
{
    /// <summary>
    /// Summary description for GameCategoryMgr
    /// </summary>
    public static class GameCategoryMgr
    {
        public const string CATEGORY_TRANSLATION_PATH = @"/Metadata/_CasinoEngine/Category/{0}";
        public const string AVAILABLE_CATEGORY_PATH = @"~/App_Data/{0}_categories.dat";

        /// <summary>
        /// Get the display name for the game category
        /// </summary>
        /// <param name="gameCategory"></param>
        /// <returns></returns>
        public static string GetDisplayName(this GameCategory gameCategory)
        {
            string path = string.Format(CATEGORY_TRANSLATION_PATH, gameCategory.ToString());
            return Metadata.Get(path + ".DisplayName").DefaultIfNullOrEmpty(gameCategory.ToString());
        }

        /// <summary>
        /// Get the display name for the game category
        /// </summary>
        /// <param name="gameCategory"></param>
        /// <returns></returns>
        public static string GetDisplayName(string gameCategory)
        {
            string path = string.Format(CATEGORY_TRANSLATION_PATH, gameCategory);
            return Metadata.Get(path + ".DisplayName").DefaultIfNullOrEmpty(gameCategory);
        }

        /// <summary>
        /// Get available categories
        /// </summary>
        /// <param name="site"></param>
        /// <returns></returns>
        public static string[] GetAvailableCategories(cmSite site = null)
        {
            if (site == null)
                site = SiteManager.Current;
            string path = string.Format(AVAILABLE_CATEGORY_PATH, site.DistinctName);
            string[] categories = HttpRuntime.Cache[path] as string[];
            if (categories != null)
                return categories;

            try
            {
                string physicalPath = HostingEnvironment.MapPath(path);
                if (File.Exists(physicalPath))
                {
                    using (FileStream fs = new FileStream(physicalPath
                    , FileMode.Open
                    , FileAccess.Read
                    , FileShare.Delete | FileShare.ReadWrite)
                    )
                    {
                        BinaryFormatter bf = new BinaryFormatter();
                        categories = (string[])bf.Deserialize(fs);
                    }
                    HttpRuntime.Cache.Insert(path
                        , categories
                        , new CacheDependencyEx(new string[] { physicalPath }, false) 
                        , Cache.NoAbsoluteExpiration 
                        , Cache.NoSlidingExpiration
                        );
                    return categories;
                }
            }
            catch
            {
            }

            return new string[0];
        }

        /// <summary>
        /// Save avaukavke categories
        /// </summary>
        /// <param name="site"></param>
        /// <param name="categories"></param>
        public static void SetAvailableCategories(cmSite site, string[] categories)
        {
            string path = string.Format(AVAILABLE_CATEGORY_PATH, site.DistinctName);
            using (FileStream fs = new FileStream(HostingEnvironment.MapPath(path)
                , FileMode.OpenOrCreate
                , FileAccess.Write
                , FileShare.Delete | FileShare.ReadWrite)
                )
            {
                fs.SetLength(0);
                BinaryFormatter bf = new BinaryFormatter();
                bf.Serialize(fs, categories);
                fs.Flush();
                fs.Close();
            }
        }
    }
}