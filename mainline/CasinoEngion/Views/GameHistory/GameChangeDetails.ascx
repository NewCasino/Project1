<%@ Control Language="C#" Inherits="System.Web.Mvc.ViewUserControl<List<GameLog>>" %>
<%@ Import Namespace="CE.db.Accessor" %>
<script language="C#" type="text/C#" runat="server">
    private string GetDomainName(long domainID)
    { 
        if(domainID == Constant.SystemDomainID)
            return "All Operator";

        if (DomainManager.GetDomains().Exists(d => d.DomainID == domainID))
        {
            return DomainManager.GetDomains().Find(d => d.DomainID == domainID).Name;
        }
        return "Undefined";
    }

    private string GetDisplayText(GameLog log, bool isFirst = false)
    {
        StringBuilder sb = new StringBuilder();
        
        foreach(string str in log.Changes.Keys)
        {
            switch (str.ToLowerInvariant()) {
                //case "opvisible":
                //    if ((bool)log.Changes[str][1])
                //        sb.AppendLine(@"<li><span class=""operation-type"">Showed</span> game</li>");
                //    else
                //        sb.AppendLine(@"<li><span class=""operation-type"">Hide</span> game.</li>");
                //    break;
                case "enabled":
                    if ((bool)log.Changes[str][1])
                        sb.AppendLine(@"<li><span class=""operation-type"">Enabled</span> game.</li>");
                    else
                        sb.AppendLine(@"<li><span class=""operation-type"">Disabled</span> game.</li>"); 
                    break;
                default:
                    if (log.Changes[str][0] != null && log.Changes[str][1] != null)
                        sb.AppendLine(string.Format(@"<li><span class=""operation-type"">Changed</span> <span class=""field-name"">{0}</span> from <span class=""value-old"">{1}</span> to <span class=""value-new"">{2}</span></li>", str, log.Changes[str][0].ToString().DefaultIfNullOrWhiteSpace("[blank]"), log.Changes[str][1].ToString().DefaultIfNullOrWhiteSpace("[blank]")));
                    else if (log.Changes[str][0] == null && log.Changes[str][1] != null)
                    {
                        if (log.DomainID == Constant.SystemDomainID)
                            sb.AppendLine(string.Format(@"<li><span class=""operation-type"">Changed </span> <span class=""field-name"">{0}</span> to <span class=""value-new"">{1}</span></li>", str, log.Changes[str][1].ToString().DefaultIfNullOrWhiteSpace("[blank]")));
                        else
                            sb.AppendLine(string.Format(@"<li><span class=""operation-type"">Overrode </span> <span class=""field-name"">{0}</span>, the new value is <span class=""value-new"">{1}</span></li>", str, log.Changes[str][1].ToString().DefaultIfNullOrWhiteSpace("[blank]")));
                    }
                    else if (log.Changes[str][0] != null && log.Changes[str][1] == null)
                    {
                        if (log.DomainID == Constant.SystemDomainID)
                            sb.AppendLine(string.Format(@"<li><span class=""operation-type"">Removed </span> the value of <span class=""field-name"">{0}</span></li>", str));
                        else if(!isFirst)
                        {
                            sb.AppendLine(string.Format(@"<li><span class=""operation-type"">Dropped </span> the overriding of <span class=""field-name"">{0}</span></li>", str));
                        }
                    }
                    break;
            }
        }
        return sb.ToString();
    }
</script>

<style type="text/css">
    .table-game-history-gamename
    {
        margin:5px 0;
        white-space:normal;
    }
    .styledTable table.table-game-history-gamename
    {
        white-space: normal;
    }
    .table-game-history-list{ margin-bottom:15px; width:100%; background-color:#FFFFFF; }
    .table-game-history-list th{ padding:5px 0; }
    .table-game-history-list tbody td { padding: 5px 15px 5px 10px; color:#000000; }
        .table-game-history-list tbody tr:nth-child(2n)
        {
            background-color:#ddf9fc;
        }
    .table-game-history-list ul
    {
        margin: 0 0 0 5px; 
        padding: 0 0 0 5px;
    }
    .operation-type
    {
        font-weight:bold;
    }
    .field-name
    {
        color: blue;
        font-weight:bold;
    }
    .value-old
    {
        font-weight:bold;
        color:green;
    }
    .value-new
    {
        font-weight:bold;
        color:red;
    }
</style>
<h1 class="table-game-history-gamename"><%=this.ViewData["GameName"].ToString() %></h1>
<table class="table-game-history-list">
    <thead>
        <tr>
        <th class="ui-state-default">Time</th>
        <th class="ui-state-default">User</th>
        <th class="ui-state-default">Domain</th>
        <th class="ui-state-default">Details</th>        
        </tr>
    </thead>
    <tbody>
        <%foreach (GameLog log in this.Model)
            { %> 
            <tr>
                <td><%=log.Time.ToString("yyyy-MM-dd HH:mm:ss") %></td>
                <td><%=log.Username %> (<%=log.UserID %>)</td>
                <td><%=GetDomainName(log.DomainID) %></td>
                <td>
                    <ul>
                    <%if(log.OperationType == GameLogOperationType.Create){
                          if (log.DomainID == Constant.SystemDomainID) { %>
                        <li><span class="operation-type">Created</span> game.</li>
                        <%} else { %>
                        <%=GetDisplayText(log, true) %>
                        <%}
                    } else {%>
                            <%=GetDisplayText(log) %>
                    <%} %>
                    </ul>
                </td>
            </tr>
        <%} %>
    </tbody>
</table>