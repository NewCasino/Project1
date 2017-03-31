using System;
using BLToolkit.DataAccess;

namespace CM.db
{
    [Serializable]
    public sealed class cmLiveCasinoFavoriteTable
    {
        [Identity, PrimaryKey, NonUpdatable]
        public long ID { get; set; }
        public long DomainID { get; set; }
        public long UserID { get; set; }
        public string TableID { get; set; }
        public DateTime Ins { get; set; }
    }
}
