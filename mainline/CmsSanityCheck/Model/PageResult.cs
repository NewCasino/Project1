using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CmsSanityCheck.Model
{
    public class PageResult
    {
        public string FriendlyUrl { get; set; }
        public string IPAddress { get; set; }
        public int SiteID { get; set; }
        public int DomainID { get; set; }
        public ResultType ResultType { get; set; }
        public int StatusCode { get; set; }

        public string UniqueID
        {
            get
            {
                return string.Format("{0},{1},{2}", FriendlyUrl, IPAddress, SiteID);
            }
        }
    }
}
