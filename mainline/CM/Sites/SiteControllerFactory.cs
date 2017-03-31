using System;
using System.Web.Mvc;
using System.Web.Routing;

namespace CM.Sites
{
    internal sealed class SiteControllerFactory : DefaultControllerFactory
    {
        public override IController CreateController(RequestContext requestContext, string controllerName)
        {
            Type controllerType = SiteManager.Current.GetControllerTypeByRoute(requestContext.RouteData.Route);
            return Activator.CreateInstance(controllerType) as IController;
        }
    }
}
