using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Threading;
using CE.db;
using Newtonsoft.Json;

namespace CE.Integration.Metadata
{
    public class Translation
    {
        public string Name { get; set; }
        public string Code { get; set; }
        public bool HasContent { get; set; }
        public string Content { get; set; }
        public bool IsInherited { get; set; } 

        // TemplateID => ( Hash => Times )
        private static ConcurrentDictionary<int, ConcurrentDictionary<ulong, int>> _dic = new ConcurrentDictionary<int, ConcurrentDictionary<ulong, int>>();
        private static int _count = 0;

        internal static Dictionary<ulong, string> Get(ceDomainConfig domain, string lang, bool reloadCache = false)
        {
            string cacheFile = MetadataFileCache.GetPathWithRegion<Translation>(domain.DomainID.ToString(CultureInfo.InvariantCulture), lang);

            if (reloadCache)
                DelayUpdateCache<Dictionary<ulong, string>>.SetExpired(cacheFile);

            Func<Dictionary<ulong, string>> func = () =>
            {
                Dictionary<ulong, string> dic = new Dictionary<ulong, string>();

                // {"6883073332696432216":"Immediately","8464306736891375262":"Visa Credit Card","11378931541622277876":"Free","15079650489870782597":""}
                string json = MetadataClient.GetDumpedTranslation(domain, lang);
                using (StringReader sr = new StringReader(json))
                using (JsonTextReader reader = new JsonTextReader(sr))
                {

                    if (!reader.Read() || reader.TokenType != JsonToken.StartObject)
                        throw new Exception("Unknown format from metadata");

                    while (reader.Read())
                    {
                        if (reader.TokenType == JsonToken.PropertyName && reader.ValueType == typeof(string))
                        {
                            ulong hash;
                            if (!ulong.TryParse(reader.Value as string, out hash))
                                throw new Exception("Unknown format from metadata");
                            if (!reader.Read() || reader.TokenType != JsonToken.String)
                                throw new Exception("Unknown format from metadata");

                            dic[hash] = reader.Value as string;
                        }
                    }
                }

                return dic;
            };

            Dictionary<ulong, string> cache = null;
            bool ret = DelayUpdateCache<Dictionary<ulong, string>>.TryGetValue(cacheFile, out cache, func, 3600);
            if (ret)
                return cache;

            return func();
        }

        public static string GetByHash(ceDomainConfig domain, string lang, ulong hash)
        {
            Dictionary<ulong, string> dic = Get(domain, lang);
            string value = string.Empty;
            if (dic.TryGetValue(hash, out value))
            {
                // get the dic for domain
                ConcurrentDictionary<ulong, int> domainDic = null;
                while (!_dic.TryGetValue(domain.TemplateID, out domainDic))
                    _dic.TryAdd(domain.TemplateID, new ConcurrentDictionary<ulong, int>());
                for (; ; )
                {
                    int count = 0;
                    while (!domainDic.TryGetValue(hash, out count))
                        domainDic.TryAdd(hash, 0);

                    if (domainDic.TryUpdate(hash, count + 1, count))
                        break;
                }
                if ((Interlocked.Increment(ref _count) % 100) == 0)
                {
                    _count = 0;
                    ConcurrentDictionary<int, ConcurrentDictionary<ulong, int>> currentDic = _dic;
                    _dic = new ConcurrentDictionary<int, ConcurrentDictionary<ulong, int>>();
                    UploadStatistic(currentDic);
                }
                return value;
            }
            return string.Empty;
        }

        public static void UploadStatistic(ConcurrentDictionary<int, ConcurrentDictionary<ulong, int>> dic)
        {
            foreach (var domainItem in dic)
            {
                using (StringWriter sw = new StringWriter())
                using (JsonTextWriter writer = new JsonTextWriter(sw))
                {
                    writer.WriteStartObject();
                    foreach (var item in domainItem.Value)
                    {
                        writer.WritePropertyName(item.Key.ToString());
                        writer.WriteValue(item.Value);
                    }
                    writer.WriteEndObject();

                    MetadataClient.UploadStatistic(domainItem.Key, sw.ToString());
                }
            }
        }

    }
}
