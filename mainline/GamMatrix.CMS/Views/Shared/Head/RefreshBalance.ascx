<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>

<% if( Profile.IsAuthenticated )
   { %>
   <div id="refresh-button-wrap">
   <%: Html.LinkButton( " ", new { @class = "refresh-button", @target = "_self", @href = "javascript:try{BalanceList.refresh(false);}catch(e){};void(0);" })%>
   </div>
<% } %>