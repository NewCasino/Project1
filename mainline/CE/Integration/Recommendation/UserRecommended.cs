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

    public class UserRecommended
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
            long userID,
            int countryID,
            string gender,
            DateTime? birthday,
            out List<RecommendedGame> games)
        {

            //string request = BuildRequest(domainID, isMobile, userID, countryID, gender, birthday, maxRecords);
            string url = GetUserRecommendedUrl(domainID, isMobile, userID, countryID, gender, birthday);

            return RecommendedGame.TryGet(url, out games);

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

        private static string GetUserRecommendedUrl(long domainID,
            bool isMobile,
            long userID,
            int countryID,
            string gender,
            DateTime? birthday)
        {
            #region Parse parameters
            if (string.Equals(gender, "M", StringComparison.InvariantCultureIgnoreCase))
                gender = "Male";
            else if (string.Equals(gender, "F", StringComparison.InvariantCultureIgnoreCase))
                gender = "Female";
            else
                gender = string.Empty;

            int? age = null;
            if (birthday.HasValue)
            {
                DateTime now = DateTime.Now;
                age = now.Year - birthday.Value.Year;
                if (birthday.Value.AddYears(age.Value) < now)
                    age = age - 1;
            }
            #endregion

            //http://109.205.93.227:8000/rec/?userID={0}&amp;Age={1}&amp;Gender={2}&amp;GameType={3}&amp;TopN={4}
            string url = string.Format(CultureInfo.InvariantCulture
                , ConfigurationManager.AppSettings["Recommendation.UserRecommendedURL"]
                , userID
                , age.HasValue ? age.Value.ToString(CultureInfo.InvariantCulture) : string.Empty
                , gender
                , isMobile ? "Mobile" : "Desktop");

            return url;
        }

        private static string BuildRequest(long domainID,
            bool isMobile,
            long userID,
            int countryID,
            string gender,
            DateTime? birthday,
            int maxRecords)
        {
            #region Parse parameters
            if (string.Equals(gender, "M", StringComparison.InvariantCultureIgnoreCase))
                gender = "Male";
            else if (string.Equals(gender, "F", StringComparison.InvariantCultureIgnoreCase))
                gender = "Female";
            else
                gender = string.Empty;

            int? age = null;
            if (birthday.HasValue)
            {
                DateTime now = DateTime.Now;
                age = now.Year - birthday.Value.Year;
                if (birthday.Value.AddYears(age.Value) < now)
                    age = age - 1;
            }
            #endregion

            using (StringWriter sw = new StringWriter())
            using (JsonTextWriter writer = new JsonTextWriter(sw))
            {
                writer.WriteStartObject();

                writer.WritePropertyName("RequestTime");
                writer.WriteValue(DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss", CultureInfo.InvariantCulture));

                writer.WritePropertyName("GameType");
                writer.WriteValue(isMobile ? "mobile" : "desktop");

                writer.WritePropertyName("UserId");
                writer.WriteValue(userID);

                writer.WritePropertyName("CountryId");
                writer.WriteValue(countryID);

                writer.WritePropertyName("Gender");
                writer.WriteValue(gender);

                writer.WritePropertyName("Age");
                writer.WriteValue(age);

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
