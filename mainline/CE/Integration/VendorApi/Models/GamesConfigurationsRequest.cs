using System.Collections.Generic;

namespace CE.Integration.VendorApi.Models
{
    public class GamesConfigurationsRequest : VendorApiRequest
    {
        public Dictionary<string, string> AdditionParameters { get; set; } 
    }
}
