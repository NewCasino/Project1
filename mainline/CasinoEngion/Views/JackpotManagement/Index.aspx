<%@ Page Title="" Language="C#" MasterPageFile="~/Views/Shared/Default.Master" Inherits="System.Web.Mvc.ViewPage<dynamic>" %>
<%@ Import Namespace="CE.db.Accessor" %>
<%@ Import Namespace="GamMatrixAPI" %>

<script type="text/C#" language="C#" runat="Server">
    private VendorID[] GetVendors()
    {
        VendorID[] vendors = GlobalConstant.AllVendors;
        CasinoVendorAccessor cva = CasinoVendorAccessor.CreateInstance<CasinoVendorAccessor>();

        if (DomainManager.CurrentDomainID != Constant.SystemDomainID)
        {
            List<VendorID> enabledVendors = cva.GetEnabledVendors(DomainManager.CurrentDomainID);
            vendors = enabledVendors.ToArray();
        }
        return vendors.OrderBy(v => v.ToString()).ToArray();
    }
</script>

<asp:Content ContentPlaceHolderID="phMain" runat="server">
<style type="text/css" media="all">
    .cont-vendors{float:left;border-right:dotted 1px #DDD;padding:10px;}
    .dotted{border:dotted 1px #DDD;}
    .cont-vendors .ul-vendors:not(:first-child){margin-left:5px;}
    .ul-vendors { list-style-type:none; margin:0px; padding:0px; display:block;float:left;padding:10px; }
    .ul-vendors li { display:block; }
    .cont-search-details{float:left;padding:10px;}
    .cont-buttons{clear:both;text-align: right;padding: 10px;}
    .filter_textbox { padding:1px 2px 1px 2px; font-size:14px; border:solid 1px #2C5E0D; color:#2C5E0D; width:200px; }
    .game_list_bottom {position: fixed;bottom: 0;width: 100%;background: #fff;}
    #pagingContainer ul li.page, #pagingContainer ul li.first, #pagingContainer ul li.last, #pagingContainer ul li.prev, #pagingContainer ul li.next{padding:2px;}
    #pagingContainer ul li.page a, #pagingContainer ul li.first a, #pagingContainer ul li.last a, #pagingContainer ul li.prev a, #pagingContainer ul li.next a { cursor:pointer; width:20px; line-height:20px; height:20px; text-decoration:none; display:inline-block; overflow:hidden; text-align:center; vertical-align:middle; color:#B8EC79; background-color:#111; }
    #pagingContainer ul li.page.active a { cursor:default; width:20px; line-height:20px; height:20px; text-decoration:none; display:inline-block; overflow:hidden; text-align:center; vertical-align:middle; color:#111; background-color:#B8EC79; }
    #pagingContainer ul li.first.disabled a, #pagingContainer ul li.last.disabled a, #pagingContainer ul li.prev.disabled a, #pagingContainer ul li.next.disabled a{background-color:grey;cursor:default;}
</style>

<form method="post" action="<%= this.Url.ActionEx("JackpotList").SafeHtmlEncode() %>" enctype="application/x-www-form-urlencoded"
    target="_blank" id="formSearchJackpot" class="dotted">
    <div class="cont-vendors">
        <label style="display:block;"><strong>Vendors</strong></label>
        <div class="cont-ul-vendors">
            <ul class="ul-vendors dotted">
                <%  var _loop = 0;
                    foreach (VendorID vendorID in GetVendors())
                    { %>
                    <li>
                        <input type="checkbox" name="filteredVendorIDs" value="<%=vendorID %>" checked="checked" id="filterVendor<%=vendorID %>" />
                        <label for="filterVendor<%=vendorID %>"><%=vendorID %></label>
                    </li>
                <% _loop++;
                   
                    if (_loop == 5)
                    {
                        _loop = 0; %>
            </ul>
            <ul class="ul-vendors dotted">
                <% } %>

                <% } %>
            </ul>
        </div>
        <div style="clear:both;">
            <span class="sp-select">Select</span>
            <a href="javascript:void(0);" id="linkSelectAllVendors">All</a>
            <a href="javascript:void(0);" id="linkSelectNoneVendors">None</a>
        </div>
    </div>
    <div class="cont-search-details">
        <label><strong>Game Name</strong></label>
        <input type="text" id="txtSearchGames" class="filter_textbox"/>
    </div>
    <div class="cont-buttons dotted">
        <% if(DomainManager.AllowEdit()) { %>
        <% if (CurrentUserSession.IsSuperUser)
           { %>
        <button id="btnAddJackpot">Add New Jackpot</button>
        <% } %>
        <button type="button" id="btnNotifyChanges">Notify Changes</button>
        <% } %>
        <button id="btnSearchJackpots">Search</button>
    </div>
</form> 
<hr />

<div id="jackpot-list-wrapper"></div>

<div id="dlgJackpotRegistration" title="Jackpot Information" style="display:none">
</div>

<script type="text/javascript" src="<%= Url.Content("~/js/smartSearch.js") %>"></script>
    <script type="text/javascript" src="<%= Url.Content("~/js/jquery.twbsPagination.min.js") %>"></script>
<script type="text/javascript">
    $(function () {
        $('#linkSelectAllVendors').click(function(){
            $('ul.ul-vendors input[type="checkbox"]').attr('checked', 'checked');
        });

        $('#linkSelectNoneVendors').click(function () {
            $('ul.ul-vendors input[type="checkbox"]').removeAttr('checked');
        });

        $('#txtSearchGames').smartSearch({
            items: $("#jackpot-list tbody td.jp-name"),
            getSearchItemText: function (item) {
                return $(item).text();
            },
            updateSearched: function (items, textSearched) {
                $(items).parent().show();
            },
            updateNotSearched: function (items) {
                $(items).parent().hide();
            }
        });

        $('#btnSearchJackpots').button({
            icons: {
                primary: "ui-icon-search"
            }
        }).click(function (e) {
            e.preventDefault();
            var options = {
                dataType: 'html',
                success: function (html) {
                    $('#jackpot-list-wrapper').html(html);
                    $('#txtSearchGames').smartSearch("updateSearchItems", $("#jackpot-list tbody td.jp-name"));
                }
            };
            $('#jackpot-list-wrapper').html('<img src="/images/loading.icon.gif" />');
            $("#formSearchJackpot").ajaxSubmit(options);
        }).trigger('click');

        $('#btnAddJackpot').button({
            icons: {
                primary: "ui-icon-plusthick"
            }
        }).click(function (e) {
            e.preventDefault();
            $('#dlgJackpotRegistration').html('<img src="/images/loading.icon.gif" />').dialog({
                width: 800,
                height: $(document.body).height() - 50,
                modal: true,
                resizable: false
            });

            var url = '<%= this.Url.ActionEx("JackpotEditorDialog").SafeJavascriptStringEncode() %>';
            $('#dlgJackpotRegistration').load(url);
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
    });
</script>

</asp:Content>
