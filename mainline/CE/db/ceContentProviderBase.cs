using System;
using BLToolkit.DataAccess;

namespace CE.db
{
    public sealed class ceContentProviderBase
    {
        [PrimaryKey, Identity, NonUpdatable]
        public int ID { get; set; }

        public string Identifying { get; set; }

        public int DomainID { get; set; }

        public string Name { get; set; }

        public string Logo { get; set; }

        public bool Enabled { get; set; }

        public DateTime Ins { get; set; }
    }
}
