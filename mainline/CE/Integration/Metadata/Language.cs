using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Runtime.Serialization;
using System.Threading.Tasks;

using CE.db;
using Newtonsoft.Json;

namespace CE.Integration.Metadata
{
    [DataContract]
    [Serializable]
    public sealed class Language
    {
        [DataMember(Name = "name")]
        public string DisplayName { get; private set; }

        [DataMember(Name = "code")]
        public string RFC1766 { get; private set; }


        /// <summary>
        /// Get All the languages for the current domain
        /// </summary>
        /// <param name="domain"></param>
        /// <param name="reloadCache"></param>
        /// <returns></returns>
        public static Language[] GetAll(ceDomainConfig domain, bool reloadCache = false)
        {
            string cacheFile = MetadataFileCache.GetPath<Language>(domain.DomainID.ToString(CultureInfo.InvariantCulture));

            if (reloadCache)
                DelayUpdateCache<Dictionary<string, Language>>.SetExpired(cacheFile);

            Func<Language[]> func = () =>
            {
                List<Language> list = new List<Language>();

                // {"ar":{"name":"\u0627\u0644\u0639\u0631\u0628\u064A\u0629"},"cs":{"name":"\u010Ce\u0161tina"},"en":{"name":"English"}}
                string json = MetadataClient.GetLanguages(domain);
                using (StringReader sr = new StringReader(json))
                using (JsonTextReader reader = new JsonTextReader(sr))
                {

                    if (!reader.Read() || reader.TokenType != JsonToken.StartObject)
                        throw new Exception("Unknown format from metadata");

                    Language lang = null;
                    while (reader.Read())
                    {
                        if (lang == null)
                        {
                            if (reader.TokenType == JsonToken.PropertyName && reader.ValueType == typeof(string))
                            {
                                lang = new Language() { RFC1766 = reader.Value as string };
                                if (!reader.Read() || reader.TokenType != JsonToken.StartObject)
                                    throw new Exception("Unknown format from metadata");
                            }
                            else if (reader.TokenType == JsonToken.EndObject)
                                break;
                            else
                                throw new Exception("Unknown format from metadata");
                        }
                        else
                        {
                            if (reader.TokenType == JsonToken.EndObject)
                            {
                                list.Add(lang);
                                lang = null;
                            }
                            else if (reader.TokenType == JsonToken.PropertyName)
                            {
                                if (reader.ValueType == typeof(string) &&
                                    reader.Value as string == "name")
                                {
                                    if (!reader.Read() || reader.TokenType != JsonToken.String)
                                        throw new Exception("Unknown format from metadata");
                                    lang.DisplayName = reader.Value as string;
                                }
                            }
                            else
                                throw new Exception("Unknown format from metadata");
                        }
                    }
                }

                return list.ToArray();
            };

            Language[] cache = null;
            bool ret = DelayUpdateCache<Language[]>.TryGetValue(cacheFile, out cache, func, 36000);
            if (ret)
                return cache;

            return func();
        }


    }
}
