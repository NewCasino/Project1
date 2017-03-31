namespace GamMatrix.CMS.Models.Common.Base
{
	public abstract class MultiuseView : ViewModelBase
	{
		public bool DisableJsCode;
		public string ComponentId;

		public string GetComponentIdProperty(string prefix = "", string postfix = "")
		{
			if (!string.IsNullOrEmpty(ComponentId))
				return string.Format("{0}{1}{2}", prefix, ComponentId, postfix);
			return string.Empty;
		}
	}
}
