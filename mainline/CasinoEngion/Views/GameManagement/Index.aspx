<%@ Page Title="" Language="C#" MasterPageFile="~/Views/Shared/Default.Master" Inherits="System.Web.Mvc.ViewPage<dynamic>" %>
<%@ Import Namespace="CE.db" %>
<%@ Import Namespace="CE.db.Accessor" %>
<%@ Import Namespace="GamMatrixAPI" %>
<script language="C#" type="text/C#" runat="server">

    private VendorID [] GetVendors()
    {
        DomainConfigAccessor dca = DomainConfigAccessor.CreateInstance<DomainConfigAccessor>();
        var domain = dca.GetByDomainID(DomainManager.CurrentDomainID);
        if (domain != null && DomainManager.CurrentDomainID != Constant.SystemDomainID)
        {
            CasinoVendorAccessor cva = CasinoVendorAccessor.CreateInstance<CasinoVendorAccessor>();
            return cva.GetEnabledVendors(DomainManager.CurrentDomainID).OrderBy(v => v.ToString()).ToArray();
        }
        return GlobalConstant.AllVendors.OrderBy(v => v.ToString()).ToArray();
    }

    private SelectList GetReportCategoryList()
    {
        DataDictionaryAccessor dda = DataDictionaryAccessor.CreateInstance<DataDictionaryAccessor>();
        Dictionary<string, string> categories = dda.GetAllReportCategory();
        categories.Add(string.Empty, "< All >");
        
        var orderedItems = categories.OrderBy(x => x.Key);

        return new SelectList(orderedItems, "Key", "Value", string.Empty);
    }

    private SelectList GetInvoicingGroupList()
    {
        DataDictionaryAccessor dda = DataDictionaryAccessor.CreateInstance<DataDictionaryAccessor>();
        Dictionary<string, string> groups = dda.GetAllInvoicingGroup();
        groups.Add(string.Empty, "< All >");

        var orderedItems = groups.OrderBy(x => x.Key);

        return new SelectList(orderedItems, "Key", "Value", string.Empty);
    }

    private SelectList GetClientTypeList()
    {
        DataDictionaryAccessor dda = DataDictionaryAccessor.CreateInstance<DataDictionaryAccessor>();
        Dictionary<string, string> types = dda.GetAllClientType();
        types.Add(string.Empty, "< All >");

        var orderedItems = types.OrderBy(x => x.Key);

        return new SelectList(orderedItems, "Key", "Value", string.Empty);
    }

    private SelectList GetAvailabilityList()
    {
        Dictionary<string, string> types = new Dictionary<string, string>();
        types.Add(string.Empty, "< All >");
        types.Add("1", "Enabled");
        types.Add("0", "Disabled");
        return new SelectList(types, "Key", "Value", string.Empty);
    }

    private SelectList GetLicenseList()
    {
        Dictionary<string, string> types = new Dictionary<string, string>();
        types.Add(string.Empty, "< All >");
        string[] names = Enum.GetNames(typeof(LicenseType));
        foreach (string name in names)
        {
            types.Add(name, name);
        }

        var orderedItems = types.OrderBy(x => x.Key);

        return new SelectList(orderedItems, "Key", "Value", string.Empty);
    }

    private SelectList GetOpVisibleList()
    {
        Dictionary<string, string> types = new Dictionary<string, string>();
        types.Add(string.Empty, "< All >");
        types.Add("1", "Visible");
        types.Add("0", "Invisible");
        return new SelectList(types, "Key", "Value", string.Empty);
    }

    private SelectList GetExcludeFromBonusesList()
    {
        Dictionary<string, string> types = new Dictionary<string, string>();
        types.Add(string.Empty, "< All >");
        types.Add("1", "Yes");
        types.Add("0", "No");
        return new SelectList(types, "Key", "Value", string.Empty);
    }
</script>

<asp:Content ContentPlaceHolderID="phMain" runat="server">

<style type="text/css" media="all">
.ul-vendors { list-style-type:none; margin:0px; padding:0px; }
.ul-categories { list-style-type:none; margin:0px; padding:0px; }
.filter_textbox { padding:1px 2px 1px 2px; font-size:14px; border:solid 1px #2C5E0D; color:#2C5E0D; width:200px; }
.fieldset { display:inline-block; border:solid 1px #666; }
.thumbnail img { width:120px; height:70px; border:solid 1px #000; }
.form_table { width:100%; }
.form_table td { border:dotted 1px #DDD; padding:10px; vertical-align:top; }
.filter_ddl { width:160px; padding:0; font-size:14px; border:solid 1px #2C5E0D; color:#2C5E0D; }
.ddl_with_textbox_size { width:205px; }
.table-vendors td { padding:5px; }
.form_table .ul-vendors { min-width: 135px; }
.form_table tr td div { height:270px; }
.pagination_button { cursor:pointer; width:20px; line-height:20px; height:20px; text-decoration:none; display:inline-block; overflow:hidden; text-align:center; vertical-align:middle; color:#B8EC79; background-color:#111; }
.pagination_current { cursor:default; width:20px; line-height:20px; height:20px; text-decoration:none; display:inline-block; overflow:hidden; text-align:center; vertical-align:middle; color:#111; background-color:#B8EC79; }
#btnExportJson, #btnImportJson { float: left;display: none; }
</style>

<form method="post" action="<%= this.Url.ActionEx("GameList").SafeHtmlEncode() %>" enctype="application/x-www-form-urlencoded"
    target="_blank" id="formSearchGameList">
        <table cellspacing="0" border="0" class="form_table">
            <tr>
                <td style="width:450px">
                    <div style="position:relative; text-align:left">
                        <label id="vendorsLabel"><strong>Vendors</strong></label>
                        <table class="table-vendors"><tr>
                        <td>
                        <ul class="ul-vendors">
                            <%
                                int _loop = 0;
                                foreach (VendorID vendorID in GetVendors())
                                { %>
                                <li>
                                    <input type="checkbox" name="filteredVendorIDs" value="<%=vendorID %>" checked="checked" id="filterVendor<%=vendorID %>" />
                                    <label for="filterVendor<%=vendorID %>"><%=vendorID %></label>
                                </li>
                            <% 
                                    _loop++;
                                    if (_loop == 12)
                                    {
                                        _loop = 0; %> 
                        </ul>
                        </td>
                        <td>
                        <ul class="ul-vendors">

                                 <% }
                                } %>
                        </ul>
                        </td>
                        </tr></table>
                        <span style="position:absolute; bottom:-5px; left:5px; text-align:center">Select <a href="#all">All</a> / <a href="#none">None</a></span>
                    </div>
                </td>
                <td style="width:130px">
                    <div style="position:relative; text-align:left">
                        <label><strong>Categories</strong></label>
                        <ul class="ul-categories">
                        
                            <%
                                DataDictionaryAccessor dda = DataDictionaryAccessor.CreateInstance<DataDictionaryAccessor>();
                                Dictionary<string, string> categories = dda.GetAllGameCategory();
                                foreach (KeyValuePair<string, string> category in categories)
                                { %>
                                <li>
                                    <input type="checkbox" name="filteredCategories" value="<%=category.Key.SafeHtmlEncode() %>" checked="checked" id="filterCategory<%=category.Key.SafeHtmlEncode() %>" />
                                    <label for="filterCategory<%=category.Key.SafeHtmlEncode() %>"><%=category.Value.SafeHtmlEncode() %></label>
                                </li>
                            <% } %>

                            <li>
                                <input type="checkbox" name="filteredCategories" value="Uncategorized" checked="checked" id="filterCategory_Uncategorized" />
                                <label for="filterCategory_Uncategorized"><b>* Uncategorized </b></label>
                            </li>
                        </ul>

                        <span style="position:absolute; bottom:-5px; left:5px; text-align:center">Select <a href="#all">All</a> / <a href="#none">None</a></span>
                    </div>
                </td>
                <td style="width:170px">
                    <table class="ddl_filters_list">
                        <tr>
                            <td style="border:0; padding:0;">
                                <label><strong>Report Category</strong></label>
                                <%: Html.DropDownList("filteredReportCategory", GetReportCategoryList(), new { @class="filter_ddl"})%>

                                <p>
                                <label><strong>Invoicing Group</strong></label>
                                <%: Html.DropDownList("filteredInvoicingGroup", GetInvoicingGroupList(), new { @class = "filter_ddl" })%>
                                </p>

                                <p>
                                <label><strong>Client Type</strong></label>
                                <%: Html.DropDownList("filteredClientType", GetClientTypeList(), new { @class = "filter_ddl" })%>
                                </p>

                                <p>
                                <label><strong>Availability</strong></label>
                                <%: Html.DropDownList("filteredAvailability", GetAvailabilityList(), new { @class = "filter_ddl" })%>
                                </p>

                                <p>
                                <label><strong>License</strong></label>
                                <%: Html.DropDownList("filteredLicense", GetLicenseList(), new { @class = "filter_ddl" })%>
                                </p>

                                <p>
                                <label><strong>Exclude from Bonuses</strong></label>
                                <%: Html.DropDownList("filteredExcludeFromBonuses", GetExcludeFromBonusesList(), new { @class = "filter_ddl" })%>
                                </p>
                            </td>
                        </tr>
                    </table>
                </td>

                <td style="border-right:0;">
                    <%if (CurrentUserSession.UserDomainID == Constant.SystemDomainID) { %>
                    <p>
                        <label><strong>Operator-Visible</strong></label>
                        <br />
                        <%: Html.DropDownList("filteredOpVisible", GetOpVisibleList(), new { @class = "filter_ddl ddl_with_textbox_size" })%>
                    </p>
                    <%} %>
                    
                    <p>
                        <label><strong>Game Name</strong></label>
                        <br />
                        <input type="text" name="filteredGameName" autocomplete="off" class="filter_textbox" />
                    </p>

                    <p>
                        <label><strong>Game Code</strong></label>
                        <br />
                        <input type="text" name="filteredGameCode" autocomplete="off" class="filter_textbox" />
                    </p>

                    <p>
                        <label><strong>Tag</strong></label>
                        <br />
                        <input type="text" name="filteredTag" autocomplete="off" class="filter_textbox" />
                    </p>
                    
                    <p>
                        <label><strong>ID (4 digits)</strong></label>
                        <br />
                        <input type="text" name="filteredID" autocomplete="off" class="filter_textbox" />
                    </p>

                    <p>
                        <label><strong>Slug</strong></label>
                        <br />
                        <input type="text" name="filteredSlug" autocomplete="off" class="filter_textbox" />
                    </p>
                </td>
                <td style="width:200px; vertical-align:bottom; text-align:right; border-left:0px;">
                    Max
                    <select name="pageSize">
                        <option value="50" selected="selected">50</option>
                        <option value="100">100</option>
                        <option value="200">200</option>
                        <option value="500">500</option>
                    </select>
                    records per page.
                </td>
            </tr>
            <tr>
                <td colspan="5" align="right">
                    <% if (DomainManager.CurrentDomainID == Constant.SystemDomainID)
                       { %>
                    <button type="button" id="btnExportJson">Export Selected Vendors Game List Json</button>
                    <button type="button" id="btnImportJson">Import Game List Json</button>

                    <% if(DomainManager.AllowEdit()) { %>
                    <button type="button" id="btnRegister">Register New Game</button>
                    <% } %>

                    <% } %>

                    <% if(DomainManager.AllowEdit()) { %>
                    <button type="button" id="btnNotifyChanges">Notify Changes</button>
                    <% } %>
                    <button type="submit" id="btnFilter">Search</button>
                    
                </td>
            </tr>
        </table>

</form> 
<hr />




<div id="dlgEditGameProperty" title="Edit Game Property" style="display:none">
</div>

<div id="dlgGameRegistration" title="Game Information" style="display:none">
</div>

<div id="dlgGameHistory" title="Game History" style="display:none">
</div>

<div id="game-list-wrapper"></div>


<script type="text/javascript">
    $(function () {
        $('#btnFilter').button({
            icons: {
                primary: "ui-icon-search"
            }
        }).click(function (e) {
            e.preventDefault();
            var options = {
                dataType: 'html',
                success: function (html) {
                    $('#game-list-wrapper').html(html);
                }
            };
            $('#game-list-wrapper').html('<img src="/images/loading.icon.gif" />');
            $("#formSearchGameList").ajaxSubmit(options);
        });


        $('#btnExportJson').button({
            icons: {
                primary: "ui-icon-circle-arrow-s"
            }
        }).click(function(e) {
            var allVendors = [];
            $('[name="filteredVendorIDs"]:checked').each(function () {
                allVendors.push($(this).val());
            });
            var params = "/?filteredVendorIDs=" + allVendors.join(",");
            var url = '<%= this.Url.ActionEx("GetGamesListJson").SafeJavascriptStringEncode() %>' + params;
            window.location.href = url;
        });

        $('#btnImportJson').button({
            icons: {
                primary: "ui-icon-plusthick"
            }
        }).click(function (e) {
            e.preventDefault();
            $('#dlgGameRegistration').html('<img src="/images/loading.icon.gif" /> Loading...').modal({
                maxWidth: 275,
                maxHeight: 150,
                dataCss: { padding: "0px" }
            });

            var url = '<%= this.Url.ActionEx("UploadGamesJson").SafeJavascriptStringEncode() %>';
            $('#dlgGameRegistration').load(url);
        });

        $('#vendorsLabel').dblclick(function (e) {
            e.preventDefault();
            $('#btnExportJson').toggle();
            $('#btnImportJson').toggle();
        });

        $('#btnRegister').button({
            icons: {
                primary: "ui-icon-plusthick"
            }
        }).click(function (e) {
            e.preventDefault();
            $('#dlgGameRegistration').html('<img src="/images/loading.icon.gif" /> Downloading data from third parties...').modal({
                minWidth: 880,
                minHeight: 630,
                dataCss: { padding: "0px" }
            });

            var url = '<%= this.Url.ActionEx("GameEditorDialog").SafeJavascriptStringEncode() %>';
            $('#dlgGameRegistration').load(url);
        });

        $('#btnNotifyChanges').button({
            icons: {
                primary: "ui-icon-signal-diag"
            }
        }).click(function (e) {
            e.preventDefault();
            $('#loading').show();
            var url = '<%= this.Url.ActionEx("NotifyChanges").SafeJavascriptStringEncode() %>';
            $.getJSON(url, function (json) {
                $('#loading').hide();
                if (json.success) {
                    alert(json.result);
                }
                else {
                    alert(json.error);
                }
            });
        });


        $('a[href="#all"]').click(function (e) {
            e.preventDefault();
            $(':checkbox', $(this).parent('span').parent()).attr('checked', true);
        });

        $('a[href="#none"]').click(function (e) {
            e.preventDefault();
            $(':checkbox', $(this).parent('span').parent()).attr('checked', false);
        });
    });


</script>


</asp:Content>
