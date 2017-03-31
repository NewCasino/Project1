using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CE.Integration.VendorApi.Models
{
    public class VendorApiRequest
    {
        public long DomainId { get; set; }

        public string VendorName { get; set; }

        public string RequestId { get; set; }
    }
}
