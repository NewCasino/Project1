using System;
using System.Diagnostics.CodeAnalysis;
using System.Web.Mvc;
using System.Web.UI;
using CM.Content;
using CM.Sites;

namespace CM.Web
{
    /// <summary>
    /// Extend the ViewUserControl, each operator has its own RouteCollection
    /// </summary>
    [FileLevelControlBuilder(typeof(ViewUserControlControlBuilderEx))]
    public class ViewUserControlEx : ViewUserControl
    {
        private AjaxHelper _ajaxHelper;
        private HtmlHelper _htmlHelper;

        public new AjaxHelper Ajax
        {
            get
            {
                if (this._ajaxHelper == null)
                {
                    this._ajaxHelper = new AjaxHelper(this.ViewContext, this, SiteManager.Current.GetRouteCollection() );
                }
                return this._ajaxHelper;
            }
        }

        public new HtmlHelper Html
        {
            get
            {
                if (this._htmlHelper == null)
                {
                    this._htmlHelper = new HtmlHelper(this.ViewContext, this, SiteManager.Current.GetRouteCollection());
                }
                return this._htmlHelper;
            }
        }

        public new UrlHelper Url
        {
            get
            {
                return new UrlHelper(base.Request.RequestContext, SiteManager.Current.GetRouteCollection());
            }
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


    /// <summary>
    /// Extend the ViewUserControl, each operator has its own RouteCollection
    /// </summary>
    /// <typeparam name="TModel"></typeparam>
    [FileLevelControlBuilder(typeof(ViewUserControlControlBuilderEx))]
    public class ViewUserControlEx<TModel> : ViewUserControlEx where TModel : class
    {
        private AjaxHelper<TModel> _ajaxHelper;
        private HtmlHelper<TModel> _htmlHelper;
        private ViewDataDictionary<TModel> _viewData;

        public new AjaxHelper<TModel> Ajax
        {
            get
            {
                if (this._ajaxHelper == null)
                {
                    this._ajaxHelper = new AjaxHelper<TModel>(base.ViewContext, this, SiteManager.Current.GetRouteCollection());
                }
                return this._ajaxHelper;
            }
        }

        public new HtmlHelper<TModel> Html
        {
            get
            {
                if (this._htmlHelper == null)
                {
                    this._htmlHelper = new HtmlHelper<TModel>(base.ViewContext, this, SiteManager.Current.GetRouteCollection());
                }
                return this._htmlHelper;
            }
        }

        public new UrlHelper Url
        {
            get
            {
                return new UrlHelper(base.Request.RequestContext, SiteManager.Current.GetRouteCollection());
            }
        }

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
                EnsureViewData();
                return _viewData;
            }
            set
            {
                SetViewData(value);
            }
        }

        protected override void SetViewData(ViewDataDictionary viewData)
        {
            _viewData = new ViewDataDictionary<TModel>(viewData);

            base.SetViewData(_viewData);
        }
    }
}
