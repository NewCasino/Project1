using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CE.Integration.VendorApi.Models
{
    public class GetBalanceRequest : VendorApiRequest
    {
        public string Password { get; set; }

        public string UserName { get; set; }

        public string Currency { get; set; }

        public long UserId { get; set; }

        public Dictionary<string, string> AdditionParameters { get; set; }       
    }
}
