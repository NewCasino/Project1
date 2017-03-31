using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BulkOperations.Operations.Standard
{
	public class FileBackup : BackupOperation
	{
		public FileBackup(string target)
		{
			Target = target;
		}


		public override void Initialize()
		{
			Log(string.Format("Backing up {0}", Target));
		}

		public override bool CanExecute()
		{
			return TargetFile.Exists;
		}

		public override void Execute()
		{
			var version = GetLastBackupVersion() + 1;
			var backupPath = string.Format(BackupFomat, TargetFile.FullName, version);

			TargetFile.CopyTo(backupPath);

			Log(string.Format("Backed up for: {0} (version {1})", Operator, version));
		}
	}
}
