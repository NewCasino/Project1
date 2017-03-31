using System.Web.Mvc;
using CM.Sites;
using Finance;

namespace GamMatrix.CMS.Controllers.BellaJackpots
{
    [HandleError]
    public class BonusWidgetController : ControllerEx
    {
        public JsonResult TransformCurrency(string sourceCurrency, string destCurrency, decimal amount)
        {
            var transformedAmount = MoneyHelper.TransformCurrency(sourceCurrency, destCurrency, amount);

            return this.Json(new { transformedAmount }, "application/json", JsonRequestBehavior.AllowGet);
        }
    }
}
