using BLToolkit.DataAccess;

namespace CE.db
{
    public sealed class ceScalableThumbnail
    {
        [PrimaryKey(1)]
        public string OrginalFileName { get; set; }

        [PrimaryKey(2)]
        public int Width { get; set; }

        [PrimaryKey(3)]
        public int Height { get; set; }

        public string FilePath { get; set; }

        public long? DomainID { get; set; }
    }
}