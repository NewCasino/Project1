using BLToolkit.DataAccess;

namespace CE.db
{
    /// <summary>
    ///  ceDomainConfigItem table
    /// </summary>
    public class ceDomainConfigItem
    {
        [PrimaryKey]
        public long ID { get; set; }

        public long DomainID { get; set; }

        public string ItemName { get; set; }

        public string ItemValue { get; set; }

        public string CountrySpecificCfg { get; set; }
    }


}
