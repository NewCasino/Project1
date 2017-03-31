using System;
using System.Text;
using System.Web;
using System.Web.Mvc;
using System.Web.Routing;
using CM.Sites;
using CM.Web;
using GamMatrix.CMS.Models.MobileShared.Components;
using GamMatrix.Infrastructure.Utility;

namespace GamMatrix.CMS.Controllers.MobileShared
{
    [HandleError]
    [ControllerExtraInfo(DefaultAction = "Index")]
    public class MobileSportsApiController : ControllerEx
    {
        #region MobileV2
        private ContentResult BuildV2Menu(string pageTitle)
        {
            this.ViewData["PageTitle"] = pageTitle;

            StringBuilder xmlResult = new StringBuilder();
            xmlResult.AppendLine("<?xml version=\"1.0\" encoding=\"utf-8\"?>");
            xmlResult.AppendLine("<pageParts>");

            string htmlView = ExternalViewComponent.AbsoluteAnchorHref
                                (
                                    ExternalViewComponent.RenderComponent("/Components/MenuV2", this.ViewData, this.ControllerContext, new MenuV2ViewModel(this.Url
                                        , showSections: true
                                        , showMainMenuEntries: true
                                        , showAccountEntries: true)),
                                    new UrlHelper(new RequestContext()).GetAbsoluteBaseUrl()
                                );

            xmlResult.AppendFormat("<menu>{0}</menu>", HttpUtility.HtmlEncode(htmlView));
            xmlResult.AppendLine("</pageParts>");
            return this.Content(xmlResult.ToString(), "text/xml", Encoding.UTF8);
        }
        #endregion

        public ContentResult PageParts(string pageTitle)
        {
            if (Settings.MobileV2.IsV2MenuEnabled)
            {
                return BuildV2Menu(pageTitle);
            }

			Func<string, string> renderPartialView = delegate(string path)
			{
				return ExternalViewComponent.AbsoluteAnchorHref
				(
				ExternalViewComponent.RenderComponent(path, this.ViewData, this.ControllerContext),
				new UrlHelper(new RequestContext()).GetAbsoluteBaseUrl()
				);
			};

            this.ViewData["PageTitle"] = pageTitle;

            StringBuilder xml = new StringBuilder();
            xml.AppendLine("<?xml version=\"1.0\" encoding=\"utf-8\"?>");
            xml.AppendLine("<pageParts>");

            string html = renderPartialView("/Components/Header");
            xml.AppendFormat("<header>{0}</header>", HttpUtility.HtmlEncode(html));

            html = renderPartialView("/Components/Footer");
            xml.AppendFormat("<footer>{0}</footer>", HttpUtility.HtmlEncode(html));

            xml.AppendLine("</pageParts>");

            return this.Content(xml.ToString(), "text/xml", Encoding.UTF8);
        }

    }
}
