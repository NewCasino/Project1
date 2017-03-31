using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BulkOperations.Operations
{
	public abstract class BackupOperation : OperationBase
	{
		protected const string BackupFomat = "{0}.bak{1:D2}";

		protected string Target;
		protected FileInfo TargetFile;

		public override void SetBasePath(string path)
		{
			base.SetBasePath(path);
			TargetFile = new FileInfo(GetFullPath(Target));
		}

		protected int GetLastBackupVersion()
		{
			var backups = GetExistingBackupFiles();
			if (backups.Count() == 0)
				return -1;

			var lastBackup = backups
				.LastOrDefault()
				.Name;

			return int.Parse(lastBackup.Substring(lastBackup.Length - 2));
		}

		protected IEnumerable<FileInfo> GetExistingBackupFiles()
		{
			var backupBase = string.Format(BackupFomat, TargetFile.Name, string.Empty);

			if (!TargetFile.Directory.Exists)
				return new FileInfo[0];

			return TargetFile.Directory
				.GetFiles()
				.Where(f => f.Name.Contains(backupBase))
				.OrderBy(f => f.Name);
		}
	}
}
