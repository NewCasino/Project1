using System;
using System.Collections.Generic;
using CM.Content;
using GamMatrixAPI;
using GmCore;

namespace Finance
{
    /// <summary>
    /// Summary description for CurrencyHelper
    /// </summary>
    public static class MoneyHelper
    {
        public static string FormatWithCurrency(string currency, decimal amount)
        {
            return string.Format("{0} {1:n2}", currency, amount);
        }

        public static string GetCurrencySymbol(string currency)
        {
            return Metadata.Get(string.Format("Metadata/Currency/{0}.Symbol", currency));
        }
        
        public static string FormatWithCurrencySymbol(string currency, decimal amount)
        {
            string currencySymbol = Metadata.Get(string.Format("Metadata/Currency/{0}.Symbol", currency));

            return string.Format("{0} {1:n2}", currencySymbol.DefaultIfNullOrEmpty(currency), amount);
        }



        /// <summary>
        /// Transform amount from one currency to another
        /// </summary>
        /// <param name="sourceCurrency"></param>
        /// <param name="destCurrency"></param>
        /// <param name="amount"></param>
        /// <returns></returns>
        public static decimal TransformCurrency(string sourceCurrency, string destCurrency, decimal amount)
        {
            if (string.Equals(sourceCurrency, destCurrency, StringComparison.OrdinalIgnoreCase))
                return amount;

            decimal transformed = amount;
            Dictionary<string, CurrencyExchangeRateRec> dic = GamMatrixClient.GetCurrencyRates();
            if (!string.Equals(sourceCurrency, "EUR", StringComparison.InvariantCultureIgnoreCase))
            {
                CurrencyExchangeRateRec rec = null;
                if (!dic.TryGetValue(sourceCurrency, out rec))
                    throw new Exception("Unknown currency :" + sourceCurrency);
                transformed = Math.Truncate(amount / rec.MidRate * 100) / 100.00M;
            }

            if (!string.Equals(destCurrency, "EUR", StringComparison.InvariantCultureIgnoreCase))
            {
                CurrencyExchangeRateRec rec = null;
                if (!dic.TryGetValue(destCurrency, out rec))
                    throw new Exception("Unknown currency :" + destCurrency);
                transformed = Math.Truncate(transformed * rec.MidRate * 100) / 100.00M;
            }
            return transformed;
        }

        /// <summary>
        /// Transform amount from one currency to another
        /// </summary>
        /// <param name="sourceCurrency"></param>
        /// <param name="destCurrency"></param>
        /// <param name="amount"></param>
        /// <param name="exchangeRate"></param>
        /// <returns></returns>
        public static decimal TransformCurrency(string sourceCurrency, string destCurrency, decimal amount,Dictionary<string, CurrencyExchangeRateRec> exchangeRate)
        {
            if (string.Equals(sourceCurrency, destCurrency, StringComparison.OrdinalIgnoreCase) || exchangeRate == null)
                return amount;

            decimal transformed = amount;
            if (!string.Equals(sourceCurrency, "EUR", StringComparison.InvariantCultureIgnoreCase))
            {
                CurrencyExchangeRateRec rec = null;
                if (!exchangeRate.TryGetValue(sourceCurrency, out rec))
                    throw new Exception("Unknown currency :" + sourceCurrency);
                transformed = Math.Truncate(amount / rec.MidRate * 100) / 100.00M;
            }

            if (!string.Equals(destCurrency, "EUR", StringComparison.InvariantCultureIgnoreCase))
            {
                CurrencyExchangeRateRec rec = null;
                if (!exchangeRate.TryGetValue(destCurrency, out rec))
                    throw new Exception("Unknown currency :" + destCurrency);
                transformed = Math.Truncate(transformed * rec.MidRate * 100) / 100.00M;
            }
            return transformed;
        }


        public static decimal SmoothFloor(decimal money)
        {
            if (money < 1)
            {
                money = 0;
            }
            else
            {
                int numDecimals = (int)Math.Ceiling(Math.Log10((double)money));
                int decimalToRound = (int)Math.Floor(numDecimals / 2.0f);
                for (int i = 0; i < decimalToRound; i++)
                {
                    int multiple = (int)Math.Pow(10, i + 1);
                    money = Math.Truncate(money / multiple) * multiple;
                }
            }
            return money;
        }

        public static decimal SmoothCeiling(decimal money)
        {
            if (money <= 0)
            {
                money = 0;
            }
            else if (money > 0 && money <= 1)
            {
                money = 1;
            }
            else
            {
                if (money % 1 != 0)
                {
                    money = Math.Truncate(money) + 1;
                }
                int numDecimals = (int)Math.Ceiling(Math.Log10((double)money));
                int decimalToRound = (int)Math.Floor(numDecimals / 2.0f);
                for (int i = 0; i < decimalToRound; i++)
                {
                    int multiple = (int)Math.Pow(10, i + 1);
                    bool hasRemainder = money % multiple != 0;
                    money = Math.Truncate(money / multiple) * multiple;
                    if (hasRemainder)
                        money += multiple;
                }
            }
            return money;
        }

        public static void SmoothCeilingAndFloor(ref decimal amountToCeiling, ref decimal amountToFloor)
        {
            amountToCeiling = SmoothCeiling(amountToCeiling);
            amountToFloor = SmoothFloor(amountToFloor);
            if (amountToCeiling > amountToFloor && amountToFloor > 0)
                amountToCeiling = amountToFloor;
        }

        public static string FormatCurrencySymbol(string inputText)
        {
            string currencySymbols = Metadata.Get("Metadata/Currency.Replacements", true, false, true);
            List<string> list = currencySymbols.SplitToList(";");
            string result = inputText;
            foreach (string currency in list)
            {
                if (String.IsNullOrWhiteSpace(currency))
                {
                    continue;
                }
                
                string symbol = Metadata.Get(string.Format("Metadata/Currency/{0}.Symbol", currency), true, false, true);
                if (String.IsNullOrWhiteSpace(symbol))
                {
                    continue;
                }
                result = result.Replace(currency.Trim(), symbol);
            }
            return result;
        }

    }
}