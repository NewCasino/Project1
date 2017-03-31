using System;
using System.Text;
using System.Web.Mvc;
using Newtonsoft.Json;

namespace CasinoEngine.Controllers
{
    
    public class CacheController : Controller
    {
        public ActionResult ClearCache(string cachePrefix)
        {
            CacheManager.ClearLocalCache(cachePrefix);
            return this.Content("OK", "text/plain");
        }

        [HttpPost]
        public ActionResult ClearCache()
        {
            try
            {
                var buffer = new byte[Request.ContentLength];
                Request.InputStream.Read(buffer, 0, buffer.Length);
                var json = Encoding.UTF8.GetString(buffer, 0, buffer.Length);
                if (string.IsNullOrWhiteSpace(json))
                    return this.Content("Invalid Request", "text/plain");
                string[] cachePrefixs = JsonConvert.DeserializeObject<string[]>(json);
                CacheManager.ClearLocalCache(cachePrefixs);
                return this.Content("OK", "text/plain");
            }
            catch (Exception ex)
            {
                return this.Content(ex.Message, "text/plain");
            }
        }
    }
}
