using System;
using System.Collections.Generic;
using System.Globalization;
using System.Web;
using System.Web.Hosting;
using System.Collections;
using System.Text.RegularExpressions;
using System.Threading;
using System.Configuration;
using System.Net;
using System.IO;

using MaxMind;

namespace CE.Utils
{
    /// <summary>
    /// Summary description for IPLocation
    /// </summary>
    [Serializable]
    public sealed class IPLocation
    {
        private static LookupService _ls;

        #region CountryCode => ID
        private static Dictionary<string, int> _map = new Dictionary<string, int>(StringComparer.InvariantCultureIgnoreCase)
        {
            { "AF", 8},
            { "AL", 9},
            { "DZ", 10},
            { "AS", 11},
            { "AD", 12},
            { "AO", 13},
            { "AI", 14},
            { "AQ", 15},
            { "AG", 16},
            { "AR", 17},
            { "AM", 18},
            { "AW", 19},
            { "AU", 20},
            { "AT", 21},
            { "AZ", 22},
            { "BS", 23},
            { "BH", 24},
            { "BD", 25},
            { "BB", 26},
            { "BY", 27},
            { "BE", 28},
            { "BZ", 29},
            { "BJ", 30},
            { "BM", 31},
            { "BT", 32},
            { "BO", 33},
            { "BA", 34},
            { "BW", 35},
            { "BV", 36},
            { "BR", 37},
            { "IO", 38},
            { "BN", 39},
            { "BG", 40},
            { "BF", 41},
            { "BI", 42},
            { "KH", 43},
            { "CM", 44},
            { "CA", 45},
            { "CV", 46},
            { "KY", 47},
            { "CF", 48},
            { "TD", 49},
            { "CL", 50},
            { "CN", 51},
            { "CX", 52},
            { "CC", 53},
            { "CO", 54},
            { "KM", 55},
            { "CG", 56},
            { "CK", 57},
            { "CR", 58},
            { "CI", 59},
            { "HR", 60},
            { "CU", 61},
            { "CY", 62},
            { "CZ", 63},
            { "DK", 64},
            { "DJ", 65},
            { "DM", 66},
            { "DO", 67},
            { "EC", 69},
            { "EG", 70},
            { "SV", 71},
            { "GQ", 72},
            { "ER", 73},
            { "EE", 74},
            { "ET", 75},
            { "FK", 76},
            { "FO", 77},
            { "FJ", 78},
            { "FI", 79},
            { "FR", 80},
            { "GF", 82},
            { "PF", 83},
            { "TF", 84},
            { "GA", 85},
            { "GM", 86},
            { "DE", 88},
            { "GH", 89},
            { "GI", 90},
            { "GR", 91},
            { "GL", 92},
            { "GD", 93},
            { "GP", 94},
            { "GU", 95},
            { "GT", 96},
            { "GN", 97},
            { "GW", 98},
            { "GY", 99},
            { "HT", 100},
            { "HM", 101},
            { "VA", 236},
            { "HN", 102},
            { "HK", 103},
            { "HU", 104},
            { "IS", 105},
            { "IN", 106},
            { "ID", 107},
            { "IR", 108},
            { "IQ", 109},
            { "IE", 110},
            { "IL", 111},
            { "IT", 112},
            { "JM", 113},
            { "JP", 114},
            { "JO", 115},
            { "KZ", 116},
            { "KE", 117},
            { "KI", 118},
            { "KP", 164},
            { "KR", 202},
            { "KW", 119},
            { "KG", 120},
            { "LA", 121},
            { "LV", 122},
            { "LB", 123},
            { "LS", 124},
            { "LR", 125},
            { "LY", 126},
            { "LI", 127},
            { "LT", 128},
            { "LU", 129},
            { "MO", 130},
            { "MK", 131},
            { "MG", 132},
            { "MW", 133},
            { "MY", 134},
            { "MV", 135},
            { "ML", 136},
            { "MT", 137},
            { "MH", 138},
            { "MQ", 139},
            { "MR", 140},
            { "MU", 141},
            { "YT", 142},
            { "MX", 143},
            { "FM", 144},
            { "MD", 145},
            { "MC", 146},
            { "MN", 147},
            { "MS", 148},
            { "MA", 149},
            { "MZ", 150},
            { "MM", 151},
            { "NA", 152},
            { "NR", 153},
            { "NP", 154},
            { "NL", 155},
            { "AN", 156},
            { "NC", 157},
            { "NZ", 158},
            { "NI", 159},
            { "NE", 160},
            { "NG", 161},
            { "NU", 162},
            { "NF", 163},
            { "MP", 165},
            { "NO", 166},
            { "OM", 167},
            { "PK", 169},
            { "PW", 170},
            { "PA", 171},
            { "PG", 172},
            { "PY", 173},
            { "PE", 174},
            { "PH", 175},
            { "PN", 176},
            { "PL", 177},
            { "PT", 178},
            { "PR", 179},
            { "QA", 180},
            { "RE", 181},
            { "RO", 182},
            { "RU", 183},
            { "RW", 184},
            { "SH", 205},
            { "KN", 185},
            { "LC", 186},
            { "PM", 206},
            { "VC", 187},
            { "WS", 188},
            { "SM", 189},
            { "ST", 190},
            { "SA", 191},
            { "SN", 192},
            { "RS", 247},
            { "ME", 248},
            { "SC", 193},
            { "SL", 194},
            { "SG", 195},
            { "SK", 196},
            { "SI", 197},
            { "SB", 198},
            { "SO", 199},
            { "ZA", 200},
            { "GS", 201},
            { "ES", 203},
            { "LK", 204},
            { "SD", 207},
            { "SR", 208},
            { "SJ", 209},
            { "SZ", 210},
            { "SE", 211},
            { "CH", 212},
            { "SY", 213},
            { "TW", 214},
            { "TJ", 215},
            { "TZ", 216},
            { "TH", 217},
            { "TG", 218},
            { "TK", 219},
            { "TO", 220},
            { "TT", 221},
            { "TN", 222},
            { "TR", 223},
            { "TM", 224},
            { "TC", 225},
            { "TV", 226},
            { "UG", 227},
            { "UA", 228},
            { "AE", 229},
            { "GB", 230},
            { "US", 231},
            { "UM", 232},
            { "UY", 233},
            { "UZ", 234},
            { "VU", 235},
            { "VE", 237},
            { "VN", 238},
            { "VG", 240},
            { "VI", 239},
            { "WF", 241},
            { "EH", 242},
            { "YE", 243},
            { "ZM", 245},
            { "ZW", 246},
            { "GE", 87},
        };

        #endregion

        public bool Found { get; set; }
        public string IP { get; set; }
        public int CountryID { get; set; }        
        public string CountryCode { get; set; }
        public string CountryName { get; set; }
        public double Longitude { get; set; }
        public double Latitude { get; set; }
        public string RegionCode { get; set; }
        public string RegionName { get; set; }
        public string City { get; set; }
        public string Zip { get; set; }
        public string MetroCode { get; set; }
        public string AreaCode { get; set; }

        public static IPLocation GetByIP(string ip)
        {
            string cacheKey = string.Format(CultureInfo.InvariantCulture, "IPLocation.GetByIP.{0}", ip);
            IPLocation ipLocation = HttpRuntime.Cache[cacheKey] as IPLocation;
            if (ipLocation != null)
                return ipLocation;

            if (_ls == null)
            {
                lock (typeof(IPLocation))
                {
                    if (_ls == null)
                    {
                        string dataFile = HostingEnvironment.MapPath("~/App_Data/geoip.dat");
                        _ls = new LookupService(dataFile, LookupService.GEOIP_MEMORY_CACHE);
                    }
                }
            }

            ipLocation = new IPLocation();
            ipLocation.IP = ip;

            Country c = _ls.getCountry(ip);
            if (c != null && c.getCode() != "--")
            {
                ipLocation.CountryCode = c.getCode();
                ipLocation.CountryName = c.getName();
            }

            Location loc = _ls.getLocation(ip);
            if (loc != null)
            {
                ipLocation.CountryCode = loc.countryCode;
                ipLocation.CountryName = loc.countryName;
                ipLocation.RegionCode = loc.region;
                ipLocation.RegionName = loc.regionName;
                ipLocation.City = loc.city;
                ipLocation.Zip = loc.postalCode;
                ipLocation.MetroCode = loc.metro_code.ToString(CultureInfo.InvariantCulture);
                ipLocation.AreaCode = loc.area_code.ToString(CultureInfo.InvariantCulture);
                ipLocation.Latitude = loc.latitude;
                ipLocation.Longitude = loc.longitude;
            }

            int countryID;
            if (!string.IsNullOrEmpty(ipLocation.CountryCode) &&
                _map.TryGetValue(ipLocation.CountryCode, out countryID))
            {
                ipLocation.Found = true;
                ipLocation.CountryID = countryID;
            }

            HttpRuntime.Cache[cacheKey] = ipLocation;

            return ipLocation;
        }
        public static void UpdateToLatest()
        {
            BackgroundThreadPool.QueueUserWorkItem("DownloadGeoIPDatabase", new WaitCallback(DownloadGeoIPDatabase), null, true);
        }

        public static void DownloadGeoIPDatabase(object state = null)
        {
            try
            {
                string url = ConfigurationManager.AppSettings["GeoIP.DownloadUrl"];
                string geoIPFile = HostingEnvironment.MapPath("~/App_Data/geoip_new.dat");
                url += "?_t=" + DateTime.Now.Ticks.ToString();

                HttpWebRequest request = HttpWebRequest.Create(url) as HttpWebRequest;
                request.KeepAlive = false;
                request.Method = "GET";
                request.ProtocolVersion = Version.Parse("1.0");
                //request.AutomaticDecompression = DecompressionMethods.GZip | DecompressionMethods.Deflate;
                //request.Accept = "text/plain";
                request.Accept = "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8";
                request.UserAgent = "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2272.89 Safari/537.36";
                request.Headers["Accept-Encoding"] = "gzip, deflate, sdch";

                HttpWebResponse response = request.GetResponse() as HttpWebResponse;

                using (Stream stream = response.GetResponseStream())
                using (FileStream fs = new FileStream(geoIPFile, FileMode.OpenOrCreate, FileAccess.Write, FileShare.ReadWrite | FileShare.Delete))
                using (BinaryWriter writer = new BinaryWriter(fs))
                {
                    byte[] buffer = new byte[4096];
                    int size;
                    while ((size = stream.Read(buffer, 0, buffer.Length)) > 0)
                        writer.Write(buffer, 0, size);
                    writer.Flush();
                    writer.Close();
                }
                response.Close();

                UpdateFile(geoIPFile);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
            }
            finally
            {
                Reload();
            }
        }

        public static void UpdateFile(string geoIPFile)
        {
            FileInfo info = new FileInfo(geoIPFile);
            //if the file length is less than 1M, it is not correct, ignore it.
            if (info.Length < 1048576)
                return;

            string dataFile = HostingEnvironment.MapPath("~/App_Data/geoip.dat");
            File.Copy(geoIPFile, dataFile, true);
            File.Delete(geoIPFile);
        }

        public static void Reload()
        {
            try
            {
                if (_ls != null)
                {
                    _ls.close();
                    _ls = null;
                }
                lock (typeof(IPLocation))
                {
                    string dataFile = HostingEnvironment.MapPath("~/App_Data/geoip.dat");
                    _ls = new LookupService(dataFile, LookupService.GEOIP_MEMORY_CACHE);
                }

                string cacheKeyPrefix = "IPLocation.GetByIP.";
                List<string> keys = new List<string>();
                foreach (DictionaryEntry entry in HttpRuntime.Cache)
                {
                    string key = entry.Key as string;
                    if (key.StartsWith(cacheKeyPrefix, StringComparison.InvariantCultureIgnoreCase))
                    {
                        keys.Add(key);
                    }
                }
                foreach (var key in keys)
                    HttpRuntime.Cache.Remove(key);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
            }
        }
    }
}