<%@ Page Title="History Viewer" Language="C#" MasterPageFile="~/Views/System/Content.master" Inherits="CM.Web.ViewPageEx"%>
<%@ Import Namespace="CM.Content" %>
<%@ Import Namespace="GamMatrix.CMS.Controllers.System" %>
<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
    <link rel="stylesheet" type="text/css" href="<%= Url.Content( "~/App_Themes/AdminConsole/HistoryViewer/Index.css") %>" />
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div style="padding:10px;">
    Error, invalid parameter [relativePath] (the path can't be found).
</div>
</asp:Content>



