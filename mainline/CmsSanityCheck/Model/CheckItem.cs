using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Text;
using System.Threading.Tasks;

namespace CmsSanityCheck.Model
{
    public class CheckItem
    {
        //public string DisplayName { get; set; }
        //public string IPAddress { get; set; }
        public string Url { get; set; }
        public string FriendlyUrl { get; set; }
        //public string Host { get; set; }
        //public int DomainID { get; set; }
        public SiteAndHost SiteAndHost { get; set; }
    }
}
