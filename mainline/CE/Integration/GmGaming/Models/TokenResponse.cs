using System.Collections.Generic;

namespace GmGamingAPI
{
    public class TokenResponse
    {
        public long ID { get; set; }
        public int DomainId { get; set; }
        public string SessionId { get; set; }
        public long SessionUserId { get; set; }
        public System.DateTime Ins { get; set; }
        public string TokenKey { get; set; }
        public int VendorId { get; set; }
        public long UserId { get; set; }
        public System.DateTime ExpireTime { get; set; }
        public short ErrorCode { get; set; }
        public string ErrorMessage { get; set; }

        public string OperatorId { get; set; }
        public string UserCasinoCurrency { get; set; }

        public string AdditionalData { get; set; }
        public List<NameValue> AdditionalParameters { get; set; }
    }
}
