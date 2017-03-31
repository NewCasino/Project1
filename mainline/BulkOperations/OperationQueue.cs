using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using BulkOperations.Operations;

namespace BulkOperations
{
	public class OperationQueue
	{
		private List<IOperation> Operations;
		private ILogger Logger;


		public OperationQueue(ILogger logger)
		{
			Operations = new List<IOperation>();
			Logger = logger;
		}

		public void AddMultiple(IEnumerable<OperationBase> operations)
		{
			foreach (var operation in operations)
				AppendOperation(operation);
		}

		public void Add(OperationBase operation)
		{
			AppendOperation(operation);
		}

		public void AddAt(int index, OperationBase operation)
		{
			operation.Logger = Logger;
			Operations.Insert(index, operation);
		}

		private void AppendOperation(OperationBase operation)
		{
			operation.Logger = Logger;
			Operations.Add(operation);
		}

		public List<IOperation> Finalize()
		{
			var operations = Operations;
			Operations = null;

			return operations;
		}
	}
}
