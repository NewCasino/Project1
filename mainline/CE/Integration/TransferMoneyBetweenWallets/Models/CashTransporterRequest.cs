using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.ComponentModel.DataAnnotations;

namespace CE.Integration.TransferMoneyBetweenWallets.Models
{
    public class CashTransporterRequest
    {
        public long DomainId { get; set; }

        public string VendorName { get; set; }

        public string Language { get; set; }

        public string Sid { get; set; }
    }
}
