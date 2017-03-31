using System;
using System.Globalization;
using System.Text;
using System.Web;
using System.Web.Mvc;
using CM.Content;
using CM.Sites;
using CM.State;
using CM.Web;
using OddsMatrix;

namespace GamMatrix.CMS.Controllers.MobileShared
{
	[HandleError]
	[MasterPageViewData(Name = "CurrentSectionMarkup", Value = "SportsHomeSection")]
	[ControllerExtraInfo(DefaultAction = "Index")]
	public class MobileSportsHomeController : ControllerEx
	{
		public ActionResult Index()
		{
            string restrictCountries = Metadata.Get("/Metadata/Settings.SportsRestrictedCountries");
            bool isRectrictCountry = string.IsNullOrEmpty(restrictCountries) ? false : (restrictCountries.SplitToList(",").Contains(CustomProfile.Current.IpCountryID.ToString()) || restrictCountries.SplitToList(",").Contains(CustomProfile.Current.UserCountryID.ToString()));
            if ((CustomProfile.Current.IsInRole("Withdraw only")) || isRectrictCountry)
                return this.View("RestrictedCountry");

            if (Settings.IsUKLicense && !Settings.IsOMAllowedonUKLicense)
            {
                string url;
                if (Request.IsHttps() && SiteManager.Current.HttpsPort > 0)
                {
                    url = string.Format("https://{0}{1}"
                            , Request.Url.Host
                            , (SiteManager.Current.HttpsPort != 443) ? (":" + SiteManager.Current.HttpsPort.ToString()) : string.Empty
                            );
                }
                else
                {
                    url = string.Format("http://{0}{1}"
                            , Request.Url.Host
                            , (SiteManager.Current.HttpPort != 80) ? (":" + SiteManager.Current.HttpPort.ToString()) : string.Empty
                            );
                }
                Response.ClearHeaders();
                Response.Clear();
                Response.AddHeader("Location", url);
                Response.StatusCode = 301;
                Response.Flush();
                Response.End();
                return null;
            }

			return Redirect(GetUrl());
		}

        private string GetDomain()
        {
            string host = Request.Url.Host;
            if (host.EndsWith(".gammatrix-dev.net", StringComparison.InvariantCultureIgnoreCase))
            {
                //If the accessing domain name is under gammatrix-dev.net (i.e, www.jetbull.gammatrix-dev.net), 
                //the domain is set to jetbull.gammatrix-dev.net
                var fields = host.Split('.');
                string domain = string.Empty;
                for (var i = fields.Length - 3; i < fields.Length; i++)
                    domain += fields[i] + ".";
                return domain.TrimStart('.').TrimEnd('.');
            }
            else
            {
                //Otherwise, the root domain name is set as the domain. 
                //For example, www.casino.jetbull.com and www.jetbull.com and jetbull.com all get the same cookie domain jetbull.com;
                //www.casino.jetbull.com.mx and www.jetbull.com.mx and jetbull.com.mx all get the same cookie domain jetbull.com.mx
                //Note: the same logic will be applied to domain XXX.net, XXX.org, XXX.co and XXX.net.XX, XXX.org.XX, XXX.co.XX
                var tlds = new[]
                {
                    ".com",
                    ".net",
                    ".org",
                    ".co",
                };//top-level domains

                foreach (var tld in tlds)
                {
                    if (host.IndexOf(tld + ".", StringComparison.InvariantCultureIgnoreCase) > 0)
                    {
                        var temp = host.Substring(0, host.IndexOf(tld + ".", StringComparison.InvariantCultureIgnoreCase));
                        if (temp.LastIndexOf(".") >= 0)
                            temp = temp.Substring(temp.LastIndexOf(".") + 1);
                        var domain2 = temp + host.Substring(host.IndexOf(tld + ".", StringComparison.InvariantCultureIgnoreCase));
                        return domain2.TrimStart('.').TrimEnd('.');
                    }
                }

                var fields = host.Split('.');
                if (fields.Length < 2)
                    return host;
                string domain = string.Empty;
                for (var i = fields.Length - 2; i < fields.Length; i++)
                    domain += fields[i] + ".";
                return domain.TrimStart('.').TrimEnd('.');
            }
        }

		private string GetUrl()
		{
			StringBuilder sb = new StringBuilder();

            if (Settings.OddsMatrix_HomePage.Contains("$DOMAIN$"))
                sb.Append(Settings.OddsMatrix_HomePage.Replace("$DOMAIN$", GetDomain()));
            else
                sb.Append(Settings.OddsMatrix_HomePage);

			string pageUrl = Request.QueryString["pageURL"];
			if (string.IsNullOrWhiteSpace(pageUrl))
			{
				pageUrl = string.Empty;
			}
			else
			{
				if (pageUrl.IndexOf("/") != 0)
					pageUrl = string.Format("/{0}", pageUrl);
			}

			int queryIndex = sb.ToString().IndexOf('?');
			if (queryIndex > 0)
				sb.Insert(queryIndex, pageUrl).Append('&');
			else
				sb.Append(pageUrl).Append('?');

			sb.AppendFormat(CultureInfo.InvariantCulture, "lang={0}"
				, HttpUtility.UrlEncode(OddsMatrixProxy.MapLanguageCode(MultilingualMgr.GetCurrentCulture()))
			);

			sb.AppendFormat(CultureInfo.InvariantCulture, "&currentSession={0}"
				, HttpUtility.UrlEncode(CustomProfile.Current.SessionID)
				);
			foreach (string key in Request.QueryString.AllKeys)
			{
				if (string.Equals(key, "_sid", StringComparison.OrdinalIgnoreCase) ||
					string.Equals(key, "pageName", StringComparison.OrdinalIgnoreCase) ||
					string.Equals(key, "pageURL", StringComparison.OrdinalIgnoreCase))
					continue;

				sb.AppendFormat(CultureInfo.InvariantCulture, "&{0}={1}", HttpUtility.UrlEncode(key), HttpUtility.UrlEncode(Request.QueryString[key]));
			}

			return sb.ToString();
		}
	}
}
