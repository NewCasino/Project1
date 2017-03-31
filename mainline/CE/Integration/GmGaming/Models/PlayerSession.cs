using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CE.Integration.GmGaming.Models
{
    public class PlayerSession
    {
        public string SessionId { get; set; }

        public string UserName { get; set; }
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public string CountryCode { get; set; }

        public string Language { get; set; }

        public string BrowserAgent { get; set; }

        public string Currency { get; set; }

        public string AffiliateMarker { get; set; }

        public string IpAddess { get; set; }
        public string IpCountryCode { get; set; }
        public DateTime Birthday { get; set; }
    }
}
