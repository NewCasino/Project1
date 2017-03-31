<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<%@ Import Namespace="CM.db" %>



<table id="table-route" class="table-list" cellpadding="0" cellspacing="0" rules="none" border="0" rules="rows">
    <thead>
        <tr>
            <th class="col-route-name">Route name</th>
            <th class="col-route-url">Url</th>
        </tr>
    </thead>
    <tbody>   
        
<%
    int index = 0;
    cmSite site = SiteManager.GetSiteByDistinctName(this.ViewData["distinctName"] as string);
    RouteCollection coll = site.GetRouteCollection();
    if (coll != null)
    {
        foreach (Route route in coll)
        {
            string routeName = route.DataTokens["RouteName"] as string;
            string routeUrl = route.Url;
    %>
        <tr class="<%= (index++)%2 == 0 ? "alternate" : "" %>">
            <td class="col-route-name"><%= routeName.SafeHtmlEncode()%></td>
            <td class="col-route-url"><%= routeUrl.SafeHtmlEncode()%></td>
        </tr>   
    <%  }
    }%>
    </tbody>
</table>

<ui:ExternalJavascriptControl runat="server" AutoDisableInPostbackRequest="true">
<script language="javascript" type="text/javascript">

</script>
</ui:ExternalJavascriptControl>
