<%@ Page Title="Region and Language" Language="C#" MasterPageFile="~/Views/System/Content.master"
    Inherits="CM.Web.ViewPageEx<GamMatrix.CMS.Controllers.System.RegionLanguageParam>" %>

<%@ Import Namespace="GamMatrix.CMS.Controllers.System" %>

<asp:Content ContentPlaceHolderID="cphHead" runat="Server">
    <link rel="stylesheet" type="text/css" href="<%= Url.Content( "~/App_Themes/AdminConsole/RegionLanguage/Index.css") %>" />
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" runat="Server">

    <div style="padding: 10px;">

        <div id="region-languages-tabs">
            <ul>
                <li><a href="#tabs-1">Languages</a></li>
                <li><a href="#tabs-2" id="tabTranslated">Translated Status</a></li>
                <li><a href="#tabs-3">Countries</a></li>
            </ul>
            <div id="tabs-1">
                <% Html.RenderPartial("TabLanguage", this.Model, this.ViewData); %>
            </div>
            <div id="tabs-2">
            </div>
            <div id="tabs-3">
                <% Html.RenderPartial("TabCountry", this.Model, this.ViewData); %>
            </div>
        </div>


        <ui:ExternalJavascriptControl runat="server" AutoDisableInPostbackRequest="true">
            <script language="javascript" type="text/javascript">
                function RegionLanguage() {
                    self.RegionLanguage = this;
                    $('#region-languages-tabs').tabs();
                    this.init = function () {
                        this.tabLanguage = new TabLanguage(this);
                        this.tabCountry = new TabCountry(this);
                    };

                    this.init();
                }
                var LoadTransList = function () {
                    var dt1 = new Date();
                    $("#tabs-2").html('<img src="//cdn.everymatrix.com/Generic/img/validating.gif" />').load("/RegionLanguage/Status/<%=this.Model.DistinctName.DefaultEncrypt()%>").data("status", "0");
                };
                $("#tabTranslated").click(function () {
                    if (!$(this).data("status")) {
                        LoadTransList();
                        $(this).data("status", "1");
                    }
                });
                $(document).ready(function () { new RegionLanguage(); });
            </script>
        </ui:ExternalJavascriptControl>



    </div>

</asp:Content>



