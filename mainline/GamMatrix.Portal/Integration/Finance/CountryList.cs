using System;
using System.Collections.Generic;
using System.Linq;

namespace Finance
{
    [Serializable]
    /// <summary>
    /// Summary description for CountryList
    /// </summary>
    public sealed class CountryList : FilteredListBase<int>
    {
        public CountryList()
            : base()
        {
        }

        public override List<int> GetAll() 
        {
            return CountryManager.GetAllCountries()
                .Where( c => c.InternalID > 0)
                .Select( c => c.InternalID)
                .ToList<int>();
        }
    }
}