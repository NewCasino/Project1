using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;
using System.Globalization;
using System.Configuration;

using GamMatrixAPI;

using Newtonsoft.Json;

namespace CE.Integration.Recommendation
{
    using db;

    public class GameRecommended
    {
        /// <summary>
        /// Get the recommended games 
        /// </summary>
        /// <param name="domainID">domain ID</param>
        /// <param name="isMobile">is mobile</param>
        /// <param name="userID">user ID</param>
        /// <param name="countryID">country ID</param>
        /// <param name="gender">Female / Male</param>
        /// <param name="age">age</param>
        /// <param name="maxNumber">The maximum records of the recommended games</param>
        /// <returns></returns>
        public static bool TryGet(long domainID,
            bool isMobile,
            VendorID vendor,
            string gameCode,
            out List<RecommendedGame> games)
        {
            string url = GetGameRecommendedUrl(domainID, isMobile, vendor, gameCode);

            bool success = RecommendedGame.TryGet(url, out games);
            if (success)
                games = games.Skip(1).ToList();
            return success;
//            string request = BuildRequest(domainID, isMobile, vendor, gameCode, maxRecords);

//            #region fake JSON
//            string json = @"{
//   ""code"":201,
//   ""message"":""success"",
//   ""results"":{
//      ""GameType"":""Desktop"",
//      ""Recolist"":[
//         [
//            ""NetEnt"",
//            ""lrtxsholdem_sw"",
//            0.5
//         ],
//         [
//            ""EGT"",
//            ""804"",
//            0.3
//         ],
//         [
//            ""PlaynGO"",
//            ""34"",
//            0.1
//         ]
//      ]
//   }
//}";
//            #endregion

//            return RecommendedGame.Parse(json);
        }

        private static string GetGameRecommendedUrl(long domainID,
            bool isMobile,
            VendorID vendor,
            string gameCode)
        {
            //http://109.205.93.227:8000/sim/?GameVendor={0}&amp;GameCode={1}&amp;GameType={2}&amp;TopN={3}
            string url = string.Format(CultureInfo.InvariantCulture
                , ConfigurationManager.AppSettings["Recommendation.GameRecommendedURL"]
                , RecommendedGame.ConvertToReportVendorID(vendor)
                , gameCode
                , isMobile ? "Mobile" : "Desktop");

            return url;
        }

        private static string BuildRequest(long domainID,
            bool isMobile,
            VendorID vendor,
            string gameCode,
            int maxRecords)
        {
            using (StringWriter sw = new StringWriter())
            using (JsonTextWriter writer = new JsonTextWriter(sw))
            {
                writer.WriteStartObject();

                writer.WritePropertyName("RequestTime");
                writer.WriteValue(DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss", CultureInfo.InvariantCulture));

                writer.WritePropertyName("GameType");
                writer.WriteValue(isMobile ? "mobile" : "desktop");

                writer.WritePropertyName("GameVendor");
                writer.WriteValue(vendor.ToString());

                writer.WritePropertyName("GameCode");
                writer.WriteValue(gameCode);

                writer.WritePropertyName("TopN");
                writer.WriteValue(maxRecords);

                writer.WritePropertyName("DomainSpecific");
                writer.WriteValue(domainID);

                writer.WriteEndObject();

                return sw.ToString();
            }
        }
    }
}
