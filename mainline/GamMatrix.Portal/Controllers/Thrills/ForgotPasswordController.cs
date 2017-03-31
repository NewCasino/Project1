using System;
using System.Web.Mvc;
using BLToolkit.DataAccess;
using CM.Content;
using CM.db;
using CM.Sites;
using CM.Web;

namespace GamMatrix.CMS.Controllers.ThrillsAccount
{
    [HandleError]
    [ControllerExtraInfo(DefaultAction = "Index", ParameterUrl = "{key}")]
    public class TrillsForgotPasswordController : GamMatrix.CMS.Controllers.Shared.ForgotPasswordController
    {
        protected override string GetKeyUrl(UrlHelper urlHelper, cmUser user)
        {
            SqlQuery<cmUserKey> query = new SqlQuery<cmUserKey>();
            cmUserKey userKey = new cmUserKey();
            userKey.KeyType = "ResetPassword";
            userKey.KeyValue = Guid.NewGuid().ToString();
            userKey.UserID = user.ID;
            userKey.Expiration = DateTime.Now.AddDays(1);
            userKey.DomainID = SiteManager.Current.DomainID;
            query.Insert(userKey);
            string ForgotPassWordUrlTemplate = string.IsNullOrEmpty(Metadata.Get("/Metadata/Email/ResetPassword.UrlTemplate")) ?
                "https://www.thrills.com:443/{0}/account/password-reset/{1}" : 
                Metadata.Get("/Metadata/Email/ResetPassword.UrlTemplate");
            return    string.Format(ForgotPassWordUrlTemplate 
                    , user.Language
                    , userKey.KeyValue
                    );

        }        
    }
}
