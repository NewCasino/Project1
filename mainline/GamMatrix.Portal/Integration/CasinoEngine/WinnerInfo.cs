using System;
using System.Runtime.Serialization;

using GamMatrixAPI;

namespace CasinoEngine
{
    /// <summary>
    /// Summary description for Winner
    /// </summary>
    [DataContract]
    [Serializable]
    public sealed class WinnerInfo
    {
        [DataMember(Name = "vendorID")]
        public string VendorIDString { get; set; }

        [DataMember(Name = "currency")]
        public string Currency { get; set; }

        [DataMember(Name = "amount")]
        public decimal Amount { get; set; }

        [DataMember(Name = "displayName")]
        public string DisplayName { get; set; }

        [DataMember(Name = "countryCode")]
        public string CountryCode { get; set; }

        [DataMember(Name = "dateTime")]
        public DateTime DateTime { get; set; }

        [DataMember(Name = "gameID")]
        public string GameID { get; set; }

        [DataMember(Name = "firstName")]
        public string FirstName { get; set; }

        [DataMember(Name = "surName")]
        public string SurName { get; set; }

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

        public Game Game { get; internal set; }
    }
}