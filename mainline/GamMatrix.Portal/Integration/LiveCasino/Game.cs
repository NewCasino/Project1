using System.Collections.Generic;
using System.Text.RegularExpressions;

namespace LiveCasino
{
    /// <summary>
    /// Summary description for Game
    /// </summary>
    public sealed class Game
    {
        public string GameID { get; internal set; }
        public GameType GameType { get; internal set; }
        public string GameName { get; internal set; }
        public string ConnectionUrl { get; internal set; }
        public string WindowParams { get; internal set; }
        public string OpenHour { get; internal set; }
        public string CloseHour { get; internal set; }
        public string DealerName { get; internal set; }
        public string DealerImageUrl { get; internal set; }

        public bool IsOpen { get; internal set; }

        public List<LimitSet> LimitSets { get; private set; }

        public Game()
        {
            this.LimitSets = new List<LimitSet>();
        }

        public string GetOpenHour()
        {
            Match m = Regex.Match(this.OpenHour, @"(?<hour>\d+)\:(?<minute>\d+)", RegexOptions.ECMAScript);
            if( m.Success )
            {
                int hour = int.Parse(m.Groups["hour"].Value);
                int minute = int.Parse(m.Groups["minute"].Value);
                return string.Format("GMT {0:00}:{1:00} {2}"
                    , (hour > 12) ? (hour - 12) : hour
                    , minute
                    , (hour > 12) ? "PM" : "AM"
                    );
            }
            return string.Empty;
        }

        public string GetCloseHour()
        {
            Match m = Regex.Match(this.CloseHour, @"(?<hour>\d+)\:(?<minute>\d+)", RegexOptions.ECMAScript);
            if (m.Success)
            {
                int hour = int.Parse(m.Groups["hour"].Value);
                int minute = int.Parse(m.Groups["minute"].Value);
                return string.Format("GMT {0:00}:{1:00} {2}"
                    , (hour > 12) ? (hour - 12) : hour
                    , minute
                    , (hour > 12) ? "PM" : "AM"
                    );
            }
            return string.Empty;
        }
    }
}