<%@ Page Language="C#" PageTemplate="/Casino/CasinoMaster.master" Inherits="CM.Web.ViewPageEx<CasinoEngine.Game>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="System.Globalization" %> 
<%@ Import Namespace="CM.db" %>
<%@ Import Namespace="CM.db.Accessor" %>
<script type="text/C#" runat="server">   private bool GetAvailablity()
    {
        if (!Profile.IsAuthenticated)
            return false;
        if (!Profile.IsEmailVerified)
        {
            UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
            cmUser user = ua.GetByID(Profile.UserID);
            if (!user.IsEmailVerified)
                return false;
            else if (!Profile.IsEmailVerified)
                Profile.IsEmailVerified = true;
        }

        return true;
    }

</script>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
<title><%= this.Model.Name.SafeHtmlEncode()%></title>
<meta name="keywords" content="<%= string.Join( ",", this.Model.Tags ).SafeHtmlEncode() %>" />
<meta name="description" content="<%= this.Model.Description.SafeHtmlEncode() %>" /> 
<meta http-equiv="pragma" content="no-cache" /> 
<meta http-equiv="cache-control" content="no-store, must-revalidate" /> 
<meta http-equiv="expires" content="Wed, 26 Feb 1997 08:21:57 GMT" /> 

</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">

<div class="CasinoGame">

<div class="MainColumn">
<% Html.RenderPartial("/Casino/Hall/GameOpenerWidget/Game", this.Model, this.ViewData); %>
</div>
<div class="SideColumn">

<div id="incentive-message-container">
</div>

<% Html.RenderPartial("../Lobby/CashRewardsWidget", this.ViewData.Merge(new { @AboutUrl = "/Casino/FPPLearnMore" })); %>

<% Html.RenderPartial("../Lobby/RecentWinnersWidget", this.ViewData.Merge(new { })); %>
</div>
<div class="Zone"></div>

</div>



<script type="text/javascript">
    function _openCasinoGame(slug, real) {
        var isAvailable = <%= GetAvailablity().ToString().ToLowerInvariant() %>;
            if( real && !isAvailable ){ 
                $(document).trigger('OPEN_OPERATION_DIALOG',{'returnUrl':'/Casino/Game/Info/'+ slug});
                return false;
            }
            var url = '/Casino/Game/Info/?gameid=' + slug + '&realMoney=' + (real ? "True" : "False");
            window.location.href = (url );
        }
        $(function () {
            $('#incentive-message-container').load('/Casino/Hall/IncentiveMessage?_=<%= DateTime.Now.Ticks %>'
        , function () {
            $('#incentive-message-container > div').fadeIn();
        });
        var $c = $('div.CasinoGame');
        var pfnResize = function (e) {
            var $iframe = $('iframe', $c);
            var w = parseInt($iframe.data('width'), 10);
            var h = parseInt($iframe.data('height'), 10) * 1.0;
            $iframe.css('width', '100%');
            $iframe.height($iframe.width() * h / w);
        };
        pfnResize(); 
        $('a.BackButton', $c).click(function (e) {
            e.preventDefault();
            self.location = '/Casino/Hall';
        });
    });
</script>
</asp:Content>

