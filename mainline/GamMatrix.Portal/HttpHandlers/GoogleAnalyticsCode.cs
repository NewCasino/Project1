using System.Globalization;
using System.Text;
using System.Web;
using CM.Content;
using CM.Sites;

namespace GamMatrix.CMS.HttpHandlers
{ 
    public sealed class GoogleAnalyticsCode : IHttpHandler
    {
        public bool IsReusable
        { 
            get { return true; }
        }

        public void ProcessRequest(HttpContext context)
        {
            int userID = 0;
            if( !string.IsNullOrWhiteSpace(context.Request.QueryString["u"]) )
                int.TryParse( context.Request.QueryString["u"], out userID);

            string product = string.Equals( context.Request.QueryString["mobile"], "1", System.StringComparison.InvariantCulture) 
                ? "GamMatrix Mobile" : "GamMatrix CMS";
            string accountCode = Metadata.Get("Metadata/Settings.GoogleAnalytics_Account");
            string client = SiteManager.Current.DistinctName.ToLowerInvariant().SafeJavascriptStringEncode();
            string userType = (userID > 0) ? "logged" : "browsing";
            string lang = MultilingualMgr.GetCurrentCulture().SafeJavascriptStringEncode();

            StringBuilder script = new StringBuilder();
            script.AppendLine(@"
(function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
(i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
})(window,document,'script','//www.google-analytics.com/analytics.js','__em_ua');");

            script.Append(@"__em_ua('create', 'UA-36030462-1', 'auto', {'name': 'global'");
            if (userID > 0)
                script.AppendFormat(", 'userId' : '{0}'", userID);
            script.AppendLine("}); ");

            script.AppendFormat(CultureInfo.InvariantCulture, @"
__em_ua('global.set', 'appName', 'GamMatrix CMS');
__em_ua('global.send', 'pageview', {{
	'dimension1':  '{0}',
	'dimension2':  '{1}',
	'dimension3':  '{2}',
	'dimension4':  '{3}'
}});"
                , client
                , userType
                , product.SafeJavascriptStringEncode()
                , lang
                );
            //Support Display Advertising
            script.AppendLine("__em_ua('require', 'displayfeatures');");

            if (!string.IsNullOrEmpty(accountCode))
            {
                script.AppendFormat(@"__em_ua('create', '{0}', 'auto', {{'name': 'local'", accountCode.SafeJavascriptStringEncode());
                if (userID > 0)
                    script.AppendFormat(", 'userId' : '{0}'", userID);
                script.AppendLine("}); ");

                script.AppendFormat(CultureInfo.InvariantCulture, @"
__em_ua('local.set', 'appName', 'GamMatrix CMS');
__em_ua('local.send', 'pageview', {{
	'dimension1':  '{0}',
	'dimension2':  '{1}',
	'dimension3':  '{2}',
	'dimension4':  '{3}'
}});"
                    , client
                    , userType
                    , product.SafeJavascriptStringEncode()
                    , lang
                    );
            }

            context.Response.ClearHeaders();
            context.Response.ContentType =  "text/javascript";
            context.Response.AddHeader("Content-Length", script.Length.ToString());
            context.Response.Write(script.ToString());

        }

    }
   
}
