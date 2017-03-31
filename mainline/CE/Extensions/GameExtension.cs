using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;
using CE.db;
using GamMatrixAPI;

namespace CE.Extensions
{
    public static class CasinoGameExtension
    {
        public static bool IsLiveCasinoGame(this ceCasinoGameBase game)
        {
            if (GlobalConstant.AllLiveCasinoVendors.Contains(game.VendorID))
            {
                if (!GlobalConstant.AllUniversalVendors.Contains(game.VendorID))
                    return true;

                if (game.GameCategories.Contains("LIVEDEALER"))
                    return true;

                switch (game.VendorID)
                {
                    case VendorID.Microgaming:
                        {
                            if (game.Slug != null &&
                                (game.Slug.StartsWith("mgs-live-", StringComparison.InvariantCultureIgnoreCase) ||
                                game.Slug.StartsWith("ce-live-", StringComparison.InvariantCultureIgnoreCase)))
                            {
                                return true;
                            }
                            else
                            {
                                return false;
                            }
                        }
                }
                
            }
            return false;
        }

        #region Spin properties
        public static List<int> GetSpinLines(this ceCasinoGameBase game)
        {
            if (!string.IsNullOrWhiteSpace(game.SpinLines))
            {
                return CovertScopeStringToList(game.SpinLines);
            }
            return null;
        }

        public static List<int> GetSpinLines(this ceCasinoGame game)
        {
            if (!string.IsNullOrWhiteSpace(game.SpinLines))
            {
                return CovertScopeStringToList(game.SpinLines);
            }
            return null;
        }

        public static List<int> GetSpinCoins(this ceCasinoGameBase game)
        {
            if (!string.IsNullOrWhiteSpace(game.SpinCoins))
            {
                return CovertScopeStringToList(game.SpinCoins);
            }
            return null;
        }

        public static List<int> GetSpinCoins(this ceCasinoGame game)
        {
            if (!string.IsNullOrWhiteSpace(game.SpinCoins))
            {
                return CovertScopeStringToList(game.SpinCoins);
            }
            return null;
        }

        public static List<float> GetSpinDenominations(this ceCasinoGameBase game)
        {
            if (!string.IsNullOrWhiteSpace(game.SpinDenominations))
            {
                List<float> list = new List<float>();
                float _temp;
                string[] denominations = game.SpinDenominations.Split(new char[] { ',' }, StringSplitOptions.RemoveEmptyEntries);
                foreach (string deno in denominations)
                {
                    if (float.TryParse(deno, out _temp))
                        list.Add(_temp);
                }

                if (list.Count > 0)
                    return list.OrderBy(f => f).ToList();
            }
            return null;
        }

        public static List<float> GetSpinDenominations(this ceCasinoGame game)
        {
            if (!string.IsNullOrWhiteSpace(game.SpinDenominations))
            {
                List<float> list = new List<float>();
                float _temp;
                string[] denominations = game.SpinDenominations.Split(new char[] { ',' }, StringSplitOptions.RemoveEmptyEntries);
                foreach (string deno in denominations)
                {
                    if (float.TryParse(deno, out _temp))
                        list.Add(_temp);
                }

                if (list.Count > 0)
                    return list.OrderBy(f => f).ToList();
            }
            return null;
        }

        public static bool IsSpinLinesValid(this ceCasinoGameBase game)
        {
            if (!string.IsNullOrWhiteSpace(game.SpinLines))
            {
                return VerifyScopeString(game.SpinLines);
            }
            return true;
        }

        public static bool IsSpinCoinsValid(this ceCasinoGameBase game)
        {
            if (!string.IsNullOrWhiteSpace(game.SpinCoins))
            {
                return VerifyScopeString(game.SpinCoins);
            }
            return true;
        }

        private static List<int> CovertScopeStringToList(string str)
        {
            return CovertScopeStringToList(str, true, false);
        }

        private static List<int> CovertScopeStringToList(string str, bool uniq, bool exactMatch)
        {
            if (!string.IsNullOrWhiteSpace(str))
            {
                Regex regInt = new Regex("^[\\d]{1,5}$");
                Regex regRange = new Regex("^(?<min>[\\d]{1,5})\\-(?<max>[\\d]{1,5})$");
                string[] sections = str.Split(new char[] { ',' }, StringSplitOptions.RemoveEmptyEntries);
                List<int> list = new List<int>();

                foreach (string sec in sections)
                {
                    if (regInt.Match(sec).Success)
                    {
                        list.Add(int.Parse(sec));
                    }
                    else
                    {
                        Match m = regRange.Match(sec);
                        if (m.Success)
                        {
                            int min = int.Parse(m.Groups["min"].Value);
                            int max = int.Parse(m.Groups["max"].Value);
                            if (min <= max)
                            {
                                for (int i = min; i <= max; i++)
                                {
                                    list.Add(i);
                                }
                            }
                        }
                        else if (exactMatch)
                        {
                            return null;
                        }
                    }
                }

                if (list.Count > 0)
                {
                    if (uniq)
                        list = list.Distinct().OrderBy(i => i).ToList();

                    return list;
                }
            }

            return null;
        }


        private static bool VerifyScopeString(string str)
        {
            if (!string.IsNullOrWhiteSpace(str))
            {
                List<int> list = CovertScopeStringToList(str, false, true);
                return list.GroupBy(i => i).Where(i => i.Count() > 1).Count() == 0;
            }
            return false;
        }

        #endregion

    }
}
