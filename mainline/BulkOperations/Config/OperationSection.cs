using System;
using System.Collections.Generic;
using System.Configuration;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using BulkOperations.Operations;

namespace BulkOperations.Config
{
	public class OperationSection : ConfigurationSection
	{
		[ConfigurationProperty("operations", IsRequired = true)]
		[ConfigurationCollection(typeof(OperationCollection), AddItemName = "operation")]
		private OperationCollection Operations
		{
			get
			{
				return (OperationCollection)this["operations"];
			}
		}

		public List<OperationBase> GetOperations()
		{
			var operations = new List<OperationBase>();

			foreach (var operationSettings in Operations)
				operations.Add(operationSettings.GetOperation());

			return operations;
		}
	}
}
