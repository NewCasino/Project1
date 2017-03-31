using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CmsSanityCheck.Model
{
    public class PageInfo
    {
        public string FriendlyUrl { get; set; }
        public string IPAddress { get; set; }
        public ResultType ResultType { get; set; }
        public int StatusCode { get; set; }
        public ResultType LastResultType { get; set; }
    }
}
