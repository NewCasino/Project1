using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BulkOperations.Operations.Standard
{
	public class FileDelete : OperationBase
	{
		private string Target;
		private FileInfo TargetFile;

		public FileDelete(string target)
		{
			Target = target;
		}

		public override void Initialize()
		{
			Log(string.Format("Deleting file {0}", Target));
		}

		public override void SetBasePath(string path)
		{
			base.SetBasePath(path);
			TargetFile = new FileInfo(GetFullPath(Target));
		}

		public override bool CanExecute()
		{
			return TargetFile.Exists;
		}

		public override void Execute()
		{
			TargetFile.Delete();
			Log(string.Format("Deleted for: {0}", Operator));
		}
	}
}
