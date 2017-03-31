<%@ Control Language="C#" Inherits="System.Web.Mvc.ViewUserControl<List<CE.db.ceCasinoGameBaseEx>>" %>
<%@ Import Namespace="CE.db" %>
<%@ Import Namespace="CE.db.Accessor" %>
<%@ Import Namespace="GamMatrixAPI" %>
<script language="C#" type="text/C#" runat="server">
    private bool ShowThumbnail { get; set; }
    private bool ShowScalableThumbnail { get; set; }

    protected override void OnInit(EventArgs e)
    {
        if (DomainManager.CurrentDomainID == Constant.SystemDomainID)
        {
            ShowThumbnail = true;
            ShowScalableThumbnail = true;
        }
        else
        {
            ceDomainConfigEx domain = DomainManager.GetDomains().First(d => d.DomainID == DomainManager.CurrentDomainID);
            ShowThumbnail = !domain.EnableScalableThumbnail;
            ShowScalableThumbnail = domain.EnableScalableThumbnail;
        }
        base.OnInit(e);
    }

    private string GetGameCategoriesHtml(string gameCategories)
    {
        StringBuilder html = new StringBuilder();

        string[] categories = gameCategories.Split(',');
        for (int i = 0; i < categories.Length; i++)
        {
            if (string.IsNullOrWhiteSpace(categories[i]))
                continue;
            if (html.Length > 0)
                html.Append("<br />");
            html.Append(GetGameCategoryText(categories[i]).SafeHtmlEncode());
        }

        return html.ToString();
    }

    private string GetGameCategoryText(string gameCategory)
    {
        string text;
        string cacheKey = "_data_directory_game_category";
        Dictionary<string, string> dic = HttpRuntime.Cache[cacheKey] as Dictionary<string, string>;
        if (dic != null)
        {
            if (dic.TryGetValue(gameCategory, out text))
                return text;
        }

        DataDictionaryAccessor dda = DataDictionaryAccessor.CreateInstance<DataDictionaryAccessor>();
        dic = dda.GetAllGameCategory();
        HttpRuntime.Cache.Insert(cacheKey, dic, null, DateTime.Now.AddMinutes(10), Cache.NoSlidingExpiration);

        if (dic.TryGetValue(gameCategory, out text))
            return text;

        return gameCategory;
    }

    private string GetInvoicingGroupText(string invoicingGroup)
    {
        string text;
        string cacheKey = "_data_directory_invoicing_group";
        Dictionary<string, string> dic = HttpRuntime.Cache[cacheKey] as Dictionary<string, string>;
        if (dic != null)
        {
            if (dic.TryGetValue(invoicingGroup, out text))
                return text;
        }
        DataDictionaryAccessor dda = DataDictionaryAccessor.CreateInstance<DataDictionaryAccessor>();
        dic = dda.GetAllInvoicingGroup();
        HttpRuntime.Cache.Insert(cacheKey, dic, null, DateTime.Now.AddMinutes(10), Cache.NoSlidingExpiration);

        if (dic.TryGetValue(invoicingGroup, out text))
            return text;

        return invoicingGroup;
    }

    private string GetReportCategoryText(string reportCategory)
    {
        string text;
        string cacheKey = "_data_directory_report_category";
        Dictionary<string, string> dic = HttpRuntime.Cache[cacheKey] as Dictionary<string, string>;
        if (dic != null)
        {
            if (dic.TryGetValue(reportCategory, out text))
                return text;
        }

        DataDictionaryAccessor dda = DataDictionaryAccessor.CreateInstance<DataDictionaryAccessor>();
        dic = dda.GetAllReportCategory();
        HttpRuntime.Cache.Insert(cacheKey, dic, null, DateTime.Now.AddMinutes(10), Cache.NoSlidingExpiration);

        if (dic.TryGetValue(reportCategory, out text))
            return text;

        return reportCategory;
    }

    private ceCasinoGameBaseEx GetGameBase(long id)
    {
        List<ceCasinoGameBaseEx> list = this.ViewData["BaseGameList"] as List<ceCasinoGameBaseEx>;

        return list.FirstOrDefault(g => g.ID == id);
    }

    private string GetTagsHtml(string tags)
    {
        StringBuilder html = new StringBuilder();
        html.Append("<ul>");
        string[] array = tags.Split(',');
        foreach (string tag in array)
        {
            if (!string.IsNullOrWhiteSpace(tag))
            {
                html.AppendFormat("<li>{0}</li>", tag.SafeHtmlEncode());
            }
        }
        html.Append("</ul>");
        return html.ToString();
    }

    private string GetClientHtml(string clientCompatibility)
    {
        StringBuilder html = new StringBuilder();
        html.Append("<ul>");
        string[] array = clientCompatibility.Split(',');
        foreach (string client in array)
        {
            if (!string.IsNullOrWhiteSpace(client))
            {
                html.AppendFormat("<li>{0}</li>", client.SafeHtmlEncode());
            }
        }
        html.Append("</ul>");
        return html.ToString();
    }

    private string GetThumbnailUrl(ceCasinoGameBaseEx game)
    {
        if (string.IsNullOrEmpty(game.Thumbnail))
            return "//cdn.everymatrix.com/images/placeholder.png";
        return string.Format("{0}{1}"
            , (ConfigurationManager.AppSettings["ResourceUrl"] ?? "//cdn.everymatrix.com").TrimEnd('/')
            , game.Thumbnail
            );
    }


    private string GetScalableThumbnailUrl(ceCasinoGameBaseEx game)
    {
        if (string.IsNullOrEmpty(game.ScalableThumbnailPath))
            return "//cdn.everymatrix.com/images/placeholder.png";
        return string.Format("{0}{1}"
            , (ConfigurationManager.AppSettings["ResourceUrl"] ?? "//cdn.everymatrix.com").TrimEnd('/')
            , game.ScalableThumbnailPath
            );
    }

    private string GetLogoUrl(ceCasinoGameBaseEx game)
    {
        if (string.IsNullOrEmpty(game.Logo))
            return "//cdn.everymatrix.com/images/logo_placeholder.png";
        return string.Format("{0}{1}"
            , (ConfigurationManager.AppSettings["ResourceUrl"] ?? "//cdn.everymatrix.com").TrimEnd('/')
            , game.Logo
            );
    }

    private VendorID GetOrginalVendor(ceCasinoGameBaseEx game)
    {
        if (game.OriginalVendorID == VendorID.Unknown)
            return game.VendorID;
        return game.OriginalVendorID;
    }
</script>


<style type="text/css">
    #table-game-list tbody td { font-size: 0.85em; }
    #table-game-list .logo { display: block; width: 60px; height: 60px; }
    #table-game-list .thumbnail { display: block; width: 120px; height: 70px; }
    #table-game-list .override { color: Red; }
    #table-game-list .override img { border: solid 1px red; }
    #table-game-list tbody tr td:first-child.override > div { background-color: red; }
    #table-game-list tbody tr td .sub-column
    {
        display:block;
        height:18px;
        line-height: 16px;
        font-size:16px;
    }
        #table-game-list tbody tr td .sub-column img
        {
            vertical-align: middle;
        }
        #table-game-list tbody tr td .sub-column span
        {
            font-size:12px;
        }

    #game-list-wrapper .styledTable {margin-bottom:60px;}
    .game_list_bottom{ position: fixed;bottom: 0;width: 100%;background: #fff;}
    .pagination_top{ display: none;}
    #btnSaveAsSpreadsheet{margin-right:15px;}
</style>

<% if (DomainManager.CurrentDomainID != Constant.SystemDomainID)
   { %>
<div class="ui-widget">
    <div style="margin-bottom: 10px; padding: 0 .7em;" class="ui-state-highlight ui-corner-all">
        <p>
            <span style="float: left; margin-right: .3em;" class="ui-icon ui-icon-info"></span>
            <strong>NOTE!</strong> The overridden attributes, which differ from the default settings, appear in <span style="color: red">red</span> color.
        </p>
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
    <input type="hidden" name="filteredReportCategory" value="<%= (this.ViewData["filteredReportCategory"] as string).SafeHtmlEncode() %>" />
    <input type="hidden" name="filteredInvoicingGroup" value="<%= (this.ViewData["filteredInvoicingGroup"] as string).SafeHtmlEncode() %>" />
    <input type="hidden" name="filteredClientType" value="<%= (this.ViewData["filteredClientType"] as string).SafeHtmlEncode() %>" />
    <input type="hidden" name="filteredAvailability" value="<%= (this.ViewData["filteredAvailability"] as string).SafeHtmlEncode() %>" />
    <input type="hidden" name="filteredGameName" value="<%= (this.ViewData["filteredGameName"] as string).SafeHtmlEncode() %>" />
    <input type="hidden" name="filteredGameCode" value="<%= (this.ViewData["filteredGameCode"] as string).SafeHtmlEncode() %>" />
    <input type="hidden" name="filteredTag" value="<%= (this.ViewData["filteredTag"] as string).SafeHtmlEncode() %>" />
    <input type="hidden" name="filteredSlug" value="<%= (this.ViewData["filteredSlug"] as string).SafeHtmlEncode() %>" />
    <input type="hidden" name="filteredID" value="<%= (this.ViewData["filteredID"] as string).SafeHtmlEncode() %>" />
    <input type="hidden" name="filteredLicense" value="<%= (this.ViewData["filteredLicense"] as string).SafeHtmlEncode() %>" />
    <input type="hidden" name="filteredOpVisible" value="<%= (this.ViewData["filteredOpVisible"] as string).SafeHtmlEncode() %>" />
    <input type="hidden" name="filteredExcludeFromBonuses" value="<%= (this.ViewData["filteredExcludeFromBonuses"] as string).SafeHtmlEncode() %>" />
    <input type="hidden" name="pageSize" value="<%= this.ViewData["pageSize"] %>" />
    <input type="hidden" name="pageIndex" value="<%= this.ViewData["pageIndex"] %>" />
</form>
<p class="pagination_top">

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

    <span style="margin-left: 10px"><%= this.ViewData["currentRecords"] %> / <%= this.ViewData["totalRecords"]%> games in this page.</span>

</p>

<div class="styledTable">
    <table id="table-game-list" cellpadding="3" cellspacing="0">
        <thead>
            <tr>
                <th class="ui-state-default">
                    <input type="checkbox" id="selectall" value="all" /></th>
                <th class="ui-state-default">ID</th>
                <% if (CurrentUserSession.UserDomainID == Constant.SystemDomainID)
                   { %>
                <th class="ui-state-default">Operator-Visible</th>
                <% } %>                
                <th class="ui-state-default">Enabled</th>               
                <th class="ui-state-default">Vendor</th>
                <th class="ui-state-default">Original Vendor</th>
                <th class="ui-state-default">Logo</th>

                <% if (this.ShowThumbnail)
                   { %>
                <th class="ui-state-default">Thumbnail</th>
                <% } %>

                <% if (this.ShowScalableThumbnail)
                   { %>
                <th class="ui-state-default">Scalable Thumbnail</th>
                <% } %>

                <th class="ui-state-default">Name</th>

                <th class="ui-state-default">Category</th>
                <th class="ui-state-default">&#160;</th>
                <th class="ui-state-default">Play Mode</th>
                <th class="ui-state-default">&#160;</th>
                <th class="ui-state-default">Tags</th>
                <th class="ui-state-default">Client</th>
                <th class="ui-state-default">Vendor Game ID & Slug</th>
                <th class="ui-state-default">Restricted Territories</th>
                <th class="ui-state-default">License</th>
                <th class="ui-state-default">Jackpot Type</th>
                <th class="ui-state-default">Html5 game mode</th>
                 <th class="ui-state-default">Age Limit</th>
                <th class="ui-state-default">Exclude from Bonuses</th>
                <th class="ui-state-default"></th>
            </tr>
        </thead>
        <tbody>

            <% 
                for (int index = 0; index < this.Model.Count; index++)
                {
                    ceCasinoGameBaseEx game = this.Model[index];
                    ceCasinoGameBaseEx gameBase = GetGameBase(game.ID);
                    if (gameBase == null || game == null)
                        continue;
                    if (CurrentUserSession.UserDomainID != Constant.SystemDomainID)
                    {
                        if (!game.OpVisible)
                            continue;
                    }
            %>

            <tr class="<%= (index % 2 == 0) ? "odd" : "even" %>">
                <td valign="middle" align="center">
                    <div>
                        <input type="checkbox" class="select_game" value="<%= game.ID %>" />
                    </div>
                </td>
                <td valign="middle" align="center">
                    <%= game.ID %>
                </td>
                <% if (CurrentUserSession.UserDomainID == Constant.SystemDomainID)
                   { %>
                <td valign="middle" align="center" class="<%= (gameBase.OpVisible != game.OpVisible) ? "override" : string.Empty %>">
                    <div>
                        <%if (game.OpVisible)
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
                <td valign="middle" align="center" class="<%= (gameBase.Enabled != game.Enabled) ? "override" : string.Empty %>">
                    <div>
                        <%if (game.Enabled)
                          { %>
                        <img src="/images/yes.png" alt="Enabled" />
                        <%}
                          else
                          {%>
                        <img src="/images/no.png" alt="Disabled" />
                        <%} %>
                    </div>
                </td>

                <td align="center">
                    <img src="/images/<%= game.VendorID.ToString().SafeHtmlEncode() %>_logo.png"
                        title="<%= game.VendorID.ToString().SafeHtmlEncode() %>"
                        alt="<%= game.VendorID.ToString().SafeHtmlEncode() %>" />
                </td>

                <td align="center">
                    <img src="/images/<%= GetOrginalVendor(game).ToString().SafeHtmlEncode() %>_logo.png"
                        title="<%= GetOrginalVendor(game).ToString().SafeHtmlEncode() %>"
                        alt="<%= GetOrginalVendor(game).ToString().SafeHtmlEncode() %>" />
                </td>

                <td align="center" class="<%= (gameBase.Logo != game.Logo) ? "override" : string.Empty %>">
                    <a class="logo" onclick="return false" href="<%= this.Url.ActionEx("GameEditorDialog", new { @id = game.ID }).SafeHtmlEncode() %>">
                        <img alt="<%= game.GameName.SafeHtmlEncode() %>" src="<%= GetLogoUrl(game).SafeHtmlEncode() %>" width="60" height="60" />
                    </a>
                </td>

                <% if (this.ShowThumbnail)
                   { %>
                <td align="center" class="<%= (gameBase.Thumbnail != game.Thumbnail) ? "override" : string.Empty %>">
                    <a class="thumbnail" onclick="return false" href="<%= this.Url.ActionEx("GameEditorDialog", new { @id = game.ID }).SafeHtmlEncode() %>">
                        <img alt="<%= game.GameName.SafeHtmlEncode() %>" src="<%= GetThumbnailUrl(game).SafeHtmlEncode() %>" width="120" height="70" />
                    </a>
                </td>
                <% } %>

                <% if (this.ShowScalableThumbnail)
                   { %>
                <td align="center" class="<%= (gameBase.ScalableThumbnail != game.ScalableThumbnail) ? "override" : string.Empty %>">
                    <a class="thumbnail" onclick="return false" href="<%= this.Url.ActionEx("GameEditorDialog", new { @id = game.ID }).SafeHtmlEncode() %>">
                        <img alt="<%= game.GameName.SafeHtmlEncode() %>" src="<%= GetScalableThumbnailUrl(game).SafeHtmlEncode() %>" width="120" height="70" />
                    </a>
                </td>
                <% } %>

                <td align="center">
                    <span class="<%= (gameBase.GameName != game.GameName) ? "override" : string.Empty %>">
                        <%= game.GameName.SafeHtmlEncode()%>
                    </span>
                    <br />
                    <span class="<%= (gameBase.ShortName != game.ShortName) ? "override" : string.Empty %>">( <%= game.ShortName.SafeHtmlEncode() %> )
                    </span>
                </td>

                <td align="center" class="<%= (gameBase.GameCategories != game.GameCategories) ? "override" : string.Empty %>">
                    <%= GetGameCategoriesHtml(game.GameCategories) %>
                </td>
                <td class="<%= (gameBase.ReportCategory != game.ReportCategory) ? "override" : string.Empty %>">
                    <ul>
                        <li class="<%= (gameBase.ReportCategory != game.ReportCategory) ? "override" : string.Empty %>">Report Category : <%= game.ReportCategory.SafeHtmlEncode() %></li>
                        <li class="<%= (gameBase.InvoicingGroup != game.InvoicingGroup) ? "override" : string.Empty %>">Invoicing Group : <%= game.InvoicingGroup.SafeHtmlEncode()%></li>
                    </ul>
                </td>
                <td class="<%= (gameBase.FunMode != game.FunMode) ? "override" : string.Empty %>">
                    <ul>
                        <li class="<%= (gameBase.FunMode != game.FunMode) ? "override" : string.Empty %>">Fun Mode : <%= game.FunMode ? "YES" : "NO"%></li>
                        <li class="<%= (gameBase.AnonymousFunMode != game.AnonymousFunMode) ? "override" : string.Empty %>">Anonymous Fun : <%= game.AnonymousFunMode ? "YES" : "NO"%></li>
                        <li class="<%= (gameBase.RealMode != game.RealMode) ? "override" : string.Empty %>">Real Mode : <%= game.RealMode ? "YES" : "NO"%></li>
                    </ul>
                </td>


                <td>
                    <ul>
                        <li class="<%= (gameBase.JackpotContribution != game.JackpotContribution) ? "override" : string.Empty %>">Jackpot Contribution : <%= string.Format("{0:f3} %", game.JackpotContribution * 100.00M)%></li>
                        <li class="<%= (gameBase.BonusContribution != game.BonusContribution) ? "override" : string.Empty %>">Bonus Contribution : <%= string.Format("{0:f3} %", game.BonusContribution * 100.00M)%></li>
                        <li class="<%= (gameBase.FPP != game.FPP) ? "override" : string.Empty %>">FPP : <%= string.Format("{0:f3} %", game.FPP * 100.00M)%></li>
                        <li class="<%= (gameBase.TheoreticalPayOut != game.TheoreticalPayOut) ? "override" : string.Empty %>">Theoretical PayOut : <%= string.Format("{0:f3} %", game.TheoreticalPayOut * 100.00M)%></li>
                        <li class="<%= (gameBase.ThirdPartyFee != game.ThirdPartyFee) ? "override" : string.Empty %>">Third Party Fee : <%= string.Format("{0:f3} %", game.ThirdPartyFee * 100.00M)%></li>
                        <li class="<%= (gameBase.PopularityCoefficient != game.PopularityCoefficient) ? "override" : string.Empty %>">Popularity Coefficient : <%= string.Format("{0:f2}", game.PopularityCoefficient)%></li>
                    </ul>
                </td>

                <td class="<%= (game.Tags == null ) ? "override" : string.Empty %>">
                    <%= GetTagsHtml(game.Tags) %>
                </td>

                <td align="center" class="<%= (gameBase.ClientCompatibility != game.ClientCompatibility) ? "override" : string.Empty %>">
                    <%= GetClientHtml(game.ClientCompatibility)%>
                </td>


                <td align="center">
                    <br />
                    <%= game.GameCode.SafeHtmlEncode()%>
                    <br />
                    ( <%= game.GameID.SafeHtmlEncode() %> ) 
                            <br />
                    [ <%= game.Slug.SafeHtmlEncode() %> ]                       
                </td>

                <td align="center">
                    <% if (string.IsNullOrWhiteSpace(game.RestrictedTerritories))
                       { %>
                               ---
                            <% }
                       else
                       {
                           int count = game.RestrictedTerritories.Split(',').Where(t => !string.IsNullOrWhiteSpace(t)).Count();
                           if (count > 0)
                           {
                            %>
                    <%= count %> countries
                                       <%
                                   }
                                   else
                                   {
                                       %>
                                       ---
                                       <%
                                   }
                                       %>
                    <% } %>    
                </td>

                <td align="center">
                    <span<%= (gameBase.License != game.License) ? @" class= ""override""" : string.Empty %>>
                            <%= game.License.ToString() == "None" ? "---" : game.License.ToString()%>
                    </span>
                </td>


                <td align="center">
                    <span<%= (gameBase.JackpotType != game.JackpotType) ? @" class= ""override""" : string.Empty %>>
                            <%= game.JackpotType.ToString() == "None" ? "---" : game.JackpotType.ToString()%>
                    </span>
                </td>
                
                 <td align="center">
                    <span<%= (gameBase.LaunchGameInHtml5 != game.LaunchGameInHtml5) ? @" class= ""override""" : string.Empty %>>
                        <%= game.LaunchGameInHtml5 ? "YES" : "NO"%>                            
                    </span>
                </td>
                 <td align="center">
                    <span<%= (gameBase.AgeLimit != game.AgeLimit) ? @" class= ""override""" : string.Empty %>>
                        <%= game.AgeLimit ? "YES" : "NO"%>                            
                    </span>
                </td>

                <td valign="middle" align="center" class="<%= (gameBase.ExcludeFromBonuses != game.ExcludeFromBonuses) ? "override" : string.Empty %>">
                    <div>
                        <%if (game.ExcludeFromBonuses)
                          { %>
                        <img src="/images/yes.png" alt="Enabled" />
                        <%}
                          else
                          {%>
                        <img src="/images/no.png" alt="Disabled" />
                        <%} %>
                        <% if (CurrentUserSession.UserDomainID == Constant.SystemDomainID)
                           { %>
                        <span class="sub-column"> (
                            <% if (game.ExcludeFromBonuses_EditableByOperator)
                               { %>
                               <img src="/images/yes.png" alt="Enabled" width="16" height="16" />
                            <% }
                               else
                               { %> 
                               <img src="/images/no.png" alt="Disabled" width="16" height="16" />
                            <% } %>
                            <span>Editable by Operator</span> )
                        </span>
                       <%  } %>
                    </div>
                </td>                
                
                <td align="center">
                    <a class="game-information" onclick="return false;" target="_blank" href="<%= this.Url.ActionEx("EditGameInformation", new { @id = game.ID }).SafeHtmlEncode() %>">Game Information
                    </a>
                <%if (CurrentUserSession.IsSystemUser)
                  { %>
                    <a class="btnGameHistory" target="_blank" href="<%=this.Url.RouteUrl("GameHistory",new{action="GameChangeDetails", @domainID = DomainManager.CurrentDomainID}) %>?gameID=<%=gameBase.ID %>">Change Log</a>
                <%} %>
                </td>
                
            </tr>
            <%  } %>
        </tbody>
    </table>
</div>
<div class="game_list_bottom">
    <p class="pagination_bottom">
        <% if(DomainManager.AllowEdit()) { %>
        <button type="button" id="btnEditSelectedGames">Edit Selected Games...</button>
        <% } %>
        <button type="submit" id="btnSaveAsSpreadsheet">Save as Spreadsheet</button>
        <%
            for (int i = 1; i <= pageCount; i++)
            {
                string cssClass = (i == pageIndex) ? "pagination_current" : "pagination_button";
        %>
        <a href="javascript:void(0)" class="<%=cssClass %>" pageindex="<%= i %>"><%= i %></a>
        <%
        }
        %>
        <span style="margin-left: 10px"><%= this.ViewData["currentRecords"] %> / <%= this.ViewData["totalRecords"]%> games in this page.</span>
    </p>
</div>


<script type="text/javascript">
    var selected_game_ids = new Array();

    function setSelectedGameIds() {
        selected_game_ids = new Array();
        var game_select_items = $("#table-game-list input.select_game");
        if (game_select_items.length > 0) {
            game_select_items.each(function (i, n) {
                $n = $(n);
                if ($n.attr("checked") == "checked")
                    selected_game_ids.push($(n).attr("value"));
            });
        }
    }

    $(function () {
        $('#btnEditSelectedGames').button({
            icons: {
                primary: "ui-icon-wrench"
            }
        });

        $('#btnSaveAsSpreadsheet').button({
            icons: {
                primary: "ui-icon-disk"
            }
        }).click(function (e) {
            e.preventDefault();

            var $form = $('#formPagination').clone(false).attr('id', '_' + (new Date()).getTime()).appendTo(document.body);
            $form.attr('method', 'post');
            $form.attr('action', '<%= this.Url.ActionEx("GameList").SafeJavascriptStringEncode() %>?exportAsSpreadsheet=True');
            $form.submit();
        });


        $("#selectall").click(function (e) {
            $this = $(this);
            if ($this.attr("checked") == "checked")
                $("#table-game-list input.select_game").attr("checked", "checked");
            else
                $("#table-game-list input.select_game").removeAttr("checked");

            setSelectedGameIds();
        });

        $("#table-game-list input.select_game").click(function () {
            setSelectedGameIds();
        });

        $('#btnEditSelectedGames').click(function () {
            if (selected_game_ids == null || selected_game_ids.length == 0)
                alert("Please select at least one game!");
            else {
                var url = '<%= this.Url.Action("GamePerprotyEditDialog").SafeJavascriptStringEncode() %>';
                <%if ((this.ViewData["filteredExcludeFromBonuses"] as string) == "1") { %>
                url += '?ShowExcludeFromBonusesForOperator=1';
                <%}%>
                $('#dlgEditGameProperty').html('<img src="/images/loading.icon.gif" /> Downloading data...').dialog({
                    width: 500,
                    height: "auto",
                    modal: true,
                    resizable: false,
                    close: function (evt, ui) {
                        $('#dlgEditGameProperty').html("");
                    },
                }).load(url);
            }
        });

        $('.btnGameHistory').button();

        $('.btnGameHistory').click(function () {
            var url = $(this).attr('href');
            $('#dlgGameHistory').html('<img src="/images/loading.icon.gif" /> Downloading data...').dialog({
                title: "Change log",
                width: 800,
                height: 450,
                modal: true,
                resizable: false,
                close: function (evt, ui) {
                    $('#dlgGameHistory').html("");
                },
            }).load(url);
            return false;
        });


        $('a.pagination_button').click(function (e) {
            e.preventDefault();
            $('#formPagination').attr('action', '<%= this.Url.ActionEx("GameList").SafeJavascriptStringEncode() %>');
            $('#formPagination input[name="pageIndex"]').val($(this).attr('pageIndex'));
            var options = {
                dataType: 'html',
                success: function (html) {
                    $('#game-list-wrapper').html(html);
                }
            };
            $("#formPagination").ajaxSubmit(options);
            $('#game-list-wrapper').html('<img src="/images/loading.icon.gif" />');
        });
    });

    setTimeout(function () {
        $('#table-game-list a.thumbnail,#table-game-list a.logo').click(function (e) {
            e.preventDefault();

            $('#dlgGameRegistration').html('<img src="/images/loading.icon.gif" /> Downloading data from third parties...').modal({
                minWidth: 880,
                minHeight: 630,
                dataCss: { padding: "0px" }
            });

            var url = $(this).attr('href');
            $('#dlgGameRegistration').load(url);
        });

        $('#table-game-list a.game-information').button();
        $('#table-game-list a.game-information').click(function (e) {
            e.preventDefault();
            var url = $(this).attr('href');
            window.open(url, "gameinformation", "menubar=false,location=false,resizable=yes,scrollbars=yes,status=yes");
        });



    }, 0);
</script>
