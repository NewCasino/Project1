﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CE.Integration.VendorApi.Models
{
    public class VendorBalance
    {
        public int VendorId { get; set; }

        public decimal Balance { get; set; }

        public string Currency { get; set; }

        public bool IsActive { get; set; }
    }
}