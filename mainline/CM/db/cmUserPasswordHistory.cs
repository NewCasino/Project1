using System;

namespace CM.db
{
    public class cmUserPasswordHistory
    {
        public int ID { get; set; }
        public int DomainID { get; set; }
        public string Password { get; set; }
        public DateTime Ins { get; set; }
    }
}
