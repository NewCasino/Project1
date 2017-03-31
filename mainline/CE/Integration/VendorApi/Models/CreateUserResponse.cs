using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CE.Integration.VendorApi.Models
{
    public class CreateUserResponse : VendorAPIResponse
    {
        public string VendorStatus { get; set; }
        public string UserId { get; set; }
    }
}
