using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CE.Integration.VendorApi.Models
{
    public class TransferRequest : VendorApiRequest
    {
        public int Source { get; set; }

        public int Target { get; set; }

        public decimal? Amount { get; set; }

        public string Currency { get; set; }
       
        public string UserName { get; set; }

        public string IpAddress { get; set; }

        public string Command { get; set; }
        
        public long UserId { get; set; }

        public Dictionary<string, string> AdditionParameters { get; set; }
      
    }
}
