using System;
using BLToolkit.DataAccess;

namespace CM.db
{
    public class cmUserPromotion
    {
        [Identity, PrimaryKey, NonUpdatable]
        public int ID { get; set; }

        public int UserID { get; set; }

        [NonUpdatable]
        public string UserName { get; set; }
        [NonUpdatable]
        public string Email { get; set; }
        public int SiteID { get; set; }
        public string TargetSource { get; set; }
        public DateTime ClickDate { get; set; }
    }
}
