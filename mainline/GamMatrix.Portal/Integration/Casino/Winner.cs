using System;

namespace Casino
{
    /// <summary>
    /// Summary description for Winner
    /// </summary>
    [Serializable]
    public sealed class Winner
    {
        public long DomainID { get; set; }
        public string DisplayName { get; set; }
        public string Username { get; set; }
        public string Firstname { get; set; }
        public string Surname { get; set; }
        public decimal Amount { get; set; }
        public string Currency { get; set; }
        public CountryInfo CountryInfo { get; set; }
        public GameID GameID { get; set; }
    }
}