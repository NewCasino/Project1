using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CE.Integration.VendorApi.Models
{
    public class TransferResponse : VendorAPIResponse
    {
        public string TransactionId { get; set; }

        public int ActiveWalletId { get; set; }
    }
}
