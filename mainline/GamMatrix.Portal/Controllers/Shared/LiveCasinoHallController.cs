using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Net;
using System.Text;
using System.Threading.Tasks;
using System.Web;
using System.Web.Caching;
using System.Web.Mvc;
using System.Web.Script.Serialization;
using System.Security.Cryptography;
using CasinoEngine;
using CM.Content;
using CM.db;
using CM.db.Accessor;
using CM.Sites;
using CM.Web;
using GmCore;

namespace GamMatrix.CMS.Controllers.Shared
{
     
    //public class  Dictionary

    [HandleError]
    [ControllerExtraInfo(DefaultAction = "Index", ParameterUrl = "{category}")]
    [MasterPageViewData(Name = "CurrentPageClass", Value = "LiveCasinoHall")]
    /// <summary>
    ///LiveCasinoLobby Controller
    /// </summary>
    public class LiveCasinoHallController : AsyncControllerEx
    {
        [HttpGet]
        public ActionResult Index(string category = "all")
        {
            this.ViewData["category"] = category;
            return View("Index");
        }
        [HttpGet]
        public void GetSeatsDataAsync(bool isProd = false)
        {
            string ceDomainProd = Metadata.Get("/Metadata/Settings.CEProdDomain").DefaultIfNullOrEmpty("casino.gammatrix.com");
            string ceDomainDev = Metadata.Get("/Metadata/Settings.CEDevDomain").DefaultIfNullOrEmpty("casino.gammatrix-dev.net");
            string hostname = isProd ? ceDomainProd : ceDomainDev;
            string opKey =   Settings.CasinoEngine_OperatorKey;
            string url = string.Format("http://{1}/RestfulAPI/GetLiveCasinoTableStatus/{0}",
                opKey,
            hostname
                );
            AsyncManager.OutstandingOperations.Increment();
            var task = Task.Factory.StartNew(() => OnGetSeatsDataCompleted(isProd, url, opKey));
        }
        protected string GETFileData(string TheURL)
        {
            try
            {
                Uri uri = new Uri(TheURL);
                HttpWebRequest request = (HttpWebRequest)WebRequest.Create(uri);
                request.Method = "GET";
                request.ContentType = "application/x-www-form-urlencoded";
                request.AllowAutoRedirect = false;
                request.Timeout = 5000;
                HttpWebResponse response = (HttpWebResponse)request.GetResponse();
                Stream responseStream = response.GetResponseStream();
                StreamReader readStream = new StreamReader(responseStream, Encoding.UTF8);
                string retext = readStream.ReadToEnd().ToString();
                readStream.Close();
                return retext;
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return ex.ToString();
            }
        }

        public void OnGetSeatsDataCompleted(bool isProd, string url, string operatorKey)
        {
            try
            {
                string env =  isProd ? "PROD" : "DEV";
                string cacheKey = string.Format("CE_JSON_SEATS_{0}_{1}"
                    , env
                    , operatorKey
                );
                string jsonData = HttpRuntime.Cache[cacheKey] as string;
                if (!string.IsNullOrEmpty(jsonData))
                {
                    AsyncManager.Parameters["json"] = jsonData;
                }
                else
                {
                    AsyncManager.Parameters["json"] = GETFileData(url);
                    HttpRuntime.Cache.Insert(cacheKey
                            , AsyncManager.Parameters["json"]
                            , null
                            , DateTime.Now.AddSeconds(20)
                            , Cache.NoSlidingExpiration
                            );
                }
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                AsyncManager.Parameters["exception"] = ex;
            }
            finally
            {
                AsyncManager.OutstandingOperations.Decrement();
            }
        }

        [HttpGet]
        public JsonResult GetSeatsDataCompleted(string json
            , Exception exception)
        {
            List<Exception> exs = new List<Exception>();
            if (null != exception) {
                exs.Add(exception);
            }
            var jser = new JavaScriptSerializer();
            try
            {
                if (  null != json &&  json.Substring(0, 1) == "(" && json.Substring(json.Length - 1, 1) == ")")
                {
                    json = json.Substring(1, json.Length - 2);
                    object jsonData = jser.Deserialize<object>(json);
                    return this.Json(new
                    {
                        @success = true,
                        @data = jsonData,
                    }
                    , JsonRequestBehavior.AllowGet);
                }
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                exs.Add(ex);
            }
            string errorStr = "";
            foreach (Exception item in exs) {
                errorStr += GmException.TryGetFriendlyErrorMsg(item);
            }
            return this.Json(new
            {
                @success = false,
                @error = errorStr,
            }
            , JsonRequestBehavior.AllowGet);
        }

        [HttpGet]
        public ActionResult Start(string tableID)
        {
            if (!CustomProfileEx.Current.IsAuthenticated)
                throw new UnauthorizedAccessException();

            if (!CustomProfileEx.Current.IsEmailVerified)
            {
                UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
                cmUser user = ua.GetByID(CustomProfileEx.Current.UserID);
                if (!user.IsEmailVerified)
                {
                    return this.View("EmailNotVerified");
                }
            }

            if (CustomProfileEx.Current.IsInRole("Incomplete Profile"))
            {
                return this.View("IncompleteProfile");
            }

            Dictionary<string, LiveCasinoTable> tables = CasinoEngineClient.GetLiveCasinoTables();
            LiveCasinoTable table;
            if (!tables.TryGetValue(tableID, out table))
                throw new HttpException(404, "Table not found");

            string userAgentInfo = Request.GetRealUserAddress() + Request.UserAgent;
            string sid64 = HttpUtility.UrlEncode(Encrypt(CustomProfileEx.Current.SessionID, userAgentInfo, true));

            string url = string.Format(CultureInfo.InvariantCulture, "{0}{1}_sid64={2}&language={3}"
                , table.Url
                , (table.Url.IndexOf("?") > 0) ? "&" : "?"
                , sid64
                , MultilingualMgr.GetCurrentCulture()
                );

            return this.Redirect(url);
        }

        private string Encrypt(string toEncrypt, string key, bool useHashing)
        {
            try
            {
                byte[] keyArray;
                byte[] toEncryptArray = UTF8Encoding.UTF8.GetBytes(toEncrypt);

                if (useHashing)
                {
                    MD5CryptoServiceProvider hashmd5 = new MD5CryptoServiceProvider();
                    keyArray = hashmd5.ComputeHash(UTF8Encoding.UTF8.GetBytes(key));
                }
                else
                    keyArray = UTF8Encoding.UTF8.GetBytes(key);

                TripleDESCryptoServiceProvider tdes = new TripleDESCryptoServiceProvider();

                tdes.Key = keyArray;
                tdes.Mode = CipherMode.ECB;
                tdes.Padding = PaddingMode.PKCS7;

                ICryptoTransform cTransform = tdes.CreateEncryptor();
                byte[] resultArray = cTransform.TransformFinalBlock(toEncryptArray, 0, toEncryptArray.Length);

                return Convert.ToBase64String(resultArray, 0, resultArray.Length);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return ex.ToString();
            }
        }

        [HttpGet]
        public ActionResult Game(string tableID)
        {
            return View("Game");
        }

    }
}