using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;

using Newtonsoft.Json;
using System.Xml.Serialization;

using CmsSanityCheck.Model;

namespace CmsSanityCheck.Misc
{
    public class ObjectHelper
    {
        //Server Statuses, IP Address -> UP / DOWN
        public static Dictionary<string, bool> LoadServerStatuses(Service service)
        {
            try
            {
                string filename = service.Name.Replace(" ", "") + "_server.json";
                string path = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "data", filename);
                string json = FileSystemHelper.ReadWithoutLock(path);
                if (string.IsNullOrWhiteSpace(json))
                    return new Dictionary<string, bool>();

                Dictionary<string, bool> statuses = JsonConvert.DeserializeObject<Dictionary<string, bool>>(json);
                if (statuses == null)
                    return new Dictionary<string, bool>();

                return statuses;
            }
            catch
            {
                return new Dictionary<string, bool>();
            }
        }

        public static void SaveServerStatuses(Service service, Dictionary<string, bool> serverStatuses)
        {
            string path = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "data");
            if (!Directory.Exists(path))
                Directory.CreateDirectory(path);
            string filename = service.Name.Replace(" ", "") + "_server.json";
            path = Path.Combine(path, filename);
            string json = JsonConvert.SerializeObject(serverStatuses);
            FileSystemHelper.WriteWithoutLock(path, json);
        }

        //Site Statuses, Site ID -> IP Address -> UP / DOWN
        public static Dictionary<int, Dictionary<string, bool>> LoadSiteStatuses(Service service)
        {
            try
            {
                string filename = service.Name.Replace(" ", "") + "_site.json";
                string path = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "data", filename);
                string json = FileSystemHelper.ReadWithoutLock(path);
                if (string.IsNullOrWhiteSpace(json))
                    return new Dictionary<int, Dictionary<string, bool>>();

                Dictionary<int, Dictionary<string, bool>> statuses = JsonConvert.DeserializeObject<Dictionary<int, Dictionary<string, bool>>>(json);
                if (statuses == null)
                    return new Dictionary<int, Dictionary<string, bool>>();

                return statuses;
            }
            catch
            {
                return new Dictionary<int, Dictionary<string, bool>>();
            }
        }

        public static void SaveSiteStatuses(Service service, Dictionary<int, Dictionary<string, bool>> siteStatuses)
        {
            string path = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "data");
            if (!Directory.Exists(path))
                Directory.CreateDirectory(path);
            string filename = service.Name.Replace(" ", "") + "_site.json";
            path = Path.Combine(path, filename);
            string json = JsonConvert.SerializeObject(siteStatuses);
            FileSystemHelper.WriteWithoutLock(path, json);
        }

        //Page Statuses, Page Url -> IP Address -> Result Type
        public static Dictionary<string, Dictionary<string, ResultType>> LoadPageStatuses(Service service)
        {
            try
            {
                string filename = service.Name.Replace(" ", "") + "_page.json";
                string path = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "data", filename);
                string json = FileSystemHelper.ReadWithoutLock(path);
                if (string.IsNullOrWhiteSpace(json))
                    return new Dictionary<string, Dictionary<string, ResultType>>();

                Dictionary<string, Dictionary<string, ResultType>> statuses = JsonConvert.DeserializeObject<Dictionary<string, Dictionary<string, ResultType>>>(json);
                if (statuses == null)
                    return new Dictionary<string, Dictionary<string, ResultType>>();

                return statuses;
            }
            catch
            {
                return new Dictionary<string, Dictionary<string, ResultType>>();
            }
        }

        public static void SavePageStatuses(Service service, Dictionary<string, Dictionary<string, ResultType>> pageStatuses)
        {
            string path = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "data");
            if (!Directory.Exists(path))
                Directory.CreateDirectory(path);
            string filename = service.Name.Replace(" ", "") + "_page.json";
            path = Path.Combine(path, filename);
            string json = JsonConvert.SerializeObject(pageStatuses);
            FileSystemHelper.WriteWithoutLock(path, json);
        }

        public static List<PageResult> LoadPageResults(Service service)
        {
            //return new List<PageResult>();
            try
            {
                string filename = service.Name.Replace(" ", "") + ".json";
                string path = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "data", filename);
                string json = FileSystemHelper.ReadWithoutLock(path);
                if (string.IsNullOrWhiteSpace(json))
                    return new List<PageResult>();

                List<PageResult> results = new List<PageResult>();

                using (StringReader sr = new StringReader(json))
                using (JsonTextReader reader = new JsonTextReader(sr))
                {
                    if (!reader.Read() || reader.TokenType != JsonToken.StartArray)
                        throw new Exception("Invalid format");

                    while (reader.Read())
                    {
                        if (reader.TokenType != JsonToken.StartObject)
                            continue;

                        PageResult result = new PageResult();
                        
                        while (reader.Read())
                        {
                            if (reader.TokenType == JsonToken.PropertyName)
                            {
                                string name = reader.Value as string;
                                reader.Read();
                                switch (name.ToLowerInvariant())
                                {
                                    case "friendly-url":
                                        result.FriendlyUrl = reader.Value as string;
                                        break;
                                    case "ip-address":
                                        result.IPAddress = reader.Value as string;
                                        break;
                                    case "site-id":
                                        result.SiteID = Convert.ToInt32(reader.Value);
                                        break;
                                    case "domain-id":
                                        result.DomainID = Convert.ToInt32(reader.Value);
                                        break;
                                    case "result-type":
                                        result.ResultType = (ResultType)Enum.Parse(typeof(ResultType), reader.Value as string);
                                        break;
                                    case "status-code":
                                        result.StatusCode = Convert.ToInt32(reader.Value);
                                        break;
                                }
                            }
                            else if (reader.TokenType == JsonToken.EndObject)
                            {
                                results.Add(result);
                                break;
                            }
                        }
                    }
                }

                return results;
            }
            catch
            {
                return new List<PageResult>();
            }
        }

        public static void SavePageResults(Service service, List<PageResult> results)
        {
            string path = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "data");
            if (!Directory.Exists(path))
                Directory.CreateDirectory(path);
            string filename = service.Name.Replace(" ", "") + ".json";
            path = Path.Combine(path, filename);

            using (StringWriter sw = new StringWriter())
            using (JsonTextWriter writer = new JsonTextWriter(sw))
            {
                writer.WriteStartArray();

                foreach (PageResult result in results)
                {
                    writer.WriteStartObject();

                    writer.WritePropertyName("friendly-url");
                    writer.WriteValue(result.FriendlyUrl);

                    writer.WritePropertyName("ip-address");
                    writer.WriteValue(result.IPAddress);

                    writer.WritePropertyName("site-id");
                    writer.WriteValue(result.SiteID);

                    writer.WritePropertyName("domain-id");
                    writer.WriteValue(result.DomainID);

                    writer.WritePropertyName("result-type");
                    writer.WriteValue(result.ResultType.ToString());

                    writer.WritePropertyName("status-code");
                    writer.WriteValue(result.StatusCode);

                    writer.WriteEndObject();
                }

                writer.WriteEndArray();

                FileSystemHelper.WriteWithoutLock(path, sw.ToString());
            }
        }

        public static string JsonSerialize(object obj)
        {
            string json = JsonConvert.SerializeObject(obj);
            return json;
        }

        public static T JsonDeserialize<T>(string json)
        {
            T t = JsonConvert.DeserializeObject<T>(json);
            return t;
        }

        public static string XmlSerialize<T>(T t)
        {
            using (var memoryStream = new MemoryStream())
            {
                using (var reader = new StreamReader(memoryStream, Encoding.UTF8))
                {
                    var serializer = new XmlSerializer(t.GetType());
                    serializer.Serialize(memoryStream, t);
                    memoryStream.Position = 0;
                    return reader.ReadToEnd();
                }
            }
        }

        public static T XmlDeserialize<T>(string xml)
        {
            if (string.IsNullOrWhiteSpace(xml))
                return default(T);
            try
            {
                var mySerializer = new XmlSerializer(typeof(T));
                using (var ms = new MemoryStream(Encoding.UTF8.GetBytes(xml)))
                {
                    using (var sr = new StreamReader(ms, Encoding.UTF8))
                    {
                        return (T)mySerializer.Deserialize(sr);
                    }
                }
            }
            catch
            {
                return default(T);
            }
        }

    }
}
