<%@ Page Language="C#" PageTemplate="/RootMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server"></asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">

    <% if (!string.IsNullOrEmpty(this.ViewData["actionName"].ToString()) && "Index" != this.ViewData["actionName"].ToString()) { %>
        <%=this.GetMetadata("." + this.ViewData["actionName"].ToString() + "_Html")%>
    <%} else{%>
        <div class="SportsBanner">
            <%=this.GetMetadata(".Content")%>
        </div>
    <%}%>
    
    <script type="text/javascript">
        $(document).ready(function(){
            jQuery('body').addClass('iframe-SideBanner');
        });
    </script>

</asp:Content>

