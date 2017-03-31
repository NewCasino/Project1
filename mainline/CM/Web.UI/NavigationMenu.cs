using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Text;
using System.Web.Mvc;

namespace CM.Web.UI
{
    public sealed class NavigationMenuItem
    {
        public string NagivationUrl { get; set; }
        public string Text { get; set; }
        public string Target { get; set; }
        public string CssClass { get; set; }
        public bool IsSelected { get; set; }
        public string ShowedOnCountries { get; set; }

        private List<NavigationMenuItem> _children = new List<NavigationMenuItem>();
        public List<NavigationMenuItem> Children { get { return _children; } }
    }

    public enum MenuType
    {
        SideMenu,
    }

    public sealed class NavigationMenu : IDisposable
    {
        public bool _disposed;
        private readonly ViewContext _viewContext;
        private readonly TextWriter _writer;
        private List<NavigationMenuItem> _items = new List<NavigationMenuItem>();

        public List<NavigationMenuItem> Items { get { return _items; } }
        public string ClientID { get; set; }
        public MenuType MenuType { get; private set; }

        internal NavigationMenu(ViewContext viewContext, MenuType menuType)
        {
            this.MenuType = menuType;
            this._viewContext = viewContext;
            this._writer = viewContext.Writer;
        }

        ~NavigationMenu()
        {
            Dispose(false);
        }

        public void Dispose()
        {
            Dispose(true);
            GC.SuppressFinalize(this);
        }

        private void Dispose(bool disposing)
        {
            if (!this._disposed)
            {
                this._disposed = true;

                bool isChildSelected = false;
                this._writer.WriteLine(this.Render(_items, ref isChildSelected));

                this._writer.Write("</div>");

                this._writer.WriteLine(string.Format(@"
<script language=""javascript"" type=""text/javascript"">
//<![CDATA[
$(document).ready( function() {{ $('#{0}').initilizeNavigationMenu('{1}'); }} );
//]]>
</script>"
    , this.ClientID
    , this.MenuType.ToString().ToLower(CultureInfo.InvariantCulture)
    ));
            }
        }

        public void EndMenu()
        {
            this.Dispose(true);
        }

        private string Render(List<NavigationMenuItem> items, ref bool isChildSelected)
        {
            StringBuilder html = new StringBuilder();

            html.Append("\n<ul>");
            for( int i = 0; i < items.Count; i++)
            {
                NavigationMenuItem item = items[i];

                bool hasUrl = !string.IsNullOrWhiteSpace(item.NagivationUrl) &&
                    !item.NagivationUrl.StartsWith("#") &&
                    !item.NagivationUrl.StartsWith("javascript:void(0)");

                string cssName = string.Empty;
                if( i == 0 )
                    cssName = "first";
                else if ( i == items.Count - 1 )
                    cssName = "last";
                else
                    cssName = "normal";
                if (item.IsSelected)
                {
                    cssName += " selected";
                    isChildSelected = true;
                }

                cssName += (i + 1) % 2 == 0 ? " Even" : " Odd";

                html.AppendFormat("\n<li class=\"{0}\">", cssName);

                html.Append("<span");
                if( !string.IsNullOrWhiteSpace(item.CssClass) )
                    html.AppendFormat(" class=\"{0}\" ", item.CssClass.SafeHtmlEncode());
                html.Append(">");

                html.AppendFormat("<a target=\"{0}\" href=\"{1}\">{2}</a>"
                    , item.Target.DefaultIfNullOrEmpty("_self").SafeHtmlEncode()
                    , item.NagivationUrl.DefaultIfNullOrEmpty("javascript:void(0)").SafeHtmlEncode()
                    , item.Text.SafeHtmlEncode()
                    );

                html.Append("</span>");

                if (item.Children.Count > 0)
                {
                    bool isSelected = false;
                    string innerHTML = this.Render(item.Children, ref isSelected);
                    if (isSelected)
                        isChildSelected = true;

                    html.AppendFormat("\n<div class=\"children {0}\">"
                        , isSelected ? "" : "collapsed"
                        );
                    html.AppendLine(innerHTML);
                    html.Append("\n</div>");
                }
                html.Append("</li>");
            }

            html.AppendLine("\n</ul>");

            return html.ToString();
        }
    }
}
