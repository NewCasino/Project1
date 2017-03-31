using System.Collections.Generic;

namespace CmsSanityCheck.Model
{
    public class Service
    {
        public string Name { get; set; }
        public string ConnectionString { get; set; }
        public string Host { get; set; }
        public int DomainID { get; set; }
        public List<string> IPAddresses { get; set; }
        public List<string> TestUrls { get; set; }

        public Service()
        {
            IPAddresses = new List<string>();
            TestUrls = new List<string>();
        }
    }
}
