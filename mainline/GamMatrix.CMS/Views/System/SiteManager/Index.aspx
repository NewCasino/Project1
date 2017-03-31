<%@ Page Title="Content Management" Language="C#" MasterPageFile="~/Views/System/Content.master" Inherits="CM.Web.ViewPageEx<CM.db.cmSite>" %>

<%@ Import Namespace="System.Globalization" %>
<script language="C#" runat="server" type="text/C#">

    private SelectList GetCultureList()
    {
        var list = CultureInfo.GetCultures(CultureTypes.NeutralCultures | CultureTypes.SpecificCultures)
            .Where(r => Regex.IsMatch(r.Name, @"^([a-z]{2}(\-[a-z]{2})?)$", RegexOptions.IgnoreCase | RegexOptions.ECMAScript | RegexOptions.CultureInvariant))
            .OrderBy(r => r.DisplayName)
            .Select(r => new { @Text = string.Format("{0} - [{1}]", r.DisplayName, r.Name.ToLowerInvariant()), @Value = r.Name })
            .ToList();
        return new SelectList(list, "Value", "Text");
    }

    private bool IsCMSSystemAdminUser
    {
        get
        {
            return Profile.IsInRole("CMS System Admin");
        }
    }   
</script>

<asp:Content ContentPlaceHolderID="cphHead" runat="Server">
    <script language="javascript" type="text/javascript" src="<%= Url.Content("~/js/jquery/jquery.ui/jquery-ui-timepicker-addon.min.js") %>"></script>
    <link rel="stylesheet" type="text/css" href="<%= Url.Content("~/js/jquery/jquery.ui/redmond/jquery-ui-1.8.custom.css") %>" />
    <script language="javascript" type="text/javascript" src="<%= Url.Content("~/js/swfobject.js") %>"></script>
    <link rel="stylesheet" type="text/css" href="<%= Url.Content( "~/App_Themes/AdminConsole/SiteManager/Index.css") %>" />
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" runat="Server">
    <div style="padding: 10px;">
        
        <div id="sitemgr-tabs">
            <ul>
                <li><a href="#tabs-1"><%= this.Model.DistinctName.SafeHtmlEncode() %></a></li>
                <li><a href="#tabs-2">Host Name</a></li>
                <li><a href="#tabs-3">Files</a></li>
                <li><a href="#tabs-4">Access Control</a></li>
                <li><a href="#tabs-5">CDN Access Control</a></li>
                <li><a href="#tabs-6">Domain Restrict Control</a></li>
                <li><a href="#tabs-7">Host Mapping</a></li>
                <% if (IsCMSSystemAdminUser)
                   { %>
                <li><a href="#tabs-8">Change Files</a></li>
                <li><a href="#tabs-9">Full Rollback</a></li>
                <% } %>
            </ul>
            <div id="tabs-1">

                <div id="properties-links" class="site-mgr-links">
                    <ul>
                        <li>
                            <a href="<%= this.Url.RouteUrl( "HistoryViewer", new {  
                        @action = "Dialog",
                        @distinctName = this.Model.DistinctName.DefaultEncrypt(),
                        @relativePath = "/.config/site_properties.setting".DefaultEncrypt(),
                        @searchPattner = "",
                        } ).SafeHtmlEncode()  %>"
                                target="_blank" class="history">Change history...</a>
                        </li>
                    </ul>
                </div>

                <hr class="seperator" />

                <div id="success-message" style="width: 450px; display: none;">
                    <% Html.RenderPartial("../Success"); %>
                </div>
                <div id="error-message" style="width: 450px; display: none">
                    <% Html.RenderPartial("../Error"); %>
                </div>
                <br />
                <% using (Html.BeginRouteForm("SiteManager"
               , new { @action = "Save", @distinctName = this.Model.DistinctName.DefaultEncrypt() }
               , FormMethod.Post
               , new { id = "formSite" }
               ))
                   {%>

                <ui:InputField ID="fldDisplayName" runat="server">
                    <labelpart>
                Display name:
                </labelpart>
                    <controlpart>
    <%= Html.TextBoxFor(r => r.DisplayName, new { @id = "txtDisplayName" , @validator = ClientValidators.Create().Required("Please enter the display name.") })%>
                </controlpart>
                </ui:InputField>

                <ui:InputField ID="fldDefaultUrl" runat="server">
                    <labelpart>
                Default page:
                </labelpart>
                    <controlpart>
                <%= Html.TextBoxFor(m => m.DefaultUrl, new { @id = "txtDefaultUrl" })%>
                </controlpart>
                </ui:InputField>

                <ui:InputField ID="fldDefaultTheme" runat="server">
                    <labelpart>
                Theme:
                </labelpart>
                    <controlpart>
                <%= Html.TextBoxFor(m => m.DefaultTheme, new { readOnly = "readOnly" })%>
                </controlpart>
                </ui:InputField>

                <ui:InputField ID="ftdTemplateSite" runat="server">
                    <labelpart>
                Inherit from:
                </labelpart>
                    <controlpart>
                <%= Html.TextBoxFor(m => m.TemplateDomainDistinctName, new { readOnly = "readOnly" })%>
                </controlpart>
                </ui:InputField>

                <ui:InputField ID="fldCulture" runat="server">
                    <labelpart>
                Default language:
                </labelpart>
                    <controlpart>
                <%= Html.DropDownListFor(r => r.DefaultCulture
                    , GetCultureList()
                    , new { id = "ddlCulture" }
                    )%>
                </controlpart>
                </ui:InputField>

                <div class="buttons-wrap">
                    <ui:Button runat="server" ID="btnSubmit"
                        type="submit">
                        Save Changes
                    </ui:Button>
                    <ui:Button runat="server" ID="btnClearCache"
                        type="submit">
                        Clear Metadata Cache
                    </ui:Button>
                </div>
                <% } %>
            </div>

            <div id="tabs-2">
                <% Html.RenderPartial("TabHostname", this.Model); %>
            </div>

            <div id="tabs-3">
                <% Html.RenderPartial("TabFiles", this.Model); %>
            </div>

            <div id="tabs-4">
                <% Html.RenderPartial("TabAccessControl", this.Model); %>
            </div>
            <div id="tabs-5">
                <% Html.RenderPartial("TabCDNAccessControl", this.Model); %>
            </div>
            <div id="tabs-6">
                <% Html.RenderPartial("TabDomainControl", this.Model); %>
            </div>
            <div id="tabs-7">
                <% Html.RenderPartial("TabHostMapping", this.Model); %>
            </div>
            <% if (IsCMSSystemAdminUser)
               { %>
            <div id="tabs-8">
                <% Html.RenderPartial("TabChangeFiles", this.Model); %>
            </div>
            <div id="tabs-9">
                <% Html.RenderPartial("TabFullRollback", this.Model); %>
            </div>
            <% } %>
        </div>
    </div>

    <ui:ExternalJavascriptControl runat="server" AutoDisableInPostbackRequest="true">
        <script language="javascript" type="text/javascript">
            function SiteManager() {
                self.SiteManager = this;
                this.btnSubmit = '#<%=btnSubmit.ClientID %>';

                // init
                this.init = function () {
                    $("#sitemgr-tabs").tabs();

                    this.tabFiles = new TabFiles(this);
                    this.tabHostname = new TabHostname(this);
                    this.tabHostMapping = new TabHostMapping(this);
            <% if (IsCMSSystemAdminUser)
               { %>
                    this.tabChangeFiles = new TabChangeFiles(this);
                    this.tabFullRollback = new TabFullRollback(this);
            <% } %>

                    InputFields.initialize($("#formSite"));

                    $(this.btnSubmit).bind('click', function (e) {
                        e.preventDefault();
                        $('#success-message').hide();
                        $('#error-message').hide();
                        if ($("#formSite").valid()) {
                            if (self.startLoad) self.startLoad();
                            var options = {
                                type: 'POST',
                                dataType: 'json',
                                success: function (json) {
                                    if (self.stopLoad) self.stopLoad();
                                    if (!json.success) { $('#error-message').show(); $('#error-message span.text').text(result.error); return; }
                                    $('#success-message').show();
                                }
                            };
                            $('#formSite').ajaxForm(options);
                            $('#formSite').submit();
                        }
                    });

                    $('#btnClearCache').click(function (e) {
                        e.preventDefault();
                        $('#success-message').hide();
                        $('#error-message').hide();
                        if (self.startLoad) self.startLoad();

                        var url = '<%= this.Url.RouteUrl( "SiteManager", new { @action = "ClearMetadataCache" }).SafeJavascriptStringEncode() %>';
                var data = { distinctName: '<%= this.Model.DistinctName.DefaultEncrypt() %>', now: (new Date()).getTime() };
                jQuery.getJSON(url, data, function (json) {
                    if (self.stopLoad) self.stopLoad();
                    if (!json.success) { alert(result.error); }
                });
            });

                    $('#properties-links a.history').click(function (e) {
                        var wnd = window.open($(this).attr('href'), null, "width=1000,height=700,toolbar=no,location=no,directories=0,status=yes,menubar=no,copyhistory=no");
                        if (wnd) e.preventDefault();
                    });
                };


        this.init();
    }
    new SiteManager();
        </script>
    </ui:ExternalJavascriptControl>



</asp:Content>



