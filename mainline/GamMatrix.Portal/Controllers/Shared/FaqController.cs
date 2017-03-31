using System;
using System.Web.Mvc;
using System.Web;
using System.Collections.Generic;
using System.Text;
using System.Text.RegularExpressions;
using CM.Content;
using CM.db;
using CM.db.Accessor;
using CM.Sites;
using CM.State;
using CM.Web;
using GmCore;

namespace GamMatrix.CMS.Controllers.Shared
{
    [HandleError]
    [ControllerExtraInfo(DefaultAction = "Index", ParameterUrl = "{p1}/{p2}/{p3}/{p4}")]
    public class FaqController : ControllerEx
    {
        private static readonly string[] RouteParameters = new[] { "p1", "p2", "p3", "p4" };
        private static readonly string DefaultActionName = "Default";
        private Dictionary<string, Func<string, ActionResult>> _actionDic = null;

        public FaqController()
        {
            this.EnableDynamicAction = true;
            _actionDic = new Dictionary<string, Func<string, ActionResult>>(StringComparer.InvariantCultureIgnoreCase)
            { 
                { "Index" , Index },
                { "Search" , Search },
                { DefaultActionName , Item }
            };

        }


        protected virtual ActionResult ResolveAction(string actionName)
        {
            Func<string, ActionResult> fun = null;
            if (_actionDic.TryGetValue(actionName, out fun))
            {
                return fun(actionName);
            }
            else
            {
                if (!_actionDic.TryGetValue(DefaultActionName, out fun))
                {
                    throw new Exception("No default action!");
                }
                return fun(actionName);
            }
        }

        public override ActionResult OnDynamicActionInvoked(string actionName)
        {
            return ResolveAction(actionName);
        }



        [HttpGet]
        public ActionResult Index(string actionName)
        {
            return View("Index");
        }

        public ActionResult Item(string actionName)
        {
            List<string> parameters = new List<string>();

            Func<string, bool> tryGetRouterData = key =>
            {
                if (!RouteData.Values.ContainsKey(key))
                    return false;
                parameters.Add(RouteData.Values[key].ToString());
                return true;
            };

            parameters.Add(actionName);
            for (int i = 0; i < RouteParameters.Length; i++)
            {
                if (!tryGetRouterData(RouteParameters[i]))
                    break;
            }


            ViewData["Parameters"] = parameters;

            return View("Item");

        }
        [HttpGet]
        public ActionResult Search(string actionName)
        {
            var key = RouteData.Values[RouteParameters[0]];
            ViewData["Key"] = key;

            return View("Search");
        }

    }
}
