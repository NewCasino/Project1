using System;
using BLToolkit.DataAccess;

namespace CM.db
{
    /// <summary>.
    /// Stores a key that is used in e-mails links to verify that a link is correct
    /// </summary>
    public class cmUserKey 
    {
        [Identity, PrimaryKey, NonUpdatable]
        public int ID { get; set; }
        public long UserID { get; set; }
        public int DomainID { get; set; }
        public string KeyType { get; set; }
        public string KeyValue { get; set; }
        public DateTime Expiration { get; set; }
        public string Email { get; set; }

        [NonUpdatable]
        public bool IsDeleted { get; set; }
    }
}
