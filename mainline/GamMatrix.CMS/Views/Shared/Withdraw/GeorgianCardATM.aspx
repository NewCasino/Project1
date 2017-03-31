<%@ Page Language="C#" PageTemplate="/ProfileMaster.master" Inherits="CM.Web.ViewPageEx<Finance.PaymentMethod>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">

</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">


<div id="withdraw-wrapper" class="content-wrapper">
<%: Html.H1(this.GetMetadata(".HEAD_TEXT"))%>
<ui:Panel runat="server" ID="pnWithdraw">


<% Html.RenderPartial("PaymentMethodDesc", this.Model); %>



<div class="withdraw_steps">
    <div id="atm-code-container">
    </div>
    
    <div id="error_step" style="display:none">
        <center>
        <br /><br /><br />
        <%: Html.ErrorMessage("Internal Error.", false, new { id="withdraw_error" })%>
        <br /><br /><br />
        <%: Html.Button(this.GetMetadata(".Button_Back"), new { @onclick = "returnPreviousWithdrawStep(); return false;" })%>
        </center>
    </div>
</div>

</ui:Panel>
</div>




<script type="text/javascript">
//<![CDATA[
    var __GeorgianCardATMCodeList_pageIndex = 0;
    function loadGeorgianCardATMCodeList(offset, callback) {
        switch (offset) {
            case 1: __GeorgianCardATMCodeList_pageIndex += 1; break;
            case -1: __GeorgianCardATMCodeList_pageIndex -= 1; break;
            case 0: break;
            default: __GeorgianCardATMCodeList_pageIndex = 0; break;
        }

        var url = '<%= this.Url.RouteUrl("Withdraw", new { @action = "GeorgianCardATMCodeList" }).SafeJavascriptStringEncode() %>';
        $('#atm-code-container').load(url, { pageIndex : __GeorgianCardATMCodeList_pageIndex }, callback);
    }
    $(function () {
        loadGeorgianCardATMCodeList(0);
    });
//]]>
</script>


</asp:Content>

