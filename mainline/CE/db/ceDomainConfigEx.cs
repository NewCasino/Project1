using System;

namespace CE.db
{
    [Serializable]
    public class ceDomainConfigEx : ceDomainConfig
    {
        public string Name { get; set; }

        public string SecurityToken { get; set; }



    }
}
