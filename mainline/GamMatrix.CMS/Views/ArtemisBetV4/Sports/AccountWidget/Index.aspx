<%@ Page Language="C#" PageTemplate="/RootMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
  <base target=_top>
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div id="header">
<% if (!Profile.IsAuthenticated){%>
    <div id="login-box">
      	 <% Html.RenderPartial("/Head/LoginPane", this.ViewData.Merge(new {@RefreshTarget="top"}) ); %>
      	<div class="login-links">
	        <%: Html.CachedPartial("/Head/SignUp", this.ViewData.Merge()) %>
	        <%: Html.CachedPartial("/Head/ForgotPassword", this.ViewData.Merge()) %>
      	</div>
    </div> 
<% }else{ %>
<%--
    <div class="userarea-box TopLinks">
      <%: Html.CachedPartial("/Head/Logout", this.ViewData) %>
      <%: Html.CachedPartial("/Head/RefreshBalance", this.ViewData) %>
      <%: Html.CachedPartial("/Head/Transfer", this.ViewData) %>
      <%: Html.CachedPartial("/Head/Deposit", this.ViewData) %>
      <%: Html.CachedPartial("/Head/Myaccount", this.ViewData) %>
      <% Html.RenderPartial("/Head/Messages", this.ViewData); %>
      <% Html.RenderPartial("/Head/Welcome", this.ViewData); %>

    </div>
    <% Html.RenderPartial("/Messages/MessagesCount", this.ViewData); %> 
--%>
<%} %>
</div>
</asp:Content>

