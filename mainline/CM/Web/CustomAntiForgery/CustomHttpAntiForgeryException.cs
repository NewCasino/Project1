using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CM
{
    public class CustomHttpAntiForgeryException : SystemException
    {
        public CustomHttpAntiForgeryException() { }

        public CustomHttpAntiForgeryException(string message) : base (message) { }

        public CustomHttpAntiForgeryException(string message, Exception inner) : base(message, inner) { }
    }
}
