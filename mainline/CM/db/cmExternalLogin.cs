using System;
using BLToolkit.DataAccess;

namespace CM.db
{
    /// <summary>
    ///cmExternalLogin
    /// </summary>
    [Serializable]
    public class cmExternalLogin
    {
        [PrimaryKey]
        public int ID { get; set; }
        public int UserID { get; set; }
        public int DomainID { get; set; }
        public int AuthParty { get; set; }
        public string ExternalID { get; set; }
        public DateTime Ins { get; set; }
    }
}
