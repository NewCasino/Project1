using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BulkOperations.Operations.Custom.Obsolete
{
	[Obsolete]
	public class MainLogoMetaLink : OperationBase
	{
		private const string TargetFile = @"\Components\HeaderView.ascx";
		private const string FindText = "this.GetMetadata(\".Url_MainLogo\")";
		private const string ReplaceText = "this.GetMetadata(\"/Metadata/Settings/.Operator_LogoUrl\")";

		private string FullTargetPath;


		public override void Initialize()
		{
			Log(string.Format("Replacing {0} with {1} in {2}", FindText, ReplaceText, TargetFile));
		}

		public override void SetBasePath(string path)
		{
			base.SetBasePath(path);
			FullTargetPath = GetFullPath(TargetFile);
		}

		public override bool CanExecute()
		{
			if (File.Exists(FullTargetPath))
			{
				var insances = File.ReadLines(FullTargetPath)
					.Where(l => l.Contains(FindText));

				return insances.Count() > 0;
			}

			return false;
		}

		public override void Execute()
		{
			var content = File.ReadAllText(FullTargetPath);
			content = content.Replace(FindText, ReplaceText);
			File.WriteAllText(FullTargetPath, content);

			Log(string.Format("Replaced for: {0}", Operator));
		}
	}
}
