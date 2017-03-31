using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BulkOperations.Operations.Custom.Obsolete
{
	[Obsolete]
	public class MainLogoDelete : OperationBase
	{
		private const string TargetPath = @"\Components\_HeaderView_ascx\.Url_MainLogo";


		public override void Initialize()
		{
			Log(string.Format("Deleting file {0}", TargetPath));
		}

		public override bool CanExecute()
		{
			return File.Exists(GetFullPath(TargetPath));
		}

		public override void Execute()
		{
			File.Delete(GetFullPath(TargetPath));
			Log(string.Format("Deleted for: {0}", Operator));
		}
	}
}
