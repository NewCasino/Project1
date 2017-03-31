<%@ Page Title="Searching..." Language="C#" MasterPageFile="~/Views/System/Content.master" Inherits="CM.Web.ViewPageEx<CM.db.cmSite>"%>

<%@ Import Namespace="GamMatrix.CMS.Controllers.System" %>

<script language="C#" type="text/C#" runat="server">

</script>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
    <link rel="stylesheet" type="text/css" href="<%= Url.Content( "~/App_Themes/AdminConsole/SearchMetadata/Result.css") %>" />
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">

<script id="search-metadata-result-template" type="text/html">
<#
var item=arguments[0];
#>
<div class="result">
    <div class="path"><span><#= item.RelativePath.htmlEncode() #></span>&#160;<a href="<#= item.Url.htmlEncode() #>" target="_blank">Edit...</a></div>
    <div class="html"><#= item.Html #></div>
</div>
</script>

<div id="search-metadata-result-wrapper">

<div class="ui-widget">
	<div style="margin-top: 20px; padding: 0pt 0.7em;" class="ui-state-highlight ui-corner-all"> 
		<p id="info-wrapper">
		<img src="/images/icon/loading.gif" align="absmiddle" /> Searching in code. Please be patient and <strong>DO NOT</strong> refresh this page.
        </p>
	</div>
</div>



</div>

<script language="javascript" type="text/javascript">
    $(function () {
        function loadResult() {
            var url = '<%= this.Url.RouteUrl( "SearchCode", new { @action = "GetResult", @distinctName = this.Model.DistinctName.DefaultEncrypt(), @taskID = this.ViewData["TaskID"] }).SafeJavascriptStringEncode() %>';
            $.getJSON(url, function (json) {
                if (!json.success) {
                    alert(json.error);
                    return;
                }
                for (var i = 0; i < json.results.length; i++) {
                    $($('#search-metadata-result-template').parseTemplate(json.results[i])).appendTo($('#search-metadata-result-wrapper'));
                }
                if (!json.isCompleted)
                    loadResult();
                else {
                    $('#info-wrapper').text('The search is completed!');
                }
            });
        }

        loadResult();
    });
</script>

</asp:Content>



