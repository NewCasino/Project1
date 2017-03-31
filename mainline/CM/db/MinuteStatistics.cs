namespace CM.db
{
    public sealed class MinuteStatistics
    {
        public long MinuteStamp { get; set; }
        public long TotalRequestNumber { get; set; }
        public float AvgExecutionSeconds { get; set; }
        public float EightyPercentAvgExecutionSeconds { get; set; }
        public float NinetyPercentAvgExecutionSeconds { get; set; }
        public float StandardDeviation { get; set; }
    }
}
