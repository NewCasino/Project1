using System;
using System.Collections.Generic;
using System.Linq;

namespace Finance
{
    [Serializable]
    /// <summary>
    /// Summary description for CurrencyList
    /// </summary>
    public sealed class CurrencyList : FilteredListBase<string>
    {
        public CurrencyList()
            : base()
        {
        }

        public override List<string> GetAll() 
        {
            return GmCore.GamMatrixClient.GetSupportedCurrencies().Select( c => c.ISO4217_Alpha).ToList();
        }
    }
}