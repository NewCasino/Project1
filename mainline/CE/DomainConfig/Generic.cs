using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CE.DomainConfig
{
    public static class Generic
    {
        // OperatorID
        [Config(Comments = "Domain disallow edit flag", MaxLength = 50
            , ProductionDefaultValue = "false"
            , StagingDefaultValue = "false")]
        public const string DisallowEdit = "Generic.DisallowEdit";
    }
}
