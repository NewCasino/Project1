using System.Web.Mvc;

namespace CM.Sites
{
    /// <summary>
    /// Dynamic action invoker inherited from ControllerActionInvoker
    /// </summary>
    public class DynamicActionInvoker : ControllerActionInvoker
    {
        /// <summary>
        ///  the delegate of the action
        /// </summary>
        internal ControllerEx.DynamicActionInvokedDelegate ActionDelegate { get; set; }

        /// <summary>
        /// override InvokeAction
        /// </summary>
        /// <param name="controllerContext">ControllerContext</param>
        /// <param name="actionName">actionName</param>
        /// <returns>always return true</returns>
        public override bool InvokeAction(ControllerContext controllerContext, string actionName)
        {
            base.InvokeActionResult(controllerContext, ActionDelegate(actionName));
            return true;

        }
    }
}
