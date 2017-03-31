using System.Collections.Generic;

namespace GamMatrix.CMS.Models.MobileShared.Deposit
{
    public class ConfirmLocalBankViewModel
    {
        public ConfirmLocalBankViewModel(Dictionary<string, string> stateVars)
        {
            StateVars = stateVars;
        }
        public Dictionary<string, string> StateVars { get; set; }
    }
}
