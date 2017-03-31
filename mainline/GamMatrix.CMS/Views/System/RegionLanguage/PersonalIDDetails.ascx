<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<CM.Content.ContentNode>" %>
<%@ Import Namespace="CM.Content" %>
<%@ Import Namespace="GamMatrix.CMS.Controllers.System" %>
<link rel="stylesheet" type="text/css" href="<%= Url.Content( "~/App_Themes/AdminConsole/MetadataEditor/Index.css") %>" />

<% Html.RenderPartial("/MetadataEditor/TabMetadata", this.Model, this.ViewData); %>

<script language="javascript" type="text/javascript">

    $(document).ready(function () {
        $("#metadata-links a.create").parent().remove();
        $("#metadata-links ul").find("li:last-child").remove();
        this.tabMetadata = new TabMetadata(this);
    });
</script>