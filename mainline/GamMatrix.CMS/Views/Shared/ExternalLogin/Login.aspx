<%@ Page Language="C#" PageTemplate="/RootMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<% if (!Profile.IsAuthenticated){%>
    <%:Html.InformationMessage(this.GetMetadata(".EmailExisted")) %>
    <div class="externallogin-box">
        <% Html.RenderPartial("/Head/LoginPane", this.ViewData.Merge(new { RefreshTarget = "top" })); %>
    </div>
    <script type="text/javascript">
        function OnLoginResponse(json) {
            if (!json.success) {
                $('#login-pane div.login_btn button').toggleLoadingSpin(false);
                alert(json.error);
                return;
            }
            switch (json.result.toLowerCase()) {
                case 'success': 
                    window.opener.location.reload();
                    window.close();
                    return;
                default:
                    $('#login-pane div.login_btn button').toggleLoadingSpin(false);
                    alert(json.error);
                    return;
            }
        }
    </script>
<%} %>
</asp:Content>

