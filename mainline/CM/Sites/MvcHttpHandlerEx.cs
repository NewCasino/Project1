using System;
using System.Web;
using System.Web.Mvc;
using System.Web.Routing;

namespace CM.Sites
{
    /*
      MVC includes the following handler types:

      MvcHandler. This handler is responsible for initiating the ASP.NET pipeline for an MVC application. 
      It receives a Controller instance from the MVC controller factory; 
      this controller handles further processing of the request. 
      Note that even though MvcHandler implements IHttpHandler, 
      it cannot be mapped as a handler (for example, to the .mvc file-name extension) 
      because the class does not support a parameterless constructor. (Its only constructor requires a RequestContext object.)

      MvcRouteHandler. This class implements IRouteHandler, therefore it can integrate with ASP.NET routing. 
      The MvcRouteHandler class associates the route with an MvcHandler instance. 
      A MvcRouteHandler instance is registered with routing when you use the MapRoute method. 
      When the MvcRouteHandler class is invoked, the class generates an MvcHandler instance using the current RequestContext instance. 
      It then delegates control to the new MvcHandler instance.

      MvcHttpHandler. 
      This handler is used to facilitate direct handler mapping without going through the routing module. 
      This is useful if you want to map a file-name extension such as .mvc directly to an MVC handler. 
      Internally, MvcHttpHandler performs the same tasks that ASP.NET routing ordinarily performs (going through MvcRouteHandler and MvcHandler). 
      However, it performs these tasks as a handler instead of as a module. 
      This handler is not typically used when the UrlRoutingModule is enabled for all requests. 
     */
    internal sealed class MvcHttpHandlerEx : MvcHttpHandler
    {
        private static SiteControllerFactory s_ControllerBuilder = new SiteControllerFactory();
        private static DynamicActionControllerFactory s_DynamicActionControllerFactory = new DynamicActionControllerFactory();
        static MvcHttpHandlerEx()
        {
            ControllerBuilder.Current.SetControllerFactory(s_ControllerBuilder);
            ControllerBuilder.Current.SetControllerFactory(s_DynamicActionControllerFactory);

            ViewEngines.Engines.Clear();
            ViewEngines.Engines.Add(new WebFormViewEngineEx());
        }

        public void PublicProcessRequest(HttpContext httpContext)
        {
            this.ProcessRequest(new HttpContextWrapper(httpContext));
        }

        protected override void ProcessRequest(HttpContextBase httpContext)
        {
            RouteCollection coll = SiteManager.Current.GetRouteCollection();
            if (coll == null || coll.Count == 0)
            {
                SiteManager.Current.ReloadConfigration();
                return;
            }
            RouteData routeData = coll.GetRouteData(httpContext);
            if (routeData == null)
            {
                httpContext.Response.Redirect("/PageNotFound", false);
                return;
            }

            IRouteHandler routeHandler = routeData.RouteHandler;
            if (routeHandler == null)
            {
                throw new InvalidOperationException("MvcHttpHandlerEx.ProcessRequest, No Route Handler");
            }
            RequestContext requestContext = new RequestContext(httpContext, routeData);
            IHttpHandler httpHandler = routeHandler.GetHttpHandler(requestContext);
            if (httpHandler == null)
            {
                throw new InvalidOperationException("MvcHttpHandlerEx.ProcessRequest, httpHandler is null!");
            }


            this.VerifyAndProcessRequest(httpHandler, httpContext);
        }


    }
    

}
