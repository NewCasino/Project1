using System;

namespace Bingo
{
    public sealed class Winner
    {
        public string Currency { get; internal set; }
        public decimal Amount { get; internal set; }
        public DateTime DateWon { get; internal set; }
        public long UserID { get; internal set; }
        public string NickName { get; internal set; }
        public string AvatarUrl { get; internal set; }
        public string City { get; internal set; }
    }
}