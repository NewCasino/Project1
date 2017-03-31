using BLToolkit.DataAccess;

namespace CM.db
{
    /// <summary>
    /// Region / State
    /// </summary>
    public class cmRegion
    {
        [Identity, PrimaryKey, NonUpdatable]
        public int              ID                  { get; set; }
        public int              CountryID           { get; set; }

        public string           RegionName          { get; set; }
    }
}
