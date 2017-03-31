<%@ Page Title="Region and Language" Language="C#" MasterPageFile="~/Views/System/Content.master"
    Inherits="CM.Web.ViewPageEx<GamMatrix.CMS.Controllers.System.RegionLanguageParam>" %>

<asp:Content ID="cphHead" ContentPlaceHolderID="cphHead" runat="Server">
    <link rel="stylesheet" type="text/css" href="<%= Url.Content( "~/App_Themes/AdminConsole/SearchMetadata/Result.css") %>" />
</asp:Content>
<asp:Content ID="cphMain" ContentPlaceHolderID="cphMain" runat="Server">

    <div id="search-metadata-result-wrapper">
        <div class="ui-widget">
            <div style="margin-top: 20px; padding: 0pt 0.7em;" class="ui-state-highlight ui-corner-all">
                <p id="info-wrapper">
                    <img src="/images/icon/loading.gif" align="absmiddle" />
                    Language package now creating ...
                    <br />
                    Please do not close this page .
                </p>
            </div>
        </div>
        <%
            var languages = this.Model.Languages;
            var lang = "";
            foreach (var language in this.Model.Languages)
            {
                lang = ObjectHelper.GetFieldValue(language, "LanguageCode").SafeJavascriptStringEncode();
            }             
            
        %>
        <script>
            $(function () {
                var url = '<%= this.Url.RouteUrl( "RegionLanguage", new { @action = "CreatePackageResult", @distinctName = this.Model.DistinctName , @countryID = lang, @translated = this.Model.Translated }).SafeJavascriptStringEncode() %>';
                $.getJSON(url, function (json) {
                    if (!json.success) {
                        alert(json.error);
                        return;
                    }
                    $("#info-wrapper").html("Click <a href='" + json.data + "'>Here</a> to download .");
                });
            });
        </script>
</asp:Content>
