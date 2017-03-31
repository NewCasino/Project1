<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<h2 class="WidgetTitle SportsTitle"><%= this.GetMetadata(".Title") %></h2>
<p class="WidgetDescription SportsDescription"><%= this.GetMetadata(".Description") %></p>
<ul id="SportsWidgetList" class="SportsWidgetList">
<% 
    string[] table1paths = Metadata.GetChildrenPaths("/Metadata/Widgets/Home/Sports/");
    string Image, Link, TextV;
    for (int i = 0; i < table1paths.Length; i++) {
        Image = Metadata.Get(string.Format("{0}.Image", table1paths[i])).DefaultIfNullOrEmpty(" ");
        Link = Metadata.Get(string.Format("{0}.Link", table1paths[i])).DefaultIfNullOrEmpty(" ");
        TextV = Metadata.Get(string.Format("{0}.Text", table1paths[i])).DefaultIfNullOrEmpty(" ");
%>
    <li class="SportsWidget_item Widget_item">
        <a href="<%=Link%>">
            <!-- <img class="SpImg" src="<%=Image%>" width="350" height="160" alt="<%=TextV%>" />                       this has been removed because is not needed on the new homepage-->
            <span><%=TextV%></span>
        </a>
    </li>
<% } %>
</ul>

<!--
<a href="<%= this.GetMetadata(".MoreLink") %>" class="ShowMore"><%= this.GetMetadata(".MoreText") %></a>                      this has been removed because is not needed on the new homepage-->
