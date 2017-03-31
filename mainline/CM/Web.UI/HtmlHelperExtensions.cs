using System;
using System.Web;
using System.Web.Caching;
using System.Web.Mvc;
using System.Web.Mvc.Html;
using CM.Content;
using CM.Sites;
using CM.State;
using CM.Web;

public static class HtmlHelperExtensions
{
    public static MvcHtmlString CachedPartial(this HtmlHelper htmlHelper
        , string partialViewName
        , ViewDataDictionary viewData = null
        , string cacheName = null
        )
    {
        string cacheKey;

        cacheKey = string.Format("Partial_{0}_{1}_{2}_{3}_{4}"
            , SiteManager.Current.DistinctName
            , partialViewName
            , CustomProfile.Current.IsAuthenticated
            , MultilingualMgr.GetCurrentCulture()
            , cacheName
            );

        MvcHtmlString html = HttpRuntime.Cache[cacheKey] as MvcHtmlString;
        if (html != null)
            return html;

        html = htmlHelper.Partial(partialViewName, null, viewData);

        HttpRuntime.Cache.Insert(cacheKey, html, null, DateTime.Now.AddMinutes(2), Cache.NoSlidingExpiration);
        return html;
    }

    public static MvcHtmlString AnonymousCachedPartial(this HtmlHelper htmlHelper
        , string partialViewName
        , ViewDataDictionary viewData = null
        , string cacheName = null
        )
    {
        MvcHtmlString html;
        if (!CustomProfile.Current.IsAuthenticated)
        {
            string cacheKey = string.Format("AnonymousPartial_{0}_{1}_{2}_{3}_{4}"
                    , SiteManager.Current.DistinctName
                    , partialViewName
                    , CustomProfile.Current.IsAuthenticated
                    , MultilingualMgr.GetCurrentCulture()
                    , cacheName
                    );

            html = HttpRuntime.Cache[cacheKey] as MvcHtmlString;
            if (html != null)
                return html;

            html = htmlHelper.Partial(partialViewName, null, viewData);

            HttpRuntime.Cache.Insert(cacheKey, html, null, DateTime.Now.AddMinutes(2), Cache.NoSlidingExpiration);
            return html;
        }
        
        return htmlHelper.Partial(partialViewName, null, viewData);
    }

    public static MvcHtmlString CustomAntiForgeryToken(this HtmlHelper htmlHelper)
    {
        if (!CustomAntiForgeryConfig.Enabled)
            return MvcHtmlString.Empty;

        string domain = null;
        string path = null;
        string salt = CustomAntiForgeryConfig.Salt;
        //string hs = CM.Web.CustomAntiForgery.GetHtml(new HttpContextWrapper(HttpContext.Current), salt, domain, path).ToString();
        //MvcHtmlString mhs = MvcHtmlString.Create(hs);
        //return mhs;
        return MvcHtmlString.Create(CM.Web.CustomAntiForgery.GetHtml(new HttpContextWrapper(HttpContext.Current), salt, domain, path).ToString());
    }
}
