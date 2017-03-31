using System.Web.UI;
using System.Web.UI.WebControls;

namespace CM.Web.UI
{
    [ParseChildren(true)]
    public sealed class BalloonTooltip : WebControl
    {
        /// <summary>
        /// {0} = ArrowDirection
        /// {1} = inner HTML
        /// {2} = for id
        /// </summary>
        public static readonly string BUBBLE_FORMAT_STRING = @"
<div class=""bubbletip {0}"" elementId=""{2}"">
    <div class=""bubbletip_Wrap"">
        <div class=""bubbletip_Arrow""></div>
        <div class=""bubbletip_Container"">
            <div class=""bubbletip_Container_Bottom"">
                <div class=""bubbletip_Container_Center"">
                    {1}
                </div>
            </div>
        </div>
    </div>
</div>";

        public enum ArrowDirection
        {
            Left,
            Top,            
        }
    }
}
