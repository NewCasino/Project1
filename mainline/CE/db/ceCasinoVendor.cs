using System;
using BLToolkit.DataAccess;

namespace CE.db
{
    /// <summary>
    ///  ceCasinoVendor table
    /// </summary>
    /// 
    [TableName("CeCasinoVendor")]
    public sealed class ceCasinoVendor
    {
        [PrimaryKey, Identity, NonUpdatable]
        public long ID { get; set; }

        public long DomainID { get; set; }

        public int VendorID { get; set; }

        public decimal BonusDeduction { get; set; }

        public string RestrictedTerritories { get; set; }

        public bool Enabled { get; set; }

        public DateTime Ins { get; set; }

        public bool EnableGmGamingAPI { get; set; }

        public bool EnableLogging { get; set; }

        public string Languages { get; set; }

        public string Currencies { get; set; }
    }
 
}
