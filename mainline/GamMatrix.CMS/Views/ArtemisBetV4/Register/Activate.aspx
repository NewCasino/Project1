<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">

<div id="register-wrapper" class="content-wrapper activateRegister">
<%: Html.H1(this.GetMetadata(".Head_Text")) %>
<ui:Panel runat="server" ID="pnRegister">
<% Html.RenderPartial(this.ViewData["PartialView"] as string, this.ViewData); %>


</ui:Panel>

</div>

<ui:MinifiedJavascriptControl runat="server">
<script type="text/javascript">
//jQuery('body').addClass('ProfilePage');
</script>
</ui:MinifiedJavascriptControl>

</asp:Content>

