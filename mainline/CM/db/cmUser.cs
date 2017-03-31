using System;
using BLToolkit.DataAccess;

namespace CM.db
{
    [Flags]
    public enum AcceptBonusByDefault
    {
        None = 0x00,
        All = 0xFF,
        Sports = 0x01,
        Casino = 0x02,
        Poker = 0x04,
    }

    [Flags]
    [Serializable]
    public enum TermsConditionsChange
    {
        No = 0,
        Major = 1,
        Minor = 2,
        UKLicense = 4,
        UpateNoticeMajor = 8,
        UpateNoticeMinor = 16,
        PluginTAC2 = 32,
        PluginTAC3 = 64

    }

    /// <summary>
    /// Stores a user record.
    /// </summary>
    public class cmUser
    {
        [Identity, PrimaryKey, NonUpdatable]
        public int              ID                  { get; set; }
        public int              DomainID            { get; set; }

        public string           DisplayName         { get; set; }
        public string           Username            { get; set; }
        public string           Password            { get; set; }
        public PasswordEncryptionMode PasswordEncMode { get; set; }
        public string           Email               { get; set; }
        public bool             IsEmailVerified     { get; set; }
        public string           Nickname            { get; set; }
        public string           Title               { get; set; }
        public string           FirstName           { get; set; }
        public string           MiddleName          { get; set; }
        public string           Surname             { get; set; }
        public string           PersonalID          { get; set; }
        public DateTime?        LastLogin           { get; set; }
        public bool             IsBlocked           { get; set; }
        public string           SecurityQuestion    { get; set; }
        public string           SecurityAnswer      { get; set; }
        public int              CountryID           { get; set; }
        public int?             RegionID            { get; set; }
        public string           SignupIP            { get; set; }
        public int              SignupCountryID     { get; set; }
        public int              LoginCount          { get; set; }
        public bool             IsExported          { get; set; }

        public string           Avatar              { get; set; }
        public long             PassportID          { get; set; }

/*
* public enum UserType
    {
        Ordinary = 0,
        Vendor = 1
}*/
        public int              Type                { get; set; }

        //////////////////////////////////////////////////////////////////////////////
        // Extension fields for billing type of things:
        public string           Language            { get; set; }
        

        public string           Address1            { get; set; }
        public string           Address2            { get; set; }
        public string           Address3            { get; set; }
        public string           Zip                 { get; set; }
        public string           TaxCode                 { get; set; }
        public string           City                { get; set; }
        public string           State               { get; set; }

        public string           Gender { get; set; }
        public DateTime?        Birth               { get; set; }

        public string           Currency            { get; set; }
        public string           PreferredCurrency   { get; set; }
        public string           Mobile              { get; set; }
        public string           MobilePrefix        { get; set; }
        public string           Phone               { get; set; }
        public string           PhonePrefix         { get; set; }
        public string           AffiliateMarker     { get; set; }
        public string           InternalUserID      { get; set; }
        public bool             IsActivationReminderSent { get; set; }

        public TermsConditionsChange IsTCAcceptRequired { get; set; }

        public bool             AllowNewsEmail      { get; set; }
        public bool             AllowSmsOffer       { get; set; }

        public string Alias { get; set; }

        public DateTime         Ins { get; set; }

        public int SignupLocationID { get; set; }
        public int TimeZoneID { get; set; }
        public int SignupHostID { get; set; }

        public AcceptBonusByDefault AcceptBonusByDefault { get; set; }
        public DateTime?        RecentLockTime { get; set; }

        public int              SessionLimitSeconds { get; set; }

        public bool              IsGeneralTCAccepted { get; set; }
		//public string			AlternatePassword	{ get; set; }

        public DateTime? CompleteProfile { get; set; }

        public DateTime? LastPasswordModified { get; set; }

        //CMS-3166 CMS part:Implementation for Denmark licence
        //public string CPRNumber { get; set; }

        public int FailedLoginAttempts { get; set; }

        public bool IsMobileSignup { get; set; }
        public string Preferences { get; set; }

        public bool IsSecondFactorVerified { get; set; }

        public string SecondFactorSecretKey { get; set; }
        public int intendedVolume { get; set; }
        public TwoFactorAuth.SecondFactorAuthType SecondFactorType { get; set; }
        public string StreetName { get; set; }
        public string StreetNumber { get; set; }
    }
}
