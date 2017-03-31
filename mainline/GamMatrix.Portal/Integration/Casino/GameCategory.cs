using System;
using CM.Content;
using CM.db;

namespace Casino
{
    /// <summary>
    /// Summary description for GameCategory
    /// </summary>
    [Serializable]
    public sealed class GameCategory
    {
        public string ID { get; set; }

        
        /// <summary>
        /// only for serializablization, you should use GetName INSTEAD!
        /// </summary>
        public string EnglishName { get; set; }

        public GameRef [] GameRefs { get; set; }

        public GameCategory()
        {
        }

        /// <summary>
        /// Get the name
        /// </summary>
        /// <param name="site"></param>
        /// <returns></returns>
        public string GetName(cmSite site = null)
        {
            string path = string.Format(GameManager.CATEGORY_METADATA, this.ID);
            path = string.Format("{0}.Name", path);
            if (site == null)
                return Metadata.Get(path).DefaultIfNullOrEmpty(this.EnglishName);
            return Metadata.Get(site, path, "").DefaultIfNullOrEmpty(this.EnglishName);
        }
    }
}