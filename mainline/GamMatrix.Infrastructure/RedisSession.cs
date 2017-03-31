using System;
using System.Configuration;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Globalization;

using BookSleeve;

namespace GamMatrix.Infrastructure
{
    public sealed class RedisSession
    {
        private static RedisConnectionEx _redis = null;
        
        public bool NotExist { get; private set; }

        private string _sid;
        private Dictionary<string, byte[]> _map = new Dictionary<string,byte[]>();
        private Dictionary<string, bool> _changeFlags = new Dictionary<string, bool>();

        public string SessionID 
        {
            get { return _sid; }
            set { _sid = value; NotExist = true; }
        }

        private RedisSession(string sessionID, Dictionary<string, byte[]> map)
        {
            _map = map;
            this.SessionID = sessionID;
            this.NotExist = map.Count == 0;
        }

        public int UserID
        {
            get { return this.Get("gm_uid", 0); }
            set { this.Set("gm_uid", value); }
        }

        public string Username
        {
            get { return this.Get("gm_u", string.Empty); }
            set { this.Set("gm_u", value); }
        }

        public int DomainID
        {
            get { return this.Get("gm_did", 0); }
            set { this.Set("gm_did", value); }
        }

        public int UserCountryID
        {
            get { return this.Get("gm_uc", 0); }
            set { this.Set("gm_uc", value); }
        }

        public int IpCountryID
        {
            get { return this.Get("gm_ic", 0); }
            set { this.Set("gm_ic", value); }
        }

        public string UserCountryCode
        {
            get { return this.Get("uc", string.Empty); }
            set { this.Set("uc", value); }
        }

        public string IpCountryCode
        {
            get { return this.Get("ic", string.Empty); }
            set { this.Set("ic", value); }
        }

        public string DisplayName
        {
            get { return this.Get("dn", string.Empty); }
            set { this.Set("dn", value); }
        }

        public string FirstName
        {
            get { return this.Get("f", string.Empty); }
            set { this.Set("f", value); }
        }

        public string Surname
        {
            get { return this.Get("s", string.Empty); }
            set { this.Set("s", value); }
        }

        public string Alias
        {
            get { return this.Get("a", string.Empty); }
            set { this.Set("a", value); }
        }

        public bool IsAuthenticated
        {
            get { return this.Get("ia", false); }
            set { this.Set("ia", value); }
        }

        public string RoleString
        {
            get { return this.Get("rs", string.Empty); }
            set { this.Set("rs", value); }
        }

        public DateTime LastAccess
        {
            get { return this.Get("la", DateTime.MinValue); }
            set 
            {
                DateTime last = this.Get("la", DateTime.MinValue);
                if( Math.Abs((value - last).TotalSeconds) > 10 )
                    this.Set("la", value); 
            }
        }

        public DateTime LoginTime
        {
            get { return this.Get("lt", DateTime.MinValue); }
            set { this.Set("lt", value); }
        }

        public DateTime LastSyncTime
        {
            get { return this.Get("lst", DateTime.MinValue); }
            set { this.Set("lst", value); }
        }

        public int SessionLimitSeconds
        {
            get { return this.Get("sls", 0); }
            set { this.Set("sls", value); }
        }

        public string UserCurrency
        {
            get { return this.Get("gm_cur", "EUR"); }
            set { this.Set("gm_cur", value); }
        }

        public string PreferredCurrency
        {
            get { return this.Get("gm_pcur", "EUR"); }
            set { this.Set("gm_pcur", value); }
        }

        public string Email
        {
            get { return this.Get("e", string.Empty); }
            set { this.Set("e", value); }
        }

        public string AffiliateMarker
        {
            get { return this.Get("am", string.Empty); }
            set { this.Set("am", value); }
        }

        public string LoginIP
        {
            get { return this.Get("ip", string.Empty); }
            set { this.Set("ip", value); }
        }

        public bool IsExternal
        {
            get { return this.Get("ie", false); }
            set { this.Set("ie", value); }
        }

        public bool IsEmailVerified
        {
            get { return this.Get("iev", false); }
            set { this.Set("iev", value); }
        }

        public DateTime JoinTime
        {
            get { return this.Get("jt", DateTime.MinValue); }
            set { this.Set("jt", value); }
        }

        private static RedisConnectionEx CreateRedisConnection()
        {
            RedisConnectionEx redis = new RedisConnectionEx();
            Task t = redis.Open();
            t.Wait();
            return redis;
        }

        /// <summary>
        /// Read the session from redis
        /// </summary>
        /// <param name="sessionID"></param>
        /// <returns></returns>
        public static RedisSession Read(string sessionID)
        {
            if (_redis == null )
            {
                _redis = CreateRedisConnection();
            }

            try
            {
                var task = _redis.Hashes.GetAll(0, sessionID);
                task.Wait();
                Dictionary<string, byte[]> map = task.Result;
                if (map == null)
                    map = new Dictionary<string, byte[]>();
                return new RedisSession(sessionID, map);
            }
            catch
            {
                _redis = null;
                throw;
            }
        }


        public async static Task<RedisSession> ReadAsync(string sessionID)
        {
            if (_redis == null)
            {
                RedisConnectionEx redis = new RedisConnectionEx();
                await redis.Open();
                _redis = redis;
            }

            try
            {
                Dictionary<string, byte[]> map = await _redis.Hashes.GetAll(0, sessionID);
                if (map == null)
                    map = new Dictionary<string, byte[]>();
                return new RedisSession(sessionID, map);
            }
            catch
            {
                _redis = null;
                throw;
            }
        }

        /// <summary>
        /// Get the field value as string
        /// </summary>
        /// <param name="fieldName">field name</param>
        /// <param name="defaultValue">default value</param>
        /// <returns>field value</returns>
        public string Get(string fieldName, string defaultValue = null)
        {
            byte [] bytes;
            if (_map.TryGetValue(fieldName, out bytes))
            {
                return Encoding.UTF8.GetString(bytes);
            }
            return defaultValue;
        }

        /// <summary>
        /// Set field value
        /// </summary>
        /// <param name="fieldName">field name</param>
        /// <param name="value">field value</param>
        public void Set(string fieldName, string value)
        {
            if (_map.ContainsKey(fieldName) && Get(fieldName) == value)
                return;
            _map[fieldName] = (value == null) ? null : Encoding.UTF8.GetBytes(value);
            _changeFlags[fieldName] = true;
        }

        /// <summary>
        /// Get the field value as int
        /// </summary>
        /// <param name="fieldName">field name</param>
        /// <param name="defaultValue">default value</param>
        /// <returns>field value</returns>
        public int Get(string fieldName, int defaultValue)
        {
            byte[] bytes;
            if (_map.TryGetValue(fieldName, out bytes))
            {
                string temp = Encoding.UTF8.GetString(bytes);
                int value;
                if (int.TryParse(temp, NumberStyles.Integer, CultureInfo.InvariantCulture, out value))
                    return value;
            }
            return defaultValue;
        }

        /// <summary>
        /// Set field value
        /// </summary>
        /// <param name="fieldName">field name</param>
        /// <param name="value">field value</param>
        public void Set(string fieldName, int value)
        {
            if (_map.ContainsKey(fieldName) && Get(fieldName, -1) == value)
                return;
            _map[fieldName] = Encoding.UTF8.GetBytes(value.ToString(CultureInfo.InvariantCulture));
            _changeFlags[fieldName] = true;
        }

        /// <summary>
        /// Get the field value as long
        /// </summary>
        /// <param name="fieldName">field name</param>
        /// <param name="defaultValue">default value</param>
        /// <returns>field value</returns>
        public long Get(string fieldName, long defaultValue)
        {
            byte[] bytes;
            if (_map.TryGetValue(fieldName, out bytes))
            {
                string temp = Encoding.UTF8.GetString(bytes);
                long value;
                if (long.TryParse(temp, NumberStyles.Integer, CultureInfo.InvariantCulture, out value))
                    return value;
            }
            return defaultValue;
        }

        /// <summary>
        /// Set field value
        /// </summary>
        /// <param name="fieldName">field name</param>
        /// <param name="value">field value</param>
        public void Set(string fieldName, long value)
        {
            if (_map.ContainsKey(fieldName) && Get(fieldName, -1) == value)
                return;
            _map[fieldName] = Encoding.UTF8.GetBytes(value.ToString(CultureInfo.InvariantCulture));
            _changeFlags[fieldName] = true;
        }

        /// <summary>
        /// Get the field value as boolean
        /// </summary>
        /// <param name="fieldName">field name</param>
        /// <param name="defaultValue">default value</param>
        /// <returns>field value</returns>
        public bool Get(string fieldName, bool defaultValue)
        {
            byte[] bytes;
            if (_map.TryGetValue(fieldName, out bytes))
            {
                string temp = Encoding.UTF8.GetString(bytes);
                if (!string.IsNullOrWhiteSpace(temp))
                    return temp == "1";
            }
            return defaultValue;
        }

        /// <summary>
        /// Set field value
        /// </summary>
        /// <param name="fieldName">field name</param>
        /// <param name="value">field value</param>
        public void Set(string fieldName, bool value)
        {
            if (_map.ContainsKey(fieldName) && Get(fieldName, false) == value)
                return;
            _map[fieldName] = Encoding.UTF8.GetBytes(value ? "1" : "0");
            _changeFlags[fieldName] = true;
        }


        /// <summary>
        /// Get the field value as DateTime
        /// </summary>
        /// <param name="fieldName">field name</param>
        /// <param name="defaultValue">default value</param>
        /// <returns>field value</returns>
        public DateTime Get(string fieldName, DateTime defaultValue)
        {
            byte[] bytes;
            if (_map.TryGetValue(fieldName, out bytes))
            {
                string temp = Encoding.UTF8.GetString(bytes);
                DateTime value;
                if (DateTime.TryParseExact(temp, "yyyy-MM-dd HH:mm:ss", CultureInfo.InvariantCulture, DateTimeStyles.None, out value))
                    return value;
            }
            return defaultValue;
        }

        /// <summary>
        /// Set field value
        /// </summary>
        /// <param name="fieldName">field name</param>
        /// <param name="value">field value</param>
        public void Set(string fieldName, DateTime value)
        {
            if (_map.ContainsKey(fieldName) && Get(fieldName, DateTime.MinValue) == value)
                return;
            _map[fieldName] = Encoding.UTF8.GetBytes(value.ToString("yyyy-MM-dd HH:mm:ss"));
            _changeFlags[fieldName] = true;
        }

        /// <summary>
        /// Save the changes
        /// </summary>
        /// <returns></returns>
        public void Save()
        {
            if (string.IsNullOrWhiteSpace(this.SessionID))
                throw new ArgumentNullException("SessionID");

            if (_changeFlags.Count == 0)
                return;

            Dictionary<string, byte[]> dic = new Dictionary<string, byte[]>();
            foreach (var item in _changeFlags)
            {
                if (!item.Value)
                    continue;

                byte[] bytes;
                if (_map.TryGetValue(item.Key, out bytes))
                {
                    if (bytes != null)
                        dic[item.Key] = bytes;
                    else
                        _redis.Hashes.Remove(0, this.SessionID, item.Key);
                }
            }

            if (dic.Count == 0)
                return;

            if (_redis == null)
            {
                _redis = CreateRedisConnection();
            }

            try
            {
                _redis.Hashes.Set( 0, this.SessionID, dic);
                if( this.NotExist )
                    _redis.Keys.Expire( 0, this.SessionID, 3600 * 24);
            }
            catch
            {
                _redis = null;
                throw;
            }
            _changeFlags.Clear();
        }

        public static Task<bool> Remove(string sessionID)
        {
            if (string.IsNullOrWhiteSpace(sessionID))
                throw new ArgumentNullException("SessionID");

            return _redis.Keys.Remove(0, sessionID);
        }

        public static Task<bool> Invalidate(string sessionID)
        {
            if (string.IsNullOrWhiteSpace(sessionID))
                throw new ArgumentNullException("SessionID");

            _redis.Hashes.Set(0, sessionID, "ia", Encoding.UTF8.GetBytes("0"));
            return _redis.Keys.Expire(0, sessionID, 3600);
        }


        private const string USER_SESSION_KEY = "$CMS_USER_SESSION$";

        public static Task SaveUserSession(long userID, string sessionID)
        {
            if (_redis == null)
            {
                _redis = CreateRedisConnection();
            }
            return _redis.Hashes.Set( 0, USER_SESSION_KEY, userID.ToString( CultureInfo.InvariantCulture), sessionID);
        }

        public static Task<string> GetUserSession(long userID)
        {
            if (_redis == null)
            {
                _redis = CreateRedisConnection();
            }
            return _redis.Hashes.GetString( 0, USER_SESSION_KEY, userID.ToString( CultureInfo.InvariantCulture));
        }
    }
}
