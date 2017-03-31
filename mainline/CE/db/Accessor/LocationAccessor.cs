using System.Collections.Generic;
using System.Web;
using System.Web.Caching;
using BLToolkit.DataAccess;

namespace CE.db.Accessor
{
    public abstract class LocationAccessor : DataAccessor
    {
        
        [Index("Alpha2Code")]
        [ScalarFieldName("Name")]
        [SqlQuery(@"SELECT Name, Alpha2Code FROM GmCountry WHERE Alpha3Code IS NOT NULL ORDER BY Name ASC")]
        public abstract Dictionary<string, string> GetCountries();

        
        [Index("StrongID")]
        [ScalarFieldName("Code")]
        [SqlQueryEx( MSSqlText = @"SELECT [StrongID], [Code] FROM cm..cmCountry WITH(NOLOCK)",
            MySqlText =  @"SELECT `StrongID`, `Code` FROM cm.cmCountry")]
        public abstract Dictionary<int, string> GetCountryID2CodeDictionary();


        [Index("Code")]
        [ScalarFieldName("StrongID")]
        [SqlQueryEx(MSSqlText = @"SELECT  [Code],[StrongID] FROM cm..cmCountry WITH(NOLOCK)",
            MySqlText = @"SELECT  `Code`,`StrongID` FROM cm.cmCountry")]
        public abstract Dictionary<string,int > GetCountryCode2IdDictionary();


        internal static string GetCountryCodeByID(int countryID)
        {
            string cacheKey = "LocationAccessor.GetCountryCodeByID";
            Dictionary<int, string> dic = HttpRuntime.Cache[cacheKey] as Dictionary<int, string>;
            if (dic == null)
            {
                LocationAccessor la = LocationAccessor.CreateInstance<LocationAccessor>();
                dic = la.GetCountryID2CodeDictionary();
                HttpRuntime.Cache.Insert( cacheKey, la, null, Cache.NoAbsoluteExpiration, Cache.NoSlidingExpiration, CacheItemPriority.NotRemovable, null);
            }

            string code = null;
            dic.TryGetValue(countryID, out code);
            return code;
        }
    }
}
