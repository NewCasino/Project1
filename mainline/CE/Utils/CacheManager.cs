using System;
using System.Collections;
using System.Collections.Generic;
using System.Collections.Specialized;
using System.Configuration;
using System.IO;
using System.Linq;
using System.Net;
using System.Web;
using System.Web.Caching;
using System.Web.Mvc;
using CE.db;
using CE.db.Accessor;
using CE.Utils;
using Newtonsoft.Json;

public static class CacheManager
{
    private static readonly string GAME_CACHE_KEY_FORMAT = @"{0}{1}";
    public static Dictionary<string, ceCasinoGameBaseEx> GetGameDictionary(long domainID
        , bool excludeDisabled = true
        , bool excludeOperatorInvisible = true
        , bool allowCache = true)
    {
        string cacheKey = string.Format(GAME_CACHE_KEY_FORMAT, Constant.DomainGamesCachePrefix, domainID);
        cacheKey = string.Format("{0}{1}{2}dict", cacheKey, excludeDisabled, excludeOperatorInvisible);
        Dictionary<string, ceCasinoGameBaseEx> games = HttpRuntime.Cache[cacheKey] as Dictionary<string, ceCasinoGameBaseEx>;
        if (games != null && allowCache)
            return games;

        List<ceCasinoGameBaseEx> allGames = GetGameList(domainID, excludeDisabled, excludeOperatorInvisible, allowCache);

        games = allGames.ToDictionary(g => g.ID.ToString(), g => g);

        foreach (ceCasinoGameBaseEx game in allGames.Where(g => !string.IsNullOrWhiteSpace(g.Slug)))
        {
            games.Add(game.Slug, game);
        }

        CacheManager.AddCache(cacheKey, games);
        return games;
    }

    public static List<ceCasinoGameBaseEx> GetGameList(long domainID
        , bool excludeDisabled = true
        , bool excludeOperatorInvisible = true
        , bool allowCache = true)
    {
        string cacheKey = string.Format(GAME_CACHE_KEY_FORMAT, Constant.DomainGamesCachePrefix, domainID);
        cacheKey = string.Format("{0}{1}{2}list", cacheKey, excludeDisabled, excludeOperatorInvisible);
        List<ceCasinoGameBaseEx> games = HttpRuntime.Cache[cacheKey] as List<ceCasinoGameBaseEx>;
        if (games != null && allowCache)
            return games;

        games = CasinoGameAccessor.GetDomainGames(domainID, excludeDisabled, excludeOperatorInvisible);

        CacheManager.AddCache(cacheKey, games);
        return games;
    }

    public static Dictionary<string, ceLiveCasinoTableBaseEx> GetLiveCasinoTableDictionary(long domainID)
    {
        string cacheKey = string.Format(GAME_CACHE_KEY_FORMAT, Constant.DomainLiveCasinoTableCachePrefix, domainID);
        Dictionary<string, ceLiveCasinoTableBaseEx> tables = HttpRuntime.Cache[cacheKey] as Dictionary<string, ceLiveCasinoTableBaseEx>;
        if (tables != null)
            return tables;

        List<ceLiveCasinoTableBaseEx> allTables = LiveCasinoTableAccessor.GetDomainTables(domainID, null, true);

        tables = allTables.ToDictionary(t => t.ID.ToString(), t => t);
        CacheManager.AddCache(cacheKey, tables);
        return tables;
    }

    public static Dictionary<int, ceCasinoVendor> GetVendorDictionary(long domainID)
    {
        string cacheKey = string.Format(GAME_CACHE_KEY_FORMAT, Constant.DomainVendorsCachePrefix, domainID);
        Dictionary<int, ceCasinoVendor> vendors = HttpRuntime.Cache[cacheKey] as Dictionary<int, ceCasinoVendor>;
        if (vendors != null)
            return vendors;

        CasinoVendorAccessor cva = CasinoVendorAccessor.CreateInstance<CasinoVendorAccessor>();
        List<ceCasinoVendor> ceCasinoVendors = cva.GetEnabledVendorList(DomainManager.CurrentDomainID, Constant.SystemDomainID);

        vendors = ceCasinoVendors.ToDictionary(v=>v.VendorID, v=>v);

        CacheManager.AddCache(cacheKey, vendors);
        return vendors;
    }

    /// <summary>
    /// Add cache, and create dependency file if not exist
    /// </summary>
    /// <param name="cacheKey"></param>
    /// <param name="value"></param>
    public static void AddCache(string cacheKey, object value)
    {
        HttpRuntime.Cache.Insert(cacheKey, value,null, DateTime.Now.AddMinutes(30), Cache.NoSlidingExpiration);
    }

    public static void ClearCache(string prefixCacheKey)
    {
        NameValueCollection servers = ConfigurationManager.GetSection("servers") as NameValueCollection;
        if (servers == null || servers.Count == 0)
            throw new Exception("Error, can not find the server configration.");

        UrlHelper urlHelper = new UrlHelper(((MvcHandler)HttpContext.Current.Handler).RequestContext);
        foreach (string serverName in servers.Keys)
        {
            try
            {
                string url = string.Format("http://{0}{1}"
                    , servers[serverName]
                    , urlHelper.RouteUrl("Cache", new { @action = "ClearCache", @cachePrefix = prefixCacheKey })
                    );
                HttpWebRequest request = HttpWebRequest.Create(url) as HttpWebRequest;
                request.KeepAlive = false;
                request.Method = "GET";
                request.ProtocolVersion = Version.Parse("1.0");
                request.ContentLength = 0;
                request.AutomaticDecompression = DecompressionMethods.GZip | DecompressionMethods.Deflate;
                request.Accept = "text/plain";
                HttpWebResponse response = request.GetResponse() as HttpWebResponse;
                string respText = null;
                using (Stream stream = response.GetResponseStream())
                {
                    using (StreamReader sr = new StreamReader(stream))
                    {
                        respText = sr.ReadToEnd();
                    }
                }
                response.Close();

                
                bool success = string.Compare(respText, "OK", true) == 0;
                if (!success)
                    Logger.Information(string.Format("Error to clear cache {0} \n\n{1}", url, respText));
                else
                    Logger.Information(string.Format("Clear cache successfully! \n {0}", url));
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
            }
        }
    }

    public static void ClearCache(string[] prefixCacheKeys)
    {
        NameValueCollection servers = ConfigurationManager.GetSection("servers") as NameValueCollection;
        if (servers == null || servers.Count == 0)
            throw new Exception("Error, can not find the server configration.");

        UrlHelper urlHelper = new UrlHelper(((MvcHandler)HttpContext.Current.Handler).RequestContext);
        foreach (string serverName in servers.Keys)
        {
            try
            {
                string url = string.Format("http://{0}{1}"
                    , servers[serverName]
                    , urlHelper.RouteUrl("Cache", new { @action = "ClearCache" })
                    );
                string json = JsonConvert.SerializeObject(prefixCacheKeys);

                HttpWebRequest request = HttpWebRequest.Create(url) as HttpWebRequest;
                request.KeepAlive = false;
                request.Method = "POST";
                request.ProtocolVersion = Version.Parse("1.0");
                request.ContentLength = json.Length;
                request.AutomaticDecompression = DecompressionMethods.GZip | DecompressionMethods.Deflate;
                request.Accept = "text/plain";
                
                using (Stream stream = request.GetRequestStream())
                using (StreamWriter writer = new StreamWriter(stream))
                {
                    writer.Write(json);
                    writer.Flush();
                }
                
                HttpWebResponse response = request.GetResponse() as HttpWebResponse;
                string respText = null;
                using (Stream stream = response.GetResponseStream())
                {
                    using (StreamReader sr = new StreamReader(stream))
                    {
                        respText = sr.ReadToEnd();
                    }
                }
                response.Close();

                bool success = string.Compare(respText, "OK", true) == 0;
                if (!success)
                    Logger.Information(string.Format("Error to clear cache {0} \n\n{1}", url, respText));
                else
                    Logger.Information(string.Format("Clear cache successfully! \n {0}", url));
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
            }
        }
    }

    /// <summary>
    /// Delete the dependency file to clear cache on all servers
    /// </summary>
    /// <param name="prefixCacheKey"></param>
    public static void ClearLocalCache(string prefixCacheKey)
    {
        foreach (DictionaryEntry entry in HttpRuntime.Cache)
        {
            string key = entry.Key as string;
            if (key.StartsWith(prefixCacheKey, StringComparison.InvariantCultureIgnoreCase))
            {
                HttpRuntime.Cache.Remove(key);
            }
        }
    }

    /// <summary>
    /// Delete the dependency file to clear cache on all servers
    /// </summary>
    /// <param name="prefixCacheKeys"></param>
    public static void ClearLocalCache(string[] prefixCacheKeys)
    {
        List<string> keys = new List<string>();
        foreach (DictionaryEntry entry in HttpRuntime.Cache)
        {
            string key = entry.Key as string;
            foreach (string prefixCacheKey in prefixCacheKeys)
            {
                if (key.StartsWith(prefixCacheKey, StringComparison.InvariantCultureIgnoreCase))
                {
                    keys.Add(key);
                }
            }
        }

        foreach (string key in keys)
            HttpRuntime.Cache.Remove(key);
    }

    
    
}

