<%@ Page Language="C#" PageTemplate="/LiveCasino/LiveCasinoMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="GamMatrixAPI" %>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">


<% Html.RenderPartial("XProGamingGames", this.ViewData.Merge()); %>


<div id="livecasino-last-winners-wrapper">

</div>
<script language="javascript" type="text/javascript">
    $(document).ready(function () {
        var url = '<%= this.Url.RouteUrl( "LiveCasinoLobby", new { @action = "LastWinners", @vendorID = VendorID.XProGaming } ).SafeJavascriptStringEncode() %>';
        $('#livecasino-last-winners').load(url);
    });
</script>

</asp:Content>

