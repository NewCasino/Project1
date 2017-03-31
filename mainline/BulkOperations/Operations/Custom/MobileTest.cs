using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BulkOperations.Operations.Custom
{
	public class MobileTest : OperationBase
	{
		private const string TestTarget = @"\Metadata\Settings\.Operator_LogoUrl";


		public override void Initialize()
		{
			Log("Testing for mobile operators");
		}

		public override bool CanExecute()
		{
			return File.Exists(GetFullPath(TestTarget));
		}

		public override void Execute()
		{
			Log(string.Format("Found mobile: {0}", Operator));
		}
	}
}
