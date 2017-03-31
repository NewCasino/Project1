using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BulkOperations.Operations.Standard
{
	public class FileCopy : OperationBase
	{
		private string Source;
		private string Destination;
		private bool Overwrite;

		private FileInfo SourceFile;
		private FileInfo DestinationFile;

		public FileCopy(string source, string destination, bool overwrite)
		{
			Source = source;
			Destination = destination;
			Overwrite = overwrite;
		}

		public override void Initialize()
		{
			Log(string.Format("Copying file from {0} to {1}.{2}"
				, Source
				, Destination
				, Overwrite ? " Overwriting existing files." : string.Empty));
		}

		public override void SetBasePath(string path)
		{
			base.SetBasePath(path);

			SourceFile = new FileInfo(GetFullPath(Source));
			DestinationFile = new FileInfo(GetFullPath(Destination));
		}

		public override bool CanExecute()
		{
			return SourceFile.Exists && (Overwrite || !DestinationFile.Exists);
		}

		public override void Execute()
		{
			Directory.CreateDirectory(DestinationFile.DirectoryName);
			SourceFile.CopyTo(DestinationFile.FullName, true);

			Log(string.Format("Copied for: {0}", Operator));
		}
	}
}
