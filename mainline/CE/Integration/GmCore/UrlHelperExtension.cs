using System.Web.Mvc;
using System.Web.Routing;

public static class UrlHelperExtensionEx
{
    public static string ActionEx( this UrlHelper urlHelper, string actionName)
    {
        return urlHelper.Action(actionName, new { @domainID = DomainManager.CurrentDomainID });
    }

    public static string ActionEx(this UrlHelper urlHelper, string actionName, object routeValues)
    {
        RouteValueDictionary dic = new RouteValueDictionary(routeValues);
        dic["domainID"] = DomainManager.CurrentDomainID;
        return urlHelper.Action(actionName, dic);
    }

    public static string RouteUrlEx(this UrlHelper urlHelper, string actionName)
    {
        return urlHelper.RouteUrl(actionName, new { @domainID = DomainManager.CurrentDomainID });
    }
}

