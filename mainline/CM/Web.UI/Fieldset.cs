using System.Web.UI;
using System.Web.UI.WebControls;

namespace CM.Web.UI
{
    [ParseChildren(false)]
    public sealed class Fieldset : WebControl
    {
        public string Legend { get; set; }

        protected override void Render(HtmlTextWriter writer)
        {
            if (!Visible || DesignMode)
                return;

            string cssClass = this.CssClass.DefaultIfNullOrEmpty("fieldset");
            if (!string.IsNullOrEmpty(this.ID))
                this.ClientIDMode = ClientIDMode.Static;
            writer.Write(@"
<div id=""{0}"" class=""{1}"">
    <fieldset>"
            , this.ClientID.SafeHtmlEncode()
            , cssClass.SafeHtmlEncode()
            );

            if( !string.IsNullOrWhiteSpace(this.Legend) )
                writer.Write(@"<legend>{0}</legend>", this.Legend.SafeHtmlEncode());
            writer.Write(@"<div class=""{0}_Container"">", cssClass.SafeHtmlEncode() );

            base.RenderChildren(writer);

            writer.Write(@"
        </div>
    </fieldset>
</div>");
        }
    }
}
