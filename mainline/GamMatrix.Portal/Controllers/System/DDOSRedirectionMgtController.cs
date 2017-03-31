using System;
using System.Collections.Generic;
using System.Web.Mvc;
using CM.Content;
using CM.Sites;
using CM.Web;

namespace GamMatrix.CMS.Controllers.System
{
    [HandleError]
    [ControllerExtraInfo(DefaultAction = "Index")]
    [SystemAuthorize( Roles = "CMS System Admin")]
    public class DDOSRedirectionMgtController : ControllerEx
    {
        public ActionResult Index()
        {

            return View(DDOSRedirector.GetAll());
        }

        [HttpPost]
        public JsonResult SaveSetting(string domainIDs)
        {
            try
            {
                List<int> selectedDomain = new List<int>();
                if (!string.IsNullOrWhiteSpace(domainIDs))
                {
                    int did = 0;
                    string[] arrDomainID = domainIDs.Split(new char[] { ',' }, StringSplitOptions.RemoveEmptyEntries);
                    foreach (string id in arrDomainID)
                    {
                        if (int.TryParse(id, out did))
                        {
                            selectedDomain.Add(did);
                        }
                    }
                }
                DDOSRedirector.Save(selectedDomain);

                string relativePath = "/.config/ddosredirectionmgt.setting";
                Revisions.Backup<string>(SiteManager.Current, domainIDs, relativePath, "DomainID:" + domainIDs);

                return this.Json(new { success = true });
            }
            catch (Exception e)
            {
                Logger.Exception(e);
                return this.Json(new { success = false, msg = e.Message });
            }
        }
    }
}
