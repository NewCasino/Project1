using System;
using System.Collections.Generic;
using System.Data;
using System.Web.Mvc;
using BLToolkit.Data;
using CM.db;
using CM.db.Accessor;
using CM.Sites;
using CM.Web;

namespace GamMatrix.CMS.Controllers.System
{
    [HandleError]
    [ControllerExtraInfo(DefaultAction = "Index", ParameterUrl = "{distinctName}")]
    [SystemAuthorize(Roles = "CMS System Admin")]
    public class TermsConditionsManagerController : ControllerEx
    {
        [HttpGet]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public ActionResult Index(string distinctName)
        {
            this.ViewData["distinctName"] = distinctName;
            return View("Index");
        }

        [HttpGet]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public ActionResult Apply(string distinctName, string termsConditionsChange)
        {
            try
            {
                distinctName = distinctName.DefaultDecrypt();
                cmSite site = SiteManager.GetSiteByDistinctName(distinctName);

                UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
                TermsConditionsChange flag = (TermsConditionsChange)Enum.Parse(typeof(TermsConditionsChange), termsConditionsChange);
                if (flag == TermsConditionsChange.No)
                    ua.ClearTermsConditionsFlagForDomain(site.DomainID);
                else
                {
                    // UPDATE cmUser SET IsTCAcceptRequired = IsTCAcceptRequired | @flag WHERE DomainID = @domainID;
                    // UPDATE cmUser SET IsGeneralTCAccepted=0 WHERE DomainID = @domainID AND @flag = 1;
                    using (DbManager db = new DbManager())
                    {
                        List<IDbDataParameter> parameters = new List<IDbDataParameter>(); 
                        parameters.Add( db.Parameter("@flag", flag) );
                        parameters.Add( db.Parameter("@domainID", site.DomainID) );
                        db.SetCommand(@"UPDATE cmUser SET IsTCAcceptRequired = IsTCAcceptRequired | @flag WHERE DomainID = @domainID;
UPDATE cmUser SET IsGeneralTCAccepted=0 WHERE DomainID = @domainID AND @flag = 1;"
                            , parameters.ToArray()
                            );
                        db.UpdateCommand.CommandTimeout = 999999;
                        db.SelectCommand.CommandTimeout = 999999;
                        db.ExecuteNonQuery();
                    }
                }
                    


                return this.Json(new { @success = true }, JsonRequestBehavior.AllowGet);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false, @error = ex.Message }, JsonRequestBehavior.AllowGet);
            }
        }
        
    }



}
