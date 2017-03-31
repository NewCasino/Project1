using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Runtime.Serialization;

namespace CE.db
{
    [DataContract]
    public class PopularityConfigurationByCountry
    {
        [DataMember(Name = "desktopPlaced")]
        public List<long> DesktopPlaced { get; set; }

        [DataMember(Name = "mobilePlaced")]
        public List<long> MobilePlaced { get; set; }

        [DataMember(Name = "desktopExcluded")]
        public List<long> DesktopExcluded { get; set; }

        [DataMember(Name = "mobileExcluded")]
        public List<long> MobileExcluded { get; set; }
    }
}
