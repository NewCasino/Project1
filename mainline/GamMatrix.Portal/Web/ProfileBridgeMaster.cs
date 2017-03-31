using System.Web;

namespace GamMatrix.CMS.Web
{
    public class ProfileBridgeMaster : CM.Web.ViewMasterPageEx
    {
        public override void SetPageTemplate()
        {           
            if (HttpContext.Current.Request.Cookies["_cvm"] != null)
            {
                this.PageTemplate = "/ConciseProfileMaster.master";
            }
        }
    }
}
