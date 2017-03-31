using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Text.RegularExpressions;
using System.Runtime.Serialization;

namespace CasinoEngine
{
    [Serializable]
    public sealed class LiveCasinoTable : Game
    {
        [DataMember(Name = "gameID")]
        public string GameID { get; set; }

        [DataMember(Name = "liveCasinoCategory")]
        public string LiveCasinoCategory { get; set; }

        [DataMember(Name = "is24HoursOpen")]
        public bool Is24HoursOpen { get; set; }

        [DataMember(Name = "openingHoursTimeZone")]
        public string OpeningHoursTimeZone { get; set; }

        [DataMember(Name = "openingHoursStart")]
        public int OpeningHoursStart { get; set; }

        [DataMember(Name = "openingHoursEnd")]
        public int OpeningHoursEnd { get; set; }

        [DataMember(Name = "openingHours")]
        public string OpeningHours { get; set; }

        [DataMember(Name = "isVIPTable")]
        public bool IsVIPTable { get; set; }

        [DataMember(Name = "isNewTable")]
        public bool IsNewTable { get; set; }

        [DataMember(Name = "isTurkishTable")]
        public bool IsTurkishTable { get; set; }

        [DataMember(Name = "isBetBehindAvailable")]
        public bool IsBetBehindAvailable { get; set; }

        [DataMember(Name = "isExcludedFromRandomLaunch")]
        public bool IsExcludedFromRandomLaunch { get; set; }

        [DataMember(Name = "isSeatsUnlimited")]
        public bool IsSeatsUnlimited { get; set; }

        [DataMember(Name = "dealerGender")]
        public string DealerGender { get; set; }

        [DataMember(Name = "dealerOrigin")]
        public string DealerOrigin { get; set; }

        [DataMember(Name = "seatsMax")]
        public int SeatsMax { get; set; }

        [DataMember(Name = "seatsTaken")]
        public int SeatsTaken { get; set; }

        [DataMember(Name = "isOpened")]
        public bool IsOpened { get; set; }

        [DataMember(Name = "limits")]
        public Dictionary<string, string> Limits { get; set; }

        public string GetLimit(string currency)
        {
            string limit;
            if (this.Limits != null && this.Limits.TryGetValue(currency, out limit))
                return limit;

            return null;
        }
    }
}
