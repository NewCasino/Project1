<%@ Page Language="C#" MasterPageFile="~/Views/System/TopBar.master" Inherits="CM.Web.ViewPageEx< List<CM.db.cmLog> >"%>
<%@ Import Namespace="CM.db" %>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
    <link rel="stylesheet" type="text/css" href="<%= Url.Content("~/js/jquery/jquery.ui/redmond/jquery-ui-1.8.custom.css") %>" />
    <link rel="stylesheet" type="text/css" href="<%= Url.Content( "~/App_Themes/AdminConsole/LogViewer/Index.css") %>" />
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">


<div id="log-viewer-result">

<% foreach (cmLog log in this.Model)
   { 
       
       %>

<div class="entry log-type-<%= log.LogType.ToString().ToLowerInvariant() %>">
    <div class="head"> 
        <span class="id">[<%= log.ID %>]</span>
        <span class="message"><%= log.Message.SafeHtmlEncode() %></span>
    </div>
    <div class="details">
        <ul>
            <li><strong>Time</strong>=<%= log.Ins.ToString("dd/MM/yyyy HH:mm:ss")%>; </li>
            <li><strong>Source</strong>=<%= log.Source.SafeHtmlEncode() %>; </li>
            <li><strong>IP</strong>=<%= log.IP.SafeHtmlEncode() %>; </li>
            <li><strong>User ID</strong>=<%= log.UserID %>; </li>
            <li><strong>Session ID</strong>=<%= log.SessionID %>; </li>
            <li><strong>Server</strong>=<%= log.ServerName %>; </li>
        </ul>
        <div style="clear:both"></div>
    </div>

    <% if( !string.IsNullOrEmpty(log.StackTrace) )
       { %>

    <div class="links">
        <a href="javascript:void(0)" target="_self">&gt;&gt;&#160;Stack Trace</a>
        <div class="details-wrap" id="<#= item.ID #>">
        <textarea readonly="readonly"><%= log.StackTrace %></textarea>
        </div>
    </div>

    <% } %>
</div>

<% } %>

</div>

</asp:Content>

