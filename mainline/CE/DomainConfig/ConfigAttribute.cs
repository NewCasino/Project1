using System;

namespace CE.DomainConfig
{
    public class ConfigAttribute : Attribute
    {
        public string Comments { get; set; }

        public int MaxLength { get; set; }

        public string ProductionDefaultValue { get; set; }

        public string StagingDefaultValue { get; set; }

        public bool AllowCountrySpecificValue { get; set; }
    }
}
