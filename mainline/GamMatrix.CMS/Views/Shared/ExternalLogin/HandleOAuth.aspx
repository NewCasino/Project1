<%@ Page Language="C#" PageTemplate="/RootMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
<script runat="server">
    public string Status
    {
        get
        {
            if (this.ViewData["status"] != null)
            {
                return this.ViewData["status"].ToString();
            }
            return string.Empty;
        }
    }
</script>
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<% if(string.Compare("1",Status,false)==0) {%>
<script type="text/javascript">
    $(function () {
        $("form").submit();
    });
</script>
<%=this.ViewData["OAuthForm"] %>
<%}%>
</asp:Content>

