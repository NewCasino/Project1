namespace LiveCasino
{
    /// <summary>
    /// Summary description for Winner
    /// </summary>
    public sealed class Winner
    {
        public string DisplayName { get; internal set; }
        public string Username { get; internal set; }
        public string Firstname { get; internal set; }
        public string Lastname { get; internal set; }
        public decimal Price { get; internal set; }
        public string Currency { get; internal set; }
        public CountryInfo CountryInfo { get; internal set; }
    }
}