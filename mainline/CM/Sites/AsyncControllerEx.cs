using System.Web.Mvc;
using System.Web.Routing;
using CM.Web;

namespace CM.Sites
{
    [CompressFilter]
    public class AsyncControllerEx : AsyncController
    {
        protected override void Initialize(RequestContext requestContext)
        {
            base.Initialize(requestContext);
            this.Url = new UrlHelper(requestContext, SiteManager.Current.GetRouteCollection());
        }
    }
}
