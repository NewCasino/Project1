using System.IO;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace CM.Web.UI
{
    /// <summary>
    /// Header, present the HTML tag,  &lt;h1&gt; &lt;h2&gt; &lt;h3&gt; &lt;h4&gt; &lt;h5&gt;
    /// </summary>
    [ParseChildren(false)]
    public sealed class Header : WebControl
    {
        /// <summary>
        /// constructor
        /// </summary>
        public Header() { this.HeadLevel = ControlExtension.HeadLevel.h1; this.EnableViewState = false; }

        /// <summary>
        /// Text for the header
        /// </summary>
        public string Text { get; set; }

        /// <summary>
        /// Level of the head
        /// </summary>
        public ControlExtension.HeadLevel HeadLevel { get; set; }

        /// <summary>
        /// Produce the HTML of the control
        /// </summary>
        /// <param name="writer"></param>
        protected override void Render(HtmlTextWriter writer)
        {
            if (!Visible || DesignMode)
                return;

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

            string cssClass = this.CssClass.DefaultIfNullOrEmpty(this.HeadLevel.ToString().ToLowerInvariant());
            writer.WriteBeginTag(this.HeadLevel.ToString());
            writer.WriteAttribute("class", cssClass);
            writer.Write(HtmlTextWriter.TagRightChar);
            writer.Write(ControlExtension.HEADER_FORMAT_STRING
                , cssClass.SafeHtmlEncode()
                , innerHtml
                );
            writer.WriteLine();

            writer.WriteEndTag(this.HeadLevel.ToString());
        }
    }
}
