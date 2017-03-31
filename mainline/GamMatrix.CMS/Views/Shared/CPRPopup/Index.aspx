<%@ Page Language="C#" PageTemplate="/RootMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>

<script runat="server" type="text/C#">
    protected string Username
    {
        get
        {
            if (!string.IsNullOrEmpty(Request.Params["username"]))
                return Request.Params["username"] as string;
            else return string.Empty;
        }
    }
</script>
<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
    <div id="CprAndIntended-popup">
        <% Html.RenderPartial("/Profile/UpdateCPRPopup", this.ViewData.Merge(new { @username = Username })); %>
    </div>
</asp:Content>

