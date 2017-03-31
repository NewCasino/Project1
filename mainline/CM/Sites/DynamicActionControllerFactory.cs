using System;
using System.Web.Mvc;

namespace CM.Sites
{
    public class DynamicActionControllerFactory : DefaultControllerFactory
    {
        public override IController CreateController(System.Web.Routing.RequestContext requestContext, string controllerName)
        {
            try
            {
                Controller controller = base.CreateController(requestContext, controllerName) as Controller;
                ControllerEx controllerEx = controller as ControllerEx;
                if (controllerEx != null && controllerEx.EnableDynamicAction)
                {
                    controller.ActionInvoker = new DynamicActionInvoker()
                    {
                        ActionDelegate = controllerEx.OnDynamicActionInvoked
                    };
                }

                return controller;
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return null;
            }
        }

    }
}
