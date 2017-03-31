using System;
using System.Web.Mvc;
using CM.Content;
using CM.Sites;

namespace CM.Web
{
    public class ViewMasterPageEx : ViewMasterPage, IViewDataContainer, IViewPageBase
    {
        public string Title { get; set; }

        public string PageTemplate { get; set; }

        public string PageTheme
        {
            get
            {
                return this.Page.Items["__page_theme"] as string;
            }
        }



        public string MetaKeywords { get; set; }

        public string MetaDescription { get; set; }


        ViewDataDictionary IViewDataContainer.ViewData 
        { 
            get
            {
                return base.ViewData;
            }
            set
            {
                throw new NotSupportedException("SET ViewMasterPageEx ViewData");
            }
        }


        public ViewPageEx ViewPage
        {
            get
            {
                ViewPageEx page = this.Page as ViewPageEx;
                if (page == null)
                {
                    throw new InvalidOperationException("Invalid page");
                }
                return page;
            }
        }

        public new AjaxHelper<object> Ajax 
        {
            get
            {
                return new AjaxHelper<object>(this.ViewContext, this, SiteManager.Current.GetRouteCollection());
            } 
        }

        public new HtmlHelper<object> Html 
        {
            get
            {
                return new HtmlHelper<object>(this.ViewContext, this, SiteManager.Current.GetRouteCollection());
            }
        }

        public new UrlHelper Url
        {
            get
            {
                return new UrlHelper(base.Request.RequestContext, SiteManager.Current.GetRouteCollection());
            }
        }

        public string CssClass { get; set; }

        public virtual void SetPageTemplate()
        {
        }

        /// <summary>
        /// override the OnPreRender to handle the meta tags
        /// </summary>
        /// <param name="e"></param>
        protected override void OnPreRender(EventArgs e)
        {
            string inlineCSS = MetadataExtension.GetMetadata(this, ".InlineCSS");
            if (!string.IsNullOrWhiteSpace(inlineCSS))
                this.Context.AppendInlineCSS(inlineCSS);

            ViewPageEx viewPage = this.Page as ViewPageEx;
            if (viewPage != null)
            {
                if (!string.IsNullOrWhiteSpace(this.Title) && 
                     string.IsNullOrWhiteSpace(viewPage.Title))
                {
                    viewPage.Title = this.Title;
                }

                if (!string.IsNullOrWhiteSpace(this.MetaKeywords))
                {
                    viewPage.MetaKeywords = this.MetaKeywords;
                }

                if (!string.IsNullOrWhiteSpace(this.MetaDescription))
                {
                    viewPage.MetaDescription = this.MetaDescription;
                }
            }
            base.OnPreRender(e);
        }

        protected override void OnError(EventArgs e)
        {
            ExceptionHandler.Process(Server.GetLastError());
            base.OnError(e);
        }
    }
}
