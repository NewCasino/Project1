using System;
using CM.Content;
using CM.db;

namespace Casino
{
    /// <summary>
    /// Summary description for GameRef
    /// </summary>
    [Serializable]
    public sealed class GameRef
    {
        public string ID { get; set; }

        public GameID [] GameIDList { get; set; }


        /// <summary>
        /// Get the group name
        /// </summary>
        /// <param name="site"></param>
        /// <returns></returns>
        public string GetGroupName(cmSite site = null)
        {
            string path = string.Format( GameManager.CATEGORY_METADATA, this.ID);
            path = string.Format( "{0}.Name", path);
            if( site == null )
                return Metadata.Get(path).DefaultIfNullOrEmpty(this.EnglishGroupName);
            return Metadata.Get(site, path, "").DefaultIfNullOrEmpty(this.EnglishGroupName);
        }

        /// <summary>
        /// only for backend serializablation , you should use GetGroupName INSTEAD!
        /// </summary>
        public string EnglishGroupName
        {
            get;
            set;
        }

        
    }
}