using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace CasinoEngine.Models
{
    public class CustomVendorJackpotConfig
    {
        public long OperatorId { get; set; }

        public string OperatorName { get; set; }

        public string Url { get; set; }

        public string MappedJackpotID { get; set; }

        public string MappedJackpotText { get; set; }
    }
}