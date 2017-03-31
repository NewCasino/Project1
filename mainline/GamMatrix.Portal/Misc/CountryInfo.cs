using System;
using System.Globalization;
using System.Linq;
using System.Text.RegularExpressions;
using CM.Content;

/// <summary>
/// Summary description for CountryInfo
/// </summary>
[Serializable]
public sealed class CountryInfo
{
    public int InternalID { get; set; } // the id for relation-ship to GmCore
    public string ISO_3166_Name { get; set; }
    public string ISO_3166_Alpha2Code { get; set; }
    public string ISO_3166_Alpha3Code { get; set; }
    public string EnglishName { get; set; }
    public string NetEntCountryName { get; set; }

    public bool RestrictRegistrationByIP { get; set; }
    public bool RestrictRegistrationByRegion { get; set; }
    public string RestrictRegistrationByRegionCode { get; set; }
    public bool RestrictLoginByIP { get; set; }
    public bool RestrictCreditCardWithdrawal { get; set; }
    public bool UserSelectable { get; set; }
    public string PhoneCode { get; set; }
    public string CurrencyCode { get; set; }

    public bool IsPersonalIdVisible { get; set; }
    public bool IsPersonalIdMandatory { get; set; }
    public string PersonalIdValidationRegularExpression { get; set; }
    public int PersonalIdMaxLength { get; set; }
    

    public bool AdminLock { get; set; }
    /*
     * Austria
Belgium
Bulgaria
Cyprus
Czech Republic
Denmark
Estonia
Finland
France
Germany
Greece
Hungary
Iceland
Republic of Ireland
Italy
Latvia
Liechtenstein
Lithuania
Luxembourg
Malta
The Netherlands
Norway
Poland
Portugal
Romania
Slovakia
Slovenia
Spain
Sweden
UK
     * */
    private static readonly string[] EEA_countries = new string[]
            {
                "AT", "BE", "BG", "CY", "CZ", "DK", "EE", "FI", "FR", "DE", "GR", "HU", "IS",
                "IE", "IT", "LV", "LI", "LT", "LU", "MT", "NL", "NO", "PL", "PT", "RO", "SK",
                "SI", "ES", "SE", "GB",
            };

    /// <summary>
    /// Check if this country is belongs to EEA
    /// </summary>
    public bool IsInEuropeanEconomicArea
    {
        get 
        {
            return EEA_countries.FirstOrDefault( c => string.Compare( c ,this.ISO_3166_Alpha2Code, true) == 0 ) != null; 
        }
    }

    public string DisplayName
    {
        get
        {
            string path = string.Format( "/Metadata/Country/.{0}", Regex.Replace( this.ISO_3166_Name, @"[^\w_]", "_") );
            return Metadata.Get(path).DefaultIfNullOrEmpty(this.EnglishName);
        }
    }

    public string PersonalIDDisplayName
    {
        get {
            string path = string.Format("/Metadata/Country/PersonalID/{0}.PersonalIDDisplayName", Regex.Replace(this.ISO_3166_Name, @"[^\w_]", "_"));
            return Metadata.Get(path).DefaultIfNullOrEmpty("");
        }
    }

    public CountryInfo()
    {
        this.UserSelectable = true;
    }

    public string GetCountryFlagName()
    {
        return this.ISO_3166_Alpha2Code.ToLower(CultureInfo.InvariantCulture);
    }
}
