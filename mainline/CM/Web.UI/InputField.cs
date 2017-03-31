using System.Web.UI;
using System.Web.UI.WebControls;

namespace CM.Web.UI
{


    [ParseChildren(true)]
    public sealed class InputField : WebControl
    {
        [ParseChildren(false)]
        public sealed class InternalWebControl : WebControl
        {
            public void PublicRenderChildren(HtmlTextWriter writer)
            {
                base.RenderChildren(writer);
            }
        }

        public InternalWebControl LabelPart { get; set; }
        public InternalWebControl ControlPart { get; set; }
        public InternalWebControl HintPart { get; set; }
        public bool ShowDefaultIndicator { get; set; }
        public bool ShowErrorAsBalloon { get; set; }
        public BalloonTooltip.ArrowDirection BalloonArrowDirection { get; set; }

        public InputField()
        {
            this.ShowDefaultIndicator = false;
            this.ShowErrorAsBalloon = true;
            this.BalloonArrowDirection = BalloonTooltip.ArrowDirection.Left;
        }

        protected override void Render(HtmlTextWriter writer)
        {
            if (!Visible || DesignMode)
                return;

            if (!string.IsNullOrEmpty(this.ID))
                this.ClientIDMode = ClientIDMode.Static;
            writer.Write("<div id=\"{0}\" class=\"inputfield {1}\""
                , this.ClientID
                , this.CssClass
                );
            this.Attributes.Render(writer);
            writer.Write(">");

            {
                if (this.LabelPart != null)
                {
                    writer.Write("<div valign=\"top\" class=\"inputfield_Label\">");
                    this.LabelPart.PublicRenderChildren(writer);
                    writer.Write("</div>");
                }

                writer.Write("<div class=\"inputfield_Container\">");
                {
                    writer.Write("<table class=\"inputfield_Table\" cellpadding=\"0\" cellspacing=\"0\" border=\"0\"><tr><td class=\"controls\">");

                    if (this.ControlPart != null)
                        this.ControlPart.PublicRenderChildren(writer);

                    if (!this.ShowErrorAsBalloon)
                        writer.Write("<div class=\"inputfield_Error\"></div>");

                    writer.Write("</td><td valign=\"top\" class=\"indicator {0}\"><div>&#160;</div></td></tr><tr><td colspan=\"2\" class=\"hint\"><span>"
                        , ShowDefaultIndicator ? string.Empty : "hide_default"
                        );

                    if (this.HintPart != null)
                        this.HintPart.PublicRenderChildren(writer);

                    writer.Write("</span></td></tr></table>");
                    

                    writer.Write("<div style=\"clear:both\"></div>");
                }
                writer.Write("</div>");                          
            }

            writer.Write("</div>");

            if (this.ShowErrorAsBalloon)
            {
                writer.Write(BalloonTooltip.BUBBLE_FORMAT_STRING
                    , this.BalloonArrowDirection.ToString().ToLowerInvariant()
                    , string.Format( "<div class=\"inputfield_Error\" elementId=\"{0}\"></div>", this.ClientID.SafeHtmlEncode())
                    , this.ClientID.SafeHtmlEncode()
                    );
            }   
        }
    }
}
