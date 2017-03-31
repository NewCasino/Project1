using System;
using BLToolkit.DataAccess;
using BLToolkit.Mapping;
using GamMatrixAPI;

namespace CE.db
{
    /// <summary>
    ///  ceCasinoJackpotBase table
    /// </summary>
    public class ceCasinoJackpotBase
    {
        [PrimaryKey, Identity, NonUpdatable]
        public long ID { get; set; }

        public long DomainID { get; set; }

        public VendorID VendorID { get; set; }

        public string Name { get; set; }

        public string GameIDs { get; set; }

        public string HiddenGameIDs { get; set; }

        public string CustomVendorConfig { get; set; }

        public bool IsFixedAmount { get; set; }

        public string BaseCurrency { get; set; }

        public decimal? Amount { get; set; }

        public string MappedJackpotID { get; set; }

        public long SessionUserID { get; set; }

        public bool IsDeleted { get; set; }

        [DefaultValue("GETDATE()")]
        public DateTime Ins { get; set; }
    }
    public class ceCasinoJackpotBaseEx : ceCasinoJackpotBase
    {
        public long BaseID { get; set; }
        public long JackpotID { get; set; }
    }
 
}
