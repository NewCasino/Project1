using System;
using System.Web.Mvc;
using CM.Sites;
using CM.Web;

namespace GamMatrix.CMS.Controllers.Shared
{
    [HandleError]
    [ControllerExtraInfo(DefaultAction = "Index")]
    public class CasinoInfoController : ControllerEx
    {
        public CasinoInfoController()
        {
            base.EnableDynamicAction = true;
        }


        public override ActionResult OnDynamicActionInvoked(string actionName)
        {
            if (string.IsNullOrWhiteSpace(actionName))
                actionName = "fpp-rates";
            else
                actionName = actionName.ToLowerInvariant();

            switch (actionName)
            {
                case "rtp":
                    this.ViewData["DataField"] = "RTP";
                    return this.View("GameList");

                case "fpp-rates":
                    this.ViewData["DataField"] = "FPP";
                    return this.View("GameList");

                case "bonus-contribution":
                    this.ViewData["DataField"] = "BonusContribution";
                    return this.View("GameList");

                default:
                    throw new NotImplementedException();
            }
            
        }



    }
}
