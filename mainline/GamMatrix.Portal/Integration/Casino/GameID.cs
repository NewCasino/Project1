using GamMatrixAPI;

namespace Casino
{
    /// <summary>
    /// Summary description for GameID
    /// </summary>
    public sealed class GameID
    {
        public VendorID VendorID { get; set; }
        public string ID { get; set; }

        public GameID()
        {
        }

        public GameID(VendorID vendorID, string id)
        {
            VendorID = vendorID;
            ID = id;
        }

        public override string ToString()
        {
            return string.Format("{0}_{1}", VendorID, ID);
        }
    }
}