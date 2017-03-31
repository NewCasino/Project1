using System;
using System.Data;

using BLToolkit.Data;
using BLToolkit.DataAccess;
using BLToolkit.Mapping;

namespace CM.db
{
    //[Index(new string[]{"Guid"})]
    /// <summary>
    /// object class mapped to database cmSession table
    /// </summary>
    public sealed class cmSession
    {
        /// <summary>
        /// Field ID
        /// </summary>
        [Identity]
        public int ID { get; set; }

        /// <summary>
        /// Field Guid
        /// </summary>
        [PrimaryKey]
        public string Guid { get; set; }

        /// <summary>
        /// UserID
        /// </summary>
        public int UserID { get; set; }

        /// <summary>
        /// Field DomainID
        /// </summary>
        public int DomainID { get; set; }


        /// <summary>
        /// Field IP
        /// </summary>
        public string IP { get; set; }

        /// <summary>
        /// Field RoleString
        /// </summary>
        public string RoleString { get; set; }

        /// <summary>
        /// Field Ins
        /// </summary>
        public DateTime Ins { get; set; }

        /// <summary>
        /// Field LastAccess
        /// </summary>
        public DateTime LastAccess { get; set; }

        /// <summary>
        /// Field Culture
        /// </summary>
        public string Culture { get; set; } //TODO: Set db column type to char 5

        /// <summary>
        /// Field Url
        /// </summary>
        public string Url { get; set; }

        /// <summary>
        /// Field UrlReferrer
        /// </summary>
        public string UrlReferrer { get; set; }

        /// <summary>
        /// Field Browser
        /// </summary>
        public string Browser { get; set; }

        /// <summary>
        /// Field CookiesSupported
        /// </summary>
        public bool CookiesSupported { get; set; }

        /// <summary>
        /// Field IsAuthenticated
        /// </summary>
        public bool IsAuthenticated { get; set; }

        /// <summary>
        /// Field Login
        /// </summary>
        public DateTime? Login { get; set; }

        /// <summary>
        /// Field Logout
        /// </summary>
        public DateTime? Logout { get; set; }

        /// <summary>
        /// Field IsExpired
        /// </summary>
        public bool IsExpired { get; set; }

        /// <summary>
        /// Field CountryID
        /// </summary>
        public int CountryID { get; set; }

        /// <summary>
        /// Field UserLanguages
        /// </summary>
        public string UserLanguages { get; set; }

        /// <summary>
        /// Field TimeZoneAddMinutes
        /// </summary>
        public int TimeZoneAddMinutes { get; set; }

        /// <summary>
        /// Field LocationID
        /// </summary>
        public int LocationID { get; set; }

        /// <summary>
        /// Field Latitude
        /// </summary>
        public float Latitude { get; set; }

        /// <summary>
        /// Field Longitude
        /// </summary>
        public float Longitude { get; set; }

        /// <summary>
        /// Field Username
        /// </summary>
        [NonUpdatable]
        public string Username { get; set; }

        /// <summary>
        /// Field Firstname
        /// </summary>
        [NonUpdatable]
        public string Firstname { get; set; }

        /// <summary>
        /// Field Surname
        /// </summary>
        [NonUpdatable]
        public string Surname { get; set; }

        /// <summary>
        /// Alias 
        /// </summary> 
        [NonUpdatable]
        public string Alias { get; set; }

        /// <summary>
        /// Field UserCountryID
        /// </summary>
        [NonUpdatable]
        public int UserCountryID { get; set; }

        /// <summary>
        /// Field UserCurrency
        /// </summary>
        [NonUpdatable]
        public string UserCurrency { get; set; }

        /// <summary>
        /// AffiliateMarker
        /// </summary>
        [MapField("AffiliateCode")]
        public string AffiliateMarker { get; set; }

        [MapField("isExternal")]
        public bool IsExternal { get; set; }

        public EveryMatrix.SessionAgent.Protocol.SessionExitReason ExitReason { get; set; }

        public int SessionLimitSeconds { get; set; }

        public bool IsEmailVerified { get; set; }
    }
}
