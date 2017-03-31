<%@ Page Title="Preview" Language="C#" MasterPageFile="~/Views/System/Content.master" Inherits="CM.Web.ViewPageEx<CM.Content.ContentNode>"%>
<%@ Import Namespace="CM.Content" %>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
    <link rel="stylesheet" type="text/css" href="<%= Url.Content( "~/App_Themes/AdminConsole/MetadataEditor/Preview.css") %>" />
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div style="padding:10px;">
    <div id="preview-tabs">
	    <ul class="country-flags">
		    <li><a href="#tabs-1">Default</a></li>
            <% foreach (LanguageInfo lang in this.ViewData["Languages"] as LanguageInfo[])
               { %>
               <li><a href="#tabs-<%=lang.LanguageCode.SafeHtmlEncode() %>"><%=lang.DisplayName.SafeHtmlEncode() %>&nbsp;<img class="<%=lang.CountryFlagName.SafeHtmlEncode() %>" /></a></li>
            <% } %>
	    </ul>
        <div id="tabs-1">
        <textarea class="autoheight" readonly="readonly"><%= (this.ViewData["Default"] as string).SafeHtmlEncode() %></textarea> 

        <iframe frameborder="0" class="htmlpreview" src="<%= Url.RouteUrl( "MetadataEditor", new { @action = "PreviewHtml", @distinctName = this.Model.ContentTree.DistinctName.DefaultEncrypt(), @path = this.Model.RelativePath.DefaultEncrypt(), id = Request["id"] }).SafeHtmlEncode() %>">
        </iframe>

        </div>

        <% foreach (LanguageInfo lang in this.ViewData["Languages"] as LanguageInfo[])
            { %>
        <div id="tabs-<%=lang.LanguageCode.SafeHtmlEncode() %>">
        <textarea class="autoheight" readonly="readonly"><%= (this.ViewData[lang.LanguageCode] as string).SafeHtmlEncode()%></textarea>
        <iframe frameborder="0" class="htmlpreview" src="<%= Url.RouteUrl( "MetadataEditor", new { @action = "PreviewHtml", @distinctName = this.Model.ContentTree.DistinctName.DefaultEncrypt(), @path = this.Model.RelativePath.DefaultEncrypt(), id = Request["id"], @lang = lang.LanguageCode }).SafeHtmlEncode() %>">
        </iframe>
        </div>
        <% } %>
    </div>
</div>


<script language="javascript" type="text/javascript">
    $(document).ready(function () {
        $('#preview-tabs').tabs();
        document.title = '<%= (this.ViewData["Title"] as string).SafeJavascriptStringEncode() %>';
    });
</script>

</asp:Content>

