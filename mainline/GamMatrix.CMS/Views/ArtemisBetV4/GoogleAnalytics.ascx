<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<%@ Import Namespace="System.Globalization" %>

<script type="text/C#" runat="server">
    public string GetCode()
    {
        //string product = "GamMatrix CMS";

        //string client = SiteManager.Current.DistinctName.ToLowerInvariant().SafeJavascriptStringEncode();
        string userType = Profile.IsAuthenticated ? "logged" : "browsing";
        string lang = MultilingualMgr.GetCurrentCulture().SafeJavascriptStringEncode();

        StringBuilder script = new StringBuilder();

        if ( Profile.IsAuthenticated ) {
            string username = Profile.UserName;
            int userId = Profile.UserID;
            script.AppendFormat(CultureInfo.InvariantCulture, @"
  _gaq.push(['_setCustomVar', 1, 'userId', '{0}', 1]);
  _gaq.push(['_setCustomVar', 2, 'userName', '{1}', 1]);
  console.log('user','{2}');", userId, username, username);
        }

        script.AppendFormat(CultureInfo.InvariantCulture, @"
  _gaq.push(['_setCustomVar', 3, 'Language', '{0}', 1]);", lang);
        script.AppendFormat(CultureInfo.InvariantCulture, @"
  _gaq.push(['_setCustomVar', 4, 'User Type', '{0}', 1]);", userType);

        return script.ToString();
    }

    public string GetUser () {
        StringBuilder script = new StringBuilder();
        if ( Profile.IsAuthenticated ) {
            int userId = Profile.UserID;
            string username = Profile.UserName;
            script.AppendFormat(CultureInfo.InvariantCulture, @", userId: '{0}'", userId);
            script.AppendFormat(CultureInfo.InvariantCulture, @", userName: '{0}'", username);
            return script.ToString();
        } else {
            return "null";
        }
    }

</script>

<script type="text/javascript">

    (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
    (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
    m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
    })(window,document,'script','https://www.google-analytics.com/analytics.js','ga');

/*  var _gaq = _gaq || [];
  _gaq.push(['_setAccount', 'UA-36030462-5']);
  _gaq.push(['_setDomainName', 'artemisbet.com']);
  _gaq.push(['_setAllowLinker', true]);
  _gaq.push(['_trackPageview']);
  console.log('GA working');

<%= GetCode() %>*/

    ga('create', {
        trackingId: 'UA-36030462-5',
        cookieDomain: 'auto'<%= GetUser() %>
    });
    ga('set', 'transport', 'beacon');
    ga('set', {
        'dimension5': 'SiteLanguage',
        'metric5': '<%=(MultilingualMgr.GetCurrentCulture().SafeJavascriptStringEncode()) %>'
    });
    ga('send', 'pageview');
    console.log("Google Analytics working<%= GetUser() %>, SiteLanguage: <%=(MultilingualMgr.GetCurrentCulture().SafeJavascriptStringEncode()) %>");

</script>