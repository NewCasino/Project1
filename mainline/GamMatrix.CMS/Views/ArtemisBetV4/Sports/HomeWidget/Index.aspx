<%@ Page Language="C#" PageTemplate="/RootMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
  <base target=_top>
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<% Html.RenderPartial("/Head/PopUp", this.ViewData.Merge(new { })); %>
<div class="HomeWidget">
            <% if (!Profile.IsAuthenticated) {
                Html.RenderPartial("/QuickRegister/RegisterWidget");
            } else { 
                Html.RenderPartial("/Home/DepositWidget");
            } %>
        </div>
<script type="text/javascript">
    $(function () {
        $("body").addClass("iframe-HomeWidget");
    });
</script>
</asp:Content>