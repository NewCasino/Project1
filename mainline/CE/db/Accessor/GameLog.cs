using System;
using System.Collections.Generic;

namespace CE.db.Accessor
{
    public enum GameLogOperationType
    {
        Create = 1,
        Update = 2,
    }
    public class GameLog
    {
        public long GameID { get; set; }
        public DateTime Time { get; set; }
        public long UserID { get; set; }
        public string Username { get; set; }
        public long DomainID { get; set; }
        public Dictionary<string, object[]> Changes { get; set; }
        public GameLogOperationType OperationType { get; set; }
    }
}
