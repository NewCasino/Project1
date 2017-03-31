<%@ Page Language="C#" PageTemplate="/Poker/PokerMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">


<div id="everleaf-tournament-list" class="content-wrapper">
<%: Html.H1(this.GetMetadata(".HEAD_TEXT")) %>
<ui:Panel runat="server" ID="pnEverleafPokerTopPayList">

<% this.Html.RenderAction("EverleafPokerTopWinnerList"); %>

<div style=" margin-top:10px;"><a class="button_showyesterday" title="<%= this.GetMetadata(".ViewYesterday").SafeHtmlEncode()%>" href=" javascript:void(0);" onclick="return shownYesterdayData();"></a></div>
<div id="everleaf-topcash-yesterday-containner" data-loaded="0" data-shown="0"></div>
</ui:Panel>
</div>
<script type="text/javascript">
    function shownYesterdayData() {
        var _container = $("#everleaf-topcash-yesterday-containner");
        if (_container.attr("data-loaded") == "0") {
            _container.load('<%= this.Url.RouteUrl( "Poker", new {@action="EverleafPokerTopWinnerList", @feedDays = 1}).SafeJavascriptStringEncode() %>');
            _container.attr("data-loaded", "1");
        }

        var _holdbutton = $(".button_showyesterday");
        if (_container.attr("data-shown") == "0") {
            _holdbutton.addClass("hideState").attr("title","<%= this.GetMetadata(".HideYesterday").SafeHtmlEncode()%>");
            _container.attr("data-shown", "1");
            _container.fadeIn();            
        }
        else {
            _holdbutton.removeClass("hideState").attr("title","<%= this.GetMetadata(".ViewYesterday").SafeHtmlEncode()%>");
            _container.attr("data-shown", "0");
            _container.fadeOut();            
        }
    }
</script>
</asp:Content>

