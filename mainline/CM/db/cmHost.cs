using System;
using BLToolkit.DataAccess;

namespace CM.db
{
    /// <summary>
    /// class cmHost is an object mapped to database cmHost table
    /// </summary>
    [Serializable]
    public sealed class cmHost
    {
        /// <summary>
        /// Field HostID
        /// </summary>
        [Identity, PrimaryKey, NonUpdatable]
        public int HostID { get; set; }

        /// <summary>
        /// Field SiteID
        /// </summary>
        public int SiteID { get; set; }

        /// <summary>
        /// Field HostName
        /// </summary>
        public string HostName { get; set; }

        /// <summary>
        /// Field DefaultCulture
        /// </summary>
        public string DefaultCulture { get; set; }
    }
}
