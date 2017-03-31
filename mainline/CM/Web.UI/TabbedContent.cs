using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace CM.Web.UI
{
    

    //[ParseChildren(true, "Tabs")]
    //[DefaultProperty("Tabs")]
    public sealed class TabbedContent : WebControl
    {
        private List<Panel> m_Tabs = new List<Panel>();

        //[PersistenceMode(PersistenceMode.InnerDefaultProperty)]
        public List<Panel> Tabs { get { return m_Tabs; } }

        protected override void Render(HtmlTextWriter writer)
        {
            if (!Visible || DesignMode)
                return;

            this.ClientIDMode = ClientIDMode.Static;
            string clientID = this.ClientID.DefaultIfNullOrEmpty( "_" + Guid.NewGuid().ToString("N") );
            writer.Write("<div id=\"{0}\" class=\"tabbed_content\">", clientID);

            StringBuilder sb = new StringBuilder();

            writer.Write("<ul class=\"tabs\">");
            foreach (Panel panel in Tabs.Where(t => t.Visible))
            {
                string caption = panel.Attributes["Caption"];
                bool isHtmlCaption = string.Equals(panel.Attributes["IsHtmlCaption"], "true", StringComparison.OrdinalIgnoreCase);
                string id = panel.ID.DefaultIfNullOrEmpty("_" + Guid.NewGuid().ToString("N"));
                bool isSelected = string.Equals(panel.Attributes["Selected"], "true", StringComparison.OrdinalIgnoreCase);

                writer.Write(@"
<li class=""tab {2}"" forid=""{0}"">
  <a href=""#{0}"">
   <div class=""tab_left"">
      <div class=""tab_right"">
         <div class=""tab_center""><span>{1}</span></div>
      </div>
   </div>
  </a>
</li>
"
                    , id
                    , isHtmlCaption ? caption.HtmlEncodeSpecialCharactors() : caption.SafeHtmlEncode()
                    , isSelected ? "selected" : string.Empty
                    );

                panel.CssClass = "tabbody";
                using (StringWriter sw = new StringWriter())
                {
                    using (HtmlTextWriter htw = new HtmlTextWriter(sw))
                    {
                        panel.RenderControl(htw);
                    }

                    string innerHtml = sw.ToString();
                    sb.Append(innerHtml);
                }
            }
            writer.Write("</ul>");
            writer.Write(sb.ToString());

            writer.Write("</div>");

            writer.Write(@"
<script language=""javascript"" type=""text/javascript"">
$(document).ready( function() {{ __initializeTabbedContent($('#{0}')); }} );
</script>"
                , clientID
                );
        }
    }
}
