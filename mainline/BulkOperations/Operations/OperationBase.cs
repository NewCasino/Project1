using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BulkOperations.Operations
{
	public abstract class OperationBase : IOperation
	{
		public ILogger Logger { private get; set; }

		private string BasePath;
		protected string Operator;


		public abstract void Initialize();
		public abstract bool CanExecute();
		public abstract void Execute();


		public virtual void SetBasePath(string path)
		{
			BasePath = path;
			Operator = path.Substring(path.LastIndexOf('\\') + 1);
		}

		protected void Log(string message)
		{
			Logger.Log(message);
		}

		protected string GetFullPath(string relativePath)
		{
			return string.Format("{0}{1}", BasePath, relativePath);
		}
	}
}
