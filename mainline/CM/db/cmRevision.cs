using System;
using BLToolkit.DataAccess;

namespace CM.db
{

    /// <summary>
    /// object mapped to database cmRevision table
    /// </summary>
    [Serializable]
    public class cmRevision
    {
        public cmRevision()
        {
        }

        /// <summary>
        /// Field ID
        /// </summary>
        [PrimaryKey, Identity]
        public int                      ID                      { get; set; }

        /// <summary>
        /// Field Ins
        /// </summary>
        public DateTime                 Ins                     { get; set; }

        /// <summary>
        /// Field UserID
        /// </summary>
        public int                      UserID                  { get; set; }

        /// <summary>
        /// Field SiteID
        /// </summary>
        public int                      SiteID                  { get; set; }

        /// <summary>
        /// Field RelativePath
        /// </summary>
        public string                   RelativePath            { get; set; }

        /// <summary>
        /// Field Comments
        /// </summary>
        public string                   Comments                { get; set; }

        /// <summary>
        /// Field FilePath
        /// </summary>
        public string                   FilePath                { get; set; }

        /// <summary>
        /// Field Username
        /// </summary>
        [NonUpdatable]
        public string                   Username                { get; set; }

        /// <summary>
        /// Field DomainDistinctName
        /// </summary>
        [NonUpdatable]
        public string                   DomainDistinctName      { get; set; }
       
    }
}
