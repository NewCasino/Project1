using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BulkOperations.Operations
{
	public interface IOperation
	{
		void Initialize();
		void SetBasePath(string path);
		bool CanExecute();
		void Execute();
	}
}
