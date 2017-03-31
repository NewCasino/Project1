using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Net;

namespace CmsSanityCheck.Model
{
    public enum ResultType
    {
        Success = 0,

        //Skip = 1,
        NoResponse = 2,
        Slow = 3,
        ClientError = 4,
        ServerError = 5,
        //Exception = 6,
        Unknown = 999,
    }

    public class CheckResult
    {
        public CheckItem Item { get; set; }

        public int StatusCode { get; set; }
        public string ResponseText { get; set; }
        public int ElapsedSeconds { get; set; }

        public ResultType ResultType { get; set; }
        public string ErrorMessage { get; set; }
    }
}
