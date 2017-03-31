using System.IO;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace CM.Web.UI
{
    [ParseChildren(false)]
    public sealed class Button : WebControl
    {
        public string Text { get; set; }

        protected override void Render(HtmlTextWriter writer)
        {
            if (!Visible || DesignMode)
                return;
            this.Attributes["onclick"] = "this.blur();" + this.Attributes["onclick"];

            string innerHtml;
            {
                if (!string.IsNullOrWhiteSpace(this.Text))
                    innerHtml = this.Text.SafeHtmlEncode();
                else
                {
                    using (StringWriter sw = new StringWriter())
                    {
                        using (HtmlTextWriter htw = new HtmlTextWriter(sw))
                        {
                            base.RenderChildren(htw);
                        }
                        innerHtml = sw.ToString();
                    }
                }
            }
            if( !string.IsNullOrEmpty(this.ID) )
                this.ClientIDMode = ClientIDMode.Static;

            string cssClass = this.CssClass.DefaultIfNullOrEmpty("button");

            writer.WriteBeginTag("button");

            if (!string.IsNullOrEmpty(this.ID))
                writer.WriteAttribute("id", this.ClientID);

            if( !this.Enabled )
                writer.WriteAttribute("disabled", "disabled");

            writer.WriteAttribute("class", cssClass);
            this.Attributes.Render(writer);
            writer.Write(HtmlTextWriter.TagRightChar);

            writer.Write(ControlExtension.BUTTON_FORMAT_STRING
                , cssClass.SafeHtmlEncode()
                , innerHtml
                );

            writer.WriteLine();

            writer.WriteEndTag("button");
        }
    }
}
