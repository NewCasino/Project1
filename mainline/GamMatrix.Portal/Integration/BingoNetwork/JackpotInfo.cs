namespace Bingo
{   
    public sealed class JackpotInfo
    {
        public string Name { get; internal set; }
        public decimal Amount { get; internal set; }
        public string Currency { get; internal set; }
        public int RoomID { get; internal set; }
    }
}