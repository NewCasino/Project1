using System;
using BLToolkit.DataAccess;

namespace CE.db
{
    public sealed class ceContentProvider
    {
        [PrimaryKey, Identity, NonUpdatable]
        public int ID { get; set; }

        public int ContentProviderBaseID { get; set; }

        public long DomainID { get; set; }

        public string Logo { get; set; }

        public bool? Enabled { get; set; }

        public DateTime Ins { get; set; }
    }
}