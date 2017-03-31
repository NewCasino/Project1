using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using BulkOperations.Operations;

namespace BulkOperations
{
	public class OperationProcessor
	{
		private List<string> ViewPaths;
		private ILogger Logger;

		public OperationProcessor(ILogger logger)
		{
			Logger = logger;
		}

		public void SelectViewPaths(string viewRoot)
		{
			ViewPaths = new List<string>();

			var rootInfo = new DirectoryInfo(viewRoot);
			foreach (var directory in rootInfo.GetDirectories())
			{
				ViewPaths.Add(directory.FullName);
			}
		}

		public void Execute(IEnumerable<IOperation> operations)
		{
			Logger.Log(string.Empty);
			foreach (var operation in operations)
				ExecuteOperation(operation);
		}

		private void ExecuteOperation(IOperation operation)
		{
			Logger.Log(string.Empty);
			Logger.Log(string.Format("Executing [{0}]", operation.GetType()));

			operation.Initialize();

			foreach (var path in ViewPaths)
			{
				operation.SetBasePath(path);
				if (operation.CanExecute())
					operation.Execute();
			}
		}
	}
}
