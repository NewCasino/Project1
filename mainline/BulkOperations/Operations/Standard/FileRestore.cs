using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BulkOperations.Operations.Standard
{
	public class FileRestore : BackupOperation
	{
		private int Version;

		private FileInfo BackupFile;

		public FileRestore(string target, int version)
		{
			Target = target;
			Version = version;
		}

		public override void Initialize()
		{
			if (Version > -1)
				Log(string.Format("Restoring file {0} (version {1})", Target, Version));
			else
				Log(string.Format("Restoring file {0}", Target));
		}

		public override bool CanExecute()
		{
			var version = Version > -1 ? Version : GetLastBackupVersion();

			BackupFile = new FileInfo(string.Format(BackupFomat, TargetFile.FullName, version));

			return BackupFile.Exists;
		}

		public override void Execute()
		{
			BackupFile.CopyTo(TargetFile.FullName, true);

			Log(string.Format("Restored for: {0}", Operator));
		}
	}
}
