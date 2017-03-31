using System;

namespace CE.db
{
    public sealed class dwWinner
    {
        public int VendorID { get; set; }
        public long DomainID { get; set; }
        public long UserID { get; set; }
        public string Username { get; set; }
        public string Currency { get; set; }
        public decimal Amount { get; set; }

        public string GameCode { get; set; }

        public string Firstname { get; set; }
        public string Surname { get; set; }
        public string CountryCode { get; set; }

        public DateTime? WinTime;
    }
}