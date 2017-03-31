<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<GamMatrix.CMS.Models.MobileShared.Components.InfoContentViewModel>" %>

<% 
    var partialView = this.Model.GetPartialView();
    if (!string.IsNullOrWhiteSpace(partialView))
    {
%>
    <% Html.RenderPartial(partialView, this.Model); %>
<% } %>
<% else %>
<% { %>
    <h2><%= this.Model.GetTitle().SafeHtmlEncode()%></h2>
    <%= this.Model.GetContent().HtmlEncodeSpecialCharactors()%>
<% } %>
