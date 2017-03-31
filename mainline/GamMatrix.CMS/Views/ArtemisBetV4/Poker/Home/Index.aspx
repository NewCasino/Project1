<%@ Page Language="C#" PageTemplate="/Poker/PokerMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%> 
<script runat="server" type="text/C#">
    protected override void OnInit(EventArgs e)
    {
        this.ViewData["MetadataPath"] = "/Metadata/Poker";
        /*if (string.Equals(MultilingualMgr.GetCurrentCulture(),"en", StringComparison.CurrentCultureIgnoreCase))
        {
            Response.Status = "301 Moved Permanently";
            Response.AddHeader("Location", "/Home");
        }*/
    }
</script>
<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">

<link rel="stylesheet" type="text/css" href="//cdn.everymatrix.com/ArtemisBetV3/poker.css" />

</asp:Content>
<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">  
<div class="Breadcrumbs" role="navigation">
        <ul class="BreadMenu Container" role="menu">
            <li class="BreadItem" role="menuitem" itemtype="http://data-vocabulary.org/Breadcrumb" itemscope="itemscope">
                <a class="BreadLink url" href="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/.Url") %>" itemprop="url" title="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/.Title") %>">
                    <span itemprop="title"><%= this.GetMetadata("/Metadata/Breadcrumbs/Home/.Name") %></span>
                </a>
            </li>
            <li class="BreadItem BreadCurrent" role="menuitem" itemtype="http://data-vocabulary.org/Breadcrumb" itemscope="itemscope">
                <a class="BreadLink url" href="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/Poker/.Url") %>" itemprop="url" title="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/ResponsibleGaming/.Title") %>">
                    <span itemprop="title"><%= this.GetMetadata("/Metadata/Breadcrumbs/Home/Poker/.Name") %></span>
                </a>
            </li>
        </ul>
    </div>
<div class="row-fluid">
    <%Html.RenderPartial("Slider"); %>
</div>
<div class="row-fluid PokerCategories">   
    <div class="row-fluid Poker-Bonuses GamesList" id="Poker-Bonuses">
<%--
        <div class="PokerCol Col4 FirstCol" id="Poker-Col-1">
            <div class="Col4-Content">
                <%=this.GetMetadata("/Metadata/Poker/PokerHomeBanners/Banner1.Html").HtmlEncodeSpecialCharactors() %>
            </div>
        </div>                
        <div class="PokerCol Col4 SecondCol" id="Poker-Col-2">
            <div class="Col4-Content">
                <%=this.GetMetadata("/Metadata/Poker/PokerHomeBanners/Banner2.Html").HtmlEncodeSpecialCharactors() %>
            </div>
        </div>         
--%>       
        <div class="PokerCol Col4 thirdCol" id="Poker-Col-3">
            <div class="Col4-Content">
                <%=this.GetMetadata("/Metadata/Poker/PokerHomeBanners/Banner3.Html").HtmlEncodeSpecialCharactors() %>
            </div>
        </div>                
        <div class="PokerCol Col4 last LastCol" id="Poker-Col-4">
            <div class="Col4-Content noaccount">
                <%=this.GetMetadata("/Metadata/Poker/PokerHomeBanners/NoAccount.Html").HtmlEncodeSpecialCharactors() %>
            </div>
            <div class="PokerCol Col4-Content needhelp">
                <%=this.GetMetadata("/Metadata/Poker/PokerHomeBanners/NeedHelp.Html").HtmlEncodeSpecialCharactors() %>
            </div>
        </div> 
    </div>
</div><div class="clear"></div>
<% this.Html.RenderPartial("/Poker/Tournaments/MergePokerTournamentList"); %>
<ui:MinifiedJavascriptControl runat="server" Enabled="true" AppendToPageEnd="true">
    <script type="text/javascript">
        $(function () { 
        $(".Authenticated div.Col4-Content.needhelp").find("a").click(function(){ 
            $("#lpButDivID-1312275796568-0").find("a").click();
            return false;
        });
        $(".Authenticated .ActionZone .pokerbutton").click(function(){window.open("/Poker/Klas/", "<%=this.GetMetadata(".PopWindow_Title").SafeJavascriptStringEncode()%>", "height=600, width=790, top=100, left=100,toolbar=no, menubar=no, scrollbars=no, resizable=no, location=no, status=no");});
        $(".Anonymous .ActionZone .pokerbutton").click(function(){alert('<%=this.GetMetadata(".NoLoginMsg_Txt").SafeJavascriptStringEncode()%>');return false;}); 
        });
        jQuery('body').addClass('PokerPage');
        jQuery('.inner').addClass('PokerContent');
    </script>
</ui:MinifiedJavascriptControl>
</asp:Content>
