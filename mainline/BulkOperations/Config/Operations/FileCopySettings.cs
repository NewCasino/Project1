using System;
using System.Collections.Generic;
using System.Configuration;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using BulkOperations.Operations.Standard;

namespace BulkOperations.Config.Operations
{
	public class FileCopySettings : OperationElement
	{
		[ConfigurationProperty("source", IsRequired = true)]
		private string Source
		{
			get
			{
				return (string)this["source"];
			}
		}

		[ConfigurationProperty("destination", IsRequired = true)]
		private string Destination
		{
			get
			{
				return (string)this["destination"];
			}
		}

		[ConfigurationProperty("overwrite", DefaultValue = false)]
		private bool Overwrite
		{
			get
			{
				return (bool)this["overwrite"];
			}
		}

		protected override BulkOperations.Operations.OperationBase CreateOperation()
		{
			return new FileCopy(Source, Destination, Overwrite);
		}
	}
}
