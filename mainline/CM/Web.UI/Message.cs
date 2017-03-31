using System.Web.UI;
using System.Web.UI.WebControls;

namespace CM.Web.UI
{
    [ParseChildren(true)]
    public sealed class Message : WebControl
    {


        public ControlExtension.MessageType Type { get; set; }
        public string Text { get; set; }
        public string Html { get; set; }

        protected override void Render(HtmlTextWriter writer)
        {
            if (!Visible || DesignMode)
                return;
            string cssClass = this.CssClass.DefaultIfNullOrEmpty("message");

            if (!string.IsNullOrEmpty(this.ID))
                this.ClientIDMode = ClientIDMode.Static;

            writer.WriteBeginTag("div");

            if (!string.IsNullOrEmpty(this.ID))
                writer.WriteAttribute("id", this.ClientID);

            writer.WriteAttribute("class", string.Format( "{0} {1}", cssClass, this.Type.ToString().ToLowerInvariant()));
            writer.Write(HtmlTextWriter.TagRightChar);

            writer.Write(ControlExtension.MESSAGE_FORMAT_STRING
                , cssClass.SafeHtmlEncode()
                , this.Html.DefaultIfNullOrEmpty( this.Text.SafeHtmlEncode() )
                );

            writer.WriteLine();

            writer.WriteEndTag("div");
        }
    }
}
