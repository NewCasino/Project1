using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Web;
using CM.Sites;
using CM.State;

namespace GamMatrix.CMS.HttpHandlers
{
	public class ManifestHandler : IHttpHandler
	{
		private const string StaticThemePath = "~/App_Themes/Generic/mobile2";
		private const string OperatorThemeFormat = "~/App_Themes/{0}/";

		public bool IsReusable
		{
			get { return true; }
		}

		public void ProcessRequest(HttpContext context)
		{
			var request = context.Request;
			var response = context.Response;
			response.ContentType = "text/cache-manifest";
			response.Write("CACHE MANIFEST\n");

			response.Write("#test v.1\n");

			CustomProfile.Current.Init(context);

			string operatorTheme = string.Format(OperatorThemeFormat, SiteManager.Current.DefaultTheme);
			List<string> files = GetFilePaths(context, StaticThemePath).ToList();
			files.AddRange(GetFilePaths(context, operatorTheme).ToList());

			response.Write("CACHE:\n");
			foreach (string file in files)
				response.Write(file + "\n");

			response.Write("NETWORK:\n*");

			response.Flush();
			response.Close();
		}

		public IEnumerable<string> GetFilePaths(HttpContext context, string path)
		{
			IEnumerable<string> files = Directory.GetFiles(context.Server.MapPath(path), "*", SearchOption.AllDirectories)
				.Select(p => p.Replace(context.Request.PhysicalApplicationPath, "/")
					.Replace(@"\", "/"));

			return files;
		}
	}
}
