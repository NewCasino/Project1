<%@ WebHandler Language="C#" Class="_get_casinorace" %>

using System;
using System.Collections.Generic;
using System.Web;
using System.Web.Hosting;
using System.Globalization;
using System.Web.Script.Serialization;
using System.IO;
using System.Linq;
using System.Xml;
using System.Xml.Linq;
using BLToolkit.Data;
using BLToolkit.DataAccess;
using CM.db;
using CM.db.Accessor;

public class _get_casinorace : IHttpHandler {

    private static Dictionary<string, string> _jsonCache = new Dictionary<string, string>();
    private static object lockObj = new object();
    
    public void ProcessRequest (HttpContext context) {
        var xmlUrl = HttpUtility.UrlDecode(context.Request.QueryString["xmlurl"]
            .DefaultIfNullOrEmpty(string.Empty)
            );
        //var useUserInfo = context.Request.QueryString["userinfo"].DefaultIfNullOrEmpty("0").Equals("1");

        context.Response.ContentType = "application/json";
        if (string.IsNullOrEmpty(xmlUrl))
        {
            context.Response.Write("arguments error!");
        }
        else
        {
            context.Response.Write(GetRaceUserJson(xmlUrl));
        }
    }

    private string GetRaceUserJson(string xmlUrl, bool useUserInfo = true)
    {
        var key = string.Format(CultureInfo.InvariantCulture,"{0}-{1}", xmlUrl, useUserInfo.ToString().ToLower());
        
        Func<string> func = () =>
        {
            try
            {
                List<RaceInfo> raceList = FindRaceListFromXml(xmlUrl);
                ExpandRaceInfo(raceList);
                var jss = new JavaScriptSerializer();
                return jss.Serialize(raceList);

            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                throw;
            }
        };
        string cached;
        if (!_jsonCache.TryGetValue(key, out cached))
        {
            lock (lockObj)
            {
                if (!_jsonCache.TryGetValue(key, out cached))
                {
                    cached = func();
                }
            }
            
            
        }
    
        return cached;
    }

    static cmUser GetUserById(DbManager db, long userId)
    {
            UserAccessor ua = DataAccessor.CreateInstance<UserAccessor>(db);
            return ua.GetByID(userId);
    }
    static CountryInfo GetCountryById(int countryId)
    {
        return CountryManager.GetAllCountries().FirstOrDefault(c => c.InternalID == countryId);
    }
    static void ExpandRaceInfo(List<RaceInfo> raceList)
    {
        using (DbManager db = new DbManager())
        {
            foreach (var race in raceList)
            {
                var cmUser = GetUserById(db, race.PlayerID);
                if (cmUser == null)
                    continue;

                race.NickName = cmUser.Nickname.SafeJavascriptStringEncode();
                race.DisplayName = cmUser.DisplayName.SafeJavascriptStringEncode();
                race.CountryID = cmUser.CountryID;
                if (!string.IsNullOrEmpty(cmUser.FirstName) && !string.IsNullOrEmpty(cmUser.Surname))
                {
                    race.Initials = (cmUser.FirstName.Substring(0, 1) + cmUser.Surname.Substring(0, 1)).SafeJavascriptStringEncode();
                }
                else
                {
                    race.Initials = string.Empty;
                }

                var country = GetCountryById(race.CountryID);
                if (country == null)
                    continue;
                race.CountryName = country.EnglishName.SafeJavascriptStringEncode();
                race.CountryCode = country.GetCountryFlagName().SafeJavascriptStringEncode();
            }
        }
        
    }
    static List<RaceInfo> FindRaceListFromXml(string xmlUrl)
    {
        try
        {
            var xDoc = XDocument.Load(xmlUrl);
            return (from item in xDoc.Descendants("record")
                    select new RaceInfo
                    {
                        Rank = int.Parse(item.Element("Rank").Value),
                        PlayerID = long.Parse(item.Element("PlayerID").Value),
                        Score = int.Parse( item.Element("Score").Value)
                    }).ToList();
        }
        catch (Exception ex)
        {
            Logger.Exception(ex);
            return new List<RaceInfo>();
        }
    }

    class RaceInfo
    {
        public int Rank { get; set; }
        public long PlayerID { get; set; }
        public int Score { get; set; }
        public string DisplayName { get; set; }
        public string NickName { get; set; }
        public string Initials { get; set; }
        public int CountryID { get; set; }
        public string CountryName { get; set; }
        public string CountryCode { get; set; }
    }
    //class UserInfo
    //{
    //    public string DisplayName { get; set; }
    //    public string NickName { get; set; }
    //    public string Initials { get; set; }
    //    public int CountryID { get; set; }
    //    private CountryInfo2 _countryInfo;
    //    public CountryInfo2 CountryInfo
    //    {
    //        get {
    //            if (_countryInfo == null)
    //            { 
    //                var c = GetCountryById(CountryID);
    //                if (c != null)
    //                {
    //                    _countryInfo = new CountryInfo2()
    //                    {
    //                        Name = c.EnglishName.SafeJavascriptStringEncode(),
    //                        Code = c.GetCountryFlagName().SafeJavascriptStringEncode()
    //                    };
    //                }
    //                else
    //                    _countryInfo = new CountryInfo2();
    //            }
    //            return _countryInfo;
                
    //        }
    //        set { _countryInfo = value; }
    //    }
    //}
    //class CountryInfo2
    //{
    //    public string Name { get; set; }
    //    public string Code { get; set; }
    //}

    public bool IsReusable
    {
        get
        {
            return false;
        }
    }
}