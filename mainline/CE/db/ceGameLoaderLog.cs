using System;
using BLToolkit.DataAccess;
using BLToolkit.Mapping;

namespace CE.db
{
    /// <summary>
    ///  ceGameLoaderLog table
    /// </summary>
    public sealed class ceGameLoaderLog
    {
        [PrimaryKey, Identity, NonUpdatable]
        public long ID { get; set; }

        public long DomainID { get; set; }

        public long UserID { get; set; }

        public long GameID { get; set; }

        public bool IsRealMoneyMode { get; set; }

        public string IPAddress { get; set; }

        public string Iso3166CountryCode { get; set; }

        public string Region { get; set; }

        public string City { get; set; }

        public decimal? Latitude { get; set; }

        public decimal? Longitude { get; set; }

        public string RefererUrl { get; set; }        

        [DefaultValue("GETDATE()")]
        public DateTime Ins { get; set; }
    }
 
}
