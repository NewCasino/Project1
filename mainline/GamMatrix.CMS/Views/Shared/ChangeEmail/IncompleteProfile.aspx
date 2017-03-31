﻿<%@ Page Language="C#" PageTemplate="/ProfileMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div id="deposit-wrapper" class="content-wrapper">
<%: Html.H1(this.GetMetadata(".HEAD_TEXT"))%>
<ui:Panel runat="server" ID="pnDeposit">
    <center>
        <br />
        <%: Html.WarningMessage( this.GetMetadata(".Message").HtmlEncodeSpecialCharactors(), true ) %>
    </center>
</ui:Panel>
</div>

<script type="text/javascript">
    $(function () {
        setTimeout(function () {
            self.location = '<%= this.Url.RouteUrl("Profile", new { @action = "Index"}).SafeJavascriptStringEncode() %>';
        }, 5000);
    });
</script>
</asp:Content>
