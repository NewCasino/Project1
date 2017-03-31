using System.IO;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace CM.Web.UI
{
    /// <summary>
    /// LinkButton control
    /// </summary>
    [ParseChildren(false)]
    public sealed class LinkButton : WebControl
    {
        public LinkButton()
        {
            this.Target = "_self";
        }

        /// <summary>
        /// Text of the button
        /// </summary>
        public string Text { get; set; }

        /// <summary>
        /// href of the button
        /// </summary>
        public string Href { get; set; }

        /// <summary>
        ///  target of the button
        /// </summary>
        public string Target { get; set; }

        /// <summary>
        /// Render the html
        /// </summary>
        /// <param name="writer"></param>
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

            string cssClass = this.CssClass.DefaultIfNullOrEmpty("linkbutton");

            writer.WriteBeginTag("a");

            if (!string.IsNullOrEmpty(this.ID))
                writer.WriteAttribute("id", this.ClientID);

            writer.WriteAttribute("href", this.Href.DefaultIfNullOrEmpty("#"));
            writer.WriteAttribute("target", this.Target);

            writer.WriteAttribute("class", cssClass);
            this.Attributes.Render(writer);
            writer.Write(HtmlTextWriter.TagRightChar);

            writer.Write(ControlExtension.LINK_FORMAT_STRING
                , cssClass.SafeHtmlEncode()
                , innerHtml
                );

            writer.WriteLine();

            writer.WriteEndTag("a");
        }
    }
}
