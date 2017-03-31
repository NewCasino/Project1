using System;
using System.Collections.Generic;
using System.Web;
using System.Web.Mvc;
using System.Web.Mvc.Html;
using System.Web.Routing;

public static class FormExtensions
{
    public static MvcForm BeginAntiForgeryForm(this HtmlHelper htmlHelper)
    {
        var mvcForm = htmlHelper.BeginForm();
        htmlHelper.ViewContext.Writer.Write(htmlHelper.CustomAntiForgeryToken().ToHtmlString());
        return mvcForm;
    }

    public static MvcForm BeginAntiForgeryForm(this HtmlHelper htmlHelper, object routeValues)
    {
        var mvcForm = htmlHelper.BeginForm(routeValues);
        htmlHelper.ViewContext.Writer.Write(htmlHelper.CustomAntiForgeryToken().ToHtmlString());
        return mvcForm;
    }

    public static MvcForm BeginAntiForgeryForm(this HtmlHelper htmlHelper, RouteValueDictionary routeValues)
    {
        var mvcForm = htmlHelper.BeginForm(routeValues);
        htmlHelper.ViewContext.Writer.Write(htmlHelper.CustomAntiForgeryToken().ToHtmlString());
        return mvcForm;
    }

    public static MvcForm BeginAntiForgeryForm(this HtmlHelper htmlHelper, string actionName, string controllerName)
    {
        var mvcForm = htmlHelper.BeginForm(actionName, controllerName);
        htmlHelper.ViewContext.Writer.Write(htmlHelper.CustomAntiForgeryToken().ToHtmlString());
        return mvcForm;
    }

    public static MvcForm BeginAntiForgeryForm(this HtmlHelper htmlHelper, string actionName, string controllerName, object routeValues)
    {
        var mvcForm = htmlHelper.BeginForm(actionName, controllerName, routeValues);
        htmlHelper.ViewContext.Writer.Write(htmlHelper.CustomAntiForgeryToken().ToHtmlString());
        return mvcForm;
    }

    public static MvcForm BeginAntiForgeryForm(this HtmlHelper htmlHelper, string actionName, string controllerName, RouteValueDictionary routeValues)
    {
        var mvcForm = htmlHelper.BeginForm(actionName, controllerName, routeValues);
        htmlHelper.ViewContext.Writer.Write(htmlHelper.CustomAntiForgeryToken().ToHtmlString());
        return mvcForm;
    }

    public static MvcForm BeginAntiForgeryForm(this HtmlHelper htmlHelper, string actionName, string controllerName, FormMethod method)
    {
        var mvcForm = htmlHelper.BeginForm(actionName, controllerName, method);
        htmlHelper.ViewContext.Writer.Write(htmlHelper.CustomAntiForgeryToken().ToHtmlString());
        return mvcForm;
    }

    public static MvcForm BeginAntiForgeryForm(this HtmlHelper htmlHelper, string actionName, string controllerName, object routeValues, FormMethod method)
    {
        var mvcForm = htmlHelper.BeginForm(actionName, controllerName, routeValues, method);
        htmlHelper.ViewContext.Writer.Write(htmlHelper.CustomAntiForgeryToken().ToHtmlString());
        return mvcForm;
    }
    public static MvcForm BeginAntiForgeryForm(this HtmlHelper htmlHelper, string actionName, string controllerName, RouteValueDictionary routeValues, FormMethod method)
    {
        var mvcForm = htmlHelper.BeginForm(actionName, controllerName, routeValues, method);
        htmlHelper.ViewContext.Writer.Write(htmlHelper.CustomAntiForgeryToken().ToHtmlString());
        return mvcForm;
    }
    public static MvcForm BeginAntiForgeryForm(this HtmlHelper htmlHelper, string actionName, string controllerName, FormMethod method, object htmlAttributes)
    {
        var mvcForm = htmlHelper.BeginForm(actionName, controllerName, method, htmlAttributes);
        htmlHelper.ViewContext.Writer.Write(htmlHelper.CustomAntiForgeryToken().ToHtmlString());
        return mvcForm;
    }
    public static MvcForm BeginAntiForgeryForm(this HtmlHelper htmlHelper, string actionName, string controllerName, FormMethod method, IDictionary<string, object> htmlAttributes)
    {
        var mvcForm = htmlHelper.BeginForm(actionName, controllerName, method, htmlAttributes);
        htmlHelper.ViewContext.Writer.Write(htmlHelper.CustomAntiForgeryToken().ToHtmlString());
        return mvcForm;
    }
    public static MvcForm BeginAntiForgeryForm(this HtmlHelper htmlHelper, string actionName, string controllerName, object routeValues, FormMethod method, object htmlAttributes)
    {
        var mvcForm = htmlHelper.BeginForm(actionName, controllerName, routeValues, method, htmlAttributes);
        htmlHelper.ViewContext.Writer.Write(htmlHelper.CustomAntiForgeryToken().ToHtmlString());
        return mvcForm;
    }
    public static MvcForm BeginAntiForgeryForm(this HtmlHelper htmlHelper, string actionName, string controllerName, RouteValueDictionary routeValues, FormMethod method, IDictionary<string, object> htmlAttributes)
    {
        var mvcForm = htmlHelper.BeginForm(actionName, controllerName, routeValues, method, htmlAttributes);
        htmlHelper.ViewContext.Writer.Write(htmlHelper.CustomAntiForgeryToken().ToHtmlString());
        return mvcForm;
    }

    public static MvcForm BeginAntiForgeryRouteForm(this HtmlHelper htmlHelper, object routeValues)
    {
        var mvcForm = htmlHelper.BeginRouteForm(routeValues);
        htmlHelper.ViewContext.Writer.Write(htmlHelper.CustomAntiForgeryToken().ToHtmlString());
        return mvcForm;
    }
    public static MvcForm BeginAntiForgeryRouteForm(this HtmlHelper htmlHelper, RouteValueDictionary routeValues)
    {
        var mvcForm = htmlHelper.BeginRouteForm(routeValues);
        htmlHelper.ViewContext.Writer.Write(htmlHelper.CustomAntiForgeryToken().ToHtmlString());
        return mvcForm;
    }
    public static MvcForm BeginAntiForgeryRouteForm(this HtmlHelper htmlHelper, string routeName)
    {
        var mvcForm = htmlHelper.BeginRouteForm(routeName);
        htmlHelper.ViewContext.Writer.Write(htmlHelper.CustomAntiForgeryToken().ToHtmlString());
        return mvcForm;
    }
    public static MvcForm BeginAntiForgeryRouteForm(this HtmlHelper htmlHelper, string routeName, object routeValues)
    {
        var mvcForm = htmlHelper.BeginRouteForm(routeName, routeValues);
        htmlHelper.ViewContext.Writer.Write(htmlHelper.CustomAntiForgeryToken().ToHtmlString());
        return mvcForm;
    }
    public static MvcForm BeginAntiForgeryRouteForm(this HtmlHelper htmlHelper, string routeName, RouteValueDictionary routeValues)
    {
        var mvcForm = htmlHelper.BeginRouteForm(routeName, routeValues);
        htmlHelper.ViewContext.Writer.Write(htmlHelper.CustomAntiForgeryToken().ToHtmlString());
        return mvcForm;
    }
    public static MvcForm BeginAntiForgeryRouteForm(this HtmlHelper htmlHelper, string routeName, FormMethod method)
    {
        var mvcForm = htmlHelper.BeginRouteForm(routeName, method);
        htmlHelper.ViewContext.Writer.Write(htmlHelper.CustomAntiForgeryToken().ToHtmlString());
        return mvcForm;
    }
    public static MvcForm BeginAntiForgeryRouteForm(this HtmlHelper htmlHelper, string routeName, object routeValues, FormMethod method)
    {
        var mvcForm = htmlHelper.BeginRouteForm(routeName, routeValues, method);
        htmlHelper.ViewContext.Writer.Write(htmlHelper.CustomAntiForgeryToken().ToHtmlString());
        return mvcForm;
    }
    public static MvcForm BeginAntiForgeryRouteForm(this HtmlHelper htmlHelper, string routeName, RouteValueDictionary routeValues, FormMethod method)
    {
        var mvcForm = htmlHelper.BeginRouteForm(routeName, routeValues, method);
        htmlHelper.ViewContext.Writer.Write(htmlHelper.CustomAntiForgeryToken().ToHtmlString());
        return mvcForm;
    }
    public static MvcForm BeginAntiForgeryRouteForm(this HtmlHelper htmlHelper, string routeName, FormMethod method, object htmlAttributes)
    {
        var mvcForm = htmlHelper.BeginRouteForm(routeName, method, htmlAttributes);
        htmlHelper.ViewContext.Writer.Write(htmlHelper.CustomAntiForgeryToken().ToHtmlString());
        return mvcForm;
    }
    public static MvcForm BeginAntiForgeryRouteForm(this HtmlHelper htmlHelper, string routeName, FormMethod method, IDictionary<string, object> htmlAttributes)
    {
        var mvcForm = htmlHelper.BeginRouteForm(routeName, method, htmlAttributes);
        htmlHelper.ViewContext.Writer.Write(htmlHelper.CustomAntiForgeryToken().ToHtmlString());
        return mvcForm;
    }
    public static MvcForm BeginAntiForgeryRouteForm(this HtmlHelper htmlHelper, string routeName, object routeValues, FormMethod method, object htmlAttributes)
    {
        var mvcForm = htmlHelper.BeginRouteForm(routeName, routeValues, method, htmlAttributes);
        htmlHelper.ViewContext.Writer.Write(htmlHelper.CustomAntiForgeryToken().ToHtmlString());
        return mvcForm;
    }

    //public static MvcForm BeginAntiForgeryRouteForm(this HtmlHelper htmlHelper, string routeName, RouteValueDictionary routeValues, FormMethod method, IDictionary<string, object> htmlAttributes)
    //{
    //    string formAction = UrlHelper.GenerateUrl(routeName, null, null, routeValues, htmlHelper.RouteCollection, htmlHelper.ViewContext.RequestContext, false);
    //    return htmlHelper.FormHelper(formAction, method, htmlAttributes);
    //}
}

