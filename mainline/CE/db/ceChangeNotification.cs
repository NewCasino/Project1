using System;
using BLToolkit.DataAccess;

namespace CE.db
{
    /// <summary>
    ///  ceChangeNotification table
    /// </summary>

    public class ceChangeNotification
    {
        [PrimaryKey, NonUpdatable]
        public long ID { get; set; }

        public DateTime Ins { get; set; }

        public long DomainID { get; set; }

        public long HashValue1 { get; set; }

        public long HashValue2 { get; set; }

        public string Type { get; set; }

        public bool Succeeded { get; set; }
    }
}
