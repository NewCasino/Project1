using System.IO;
using System.Web;
using System.Web.Mvc;

namespace CM.Sites
{
    public sealed class WebFormViewEx : WebFormView
    {
        public WebFormViewEx(string viewPath) : base(viewPath)
        {
        }

        public WebFormViewEx(string viewPath, string masterPath)
            : base(viewPath, masterPath)
        {
        }

        public override void Render(ViewContext viewContext, TextWriter writer)
        {
            viewContext.ViewData["__client_base_path"] = VirtualPathUtility.ToAbsolute(VirtualPathUtility.GetDirectory(this.ViewPath));
            viewContext.ViewData["__current_view_path"] = this.ViewPath;
            base.Render(viewContext, writer);
        }
    }
}
