using System;
using System.Collections.Generic;
using System.Configuration;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using BulkOperations.Config;
using BulkOperations.Operations.Custom;

namespace BulkOperations
{
	class Program
	{
		private static OperationQueue Queue;
		private static OperationProcessor Processor;

		/// <summary>
		/// To add a new custom operation:
		///  - create a new operation type in BulkOperations.Operations.Custom inherited from BulkOperations.Operations.OperationBase;
		/// 
		/// To add a new standard operation:
		///  - create a new operation type in BulkOperations.Operations.Standard inherited from BulkOperations.Operations.OperationBase (i.e. FileCopy)
		///  - create a new configuration type in BulkOperations.Config.Operations inherited from BulkOperations.Config.OperationElement
		///  - the configuration type should have the same name as the operation type followed by 'Settings' (i.e. FileCopySettings)
		/// </summary>
		private static void Main(string[] args)
		{
			using (var logger = new Logger())
			{
				Queue = new OperationQueue(logger);
				Processor = new OperationProcessor(logger);

				AddOperations();
				ExecuteOperations();
			}

			Console.WriteLine("Complete!");
			Console.ReadKey();
		}

		private static void AddOperations()
		{
			var config = (OperationSection)ConfigurationManager.GetSection("operationSettings");
			Queue.AddMultiple(config.GetOperations());

			//Queue.AddAt(0, new MobileTest());//examples
			//Queue.Add(new MobileTest());
		}

		private static void ExecuteOperations()
		{
			Processor.SelectViewPaths(ConfigurationManager.AppSettings["ViewRoot"]);
			Processor.Execute(Queue.Finalize());
		}
	}
}
