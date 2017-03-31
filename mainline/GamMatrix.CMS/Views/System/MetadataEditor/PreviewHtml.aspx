<%@ Page Title="Preview HTML" Language="C#" MasterPageFile="~/Views/System/Content.master" Inherits="CM.Web.ViewPageEx<CM.Content.ContentNode>"%>
<%@ Import Namespace="CM.Content" %>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
<style type="text/css">
<!--
html, body { background-image:none !important; background-color:#EFEFEF !important; }
-->
</style>
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<%= this.ViewData["Html"] as string %>
</asp:Content>

