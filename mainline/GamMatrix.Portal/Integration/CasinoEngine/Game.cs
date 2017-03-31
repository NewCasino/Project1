using System;
using System.Linq;
using System.Web;
using System.Runtime.Serialization;

using CM.Content;
using CM.State;

using GamMatrixAPI;

namespace CasinoEngine
{
    /// <summary>
    /// Summary description for Game
    /// </summary>
    [DataContract]
    [Serializable]
    public class Game
    {
        public const string GAME_TRANSLATION_PATH = @"/Metadata/_CasinoEngine/Games/{0}";

        [DataMember(Name = "id")]
        public string ID { get; set; }

        [DataMember(Name = "slug")]
        public string Slug { get; set; }

        [DataMember(Name = "vendorID")]
        public string VendorIDString { get; set; }

        [DataMember(Name = "isNewGame")]
        public bool IsNewGame { get; set; }

        [DataMember(Name = "isMiniGame")]
        public bool IsMiniGame { get; set; }

        [DataMember(Name = "isRealMoneyModeEnabled")]
        public bool IsRealMoneyModeEnabled { get; set; }

        [DataMember(Name = "isAnonymousFunModeEnabled")]
        public bool IsAnonymousFunModeEnabled { get; set; }

        [DataMember(Name = "isFunModeEnabled")]
        public bool IsFunModeEnabled { get; set; }

        [DataMember(Name = "iconUrlFormat")]
        public string IconUrlFormat { get; set; }

        [DataMember(Name = "logoUrl")]
        public string LogoUrl { get; set; }

        [DataMember(Name = "thumbnailUrl")]
        public string ThumbnailUrl { get; set; }

        [DataMember(Name = "backgroundImageUrl")]
        public string BackgroundImageUrl { get; set; }

        [DataMember(Name = "url")]
        public string Url { get; set; }

        [DataMember(Name = "helpUrl")]
        public string HelpUrl { get; set; }

        [DataMember(Name = "width")]
        public int? Width { get; set; }

        [DataMember(Name = "height")]
        public int? Height { get; set; }

        [DataMember(Name = "popularity")]
        public long Popularity { get; set; }

        [DataMember(Name = "fpp")]
        public decimal FPP { get; set; }

        [DataMember(Name = "bonusContribution")]
        public decimal BonusContribution { get; set; }

        [DataMember(Name = "theoreticalPayOut")]
        public decimal TheoreticalPayOut { get; set; }

        [DataMember(Name = "contentProvider")]
        public string ContentProvider { get; set; }

        [DataMember(Name = "categories")]
        public string[] Categories { get; set; }

        [DataMember(Name = "tags")]
        public string[] Tags { get; set; }

        [DataMember(Name = "platforms")]
        public string[] PlatformStrings { get; set; }

        [DataMember(Name = "restrictedTerritories")]
        public string[] RestrictedTerritories { get; set; }

        [DataMember(Name = "englishName")]
        public string EnglishName { get; set; }

        [DataMember(Name = "englishShortName")]
        public string EnglishShortName { get; set; }

        [DataMember(Name = "englishDescription")]
        public string EnglishDescription { get; set; }

        [DataMember(Name = "licenseType")]
        public string LicenseType { get; set; }

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

        public Platform[] Platforms
        {
            get
            {
                return this.PlatformStrings.Select(c =>
                {
                    var v = default(Platform);
                    Enum.TryParse(c, out v);
                    return v;
                }).ToArray();
            }
        }

        [IgnoreDataMember]
        public bool IsJackpotGame
        {
            get
            {
                return this.Categories.Contains(GameCategory.JACKPOTGAMES);
            }
        }

        public string Name
        {
            get
            {
                return Metadata.Get(string.Format(GAME_TRANSLATION_PATH, this.ID) + ".Name")
                    .DefaultIfNullOrEmpty(this.EnglishName);
            }
        }

        public string ShortName
        {
            get
            {
                return Metadata.Get(string.Format(GAME_TRANSLATION_PATH, this.ID) + ".ShortName")
                    .DefaultIfNullOrEmpty(this.EnglishShortName).DefaultIfNullOrEmpty(this.EnglishName);
            }
        }

        public string Description
        {
            get
            {
                return Metadata.Get(string.Format(GAME_TRANSLATION_PATH, this.ID) + ".Description")
                    .DefaultIfNullOrEmpty(this.EnglishDescription);
            }
        }

        public bool IsAvailable
        {
            get
            {
                if (HttpContext.Current != null && this.RestrictedTerritories != null && this.RestrictedTerritories.Length > 0)
                {
                    IPLocation ipLocation = IPLocation.GetByIP(HttpContext.Current.Request.GetRealUserAddress());
                    if (ipLocation.Found && this.RestrictedTerritories.Contains(ipLocation.CountryCode, StringComparer.InvariantCultureIgnoreCase))
                    {
                        return false;
                    }

                    if (CustomProfile.Current.IsAuthenticated && CustomProfile.Current.UserCountryID > 0)
                    {
                        CountryInfo country = CountryManager.GetAllCountries().FirstOrDefault(c => c.InternalID == CustomProfile.Current.UserCountryID);
                        if (country != null)
                            return !this.RestrictedTerritories.Contains(country.ISO_3166_Alpha2Code);
                    }
                }
                return true;
            }
        }
    }
}