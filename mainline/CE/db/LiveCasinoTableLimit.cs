using System;
using System.Collections.Generic;
using System.Linq;

namespace CE.db
{
    [Serializable]
    public enum LiveCasinoTableLimitType
    {
        None,
        SameForAllCurrency,
        SpecificForEachCurrency,
        AutoConvertBasingOnCurrencyRate,
    }

    [Serializable]
    public sealed class LimitAmount
    {
        public decimal MinAmount;
        public decimal MaxAmount;
    }

    [Serializable]
    public sealed class LiveCasinoTableLimit
    {
        public LiveCasinoTableLimitType Type 
        {
            get;
            set; 
        }
        public string BaseCurrency { get; set; }
        public LimitAmount BaseLimit { get; private set; }
        public Dictionary<string, LimitAmount> CurrencyLimits { get; private set; }

        public LiveCasinoTableLimit()
        {
            this.BaseLimit = new LimitAmount();
            this.Type = LiveCasinoTableLimitType.None;
            this.CurrencyLimits = new Dictionary<string, LimitAmount>(StringComparer.InvariantCultureIgnoreCase);
        }

        public bool Equals(LiveCasinoTableLimit l)
        {
            if (this == l)
                return true;

            if (l == null)
                return false;

            if (this.Type != l.Type)
                return false;

            if (!this.BaseCurrency.Equals(l.BaseCurrency, StringComparison.InvariantCultureIgnoreCase))
                return false;

            if(this.BaseLimit.MaxAmount != l.BaseLimit.MaxAmount || this.BaseLimit.MinAmount != l.BaseLimit.MinAmount)
                return false;

            if (this.CurrencyLimits.Keys.Count != l.CurrencyLimits.Keys.Count)
                return false;
            foreach (string k in this.CurrencyLimits.Keys)
            {
                if (!l.CurrencyLimits.Keys.Contains(k))
                    return false;
                if (this.CurrencyLimits[k].MaxAmount != l.CurrencyLimits[k].MaxAmount || this.CurrencyLimits[k].MinAmount != l.CurrencyLimits[k].MinAmount)
                    return false;
            }

            return true;
        }
    }
}
