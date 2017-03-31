using System.Linq;
using CM.Content;

/// <summary>
/// Summary description for RegionExtensions
/// </summary>
public static class RegionExtensions
{
	public static string GetDisplayName(this CM.db.cmRegion region)
    {
        CountryInfo ci = CountryManager.GetAllCountries().FirstOrDefault( c => c.InternalID == region.CountryID);
        if( ci == null )
            return string.Empty;
        string path = string.Format(@"Metadata\Regions.{0}_{1}"
            , ci.ISO_3166_Alpha2Code
            , region.ID
            );
        return Metadata.Get(path).DefaultIfNullOrEmpty(region.RegionName);
    }
}