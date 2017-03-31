<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="CasinoEngine" %>

<script runat="server">
    private void Page_Load(object sender, System.EventArgs e)
    {
        if (!Profile.IsAuthenticated)
            Response.Redirect("/", true);
        this.ViewData["RealMoney"] = Profile.IsAuthenticated;
        this.ViewData["CurrentPageClass"]="LotteryGame";
    }
</script>



<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div class="LiveCasino-lottery-InlineContainer"></div>
<script type="text/javascript">
    (function () {
        var container = $('.LiveCasino-lottery-InlineContainer');
        if (container != null) {
            var $iframe = $('<iframe>', {
                src: '/LiveCasino/Hall/Start?tableID=' + <%=(this.ViewData["parameter"] as string) %>,
                id: 'LiveCasinoTableFrame',
                frameborder: 0,
                scrolling: 'yes',
            });
            $(container).empty();
            $iframe.appendTo(container);

            var fw = parseInt($iframe.width(), 10);
            var fh = parseInt($iframe.height(), 10) * 1.0;
            var finalHeight = container.width() * fh / fw;

            $iframe.width('100%');
            $iframe.height(finalHeight);
            setTimeout(function(){ $(".lottery-ddl-wraper .gameitem[m='<%=(this.ViewData["parameter"] as string) %>']").addClass("selected");},500);
        }
    })()
</script>
</asp:Content>

