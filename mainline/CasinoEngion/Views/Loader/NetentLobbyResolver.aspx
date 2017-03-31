<%@ Page Language="C#" Inherits="System.Web.Mvc.ViewPage" %>

<%@ Import Namespace="CE.db" %>
<%@ Import Namespace="CE.DomainConfig" %>
<%@ Import Namespace="GmGamingAPI" %>

<script language="C#" type="text/C#" runat="server">

    protected string LobbyLink;
    protected string HistoryLink;
    
    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);

        bool isMobile = CE.Utils.PlatformHandler.IsMobile;
        ceDomainConfigEx domain = (ceDomainConfigEx)ViewData["Domain"];
        LobbyLink = isMobile ? domain.MobileLobbyUrl : domain.LobbyUrl;
        HistoryLink = isMobile ? domain.MobileAccountHistoryUrl : domain.AccountHistoryUrl;
        if (String.IsNullOrWhiteSpace(HistoryLink))
        {
            HistoryLink = LobbyLink;
        }
    }

</script>

<html xmlns="http://www.w3.org/1999/xhtml" lang="en">
<head>
    
    <script type="text/javascript">
        window.onload = function () {

            var hash = window.location.hash;
            if (hash == '#10') { // history
                __redirect('<%=HistoryLink%>');
            } else {
                __redirect('<%=LobbyLink%>');
            }
        };

        function __redirect(url) {
            try {
                self.location.replace(url);
            } catch (e) {
                self.location = url;
            }
        }
    </script>
    

</head>
<body>
</body>
</html>
