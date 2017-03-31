using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CE.Integration.VendorApi.Models
{
    public class CreateGameSessionRequest : VendorApiRequest
    {
        private readonly UserDetails userDetails = new UserDetails();
        private readonly Dictionary<string, string> additionParameters = new Dictionary<string, string>();

        public UserDetails UserDetails
        {
            get { return userDetails; }
        }

        public long DomainId { get; set; }

        public bool IsMobile { get; set; }

        public Dictionary<string, string> AdditionParameters
        {
            get
            {
                return additionParameters;
            }
        }
    }
}
