using System.Web.UI;
using System.Web.UI.WebControls;

namespace CM.Web.UI
{
    [ParseChildren(false)]
    public sealed class Panel : WebControl
    {
        protected override void Render(HtmlTextWriter writer)
        {
            if (!Visible || DesignMode)
                return;

            if (!string.IsNullOrEmpty(this.ID))
                this.ClientIDMode = ClientIDMode.Static;
            string cssClass = this.CssClass.DefaultIfNullOrEmpty("panel");
            writer.Write(@"
<div id=""{0}"" class=""{1}"">
    <div class=""{1}_Center_Right"">
        <div class=""{1}_Center_Left"">
            <div class=""{1}_Center_Middle"">"
                , this.ClientID.SafeHtmlEncode()
                , cssClass.SafeHtmlEncode()
                );

            base.RenderChildren(writer);

            writer.Write(@"
            </div>
        </div>
    </div>
    <div class=""{0}_Bottom"">
    	<div class=""{0}_Bottom_Left""></div>
        <div class=""{0}_Bottom_Right""></div>
    </div>
</div>"
                , cssClass.SafeHtmlEncode()
                );
        }
    }
}
