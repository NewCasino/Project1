using System;
using System.Collections.Generic;
using System.Linq;

namespace CmsSanityCheck.Model
{
    public class SiteAndHost
    {
        public int SiteID { get; set; }
        public int DomainID { get; set; }
        public string DisplayName { get; set; }
        public string Host 
        {
            get
            {
                if (HostNames.Count == 0)
                    return null;

                var host = HostNames.FirstOrDefault(h => h.StartsWith("www.", StringComparison.InvariantCultureIgnoreCase) || h.StartsWith("m.", StringComparison.InvariantCultureIgnoreCase));
                if (host != null)
                    return host;

                return HostNames.FirstOrDefault();
            }
        }
        public List<string> HostNames { get; set; }

        public SiteAndHost()
        {
            HostNames = new List<string>();
        }
    }
}
