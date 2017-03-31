using System.Web.Mvc;

namespace CM.Web
{
    public sealed class MasterPageViewDataAttribute : ActionFilterAttribute
    {
        public string Name { get; set; }
        public string Value { get; set; }

        public override void OnActionExecuting(ActionExecutingContext filterContext)
        {
            filterContext.Controller.ViewData[Name] = Value;
        }
    }
}
