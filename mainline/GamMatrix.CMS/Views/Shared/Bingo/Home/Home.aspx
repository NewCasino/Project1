<%@ Page Language="C#" PageTemplate="/Bingo/BingoMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div id="bingo-wrapper" class="content-wrapper">
<div class="con-main">
<div class="bingo-rooms-containner"><%Html.RenderPartial("/Bingo/Home/RoomsWidget"); %></div>
</div>
<div class="con-side">
<div></div>
<div class="bingo-jackpots-containner"></div>
<div class="bingo-winners-containner"></div>
</div>
</div>

<script language="javascript" type="text/javascript">
    $(document).ready(function () {        
        $("#bingo-wrapper").find(".bingo-jackpots-containner").load('<%= this.Url.RouteUrl( "Bingo", new {@action="JackpotRotator"}).SafeJavascriptStringEncode() %>');
        $("#bingo-wrapper").find(".bingo-winners-containner").load('<%= this.Url.RouteUrl( "Bingo", new {@action="LastWinners"}).SafeJavascriptStringEncode() %>');
    });
</script>
</asp:Content>


