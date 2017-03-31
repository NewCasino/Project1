namespace CE.Models
{
    public sealed class MicrogamingNanoGameSessionInfo
    {
        public decimal Balance { get; set; }
        public string UserType { get; set; }
        public string SessionId { get; set; }
        public string Token { get; set; }
        public string LocalConnectionID { get; set; }
    }
}