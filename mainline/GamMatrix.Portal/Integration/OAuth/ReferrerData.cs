using System;
using System.Collections.Generic;
using System.Text;
using System.Threading.Tasks;
using System.Configuration;

using BLToolkit.Data;
using BLToolkit.DataAccess;

using CM.db.Accessor;
using CM.Sites;
using CM.State;

using GamMatrix.Infrastructure;

using EveryMatrix.SessionAgent;

namespace OAuth
{
    public sealed class ReferrerData
    {
        private const int DB = 2;

        public string ID { get; private set; }
        public ExternalAuthParty AuthParty { get; set; }
        public ExternalAuthAction Action { get; set; }
        public long UserID { get; set; }
        public int DomainID { get; set; }
        public string DomainName { get; private set; }
        public string Language { get; private set; }
        public string IPAddress { get; private set; }
        public string UserAgent { get; private set; }
        public string ExternalID { get; set; }
        public string ReturnUrl { get; set; }
        public string CallbackUrl { get; set; }
        public string ProcessUrl { get; set; }
        public string SessionID { get; private set; }
        public string Channel { get; private set; }

        // for oauth v1.0
        public string OAuthToken { get; set; }
        public string OAuthTokenSecret { get; set; }

        public ExternalUserInfo ExternalUserInfo { get; set; }
        public string ErrorMessage { get; set; }

        //private static NonBlockingRedisClient _redisClient
        //    = new NonBlockingRedisClient(ConfigurationManager.AppSettings["SessionAgent.RedisServer"] ?? "10.0.10.38:6379");
        private static readonly NonBlockingRedisClient _redisClient = string.Equals(ConfigurationManager.AppSettings["SessionAgent.UseSentinel"], "true", StringComparison.InvariantCultureIgnoreCase)
            ? new NonBlockingRedisClient(ConfigurationManager.AppSettings["SessionAgent.SentinelAddress"].Split(";".ToCharArray(), StringSplitOptions.RemoveEmptyEntries), ConfigurationManager.AppSettings["SessionAgent.SentinelMasterName"])
            : new NonBlockingRedisClient(ConfigurationManager.AppSettings["SessionAgent.RedisServer"] ?? "10.0.10.38:6379");

        public AssociateStatus GetAssociateStatus()
        {
            using (var dbManager = new DbManager())
            {
                var ula = DataAccessor.CreateInstance<ExternalLoginAccessor>(dbManager);
                var ua = DataAccessor.CreateInstance<UserAccessor>(dbManager);

                var externalLogin = ula.GetUserByKey(this.ExternalID, this.DomainID, (int)this.AuthParty);
                if (externalLogin != null)
                {
                    return OAuth.AssociateStatus.Associated;
                }
                else if (!string.IsNullOrEmpty(this.ExternalUserInfo.Email))
                {
                    if (ua.GetByEmail(this.DomainID, this.ExternalUserInfo.Email) != null)
                        return OAuth.AssociateStatus.EmailAlreadyRegistered;
                    else
                        return OAuth.AssociateStatus.NotAssociated;
                }
                else
                {
                    return OAuth.AssociateStatus.NotAssociated;
                }
            }
        }

        public ReferrerData SetError(string errorMessage)
        {
            this.Action = ExternalAuthAction.Error;
            this.ErrorMessage = errorMessage;
            return this;
        }

        public ReferrerData Cancel()
        {
            this.Action = ExternalAuthAction.Cancel;
            return this;
        }

        internal static ReferrerData Create(CustomProfile profile)
        {
            ReferrerData data = new ReferrerData()
            {
                ID = Guid.NewGuid().ToString("N"),
                DomainID = SiteManager.Current.DomainID,
                DomainName = SiteManager.Current.DistinctName,
                UserID = profile.UserID,
                IPAddress = profile.LoginIP,
                SessionID = profile.SessionID
            };
            return data;
        }

        public void Save()
        {
            var dic = new Dictionary<string, byte[]>();
            dic.Add("AuthParty", Encoding.UTF8.GetBytes(AuthParty.ToString()));
            dic.Add("Action", Encoding.UTF8.GetBytes(Action.ToString()));
            dic.Add("UserID", Encoding.UTF8.GetBytes(UserID.ToString()));
            dic.Add("DomainID", Encoding.UTF8.GetBytes(DomainID.ToString()));

            if (!string.IsNullOrWhiteSpace(ErrorMessage))
                dic.Add("ErrorMessage", Encoding.UTF8.GetBytes(ErrorMessage));

            if (!string.IsNullOrWhiteSpace(Channel))
                dic.Add("Channel", Encoding.UTF8.GetBytes(Channel));

            if (!string.IsNullOrWhiteSpace(DomainName))
                dic.Add("DomainName", Encoding.UTF8.GetBytes(DomainName));

            if (!string.IsNullOrWhiteSpace(Language))
                dic.Add("Language", Encoding.UTF8.GetBytes(Language));

            if (!string.IsNullOrWhiteSpace(IPAddress))
                dic.Add("IPAddress", Encoding.UTF8.GetBytes(IPAddress));

            if (!string.IsNullOrWhiteSpace(UserAgent))
                dic.Add("UserAgent", Encoding.UTF8.GetBytes(UserAgent));

            if (!string.IsNullOrWhiteSpace(ExternalID))
                dic.Add("ExternalID", Encoding.UTF8.GetBytes(ExternalID));

            if (!string.IsNullOrWhiteSpace(ReturnUrl))
                dic.Add("ReturnUrl", Encoding.UTF8.GetBytes(ReturnUrl));

            if (!string.IsNullOrWhiteSpace(CallbackUrl))
                dic.Add("CallbackUrl", Encoding.UTF8.GetBytes(CallbackUrl));

            if (!string.IsNullOrWhiteSpace(ProcessUrl))
                dic.Add("ProcessUrl", Encoding.UTF8.GetBytes(ProcessUrl));

            if (!string.IsNullOrWhiteSpace(SessionID))
                dic.Add("SessionID", Encoding.UTF8.GetBytes(SessionID));

            if (!string.IsNullOrWhiteSpace(OAuthToken))
                dic.Add("OAuthToken", Encoding.UTF8.GetBytes(OAuthToken));

            if (!string.IsNullOrWhiteSpace(OAuthTokenSecret))
                dic.Add("OAuthTokenSecret", Encoding.UTF8.GetBytes(OAuthTokenSecret));
            if (ExternalUserInfo != null)
            {
                if (!string.IsNullOrWhiteSpace(ExternalUserInfo.ID))
                    dic.Add("Info_ID", Encoding.UTF8.GetBytes(ExternalUserInfo.ID));
                if (!string.IsNullOrWhiteSpace(ExternalUserInfo.Username))
                    dic.Add("Info_Username", Encoding.UTF8.GetBytes(ExternalUserInfo.Username));
                if (!string.IsNullOrWhiteSpace(ExternalUserInfo.Firstname))
                    dic.Add("Info_Firstname", Encoding.UTF8.GetBytes(ExternalUserInfo.Firstname));
                if (!string.IsNullOrWhiteSpace(ExternalUserInfo.Lastname))
                    dic.Add("Info_Lastname", Encoding.UTF8.GetBytes(ExternalUserInfo.Lastname));
                if (!string.IsNullOrWhiteSpace(ExternalUserInfo.Email))
                    dic.Add("Info_Email", Encoding.UTF8.GetBytes(ExternalUserInfo.Email));
                if (ExternalUserInfo.Birth != null)
                    dic.Add("Info_Birth", Encoding.UTF8.GetBytes(ExternalUserInfo.Birth.Value.ToBinary().ToString()));
                if (ExternalUserInfo.IsFemale != null)
                    dic.Add("Info_IsFemale", Encoding.UTF8.GetBytes(ExternalUserInfo.IsFemale.Value.ToString()));
            }

            _redisClient.SetAllByKey(this.ID, dic, 60 * 30);

            //using (var tran = _redis.CreateTransaction())
            //{
            //    tran.Hashes.Set(DB, this.ID, dic);
            //    tran.Keys.Expire(DB, this.ID, 60 * 30);
            //    Task<bool> tSave = tran.Execute();
            //    tSave.Wait();
            //}
        }

        public static ReferrerData Load(string referrerID)
        {
            //if (_redis == null)
            //    _redis = CreateRedisConnection();

            Dictionary<string, byte[]> map = _redisClient.GetAllByKey(referrerID);
            //using (Task<Dictionary<string, byte[]>> mapTask = _redis.Hashes.GetAll(DB, referrerID))
            //{
            //    mapTask.Wait();
            //    map = mapTask.Result;
            //}
            if (map == null || map.Count == 0)
                return null;

            ReferrerData data = new ReferrerData()
            {
                ID = referrerID,
            };


            byte[] bytes;

            if (map.TryGetValue("ErrorMessage", out bytes) && bytes != null && bytes.Length > 0)
                data.ErrorMessage = Encoding.UTF8.GetString(bytes);

            if (map.TryGetValue("SessionID", out bytes) && bytes != null && bytes.Length > 0)
                data.SessionID = Encoding.UTF8.GetString(bytes);

            if (map.TryGetValue("ReturnUrl", out bytes) && bytes != null && bytes.Length > 0)
                data.ReturnUrl = Encoding.UTF8.GetString(bytes);

            if (map.TryGetValue("CallbackUrl", out bytes) && bytes != null && bytes.Length > 0)
                data.CallbackUrl = Encoding.UTF8.GetString(bytes);

            if (map.TryGetValue("ProcessUrl", out bytes) && bytes != null && bytes.Length > 0)
                data.ProcessUrl = Encoding.UTF8.GetString(bytes);

            if (map.TryGetValue("ExternalID", out bytes) && bytes != null && bytes.Length > 0)
                data.ExternalID = Encoding.UTF8.GetString(bytes);

            if (map.TryGetValue("UserAgent", out bytes) && bytes != null && bytes.Length > 0)
                data.UserAgent = Encoding.UTF8.GetString(bytes);

            if (map.TryGetValue("IPAddress", out bytes) && bytes != null && bytes.Length > 0)
                data.IPAddress = Encoding.UTF8.GetString(bytes);

            if (map.TryGetValue("DomainName", out bytes) && bytes != null && bytes.Length > 0)
                data.DomainName = Encoding.UTF8.GetString(bytes);

            if (map.TryGetValue("Language", out bytes) && bytes != null && bytes.Length > 0)
                data.Language = Encoding.UTF8.GetString(bytes);

            if (map.TryGetValue("Channel", out bytes) && bytes != null && bytes.Length > 0)
                data.Channel = Encoding.UTF8.GetString(bytes);
            if (map.TryGetValue("OAuthToken", out bytes) && bytes != null && bytes.Length > 0)
                data.OAuthToken = Encoding.UTF8.GetString(bytes);

            if (map.TryGetValue("OAuthTokenSecret", out bytes) && bytes != null && bytes.Length > 0)
                data.OAuthTokenSecret = Encoding.UTF8.GetString(bytes);


            if (map.TryGetValue("AuthParty", out bytes) && bytes != null && bytes.Length > 0)
            {
                ExternalAuthParty authParty;
                if (Enum.TryParse<ExternalAuthParty>(Encoding.UTF8.GetString(bytes), out authParty))
                    data.AuthParty = authParty;
            }

            if (map.TryGetValue("Action", out bytes) && bytes != null && bytes.Length > 0)
            {
                ExternalAuthAction action;
                if (Enum.TryParse<ExternalAuthAction>(Encoding.UTF8.GetString(bytes), out action))
                {
                    data.Action = action;
                }
            }

            if (map.TryGetValue("UserID", out bytes) && bytes != null && bytes.Length > 0)
            {
                long userID = 0;
                if (long.TryParse(Encoding.UTF8.GetString(bytes), out userID) && userID >= 0)
                {
                    data.UserID = userID;
                }
            }

            if (map.TryGetValue("DomainID", out bytes) && bytes != null && bytes.Length > 0)
            {
                int domainID = 0;
                if (int.TryParse(Encoding.UTF8.GetString(bytes), out domainID) && domainID >= 0)
                {
                    data.DomainID = domainID;
                }
            }
            //ExternalUserInfo
            data.ExternalUserInfo = new ExternalUserInfo();
            if (map.TryGetValue("Info_ID", out bytes) && bytes != null && bytes.Length > 0)
                data.ExternalUserInfo.ID = Encoding.UTF8.GetString(bytes);
            if (map.TryGetValue("Info_Username", out bytes) && bytes != null && bytes.Length > 0)
                data.ExternalUserInfo.Username = Encoding.UTF8.GetString(bytes);
            if (map.TryGetValue("Info_Firstname", out bytes) && bytes != null && bytes.Length > 0)
                data.ExternalUserInfo.Firstname = Encoding.UTF8.GetString(bytes);
            if (map.TryGetValue("Info_Lastname", out bytes) && bytes != null && bytes.Length > 0)
                data.ExternalUserInfo.Lastname = Encoding.UTF8.GetString(bytes);
            if (map.TryGetValue("Info_Email", out bytes) && bytes != null && bytes.Length > 0)
                data.ExternalUserInfo.Email = Encoding.UTF8.GetString(bytes);
            if (map.TryGetValue("Info_Birth", out bytes) && bytes != null && bytes.Length > 0)
            {
                long birthBinary = 0;
                if (long.TryParse(Encoding.UTF8.GetString(bytes), out birthBinary))
                    data.ExternalUserInfo.Birth = DateTime.FromBinary(birthBinary);
            }
            if (map.TryGetValue("Info_IsFemale", out bytes) && bytes != null && bytes.Length > 0)
            {
                bool isFemale = false;
                if (bool.TryParse(Encoding.UTF8.GetString(bytes), out isFemale))
                    data.ExternalUserInfo.IsFemale = isFemale;
            }
            return data;
        }

        public static bool Delete(string referrerID)
        {
            //if (_redis == null)
            //    _redis = CreateRedisConnection();

            //Task<bool> delT = _redis.Keys.Remove(DB, referrerID);
            //delT.Wait();
            //return delT.Result;
            _redisClient.SetAllByKey(referrerID, null);
            return true;
        }

        
    }
}
