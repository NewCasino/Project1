using System.Collections.Generic;
using System.Web.Mvc;

namespace CasinoEngine.Models
{
    public class VendorWizardsModel
    {
        public List<SelectListItem> LiveCasinoGameCategories { get; set; }
        public Dictionary<string, string> ClientTypes { get; set; }
        public List<SelectListItem> Games { get; set; }
    }
}