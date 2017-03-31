<%@ Page Title="" Language="C#" MasterPageFile="~/Views/Shared/Default.Master" Inherits="System.Web.Mvc.ViewPage" %>
<%@ Import Namespace="CE.db.Accessor" %>
<%@ Import Namespace="GamMatrixAPI" %>
<script language="C#" type="text/C#" runat="server">

    private VendorID[] GetLiveCasinoVendors()
    {
        DomainConfigAccessor dca = DomainConfigAccessor.CreateInstance<DomainConfigAccessor>();
        var domain = dca.GetByDomainID(DomainManager.CurrentDomainID);
        if (domain != null && DomainManager.CurrentDomainID != Constant.SystemDomainID)
        {
            CasinoVendorAccessor cva = CasinoVendorAccessor.CreateInstance<CasinoVendorAccessor>();
            return cva.GetLiveCasinoVendors(DomainManager.CurrentDomainID).OrderBy(v => v.ToString()).ToArray();
        }
        return GlobalConstant.AllLiveCasinoVendors.OrderBy(v => v.ToString()).ToArray();
    }

    private SelectList GetClientTypeList()
    {
        DataDictionaryAccessor dda = DataDictionaryAccessor.CreateInstance<DataDictionaryAccessor>();
        Dictionary<string, string> types = dda.GetAllClientType();
        types.Add(string.Empty, "< All >");

        var orderedItems = types.OrderBy(x => x.Key);

        return new SelectList(orderedItems, "Key", "Value", string.Empty);
    }

    private SelectList GetTableTypeList()
    { 
        Dictionary<string, string> types = new Dictionary<string,string>();
        types.Add("","All");
        types.Add("VIPTable","VIP Table");
        types.Add("NewTable","New Table");
        types.Add("TurkishTable","Turkish Table");
        types.Add("BetBehindAvailable", "Bet Behind Table");
        types.Add("ExcludeFromRandomLaunch", "Random Launch Excluded Table");
        types.Add("SeatsUnlimited", "Seats Unlimited Table");

        var orderedItems = types.OrderBy(x => x.Key);

        return new SelectList(orderedItems, "Key", "Value", string.Empty);
    }

    private SelectList GetOpeningHourList()
    {
        Dictionary<string, string> dic = new Dictionary<string, string>();
        dic.Add("", "All");
        dic.Add("24x7", "24/7");
        dic.Add("non24x7", "non 24/7");

        return new SelectList(dic, "Key", "Value", string.Empty);
    }
</script>

<asp:Content ContentPlaceHolderID="phMain" runat="server">

<style type="text/css" media="all">
.game_list_bottom {position: fixed;bottom: 0;width: 100%;background: #fff;margin: 0;padding: 10px 0;}
.form_table { width:100%; }
.form_table td { border:dotted 1px #DDD; padding:10px; vertical-align:top; }
.filter_textbox, .filter_ddl { padding:1px 2px 1px 2px; font-size:14px; border:solid 1px #2C5E0D; color:#2C5E0D; width:200px; }
.filter_ddl{ width:206px;}
.fieldset { display:inline-block; border:solid 1px #666; }
.ul-vendors { list-style-type:none; margin:0px; padding:0px; }
.pagination_button { cursor:pointer; width:20px; line-height:20px; height:20px; text-decoration:none; display:inline-block; overflow:hidden; text-align:center; vertical-align:middle; color:#B8EC79; background-color:#111; }
.pagination_current { cursor:default; width:20px; line-height:20px; height:20px; text-decoration:none; display:inline-block; overflow:hidden; text-align:center; vertical-align:middle; color:#111; background-color:#B8EC79; }
</style>


<form method="post" action="<%= this.Url.ActionEx("TableList").SafeHtmlEncode() %>" enctype="application/x-www-form-urlencoded"
    target="_blank" id="formSearchTableList">
        <table cellspacing="0" border="0" class="form_table">
            <tr>
                <td style="width:170px" valign="top">
                    <div style="position:relative; text-align:left; padding-bottom:25px;">
                        <label><strong>Vendors</strong></label>
                        <ul class="ul-vendors">
                            <% foreach (VendorID vendorID in GetLiveCasinoVendors())
                                { %>
                                <li>
                                    <input type="checkbox" name="filteredVendorIDs" value="<%=vendorID %>" checked="checked" id="filterVendor<%=vendorID %>" />
                                    <label for="filterVendor<%=vendorID %>"><%=vendorID %></label>
                                </li>
                            <% } %>
                        </ul>
                    
                        <span style="position:absolute; bottom:0; text-align:center">Select <a href="#all">All</a> / <a href="#none">None</a></span>
                    </div>
                </td>
                
                <td style="width:130px">
                    <div style="position:relative; height:250px; text-align:left">
                        <label><strong>Categories</strong></label>
                        <ul class="ul-categories">
                        
                            <%
                                DataDictionaryAccessor dda = DataDictionaryAccessor.CreateInstance<DataDictionaryAccessor>();
                                Dictionary<string, string> categories = dda.GetAllLiveCasinoCategory();
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

                        <span style="position:absolute; bottom:0; text-align:center">Select <a href="#all">All</a> / <a href="#none">None</a></span>
                    </div>
                </td>

                <td style="border-right:0px;">
                    <label><strong>Client Type</strong></label>
                    <br />
                    <%: Html.DropDownList("filteredClientType", GetClientTypeList(), new { @class = "filter_ddl" })%>

                    <p>
                    <label><strong>Table Type</strong></label>
                    <br />
                    <%: Html.DropDownList("filteredTableType", GetTableTypeList(), new { @class = "filter_ddl" })%>
                    </p>
                    <p>
                    <label><strong>Opening Hour</strong></label>
                    <br />
                    <%: Html.DropDownList("filteredOpeningHour", GetOpeningHourList(), new { @class = "filter_ddl" })%>
                    </p>
                    <p>
                    <label><strong>Table Name</strong></label>
                    <br />
                    <input type="text" name="filteredTableName" autocomplete="off" class="filter_textbox" />
                    </p>
                    <p>
                        <label><strong>Game ID (4 digits)</strong></label>
                        <br />
                        <input type="text" name="filteredGameID" autocomplete="off" class="filter_textbox" />
                    </p>

                    <p>
                        <label><strong>Game Slug</strong></label>
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
                <td colspan="4" align="right">
                    <% if (DomainManager.CurrentDomainID == Constant.SystemDomainID)
                       { %>
                    <% if(DomainManager.AllowEdit()) { %>
                    <button type="button" id="btnRegister">Register New Table</button>
                    <% } %>

                    <button type="button" id="btnReloadOriginalFeeds">Reload Original Feeds</button>
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

<div id="table-list-wrapper"></div>

<div id="dlgTableRegistration" style="display:none">
</div>

<div id="dlgEditTableProperty" title="Edit Game Property" style="display:none">
</div>

<script type="text/javascript">
    var ReloadOriginalFeeds = {
        cookieName: "_Reload_Original_Feeds_Cookie",      

        remainSeconds: 0
    };    
    
    ReloadOriginalFeeds.checkCookie = function(){
        var _val = $.cookie(ReloadOriginalFeeds.cookieName);
        if (_val != null)
        {
            var d = new Date();                  
            return parseInt((_val - d.getTime()) / 1000);
        }
        return 0;
    };

    ReloadOriginalFeeds.countDown = function(){
        if(ReloadOriginalFeeds.remainSeconds>1)
        {
            if(ReloadOriginalFeeds.timer)
                window.clearTimeout(ReloadOriginalFeeds.timer);
            ReloadOriginalFeeds.remainSeconds = ReloadOriginalFeeds.remainSeconds - 1;
            var _text = ReloadOriginalFeeds.originalText + ' ( ' + ReloadOriginalFeeds.remainSeconds + 's )';
            ReloadOriginalFeeds.buttonTextHolder.text(_text);
            ReloadOriginalFeeds.timer = window.setTimeout(ReloadOriginalFeeds.countDown,1000);
        }
        else
        {
            ReloadOriginalFeeds.buttonTextHolder.text(ReloadOriginalFeeds.originalText);
            ReloadOriginalFeeds.button.removeAttr('disabled');
        }
    };

    ReloadOriginalFeeds.init = function () {
        ReloadOriginalFeeds.button = $('#btnReloadOriginalFeeds');
        ReloadOriginalFeeds.buttonTextHolder = ReloadOriginalFeeds.button.find('.ui-button-text');
        ReloadOriginalFeeds.originalText = ReloadOriginalFeeds.buttonTextHolder.text();

        ReloadOriginalFeeds.remainSeconds = ReloadOriginalFeeds.checkCookie();
        if (ReloadOriginalFeeds.remainSeconds > 0) {
            ReloadOriginalFeeds.button.attr('disabled', 'disabled').addClass('ui-state-disabled');
            ReloadOriginalFeeds.countDown();
        }
        else {
            ReloadOriginalFeeds.button.removeAttr('disabled');
        }
    };

    ReloadOriginalFeeds.set = function(){
        $.cookie(ReloadOriginalFeeds.cookieName, (new Date()).getTime() + 1000 * 60 * 30);
        ReloadOriginalFeeds.init();
    };


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
                    $('#table-list-wrapper').html(html);
                }
            };
            $('#table-list-wrapper').html('<img src="/images/loading.icon.gif" />');
            $("#formSearchTableList").ajaxSubmit(options);
        });

        


        $('#btnRegister').button({
            icons: {
                primary: "ui-icon-plusthick"
            }
        }).click(function (e) {
            e.preventDefault();
            $('#dlgTableRegistration').html('<img src="/images/loading.icon.gif" /> Loading...').modal({
                minWidth: 500,
                minHeight: 520,
                dataCss: { padding: "0px" }
            });

            var url = '<%= this.Url.ActionEx("RegisterTableDialog").SafeJavascriptStringEncode() %>';
            $('#dlgTableRegistration').load(url);
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


        $('#btnReloadOriginalFeeds').removeAttr('disabled').button({
            icons: {
                primary: "ui-icon-signal-diag"
            }
        }).click(function (e) {
            e.preventDefault();
            $('#loading').show();
            var url = '<%= this.Url.ActionEx("ReloadOriginalFeeds").SafeJavascriptStringEncode() %>';
            $.getJSON(url, function (json) {
                $('#loading').hide();
                if (json.success) {
                    alert(json.result);
                }
                else {
                    alert(json.error);
                }
            });
            ReloadOriginalFeeds.set();
        });

        $('a[href="#all"]').click(function (e) {
            e.preventDefault();
            $(':checkbox', $(this).parent('span').siblings("ul")).attr('checked', true);
        });

        $('a[href="#none"]').click(function (e) {
            e.preventDefault();
            $(':checkbox', $(this).parent('span').siblings("ul")).attr('checked', false);
        });

        

        $(document).on('LIVE_CASINO_TABLE_CHANGED', function () { $('#btnFilter').click(); });

        ReloadOriginalFeeds.init();
    });
</script>

</asp:Content>
