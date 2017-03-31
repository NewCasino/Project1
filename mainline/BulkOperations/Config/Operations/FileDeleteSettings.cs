using System;
using System.Collections.Generic;
using System.Configuration;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using BulkOperations.Operations;
using BulkOperations.Operations.Standard;

namespace BulkOperations.Config.Operations
{
	public class FileDeleteSettings : OperationElement
	{
		[ConfigurationProperty("target", IsRequired = true)]
		private string Target
		{
			get
			{
				return (string)this["target"];
			}
		}

		protected override OperationBase CreateOperation()
		{
			return new FileDelete(Target);
		}
	}
}
