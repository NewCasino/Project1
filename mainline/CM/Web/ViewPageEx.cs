using System;
using System.Collections;
using System.Collections.Generic;
using System.Diagnostics.CodeAnalysis;
using System.Globalization;
using System.IO;
using System.Web;
using System.Web.Hosting;
using System.Web.Mvc;
using System.Web.UI;
using CM.Content;
using CM.db;
using CM.Sites;
using GamMatrix.Infrastructure;

namespace CM.Web
{
    /// <summary>
    /// Override System.Web.Mvc.dll ViewPage and ViewPage&lt;T&gt;
    /// </summary>
    [FileLevelControlBuilder(typeof(ViewPageControlBuilderEx))]
    public class ViewPageEx : ViewPage, IViewPageBase
    {
        public string PageTemplate { get; set; }
        public string PageTheme 
        {
            set { this.Page.Items["__page_theme"] = value; }
            get { return this.Page.Items["__page_theme"] as string; }
        }

        private bool HasMetaDescription { get; set; }
        private bool HasMetaKeywords { get; set; }
        private bool HasTitle { get; set; }

        public new string MetaDescription 
        {
            get { return base.MetaDescription; }
            set
            {
                if (!this.HasMetaDescription)
                {
                    base.MetaDescription = value;
                    this.HasMetaDescription = !string.IsNullOrWhiteSpace(value);
                }
            }
        }

        public new string MetaKeywords
        {
            get { return base.MetaKeywords; }
            set
            {
                if (!this.HasMetaKeywords)
                {
                    base.MetaKeywords = value;
                    this.HasMetaKeywords = !string.IsNullOrWhiteSpace(value);
                }
            }
        }

        public new string Title
        {
            get { return base.Title; }
            set
            {
                if (!this.HasTitle)
                {
                    base.Title = value;
                    this.HasTitle = !string.IsNullOrWhiteSpace(value);
                }
            }
        }

        public string CssClass { get; set; }

        public static void ClearMasterPageCache(cmSite site)
        {
            string cachePrefix = string.Format("ViewPageEx.SetMasterPageFile.{0}.", site.DistinctName);
            foreach (DictionaryEntry entry in HttpRuntime.Cache)
            {
                string key = entry.Key.ToString();
                if (key.StartsWith(cachePrefix))
                    HttpRuntime.Cache.Remove(key);
            }
        }

        /// <summary>
        /// If there is a PageTemplate instructions on the header, find the master page and set it
        /// </summary>
        /// <param name="site"></param>
        /// <param name="page">ViewPage / ViewMasterPage</param>
        private void SetMasterPageFile(cmSite site, IViewPageBase page)
        {
            if (!string.IsNullOrEmpty(page.PageTemplate) && page.PageTemplate.StartsWith("/"))
            {
                string cacheKey = string.Format("ViewPageEx.SetMasterPageFile.{0}.{1}.{2}"
                    , site.DistinctName
                    , page.AppRelativeVirtualPath
                    , page.PageTemplate
                    );
                string masterPageFile = HttpRuntime.Cache[cacheKey] as string;
                if (masterPageFile == null)
                {
                    {
                        int count = 0;
                        if (HttpContext.Current.Items["__master_page_count"] != null)
                            count = (int)HttpContext.Current.Items["__master_page_count"];
                        HttpContext.Current.Items["__master_page_count"] = ++count;
                        if (count > 10)
                            throw new Exception("Too many recurrences, please check the \"PageTemplate\" setting");
                    }

                    List<string> dependencyFiles = new List<string>();

                    {
                        masterPageFile = string.Format("~/Views/{0}{1}", site.DistinctName, page.PageTemplate);
                        string newPath = HostingEnvironment.MapPath(masterPageFile);
                        dependencyFiles.Add(newPath);
                        if (File.Exists(newPath))
                        {
                            HttpRuntime.Cache.Insert(cacheKey
                                , masterPageFile
                                , new CacheDependencyEx(dependencyFiles.ToArray(), false)
                                );
                        }
                        else if (!string.IsNullOrWhiteSpace(site.TemplateDomainDistinctName))
                        {
                            masterPageFile = string.Format("~/Views/{0}{1}", site.TemplateDomainDistinctName, page.PageTemplate);
                            newPath = HostingEnvironment.MapPath(masterPageFile);
                            dependencyFiles.Add(newPath);
                            if (File.Exists(newPath))
                            {
                                HttpRuntime.Cache.Insert(cacheKey
                                    , masterPageFile
                                    , new CacheDependencyEx(dependencyFiles.ToArray(), false)
                                    );
                            }
                            else
                                masterPageFile = null;
                        }
                        else
                        {
                            masterPageFile = null;
                        }
                    }
                }

                if (!string.IsNullOrEmpty(masterPageFile))
                    page.MasterPageFile = masterPageFile;
            }

            ViewMasterPageEx viewMasterPage = page.Master as ViewMasterPageEx;
            if (viewMasterPage != null)
            {
                viewMasterPage.SetPageTemplate();
                SetMasterPageFile(site, viewMasterPage);
            }
        }

        /// <summary>
        /// process the theme and master page
        /// </summary>
        /// <param name="e"></param>
        protected override void OnPreInit(EventArgs e)
        {
            cmSite domain = SiteManager.Current;
            if (domain != null &&
                !string.IsNullOrWhiteSpace(domain.DefaultTheme))
            {
                string theme = domain.DefaultTheme;
                string lang = HttpContext.Current.GetLanguage();
                if (lang != null)
                {
                    CultureInfo cultureInfo = new CultureInfo(lang);
                    if (cultureInfo.TextInfo.IsRightToLeft)
                        theme = string.Format("{0}_rtl", domain.DefaultTheme);
                }

                this.PageTheme = theme;
            }

            SetMasterPageFile(domain, this);

            base.OnPreInit(e);
        }

        public override void InitHelpers()
        {
            this.Ajax = new AjaxHelper<object>(this.ViewContext, this, SiteManager.Current.GetRouteCollection());
            this.Html = new HtmlHelper<object>(this.ViewContext, this, SiteManager.Current.GetRouteCollection());
            this.Url = new UrlHelper(this.ViewContext.RequestContext, SiteManager.Current.GetRouteCollection());
        }

        protected override void OnPreRender(EventArgs e)
        {
            string inlineCSS = MetadataExtension.GetMetadata(this, ".InlineCSS");
            if (!string.IsNullOrWhiteSpace(inlineCSS))
                this.Context.AppendInlineCSS(inlineCSS);

            base.OnPreRender(e);
        }

        protected override void OnError(EventArgs e)
        {
            ExceptionHandler.Process(Server.GetLastError());
            base.OnError(e);
        }
    }

    [FileLevelControlBuilder(typeof(ViewPageControlBuilderEx))]
    public class ViewPageEx<TModel> : ViewPageEx where TModel : class
    {
        private ViewDataDictionary<TModel> _viewData;

        public new AjaxHelper<TModel> Ajax { get; set; }

        public new HtmlHelper<TModel> Html { get; set; }

        public new TModel Model
        {
            get
            {
                return ViewData.Model;
            }
        }

        [SuppressMessage("Microsoft.Usage", "CA2227:CollectionPropertiesShouldBeReadOnly")]
        public new ViewDataDictionary<TModel> ViewData
        {
            get
            {
                if (_viewData == null)
                {
                    SetViewData(new ViewDataDictionary<TModel>());
                }
                return _viewData;
            }
            set
            {
                SetViewData(value);
            }
        }

        public override void InitHelpers()
        {
            this.Ajax = new AjaxHelper<TModel>(this.ViewContext, this, SiteManager.Current.GetRouteCollection());
            this.Html = new HtmlHelper<TModel>(this.ViewContext, this, SiteManager.Current.GetRouteCollection());
            this.Url = new UrlHelper(this.ViewContext.RequestContext, SiteManager.Current.GetRouteCollection());
        }

        protected override void SetViewData(ViewDataDictionary viewData)
        {
            _viewData = new ViewDataDictionary<TModel>(viewData);

            base.SetViewData(_viewData);
        }

        
    }
}
