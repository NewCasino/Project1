<%@ Page Language="C#" PageTemplate="/ProfileMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>

<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div id="withdraw-wrapper" class="content-wrapper">

<%: Html.H1(this.GetMetadata(".HEAD_TEXT"))%>
<ui:Panel runat="server" ID="pnWithdraw">

<div id="withdraw-plus-container">
</div>

<% Html.RenderPartial("PaymentMethodList", this.ViewData); %>

</ui:Panel>
</div>


<script language="javascript" type="text/javascript">
    $(document).ready(function () {
        var url = '<%= this.Url.RouteUrl("Withdraw", new { @action = "WithdrawPlus" }).SafeJavascriptStringEncode()  %>';
        $('#withdraw-plus-container').load(url, function () {
            $('#withdraw-plus-container').fadeIn();
        });
    });
</script>

<%  Html.RenderPartial("IndexBodyPlus", this.ViewData ); %>
</asp:Content>

