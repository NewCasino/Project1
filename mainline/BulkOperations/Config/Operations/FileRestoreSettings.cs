using System;
using System.Collections.Generic;
using System.Configuration;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using BulkOperations.Operations.Standard;

namespace BulkOperations.Config.Operations
{
	public class FileRestoreSettings : OperationElement
	{
		[ConfigurationProperty("target", IsRequired = true)]
		private string Target
		{
			get
			{
				return (string)this["target"];
			}
		}

		[ConfigurationProperty("version", DefaultValue = -1)]
		private int Version
		{
			get
			{
				return (int)this["version"];
			}
		}

		protected override BulkOperations.Operations.OperationBase CreateOperation()
		{
			return new FileRestore(Target, Version);
		}
	}
}
