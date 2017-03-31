using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Xml;
using System.Xml.Linq;
using System.Runtime.Serialization;

namespace CasinoEngine
{
    [DataContract]
    public class GamePopularity
    {
        [DataMember(Name = "gameID")]
        public string GameID { get; set; }

        [DataMember(Name = "desktopPopularity")]
        public Dictionary<string, decimal> DesktopPopularity { get; set; }

        [DataMember(Name = "mobilePopularity")]
        public Dictionary<string, decimal> MobilePopularity { get; set; }


        public bool IsAvaliable(Platform platForm, string countryCode)
        {
            if (platForm == Platform.PC)
            {
                return DesktopPopularity.Keys.Any(key => string.Equals(key, countryCode, StringComparison.InvariantCultureIgnoreCase));
            }
            else
            {
                return MobilePopularity.Keys.Any(key => string.Equals(key, countryCode, StringComparison.InvariantCultureIgnoreCase));
            }
        }
    }
}
