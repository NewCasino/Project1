using System.Web;
using System.Web.Mvc;
using CM.Content;
using CM.Sites;
using CM.State;

namespace GamMatrix.CMS.Models.Common.Base
{
	public abstract class ViewModelBase
	{
		private UrlHelper _urlHelper;
		protected UrlHelper UrlHelper
		{
			get
			{
				if (_urlHelper == null)
					_urlHelper = new UrlHelper(HttpContext.Current.Request.RequestContext, SiteManager.Current.GetRouteCollection());
				return _urlHelper;
			}
		}

		protected HttpRequest Request
		{
			get
			{
				return HttpContext.Current.Request;
			}
		}

		protected CustomProfile Profile
		{
			get { return CustomProfile.Current; }
		}

		protected string GetMetadata(string path)
		{
			return Metadata.Get(path);
		}
	}
}
