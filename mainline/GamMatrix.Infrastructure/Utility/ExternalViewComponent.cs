using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Web.Mvc;
using System.IO;
using System.Web.Mvc.Html;
using System.Web;
using System.Text.RegularExpressions;

namespace GamMatrix.Infrastructure.Utility
{
	public static class ExternalViewComponent
	{
		private class LighWeightView : IView
		{
			public void Render(ViewContext viewContext, TextWriter writer)
			{
			}
		}

		private class LighWeightDataContainer : IViewDataContainer
		{
			private ViewDataDictionary _viewData;
			public ViewDataDictionary ViewData { get { return _viewData; } set { _viewData = value; } }

			public LighWeightDataContainer(ViewDataDictionary viewData)
			{
				_viewData = viewData;
			}
		}

		public static string RenderComponent(string path, ViewDataDictionary viewData, ControllerContext context, object model = null)
		{
			string componentHtml;
			using (StringWriter sw = new StringWriter())
			{
				ViewContext viewContext = new ViewContext(context
					, new LighWeightView()
					, viewData
					, new TempDataDictionary()
					, sw
					);
				LighWeightDataContainer container = new LighWeightDataContainer(viewData);
				HtmlHelper htmlHelper = new HtmlHelper(viewContext, container);

				componentHtml = PartialExtensions.Partial(htmlHelper, path, model).ToString();
			}

			return componentHtml;
		}

		public static string AbsoluteUrl(string html, string baseUrl, bool links = true, bool images = true)
		{
			if (!(links || images))
				throw new ArgumentException("At least one option must be enabled");

			if (links)
				html = AbsoluteAnchorHref(html, baseUrl);

			if (images)
				html = AbsoluteImgSrc(html, baseUrl);

			return html;
		}

		public static string AbsoluteAnchorHref(string html, string baseUrl)
		{
			Func<Match, string> onLinkFound = delegate(Match match)
			{
				return ParseMatchedElement(match, "href", baseUrl);
			};

			html = Regex.Replace(html
				, @"\<(\s*)a(\s+)([^\>]*?)href(\s*)\=(\s*)(?<quot>(\""|\'))(?<href>.+?)\k<quot>([^\>]*)\>"
				, new MatchEvaluator(onLinkFound)
				, RegexOptions.Compiled | RegexOptions.Multiline | RegexOptions.ECMAScript | RegexOptions.IgnoreCase | RegexOptions.CultureInvariant
				);

			return html;
		}

		public static string AbsoluteImgSrc(string html, string baseUrl)
		{
			Func<Match, string> onImageFound = delegate(Match match)
			{
				return ParseMatchedElement(match, "src", baseUrl);
			};

			html = Regex.Replace(html
				, @"\<(\s*)img(\s+)([^\>]*?)src(\s*)\=(\s*)(?<quot>(\""|\'))(?<src>.+?)\k<quot>([^\>]+)\>"
				, new MatchEvaluator(onImageFound)
				, RegexOptions.Compiled | RegexOptions.Multiline | RegexOptions.ECMAScript | RegexOptions.IgnoreCase | RegexOptions.CultureInvariant
				);

			return html;
		}

		private static string ParseMatchedElement(Match match, string property, string baseUrl)
		{
			if (match.Success)
			{
				if (match.Groups[property].Value.StartsWith("/", StringComparison.OrdinalIgnoreCase))
					return match.Value.Insert(match.Groups[property].Index - match.Index, baseUrl);

				return match.Value;
			}
			return string.Empty;
		}
	}
}
