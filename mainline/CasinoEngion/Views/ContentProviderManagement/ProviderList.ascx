<%@ Control Language="C#" Inherits="System.Web.Mvc.ViewUserControl" %>
<%@ Import Namespace="CE.db" %>
<%@ Import Namespace="CE.db.Accessor" %>


<script type="text/C#" language="C#" runat="Server">

    private string GetLogoImage(ceContentProviderBase provider)
    {
        if (string.IsNullOrWhiteSpace(provider.Logo))
            return "//cdn.everymatrix.com/images/placeholder.png";

        return string.Format("{0}{1}"
            , (ConfigurationManager.AppSettings["ResourceUrl"] ?? "//cdn.everymatrix.com").TrimEnd('/')
            , provider.Logo
            );
    }
</script>

<table id="table-content-providers" cellpadding="0" cellspacing="0">
    <thead>
        <tr>
            <th class="ui-state-default"><input type="checkbox" id="selectall" value="all" /></th>
            <th class="ui-state-default">Internal ID</th>
            <th class="ui-state-default">Content Provider ID</th>
            <th class="ui-state-default">Enabled</th>
            <th class="ui-state-default">Name</th>
            <th class="ui-state-default">Logo</th>
        </tr>
    </thead>
    <tbody>
        <%                 
            List<ceContentProviderBase> providers = ContentProviderAccessor.GetAll(DomainManager.CurrentDomainID, Constant.SystemDomainID);
            int index = 0;
            foreach (ceContentProviderBase provider in providers)
            {  %>
                <tr class="<%= ((index++) % 2 == 0) ? "odd" : "even" %>">
                    <td valign="middle" align="center">
                    <div>
                        <input type="checkbox" class="select_provider" value="<%= provider.ID %>" />
                    </div>
                    </td>
                    <td align="center"><%=provider.ID %></td>
                    <td align="center"><%=provider.Identifying %></td>
                    <td align="center">
                        <%if (provider.Enabled)
                          { %>
                        <img src="/images/yes.png" alt="Enabled" />
                        <%}
                          else
                          {%>
                        <img src="/images/no.png" alt="Disabled" />
                        <%} %>
                    </td>
                    <td align="center"><%=provider.Name %></td>
                    <td align="center" style="cursor:pointer" onclick="editProvider(<%=provider.ID%>)">
                        <img src="<%=GetLogoImage(provider) %>" />
                    </td>
                </tr>
        <%  } %>
            
           
    </tbody>
    <tfoot>
    </tfoot>
</table>

<script type="text/javascript">
    $(function () {
        $("#selectall").click(function (e) {
            $this = $(this);
            if ($this.attr("checked") == "checked")
                $("#table-content-providers input.select_provider").attr("checked", "checked");
            else
                $("#table-content-providers input.select_provider").removeAttr("checked");
        });        
    });
</script>