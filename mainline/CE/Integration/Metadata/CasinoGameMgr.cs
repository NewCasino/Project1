using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using CE.db;
using Newtonsoft.Json;

namespace CE.Integration.Metadata
{
    public class CasinoGameMgr
    {
        public const string METADATA_GAME_INFORMATION = "game-information";
        public const string METADATA_DESCRIPTION = "description";

        public const string METADATA_PATH = "/casino/games";
        private string _metadataItemName;

        public CasinoGameMgr(string name)
        {
            _metadataItemName = name;
        }

        public List<Translation> Get(ceDomainConfig domain, long id)
        {
            //var path = string.Format("/casino/games/{0}.game-information", id.ToString(CultureInfo.InvariantCulture));
            string path = string.Format("{0}/{1}.{2}", METADATA_PATH, id.ToString(CultureInfo.InvariantCulture), _metadataItemName);
            var json = MetadataClient.GetTranslation(domain, path);

            var translations = new List<Translation>();

            using (var sr = new StringReader(json))
            using (var reader = new JsonTextReader(sr))
            {
                if (!reader.Read() || reader.TokenType != JsonToken.StartArray)
                    throw new Exception("Unknown format from metadata");

                while (reader.Read())
                {
                    if (reader.TokenType == JsonToken.StartObject)
                    {
                        var translation = Read(reader);
                        if (translation != null)
                            translations.Add(translation);
                    }
                    else if (reader.TokenType == JsonToken.EndArray)
                        break;
                    else
                        throw new Exception("Unknown format from metadata");
                }

            }
            return translations;
        }

        private Translation Read(JsonReader reader)
        {
            var translation = new Translation();
            while (reader.Read())
            {
                if (reader.TokenType == JsonToken.PropertyName)
                {
                    string name = ConvertHelper.ToString(reader.Value);
                    reader.Read();
                    switch (name.ToLowerInvariant())
                    {
                        case "code":
                            translation.Code = ConvertHelper.ToString(reader.Value);
                            break;
                        case "name":
                            translation.Name = ConvertHelper.ToString(reader.Value);
                            break;
                        case "hascontent":
                            translation.HasContent = ConvertHelper.ToBoolean(reader.Value);
                            break;
                        case "content":
                            translation.Content = ConvertHelper.ToString(reader.Value);
                            break;
                        case "isinherited":
                            translation.IsInherited = ConvertHelper.ToBoolean(reader.Value);
                            break;
                    }
                }
                else if (reader.TokenType == JsonToken.EndObject)
                    return translation;
            }
            return null;
        }

        public bool Update(ceDomainConfig domain, long id, Dictionary<string, string> translations, out string error)
        {
            error = null;
            //var path = string.Format("/casino/games/{0}.game-information", id.ToString(CultureInfo.InvariantCulture));
            string path = string.Format("{0}/{1}.{2}", METADATA_PATH, id.ToString(CultureInfo.InvariantCulture), _metadataItemName);
            using (var sw = new StringWriter())
            using (var writer = new JsonTextWriter(sw))
            {
                writer.WriteStartObject();
                foreach (var translation in translations)
                {
                    writer.WritePropertyName(translation.Key);
                    writer.WriteValue(translation.Value);
                }
                writer.WriteEndObject();

                var ret = MetadataClient.UpdateTranslation(domain, path, sw.ToString());
                if (ret == "success") 
                    return true;

                error = ret;
                return false;
            }
        }

        public bool Delete(ceDomainConfig domain, long id, List<string> languages, out string error)
        {
            error = null;
            //var path = string.Format("/casino/games/{0}.game-information", id.ToString(CultureInfo.InvariantCulture));
            string path = string.Format("{0}/{1}.{2}", METADATA_PATH, id.ToString(CultureInfo.InvariantCulture), _metadataItemName);
            using (var sw = new StringWriter())
            using (var writer = new JsonTextWriter(sw))
            {
                writer.WriteStartArray();
                foreach (var language in languages)
                {
                    writer.WriteValue(language);
                }
                writer.WriteEndArray();

                var ret = MetadataClient.DeleteTranslation(domain, path, sw.ToString());
                if (ret == "success")
                    return true;

                error = ret;
                return false;
            }
        }

    }
}
