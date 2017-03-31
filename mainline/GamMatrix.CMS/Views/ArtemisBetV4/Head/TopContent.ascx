<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<script type="text/C#" runat="server">
    private string MetaPath { get; set; } 
    protected override void OnInit(EventArgs e) {
        this.MetaPath = this.ViewData["MetaPath"] as string;
        base.OnInit(e);
    }
    private string VideoStatus = "No";
</script>

<% if ( string.Equals( this.GetMetadata("/Metadata/Settings/.ArtemisHomePage_HasVideo"), "Yes" ) ) { %>

<div class="topContentMain commonTopContent Hidden">
    <div class="TopContentContainer">
        <a class="Button closeTopContent" href="javascript:void(0)" title="<%= this.GetMetadata(".CloseTitle") %>">
            <span class="ButtonIcon">&times;</span>
            <span class="ButtonText"><%= this.GetMetadata(".Close") %></span>
        </a>
        <ul class="topContentList">
            <% 
                string[] table1paths = Metadata.GetChildrenPaths(MetaPath);
                string HtmlV;
                string HtmlUrl;
                for (int i = 0; i < table1paths.Length; i++) {
                    HtmlV = Metadata.Get(string.Format("{0}.Html", table1paths[i])).DefaultIfNullOrEmpty(" ");
                    HtmlUrl = Metadata.Get(string.Format("{0}.MatchId", table1paths[i])).DefaultIfNullOrEmpty(" ");
            %>
                <li class="topContent_item">
                    <div class="topContent_Container"><%=HtmlV %></div>
                    <a class="Button TopContentBetNow" href="/spor-bahisleri/?matchid=<%=HtmlUrl %>" title="<%= this.GetMetadata(".BetNowTitle") %>"><%= this.GetMetadata(".BetNow") %></a>
                </li>
            <% } %>
        </ul>
    </div>
</div>

<ui:MinifiedJavascriptControl runat="server" AppendToPageEnd="true">
    <script type="text/javascript">
        $(function() {
            if($.cookie("hide_topContent_new") == "1" && !$(document.body).hasClass('HomePage')){
                $(".topContentMain").remove();
            } else{
                //$(".topContentMain").show(500);
            }
            $(".PopUpPage .topContentMain").remove();
            $(".closeTopContent").click(function () {
                $.cookie("hide_topContent_new", "1",{expires:1,path: "/"});
                $(".topContentMain").remove();
            });
            if($(document.body).hasClass('AffLandingPage')){
                //$(".topContentMain.AffVedio").show(500);
            }
        });
        $(window).load(function() {
            $('.PopUpPage .topContentMain').remove();
            try{
                $("iframe",top.document.body).contents().find(".PopUpPage .topContentMain").remove();
            }
            catch (e) {}
        });
    </script>
</ui:MinifiedJavascriptControl>

<% } else { %>

<ui:MinifiedJavascriptControl runat="server" AppendToPageEnd="true">
    <script type="text/javascript">
        $(function() {
            $(".topContentMain").remove();
            try{
                $("iframe",top.document.body).contents().find(".PopUpPage .topContentMain").remove();
            }
            catch (e) {}
            $(".HomeSlideContent").css("visibility","visible");
            $(".HomeSlideContent").parents(".SliderItem").css("background","<%= this.GetMetadata(".HomeNoVideoImage") %>");
        });
    </script>
</ui:MinifiedJavascriptControl>

<% } %>