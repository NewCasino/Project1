using System;
using System.Collections;
using System.Collections.Generic;

namespace CE.db
{
    [Serializable]
    public sealed class dwGamePopularity
    {
        public int VendorID { get; set; }
        public string GameCode { get; set; }
        public long Popularity { get; set; }
        public string CountryCode { get; set; }
        public string GameType { get; set; }
    }
}