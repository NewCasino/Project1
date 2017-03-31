using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CE.db
{
    public sealed class ceCasinoGamePopularity
    {
        public long GameID { get; set; }
        public string Platform { get; set; }
        public string CountryCode { get; set; }
        public decimal Popularity { get; set; }
    }
}
