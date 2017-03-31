using System.Web.UI;

namespace CM.Web
{
    interface IViewPageBase
    {
        string PageTemplate { get; set; }
        string MasterPageFile { get; set; }
        MasterPage Master { get; }
        string AppRelativeVirtualPath { get; set; }
        string CssClass { get; set; }
    }
}
