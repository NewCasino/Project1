<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>


<ui:TabbedContent ID="tabbedBingoRooms" runat="server">
    <Tabs>
    <ui:Panel runat="server" ID="tabRealMoney"  Caption="<%$ Metadata:value(.RealMoney) %>" Selected="true">
        <div id="rooms_real" class="rooms_container" data-loadurl="<%= this.Url.RouteUrl( "Bingo", new {@action="Rooms" ,@ScrollBarStyle=this.ViewData["ScrollBarStyle"].ToString().SafeHtmlEncode(),@IsFunMode = false}).SafeHtmlEncode() %>"></div>
    </ui:Panel>

    <ui:Panel runat="server" ID="tabFun"  Caption="<%$ Metadata:value(.FreePlay) %>" >
        <div id="rooms_fun" class="rooms_container" data-loadurl="<%= this.Url.RouteUrl( "Bingo", new {@action="Rooms",@ScrollBarStyle=this.ViewData["ScrollBarStyle"].ToString().SafeHtmlEncode(),@IsFunMode = true }).SafeHtmlEncode() %>"></div>
    </ui:Panel>
    </Tabs>
</ui:TabbedContent>

<script type="text/javascript">
    $(document).ready(function () {

        $("#tabbedBingoRooms").find(".tab").find("a").click(function () {
            var tabID = $(this).parent().attr("forid");
            var container = $("#" + tabID).find(".rooms_container");
            container.load(container.attr("data-loadurl"));
        });

        $("#tabbedBingoRooms").find(".tab:first").find("a").click();
    });
</script>