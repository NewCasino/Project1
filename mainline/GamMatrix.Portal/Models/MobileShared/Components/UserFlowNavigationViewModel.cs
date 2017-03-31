namespace GamMatrix.CMS.Models.MobileShared.Components
{
	public class UserFlowNavigationViewModel
	{
		public bool BackButtonEnabled = true;
		public bool NextButtonEnabled = true;
		private bool _isFormSection = true;
		public bool IsFormSection 
		{
			get { return _isFormSection; }
			set 
			{ 
				_isFormSection = value;
				if (_isFormSection == true)
					NextUrl = null;
			}
		}
		private string _nextUrl;
		public string NextUrl 
		{
			get { return _nextUrl; }
			set
			{
				_nextUrl = value;
				if (!string.IsNullOrWhiteSpace(_nextUrl))
					IsFormSection = false;
			}
		}
		public string NextName;
	}
}
