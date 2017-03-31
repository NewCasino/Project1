using System.Collections.Generic;
using CE.Integration.GmGaming.Models;
using GamMatrixAPI;

namespace GmGamingAPI
{
    public class TokenRequest : GmGamingRequestBase
    {
        public VendorID VendorID { get; set; }
        public long UserID { get; set; }
        public bool IsMobile { get; set; }
        public List<NameValue> AdditionalParameters { get; set; }
        public string GameId { get; set; }
        public string GameCode { get; set; }
        public string Slug { get; set; }
        public long CasinoGameId { get; set; }
        public long CasinoBaseGameId { get; set; }
        public string TableId { get; set; }
        public PlayerSession PlayerSession { get; set; }
    }
}
