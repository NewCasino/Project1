using System.Collections.Generic;

namespace CE.Integration.VendorApi.Models
{
    public class VendorAPIResponse : IVendorAPIResponse
    {
        private readonly Dictionary<string, string> additionalParameters = new Dictionary<string, string>();

        public bool Success { get; set; }

        public string Message { get; set; }

        public string VendorError { get; set; }

        public string GICError { get; set; }

        public Dictionary<string, string> AdditionalParameters
        {
            get { return additionalParameters; } 
        }
    }
}
