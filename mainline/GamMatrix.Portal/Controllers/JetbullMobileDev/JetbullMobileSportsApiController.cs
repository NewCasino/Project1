using System;
using System.Text;
using System.Web.Mvc;
using System.Web.Routing;
using CM.Sites;
using GamMatrix.CMS.Controllers.MobileShared;
using GamMatrix.CMS.Models.MobileShared.Components;
using GamMatrix.Infrastructure.Utility;
using RestSharp.Contrib;

namespace GamMatrix.CMS.Controllers.JetbullMobileDev
{
    public class JetbullMobileSportsApiController : MobileSportsApiController
    {
        public ContentResult MenuV2(string pageTitle)
        {
            Func<string, string> renderPartialView = delegate(string path)
            {
                return ExternalViewComponent.AbsoluteAnchorHref
                (
                    ExternalViewComponent.RenderComponent(path, this.ViewData, this.ControllerContext, new MenuV2ViewModel(this.Url
                        , showSections: true
                        , showMainMenuEntries: true
                        , showAccountEntries: true)),
                    new UrlHelper(new RequestContext()).GetAbsoluteBaseUrl()
                );
            };

            this.ViewData["PageTitle"] = pageTitle;

            StringBuilder xml = new StringBuilder();
            xml.AppendLine("<?xml version=\"1.0\" encoding=\"utf-8\"?>");
            xml.AppendLine("<pageParts>");

            string html = renderPartialView("/Components/MenuV2");
            xml.AppendFormat("<menu>{0}</menu>", HttpUtility.HtmlEncode(html));

            xml.AppendLine("</pageParts>");

            return this.Content(xml.ToString(), "text/xml", Encoding.UTF8);
        }
    }
}
