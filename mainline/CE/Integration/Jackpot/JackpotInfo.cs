using System;
using System.Collections.Generic;
using GamMatrixAPI;

namespace Jackpot
{
    [Serializable]
    public sealed class JackpotInfo
    {
        public VendorID VendorID { get; set; }
        public string ID { get; set; }
        public string Name { get; set; }

        public Dictionary<string, decimal> Amounts { get; private set; }

        public JackpotInfo()
        {
            this.Amounts = new Dictionary<string, decimal>(StringComparer.InvariantCultureIgnoreCase);
        }
    }
}

