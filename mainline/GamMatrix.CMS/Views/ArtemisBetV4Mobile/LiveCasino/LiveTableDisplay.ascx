<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<List<GamMatrix.CMS.Models.MobileShared.LiveCasino.LiveTable>>" %>
<%@ Import Namespace="CasinoEngine" %>

<ol class="TableList IconList Cols-2 Cols-X-2 L Container">
<% foreach (var table in Model)
   {%>
<li class="TableItem Col X <%= table.IsOpen ? "OpenedTable" : "ClosedTable"%><%= table.VisibleOnSmallDevice ? " VisibleOnSmallDevice" : "" %>">
<a class="GameLink TableLink B Container" href="<%= table.IsOpen ? table.LaunchUrl.SafeHtmlEncode() : "#"%>">
<span class="TableThumb">                          
<span class="GTprovider <%= table.VendorID %>">
<span class="GTicon"><%= table.VendorID %></span>
</span>    
<span class="GTStatus">
<span class="GTStatusIcon"></span>
<span class="OptionSpecial"><%= this.GetMetadata(table.IsOpen ? ".Status_Online" : ".Status_Offline").SafeHtmlEncode()%></span>
</span>
<% if (table.HasLimits())
{ %>
<span class="GTLimit">
<%= this.GetMetadata(".Limit_Label").SafeHtmlEncode()%>
<span class="OptionSpecial"><%= table.Limits %></span>
</span>  
<% } %>       
<span class="GTOpeningHours">
<span class="OpeningHoursText"><%= this.GetMetadata(".OpeningHours_Label").SafeHtmlEncode()%></span>
<span class="OptionSpecial"><%= table.OpeningHours.SafeHtmlEncode() %></span>
</span>
<span class="GT" title="<%= table.Name.SafeHtmlEncode() %>" style="background-image:url('<%= table.ThumbnailUrl.SafeHtmlEncode() %>');"></span>
</span> 
<span class="TableName N"><%= table.Name.SafeHtmlEncode() %></span>       
</a>     
</li>   
<% } %>
</ol>