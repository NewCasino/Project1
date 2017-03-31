<%@ Page Language="C#" MasterPageFile="~/Views/System/TopBar.master" Inherits="CM.Web.ViewPageEx< List<CM.db.cmLog> >"%>
<%@ Import Namespace="CM.db" %>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
    <link rel="stylesheet" type="text/css" href="<%= Url.Content("~/js/jquery/jquery.ui/redmond/jquery-ui-1.8.custom.css") %>" />
    <link rel="stylesheet" type="text/css" href="<%= Url.Content( "~/App_Themes/AdminConsole/LogViewer/AccessLog.css") %>" />
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">

<table id="access-log-table" cellpadding="0" cellspacing="0" rules="none" border="0" rules="rows">
    <thead>
        <tr>
            <th class="col-1">Ins</th>
            <th class="col-2">Execution Time</th>
            <th class="col-3">URL</th>
            <th class="col-4">User ID</th>
            <th class="col-5">Session ID</th>
            <th class="col-6">User IP</th>
            <th class="col-7">Operator</th>
            <th class="col-8">Url Referrer & User Agent</th>       
        </tr>
    </thead>
    <tbody>

    <% 
        int index = 0;
       foreach (cmLog log in this.Model)
       {
           
           %>

        <tr class="<%= (++index % 2) == 0 ? "odd" : "" %>" >
            <td class="col-1">
                <%= log.Ins.ToString("HH:mm:ss") %>
            </td>
            <td class="col-2">
                <%= log.ElapsedSeconds.ToString("F2") %> s
                <br />
                (<a href="/LogViewer/Details?ID=<%=log.ID %>" target="_blank">Details...</a>)
            </td>
            <td class="col-3">
                <%= log.HttpMethod %> <%= log.BaseUrl.SafeHtmlEncode()%>
                <br />
                <%= log.PathAndQuery.SafeHtmlEncode()%>
            </td>
            <td class="col-4">
                <%= log.UserID %>
            </td>
            <td class="col-5">
                <%= log.SessionID %>
            </td>
            <td class="col-6">
                <%= log.ServerName %>
            </td>
            <td class="col-7">
                <%= log.OperatorName %>
            </td>
            <td class="col-8">
                <strong>Url Refererer : </strong><%= log.UrlReferrer.SafeHtmlEncode() %>
                <br />
                <strong>User Agent : </strong><%= log.Data.SafeHtmlEncode() %>
            </td>
        </tr>

   <% } %>
    </tbody>
</table>



</asp:Content>

