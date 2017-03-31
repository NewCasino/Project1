<%@ Page Language="C#" PageTemplate="/ProfileMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div id="limit-wrapper" class="content-wrapper">
<%: Html.H1(this.GetMetadata(".HEAD_TEXT")) %>
<ui:Panel runat="server" ID="pnLimit">

    <center>
        <br />
        <%: Html.SuccessMessage(this.GetMetadata(".Message")) %>
        <br />
        <%: Html.Button( this.GetMetadata(".Button_Back"), new { @onclick = "self.location = '/Limit'; return false;" }) %>
    </center>

</ui:Panel>

</div>
<% if(!string.IsNullOrWhiteSpace(Request.QueryString["ref"])){ %>
   
<script type="text/javascript">
    $(function () {
        window.setTimeout(window.location.href = '<%=Request.QueryString["ref"].SafeJavascriptStringEncode()%>', 5000);
    });
</script>
<% }%>

</asp:Content>

