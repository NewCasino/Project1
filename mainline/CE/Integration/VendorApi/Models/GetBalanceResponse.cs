using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CE.Integration.VendorApi.Models
{
    public class GetBalanceResponse : VendorAPIResponse
    {
        public decimal Balance { get; set; }

        public string Currency { get; set; }

        public List<VendorBalance> VendorBalances { get; set; }
    }
}
