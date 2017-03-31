using System;
using System.Collections.Generic;
using CM.Content;
using System.Text.RegularExpressions;

namespace Finance
{
    [Serializable]
    public enum ProcessFeeType
    {
        Free,
        Percent,
        Fixed,
        Bank,
    }

    
    /// <summary>
    /// Summary description for Limitation
    /// </summary>
    [Serializable]
    public sealed class ProcessFee
    {
        public ProcessFeeType ProcessFeeType { get; set; }
        public decimal Percentage { get; set; }
        public Dictionary<string, decimal> Currency2FixedFee { get; set; }
        public Dictionary<string, KeyValuePair<decimal, decimal> > Currency2BankFee { get; set; }

        public ProcessFee()
        {
            this.Currency2FixedFee = new Dictionary<string, decimal>(StringComparer.OrdinalIgnoreCase);
            this.Currency2BankFee = new Dictionary<string, KeyValuePair<decimal, decimal>>(StringComparer.OrdinalIgnoreCase);
        }

        public string GetText(string currency)
        {
            try
            {
                switch (this.ProcessFeeType)
                {
                    case ProcessFeeType.Free:
                        return Metadata.Get("/Metadata/ProcessFee.Free").DefaultIfNullOrEmpty("Free");

                    case ProcessFeeType.Percent:
                        return string.Format("{0}%", Percentage.ToString());

                    case ProcessFeeType.Fixed:
                        {
                            decimal fee;
                            if (Regex.IsMatch(Metadata.Get("/Metadata/ProcessFee.IsFeeTransformEUR").DefaultIfNullOrEmpty("NO"), @"(YES)|(ON)|(OK)|(TRUE)|(\1)", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant | RegexOptions.Compiled))
                            {
                                if (currency.ToUpper() == "EUR")
                                {
                                    return string.Format("{0} {1}", "EUR", Currency2FixedFee["EUR"]);
                                }
                                else
                                {
                                    return string.Format("{0} {1}", currency.ToUpper(), MoneyHelper.TransformCurrency("EUR", currency.ToUpper(), Currency2FixedFee["EUR"]));
                                }
                            }
                            else
                            {
                                if (Currency2FixedFee.TryGetValue(currency, out fee))
                                {
                                    return string.Format("{0} {1}", currency.ToUpper(), fee);
                                }
                                else if (Currency2FixedFee.ContainsKey("EUR"))
                                {
                                    return string.Format("{0} {1}", "EUR", Currency2FixedFee["EUR"]);
                                }
                            }
                            break;
                        }

                    case ProcessFeeType.Bank:
                        {
                            KeyValuePair<decimal, decimal> pair;
                            if (Currency2BankFee.TryGetValue(currency, out pair))
                            {
                                string format = Metadata.Get("/Metadata/ProcessFee.Bank").DefaultIfNullOrEmpty("Local bank transfer:{0} {1}; International bank transfer:{2} {3};");
                                return string.Format(format
                                    , currency.ToUpper()
                                    , pair.Key
                                    , currency.ToUpper()
                                    , pair.Value                                    
                                    );
                            }
                            else if (Currency2BankFee.ContainsKey("EUR"))
                            {
                                return string.Format("{0} {1}", Currency2BankFee["EUR"], "EUR");
                            }
                            break;
                        }
                }
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
            }
            return string.Empty;
        }

    }
}