using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;
using System.Web;
using System.Web.Mvc;
using BLToolkit.Data;
using BLToolkit.DataAccess;
using CE.db;
using CE.db.Accessor;

namespace CasinoEngine.Controllers
{
    [SystemAuthorize]
    public class VendorManagementController : Controller
    {
        //
        // GET: /VendorManagement/

        public ActionResult Index()
        {
            return View();
        }

        [HttpPost]
        public JsonResult Save()
        {
            if (!DomainManager.AllowEdit())
            {
                throw new Exception("Data modified is not allowed");
            }
            if (!CurrentUserSession.IsSuperUser)
                throw new HttpException(503, "Access Denied");

            using (DbManager db = new DbManager())
            {
                CasinoVendorAccessor cva = CasinoVendorAccessor.CreateInstance<CasinoVendorAccessor>(db);
                List<ceCasinoVendor> vendors = cva.GetEnabledVendorList(DomainManager.CurrentDomainID, Constant.SystemDomainID);

                List<ceCasinoVendor> enabledGmGamingAPI = new List<ceCasinoVendor>();
                List<ceCasinoVendor> enabledLogging = new List<ceCasinoVendor>();

                foreach (string key in Request.Form.AllKeys)
                {
                    Match m = Regex.Match(key, @"^(BonusDeduction_)(?<VendorID>\d+)", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant | RegexOptions.Compiled);
                    if (m.Success)
                    {
                        ceCasinoVendor vendor = vendors.FirstOrDefault(v => (int)v.VendorID == int.Parse(m.Groups["VendorID"].Value));
                        decimal bonusDeduction = 0.00M;
                        if (vendor != null && decimal.TryParse(Request.Form[key], out bonusDeduction))
                            vendor.BonusDeduction = bonusDeduction;

                        continue;
                    }

                    m = Regex.Match(key, @"^(RestrictedTerritories_)(?<VendorID>\d+)", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant | RegexOptions.Compiled);
                    if (m.Success)
                    {
                        ceCasinoVendor vendor = vendors.FirstOrDefault(v => (int)v.VendorID == int.Parse(m.Groups["VendorID"].Value));
                        if (vendor != null)
                            vendor.RestrictedTerritories = Request.Form[key];

                        continue;
                    }

                    
                    m = Regex.Match(key, @"^(Languages_)(?<VendorID>\d+)", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant | RegexOptions.Compiled);
                    if (m.Success)
                    {
                        ceCasinoVendor vendor = vendors.FirstOrDefault(v => (int)v.VendorID == int.Parse(m.Groups["VendorID"].Value));
                        if (vendor != null) {
                            vendor.Languages = Request.Form[key];
                        }
                        continue;
                    }


                    m = Regex.Match(key, @"^(Currencies_)(?<VendorID>\d+)", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant | RegexOptions.Compiled);
                    if (m.Success)
                    {
                        ceCasinoVendor vendor = vendors.FirstOrDefault(v => (int)v.VendorID == int.Parse(m.Groups["VendorID"].Value));
                        if (vendor != null)
                        {
                            vendor.Currencies = Request.Form[key];
                        }
                        continue;
                    }

                    m = Regex.Match(key, @"^(EnableGmGamingAPI_)(?<VendorID>\d+)", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant | RegexOptions.Compiled);
                    if (m.Success)
                    {
                        ceCasinoVendor vendor = vendors.FirstOrDefault(v => (int)v.VendorID == int.Parse(m.Groups["VendorID"].Value));
                        if (vendor != null)
                        {
                            vendor.EnableGmGamingAPI = true;

                            enabledGmGamingAPI.Add(vendor);
                        }
                        continue;
                    }

                    m = Regex.Match(key, @"^(EnableLogging_)(?<VendorID>\d+)", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant | RegexOptions.Compiled);
                    if (m.Success)
                    {
                        ceCasinoVendor vendor = vendors.FirstOrDefault(v => (int)v.VendorID == int.Parse(m.Groups["VendorID"].Value));
                        if (vendor != null)
                        {
                            vendor.EnableLogging = true;

                            enabledLogging.Add(vendor);
                        }
                        continue;
                    }
                }

                SqlQuery<ceCasinoVendor> query = new SqlQuery<ceCasinoVendor>();
                foreach( ceCasinoVendor vendor in vendors )
                {
                    if (!enabledGmGamingAPI.Exists(v => v.VendorID == vendor.VendorID))
                        vendor.EnableGmGamingAPI = false;
                    if (!enabledLogging.Exists(v => v.VendorID == vendor.VendorID))
                        vendor.EnableLogging = false;

                    query.Update(vendor);
                }
                CacheManager.ClearCache(Constant.VendorListCachePrefix);
                CacheManager.ClearCache(Constant.DomainVendorsCachePrefix);                
            }

            return this.Json(new { @success = true });
        }
    }
}
