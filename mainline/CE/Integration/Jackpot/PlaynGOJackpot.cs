namespace Jackpot
{
    public sealed class PlaynGOJackpot
    {
        public int JackpotId { get; set; }
        public string Description { get; set; }
        public long BaseTime { get; set; }
        public decimal BaseAmount { get; set; }
        public string Currency { get; set; }
        public decimal TotalPaid { get; set; }
        public int NumPayouts { get; set; }
    }
}
