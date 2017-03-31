using System;
using System.Collections.Generic;
using System.Runtime.Serialization;

using GamMatrixAPI;

namespace CasinoEngine
{
    /// <summary>
    /// Summary description for JackpotInfo
    /// </summary>
    [DataContract]
    [Serializable]
    public sealed class JackpotInfo
    {
        [DataMember(Name = "name")]
        public string Name { get; set; }

        [DataMember(Name = "vendorID")]
        public string VendorIDString { get; set; }

        [DataMember(Name = "amount")]
        public Dictionary<string, decimal> Amount { get; set; }

        [DataMember(Name = "gameIDs")]
        public List<string> GameIDs { get; set; }

        [DataMember(Name = "hiddenGames")]
        public string HiddenGames { get; set; }

        [IgnoreDataMember]
        public VendorID VendorID
        {
            get
            {
                VendorID vendor;
                if (Enum.TryParse<VendorID>(this.VendorIDString, out vendor))
                    return vendor;

                return VendorID.Unknown;
            }
        }

        [IgnoreDataMember]
        public List<Game> Games { get; internal set; }

    }
}