<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<%@ Import Namespace="System.Globalization" %>

<script type="text/C#" runat="server">
    public string GetCode()
    {
        string product = "GamMatrix CMS";
        string accountCode = Metadata.Get("Metadata/Settings.GoogleAnalytics_Account");
        string client = SiteManager.Current.DistinctName.ToLowerInvariant().SafeJavascriptStringEncode();
        string userType = Profile.IsAuthenticated ? "logged" : "browsing";
        string lang = MultilingualMgr.GetCurrentCulture().SafeJavascriptStringEncode();

        StringBuilder script = new StringBuilder();
        script.AppendFormat(CultureInfo.InvariantCulture, @"
var _gaq = _gaq || [];
_gaq.push(['_setAccount', 'UA-36030462-1']);
_gaq.push(['_setCustomVar', 1, 'Client', '{0}']);
_gaq.push(['_setCustomVar', 2, 'User Type', '{1}']);
_gaq.push(['_setCustomVar', 3, 'Product', '{2}']);
_gaq.push(['_setCustomVar', 4, 'Language', '{3}']);
_gaq.push(['_trackPageview']);
_gaq.push(['_trackPageLoadTime']);"
                    , client
                    , userType
                    , product.SafeJavascriptStringEncode()
                    , lang
                    );


        if (!string.IsNullOrEmpty(accountCode))
        {
            script.AppendFormat(CultureInfo.InvariantCulture, @"
_gaq.push(['{0}._setAccount', '{1}']);
_gaq.push(['{0}._setCustomVar', 1, 'Client', '{0}']);
_gaq.push(['{0}._setCustomVar', 2, 'User Type', '{2}']);
_gaq.push(['{0}._setCustomVar', 3, 'Product', '{3}']);
_gaq.push(['{0}._setCustomVar', 4, 'Language', '{4}']);
_gaq.push(['{0}._trackPageview']);
_gaq.push(['{0}._trackPageLoadTime']);"
                        , client
                        , accountCode.SafeJavascriptStringEncode()
                        , userType
                        , product.SafeJavascriptStringEncode()
                        , lang
                        );
        }
        script.Append(@"
(function () {
    var c_protocol = 'https:';
    try{
        c_protocol = document.location.protocol;
    }catch(ex){}
    var ga = document.createElement('script');
    ga.type = 'text/javascript';
    ga.async = true;
    ga.src = ('https:' == c_protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
    var s = document.getElementsByTagName('script')[0];
    s.parentNode.insertBefore(ga, s);
})();");

        return script.ToString();
    }
</script>

<script type="text/javascript">
<%= GetCode() %>
</script>