<%@ Page Title="History Viewer" Language="C#" MasterPageFile="~/Views/System/Content.master" Inherits="CM.Web.ViewPageEx<CM.Content.ContentNode>"%>
<%@ Import Namespace="CM.Content" %>
<%@ Import Namespace="GamMatrix.CMS.Controllers.System" %>
<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
    <link rel="stylesheet" type="text/css" href="<%= Url.Content( "~/App_Themes/AdminConsole/HistoryViewer/Index.css") %>" />
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div style="padding:10px;">
    <% Html.RenderPartial("Index", this.Model, this.ViewData); %>
</div>

<script language="javascript" type="text/javascript">
    $(document).ready(function () { (new TabHistory()).load(); });
    document.title = '<%= (this.ViewData["Title"] as string).SafeJavascriptStringEncode() %>';
</script>
</asp:Content>



