<%@ Page Language="C#" PageTemplate="/RootMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div>
    <%--------------------------
        LOGIN BOX
        --------------------------%>
    <% if (!Profile.IsAuthenticated)
       {

    %>
        <div id="login-box">
            <%: Html.CachedPartial("/Head/SignUp", this.ViewData.Merge()) %>
            <%: Html.CachedPartial("/Head/ForgotPassword", this.ViewData.Merge()) %>
            <% Html.RenderPartial("/ExternalLogin/ExternalPanel", this.ViewData.Merge(new { Associate = false, LoginPanel = true})); %>
            <%: Html.Partial("/Head/LoginPane", this.ViewData.Merge(new { RefreshTarget = "top" }))%>
        </div>   
    <% }
       else
       { %>
        <div class="userarea-box">
             
        
            
            <div class="buttons Container">  
            <%: Html.CachedPartial( "/Head/Logout", this.ViewData) %>
            <%: Html.CachedPartial( "/Head/Withdraw", this.ViewData) %>
            <%: Html.CachedPartial( "/Head/Transfer", this.ViewData) %>
            <%: Html.CachedPartial( "/Head/Deposit", this.ViewData) %>
            <%: Html.CachedPartial( "/Head/MyAccount", this.ViewData) %>
            <%: Html.CachedPartial("/Head/Messages", this.ViewData) %> 
            <% Html.RenderPartial("/Head/Welcome", this.ViewData); %>   
            </div>
        </div>            
        <script type="text/javascript">
            $(document).ready(function () {
                $('.userarea-box a').each(function () {
                    var url = $(this).attr('href');
                    var siteUrl = top.location.href;
                    if (siteUrl.search(url) >= 0) {
                        $(this).parent().addClass('ActiveItem');
                    }
                });
            });
        </script>
    <%} %>
    </div>
</asp:Content>

