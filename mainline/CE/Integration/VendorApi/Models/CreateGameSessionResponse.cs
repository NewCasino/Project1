using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CE.Integration.VendorApi.Models
{
    public class CreateGameSessionResponse : VendorAPIResponse
    {
        public string GameSession { get; set; }
    }
}
