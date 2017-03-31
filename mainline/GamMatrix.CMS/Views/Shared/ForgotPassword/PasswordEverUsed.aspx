<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div id="forgot-pwd-wrapper" class="content-wrapper">
<%: Html.H1(this.GetMetadata(".HEAD_TEXT")) %>

<ui:Panel runat="server" ID="pnForgotPwd">
    <center>
        <br />
        <%: Html.ErrorMessage( this.GetMetadata(".Message") ) %>
    </center>
    <center>
    <%: Html.Button(this.GetMetadata(".Button_Back"), new { @id = "btnChangePasswordBack", @type = "button" })%>
    </center>
</ui:Panel>

</div>
<script type="text/javascript">
    $(function () {
        $('#btnChangePasswordBack').click(function () {
            window.history.back();
        });
    });
</script>
</asp:Content>

