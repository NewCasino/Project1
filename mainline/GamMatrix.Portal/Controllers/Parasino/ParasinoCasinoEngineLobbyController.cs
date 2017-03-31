using System.Web.Mvc;
using CM.Web;

namespace GamMatrix.CMS.Controllers.Parasino
{
    public class ParasinoCasinoEngineLobbyController : GamMatrix.CMS.Controllers.Shared.CasinoEngineLobbyController
    {
        [HttpGet]
        [MasterPageViewData(Name = "CurrentPageClass", Value = "CasinoLobby")]
        [CompressFilter]
        public ActionResult Microgaming()
        {
            this.ViewData["vendor"] = "Microgaming";
            return this.View("Index");
        }

        [HttpGet]
        [MasterPageViewData(Name = "CurrentPageClass", Value = "CasinoLobby")]
        [CompressFilter]
        public ActionResult NetEnt()
        {
            this.ViewData["vendor"] = "NetEnt";
            return this.View("Index");
        }
    }
}