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
            container.load(container.attr("data-loadurl"), function () {
                $('.bingroom-list-jackpot .bingroom-title-jackpot').remove();
                $('.bingroom-list-win .bingroom-title-win').remove();
                $('.bingroom-list-price .bingroom-title-price').remove();
                $('.bingroom-list-num .bingroom-title-num').remove();
                $('.bingroom-list-start .bingroom-title-start').remove();

                $('.bingroom-list-jackpot').prepend($("#" + tabID + ' .bingroom-title .bingroom-title-jackpot').clone());
                $('.bingroom-list-win').prepend($("#" + tabID + ' .bingroom-title .bingroom-title-win').clone());
                $('.bingroom-list-price').prepend($("#" + tabID + ' .bingroom-title .bingroom-title-price').clone());
                $('.bingroom-list-num').prepend($("#" + tabID + ' .bingroom-title .bingroom-title-num').clone());
                $('.bingroom-list-start').prepend($("#" + tabID + ' .bingroom-title .bingroom-title-start').clone());
            });
        });

        $("#tabbedBingoRooms").find(".tab:first").find("a").click();
    });
</script>