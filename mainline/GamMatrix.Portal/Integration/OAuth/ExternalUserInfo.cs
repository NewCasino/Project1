using System;

namespace OAuth
{
    public sealed class ExternalUserInfo
    {
        public string ID { get; set; }
        public string Username { get; set; }
        public string Firstname { get; set; }
        public string Lastname { get; set; }
        public DateTime? Birth { get; set; }
        public string Email { get; set; }
        public bool? IsFemale { get; set; }
    }
}
