<%@ Control Language="C#" Inherits="System.Web.Mvc.ViewUserControl<CE.db.ceDomainConfigEx>" %>
<%@ Import Namespace="System.Globalization" %>
<script type="text/C#" runat="server">
    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);
    }

    private string Language
    {
        get
        {
            return (this.ViewData["Language"] as string).DefaultIfNullOrEmpty("en");
        }
    }

    private bool IsLoggedIn
    {
        get
        {
            if (this.ViewData["IsLoggedIn"] != null)
                return (bool)this.ViewData["IsLoggedIn"];
            return false;
        }
    }


    private string GetGoogleAnalyticsScript()
    {
        StringBuilder script = new StringBuilder();
        script.AppendFormat( CultureInfo.InvariantCulture, @"
var _gaq = _gaq || [];
_gaq.push(['_setAccount', 'UA-36030462-1']);
_gaq.push(['_setCustomVar', 1, 'Client', '{0}']);
_gaq.push(['_setCustomVar', 2, 'User Type', '{1}']);
_gaq.push(['_setCustomVar', 3, 'Product', 'CasinoEngine']);
_gaq.push(['_setCustomVar', 4, 'Language', '{2}']);
_gaq.push(['_trackPageview']);
_gaq.push(['_trackPageLoadTime']);"
            , this.Model.Name.ToLowerInvariant()
            , IsLoggedIn ? "logged" : "browsing"
            , Language.SafeJavascriptStringEncode()
            );

        if (!string.IsNullOrWhiteSpace(this.Model.GoogleAnalyticsAccount))
        {
            script.AppendFormat( CultureInfo.InvariantCulture, @"
_gaq.push(['{0}._setAccount', '{1}']);
_gaq.push(['{0}._setCustomVar', 1, 'Client', '{0}']);
_gaq.push(['{0}._setCustomVar', 2, 'User Type', '{2}']);
_gaq.push(['{0}._setCustomVar', 3, 'Product', 'CasinoEngine']);
_gaq.push(['{0}._setCustomVar', 4, 'Language', '{3}']);
_gaq.push(['{0}._trackPageview']);
_gaq.push(['{0}._trackPageLoadTime']);"
            , this.Model.Name.ToLowerInvariant()
            , this.Model.GoogleAnalyticsAccount.SafeJavascriptStringEncode()
            , IsLoggedIn ? "logged" : "browsing"
            , Language.SafeJavascriptStringEncode()
            );
        }
        
        script.Append(@"
(function () {
    var ga = document.createElement('script');
    ga.type = 'text/javascript';
    ga.async = true;
    ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
    var s = document.getElementsByTagName('script')[0];
    s.parentNode.insertBefore(ga, s);
})();"
            );


        return script.ToString();
    }
</script>


<script type="text/javascript">
<%= GetGoogleAnalyticsScript() %>
</script>