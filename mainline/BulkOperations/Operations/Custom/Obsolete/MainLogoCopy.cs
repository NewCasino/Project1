using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BulkOperations.Operations.Custom.Obsolete
{
	[Obsolete]
	public class MainLogoCopy : OperationBase
	{
		private const string SourcePath = @"\Components\_HeaderView_ascx\.Url_MainLogo";
		private const string DestinationPath = @"\Metadata\Settings\.Operator_LogoUrl";


		public override void Initialize()
		{
			Log(string.Format("Copying main logo url from {0} to {1}", SourcePath, DestinationPath));
		}

		public override bool CanExecute()
		{
			return File.Exists(GetFullPath(SourcePath));
		}

		public override void Execute()
		{
			var source = GetFullPath(SourcePath);
			var destination = GetFullPath(DestinationPath);

			Directory.CreateDirectory(destination.Substring(0, destination.LastIndexOf('\\')));
			File.Copy(source, destination, true);

			Log(string.Format("Copied for: {0}", Operator));
		}
	}
}
