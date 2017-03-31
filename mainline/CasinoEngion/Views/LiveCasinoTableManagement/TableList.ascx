<%@ Control Language="C#" Inherits="System.Web.Mvc.ViewUserControl<List<CE.db.ceLiveCasinoTableBaseEx>>" %>
<%@ Import Namespace="CE.db" %>
<%@ Import Namespace="CE.db.Accessor" %>
<%@ Import Namespace="GamMatrixAPI" %>
<script language="C#" type="text/C#" runat="server">

    private string GetParameters(ceLiveCasinoTableBaseEx table)
    {
        switch (table.VendorID)
        {
            case VendorID.Microgaming:
                return string.Empty;
                
            case VendorID.XProGaming:
                return string.Format("Limit Set ID : {0}", table.ExtraParameter1);
                
            case VendorID.EvolutionGaming:
                return string.Format("<ul><li><strong>gtype</strong> = {0}</li><li><strong>gif</strong> = {1}</li><li><strong>tid</strong> = {2}</li><li><strong>vtid</strong> = {3}</li></ul>"
                    , table.ExtraParameter1.SafeHtmlEncode()
                    , table.ExtraParameter2.SafeHtmlEncode()
                    , table.ExtraParameter3.SafeHtmlEncode()
                    , table.ExtraParameter4.SafeHtmlEncode()
                    );
                
            default:
                return string.Empty;
        }
    }

    private string GetThumbnailUrl(ceLiveCasinoTableBaseEx table)
    {
        if (string.IsNullOrEmpty(table.Thumbnail))
            return "//cdn.everymatrix.com/images/placeholder.png";
        return string.Format("{0}{1}"
            , (ConfigurationManager.AppSettings["ResourceUrl"] ?? "//cdn.everymatrix.com").TrimEnd('/')
            , table.Thumbnail
            );
    }

    Dictionary<string, string> _categories;
    
    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);
        

        DataDictionaryAccessor dda = DataDictionaryAccessor.CreateInstance<DataDictionaryAccessor>();
        _categories = dda.GetAllLiveCasinoCategory();
    }

    private string GetCategoryText(ceLiveCasinoTableBaseEx table)
    {
        string text;
        if (_categories.TryGetValue(table.Category, out text))
            return text;
        return table.Category.DefaultIfNullOrEmpty("--"); ;
    }

    private string GetOpeningTime(ceLiveCasinoTableBaseEx table)
    {
        if (string.IsNullOrEmpty(table.OpenHoursTimeZone) ||
            table.OpenHoursStart == table.OpenHoursEnd)
        {
            return "24 / 7";
        }

        return string.Format("{0:D2}:{1:D2} - {2:D2}:{3:D2} <br /> {4}"
            , table.OpenHoursStart / 60
            , table.OpenHoursStart % 60
            , table.OpenHoursEnd / 60
            , table.OpenHoursEnd % 60
            , table.OpenHoursTimeZone.SafeHtmlEncode()
            );
    }

    
</script>


<style type="text/css">
    #table-game-list tbody td { font-size:0.85em; }
    #table-game-list .logo { display:block; width:60px; height:60px; }
    #table-game-list .thumbnail { display:block; width:120px; height:70px; }
    #table-game-list .override { color:Red; }
    #table-game-list .override img { border:solid 1px red; }
    #table-game-list tbody tr td:first-child.override > div  { background-color:red; }
    #table-game-list .col-1 { width:40px; }
    #table-game-list .col-2 { width:70px; }
    #table-game-list .col-3 { width:70px; }
    #table-game-list .col-4 { width:100px; }
    #table-game-list .col-5 { width:70px; }
    #table-game-list .col-6 { width:250px; }
    #table-game-list .col-7 { width:170px; }
    #table-game-list .thumbnailImage { max-height:80px }
    #table-game-list .col-9 { text-align:center; }
    #table-game-list .col-10 { text-align:left; }
    #table-game-list .override a { color:Red !important; }
    #table-game-list .override img { border:1px solid red; }
</style>

<% if (DomainManager.CurrentDomainID != Constant.SystemDomainID)
    { %>
<div class="ui-widget">
	<div style="margin-bottom: 10px; padding: 0 .7em;" class="ui-state-highlight ui-corner-all"> 
		<p><span style="float: left; margin-right: .3em;" class="ui-icon ui-icon-info"></span>
		<strong>NOTE!</strong> The overridden attributes, which differ from the default settings, appear in <span style="color:red">red</span> color.</p>
	</div>
</div>
<% } %>

<form id="formPagination" method="post" target="_blank" enctype="application/x-www-form-urlencoded">
    <% 
        VendorID[] filteredVendorIDs = this.ViewData["filteredVendorIDs"] as VendorID[];
        if (filteredVendorIDs != null)
        {
            foreach (VendorID filteredVendorID in filteredVendorIDs)
            {
    %>
    <input type="hidden" name="filteredVendorIDs" value="<%= filteredVendorID %>" />
    <%
            }
        }
        string[] filteredCategories = this.ViewData["filteredCategories"] as string[];
        if (filteredCategories != null)
        {
            foreach (string filteredCategory in filteredCategories)
            {
    %>
    <input type="hidden" name="filteredCategories" value="<%= filteredCategory %>" />
    <%
            }
        }
    %>
    <input type="hidden" name="filteredGameID" value="<%= (this.ViewData["filteredGameID"] as string).SafeHtmlEncode() %>" />
    <input type="hidden" name="filteredSlug" value="<%= (this.ViewData["filteredSlug"] as string).SafeHtmlEncode() %>" />
    <input type="hidden" name="filteredTableName" value="<%= (this.ViewData["filteredTableName"] as string).SafeHtmlEncode() %>" />
    <input type="hidden" name="filteredClientType" value="<%= (this.ViewData["filteredClientType"] as string).SafeHtmlEncode() %>" />
    
    <input type="hidden" name="pageSize" value="<%= this.ViewData["pageSize"] %>" />
    <input type="hidden" name="pageIndex" value="<%= this.ViewData["pageIndex"] %>" />
</form>

<div class="styledTable" style="margin-bottom: 50px;">
    <table id="table-game-list" cellpadding="3" cellspacing="0">
        <thead>
            <tr>
                <th class="ui-state-default col-1"><input type="checkbox" id="selectall"  value="all" /></th>
                <th class="ui-state-default col-2">ID</th>
                <% if (CurrentUserSession.UserDomainID == Constant.SystemDomainID)
                   { %>
                <th class="ui-state-default">Operator-Visible</th>
                <% } %>   
                <th class="ui-state-default col-3">Enabled</th>
                <th class="ui-state-default col-4">Vendor</th>
                <th class="ui-state-default col-5">Game ID</th>
                <th class="ui-state-default col-6">Table Name</th>
                <th class="ui-state-default col-7">Category</th>
                <th class="ui-state-default col-8">Thumbnail</th>
                <th class="ui-state-default col-9">Opening Time</th>
                <th class="ui-state-default col-10"></th>
            </tr>
        </thead>
        <tbody>
        
            <% 
                List<ceLiveCasinoTableBaseEx> baseTables = LiveCasinoTableAccessor.GetDomainTables(Constant.SystemDomainID, null);
                for (int index = 0; index < this.Model.Count; index++ )
                {
                    var atLeastOnePropertyIsOveeriden = false;
                    
                    ceLiveCasinoTableBaseEx table = this.Model[index];
                    if (!baseTables.Exists(t => t.ID == table.ID))
                        continue;
                    ceLiveCasinoTableBaseEx baseTable = baseTables.First(t => t.ID == table.ID);

                    atLeastOnePropertyIsOveeriden = baseTable.OpVisible != table.OpVisible || 
                        baseTable.Enabled != table.Enabled ||
                        baseTable.TableName != table.TableName ||
                        baseTable.Category != table.Category ||
                        baseTable.Thumbnail != table.Thumbnail ||
                        baseTable.VIPTable != table.VIPTable ||
                        baseTable.TurkishTable != table.TurkishTable ||
                        baseTable.SeatsUnlimited != table.SeatsUnlimited ||
                        baseTable.NewTable != table.NewTable ||
                        baseTable.BetBehindAvailable != table.BetBehindAvailable ||
                        baseTable.ExcludeFromRandomLaunch != table.ExcludeFromRandomLaunch
                        //|| baseTable.ClientCompatibility != table.ClientCompatibility
                        ;
                    %>
                    
                    <tr class="<%= (index % 2 == 0) ? "odd" : "even" %>">
                        <td valign="middle" align="center">
                            <div>
                            <input type="checkbox" class="select_table" value="<%= table.ID %>" />
                            </div>
                        </td>
                        <td valign="middle" align="center" class="<%= atLeastOnePropertyIsOveeriden ? "override" : string.Empty %>">
                            <span>
                                <a class="table-name" onclick="return false" href="<%= this.Url.ActionEx("TableEditorDialog", new { @id = table.ID }).SafeHtmlEncode() %>">
                                <%= table.ID %>
                                </a>
                            </span>
                        </td>

                        <% if (CurrentUserSession.UserDomainID == Constant.SystemDomainID)
                            { %>
                        <td valign="middle" align="center" class="<%= (baseTable.OpVisible != table.OpVisible) ? "override" : string.Empty %>">
                            <div>
                                <%if (table.OpVisible)
                                    { %>
                                <img src="/images/yes.png" alt="Visible" />
                                <%}
                                    else
                                    {%>
                                <img src="/images/no.png" alt="Invisible" />
                                <%} %>
                            </div>
                        </td>
                        <% } %>

                        <td valign="middle" align="center" class="<%= (baseTable.Enabled != table.Enabled) ? "override" : string.Empty %>">
                            <div>
                            <img src="/images/<%= table.Enabled ? "yes" : "no" %>.png" alt="Enabled" />
                            </div>
                        </td>                 
                        <td align="center">
                            <img src="/images/<%= table.VendorID.ToString().SafeHtmlEncode() %>_logo.png" 
                            title="<%= table.VendorID.ToString().SafeHtmlEncode() %>"
                            alt="<%= table.VendorID.ToString().SafeHtmlEncode() %>" />                            
                        </td>
                        
                        <td align="center">
                            <span>
                                <%= table.CasinoGameBaseID %>
                            </span>
                        </td>


                        <td align="center"  class="<%= (baseTable.TableName != table.TableName) ? "override" : string.Empty %>">
                            <span>
                                <a class="table-name" onclick="return false" href="<%= this.Url.ActionEx("TableEditorDialog", new { @id = table.ID }).SafeHtmlEncode() %>">
                                    <%= table.TableName.SafeHtmlEncode()%>
                                </a>
                            </span>
                        </td>

                        <td align="center" class="<%= (baseTable.Category != table.Category) ? "override" : string.Empty %>">
                            <span>
                                <%= GetCategoryText(table).SafeHtmlEncode()%>
                            </span>
                        </td>
                        
                        <td align="center" class="<%= (baseTable.Thumbnail != table.Thumbnail) ? "override" : string.Empty %>">
                            <img class="thumbnailImage" src='<%= GetThumbnailUrl(table).SafeHtmlEncode() %>' />
                        </td>

                        <td align="center" class="col-9">
                            <%= GetOpeningTime(table) %>
                        </td>

                        <td align="center" class="col-10">
                            <%= GetParameters(table) %>
                        </td>
                    </tr>
            <%  } %>
        </tbody>

    </table>
</div>

<div id="dlgTableEditorDialog" style="display:none">
</div>

<p class="game_list_bottom">
    <% if(DomainManager.AllowEdit()) { %>
    <button type="button" id="btnEditSelectedTables">Edit Selected Tables...</button>
    <% } %>
    <%
        int pageIndex = (int)this.ViewData["pageIndex"];
        int pageCount = (int)this.ViewData["pageCount"];
        for (int i = 1; i <= pageCount; i++)
        {
            string cssClass = (i == pageIndex) ? "pagination_current" : "pagination_button";
    %>
    <a href="javascript:void(0)" class="<%=cssClass %>" pageindex="<%= i %>"><%= i %></a>
    <%
    }
    %>

    <span style="margin-left: 10px"><%= this.ViewData["currentRecords"] %> / <%= this.ViewData["totalRecords"]%> tables in this page.</span>
</p>

<script type="text/javascript">
    var selected_game_ids = new Array();

    function setSelectedGameIds() {
        selected_game_ids = new Array();
        var game_select_items = $("#table-game-list input.select_table");
        if (game_select_items.length > 0) {
            game_select_items.each(function (i, n) {
                $n = $(n);
                if ($n.attr("checked") == "checked")
                    selected_game_ids.push($(n).attr("value"));
            });
        }
    }

    $(function () {

        $('#table-game-list a.table-name').click(function (e) {
            e.preventDefault();

            $('#dlgTableEditorDialog').html('<img src="/images/loading.icon.gif" /> Loading...').modal({
                minWidth: 720,
                minHeight: 600,
                dataCss: { padding: "0px" }
            });

            var url = $(this).attr('href');
            $('#dlgTableEditorDialog').load(url);
        });

        $("#selectall").click(function (e) {
            if ($(this).is(':checked'))
                $("#table-game-list input.select_table").attr("checked", true);
            else
                $("#table-game-list input.select_table").removeAttr("checked");

            setSelectedGameIds();
        });

        $("#table-game-list input.select_table").click(function () {
            setSelectedGameIds();
        });


        $('#btnEditSelectedTables').button({
            icons: {
                primary: "ui-icon-wrench"
            }
        }).click(function () {
            if (selected_game_ids == null || selected_game_ids.length == 0)
                alert("Please select at least one game!");
            else {
                var url = '<%= this.Url.Action("TablePerprotyEditDialog").SafeJavascriptStringEncode() %>';
                
                $('#dlgEditTableProperty').html('<img src="/images/loading.icon.gif" /> Downloading data...').dialog({
                    width: 500,
                    height: "auto",
                    modal: true,
                    resizable: false,
                    close: function (evt, ui) {
                        $('#dlgEditTableProperty').html("");
                    },
                }).load(url);
            }
        });


        $('a.pagination_button').click(function (e) {
            e.preventDefault();
            $('#formPagination').attr('action', '<%= this.Url.ActionEx("TableList").SafeJavascriptStringEncode() %>');
            $('#formPagination input[name="pageIndex"]').val($(this).attr('pageIndex'));
            var options = {
                dataType: 'html',
                success: function (html) {
                    $('#table-list-wrapper').html(html);
                }
            };
            $("#formPagination").ajaxSubmit(options);
            $('#table-list-wrapper').html('<img src="/images/loading.icon.gif" />');
        });
    });
</script>