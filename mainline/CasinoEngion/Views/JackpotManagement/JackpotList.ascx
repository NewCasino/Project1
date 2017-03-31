<%@ Control Language="C#" Inherits="System.Web.Mvc.ViewUserControl<List<CE.db.ceCasinoJackpotBaseEx>>" %>
<%@ Import Namespace="CE.db" %>
<%@ Import Namespace="CE.db.Accessor" %>

<style type="text/css">
#jackpot-list { table-layout:fixed; }
#pagingContainer{padding:10px;text-align:left;}
#pagingDetails{padding: 0 0 0 10px;line-height: 22px;}
#pagingDetails{color:black;}
#pagingContainer ul{
    list-style-type:none;
}
#pagingContainer ul li{float:left;}
#dvJackpotsFooter{text-align:right;padding:5px;}
#lstItemsPerPage{cursor:pointer;}
.game_list_bottom{left:0;}
</style>

<div class="styledTable">
    <div id="dvJackpotsFooter">
        <span>Max</span>
        <select id="lstItemsPerPage">
            <option value="5">5</option>
            <option value="20">20</option>
            <option value="50" selected="selected">50</option>
            <option value="100">100</option>
            <option value="200">200</option>
        </select>
        <span>records per page.</span>
    </div>
    <table id="jackpot-list" cellpadding="3" cellspacing="0" style="clear:both;">
        <thead>
            <tr>
                <% if (CurrentUserSession.IsSuperUser) {%>
                <th class="ui-state-default" style="width:80px"></th>
                <%} %>
                <th class="ui-state-default" style="width:80px">Vendor</th>
                <th class="ui-state-default">Name</th>
                <th class="ui-state-default">Detail</th>
                <th class="ui-state-default">Games</th>
            </tr>
        </thead>
        <tbody>

            <%
                List<ceCasinoGameBaseEx> games = CasinoGameAccessor.GetDomainGames(Constant.SystemDomainID, false);
                for (int index = 0; index < this.Model.Count; index++)
                {
                    ceCasinoJackpotBaseEx jackpot = this.Model[index];
                    %>

                    <tr class="<%= (index % 2 == 0) ? "odd" : "even" %>">
                        <% if (CurrentUserSession.IsSuperUser) {%>
                        <td>
                            <% if(DomainManager.AllowEdit()) { %>
                            <a href="javascript:deleteJackpot(<%= jackpot.BaseID %>,<%= jackpot.JackpotID%>)">Delete</a> |
                            <% } %>
                            <a href="javascript:openJackpotEditorDlg(<%= jackpot.BaseID %>,<%= jackpot.JackpotID%>);">Edit...</a>                            
                        </td>
                        <%} %>
                        <td align="center">
                            <img src="/images/<%= jackpot.VendorID.ToString().SafeHtmlEncode() %>_logo.png" 
                            title="<%= jackpot.VendorID.ToString().SafeHtmlEncode() %>"
                            alt="<%= jackpot.VendorID.ToString().SafeHtmlEncode() %>" />                            
                        </td>
                        <td align="center" class="jp-name">
                            <%= jackpot.Name.SafeHtmlEncode() %>
                        </td>
                        <td>
                            <% if (jackpot.IsFixedAmount && jackpot.Amount.HasValue )
                               { %>
                               Fixed amount, <%= jackpot.BaseCurrency %> <%= jackpot.Amount.Value.ToString("N0") %>
                            <% }
                               else
                               { %>
                               Mapped to jackpot id : <strong><%= jackpot.MappedJackpotID.SafeHtmlEncode() %></strong>
                            <% } %>
                        </td>
                        <td>
                            <ul>
                                <% 
                                    string [] gameIDs = jackpot.GameIDs.Split(',');
                                    foreach (string gameID in gameIDs)
                                    {
                                        if (string.IsNullOrWhiteSpace(gameID))
                                            continue;
                                        ceCasinoGameBaseEx game = games.FirstOrDefault(g => g.VendorID == jackpot.VendorID && g.ID.ToString() == gameID);
                                        if (game == null)
                                            continue;
                                        
                                        %>
                                        <li><%= game.ShortName.SafeHtmlEncode() %>
                                            <input type="checkbox" class="cbx-hide-game" data-jackpotid="<%= jackpot.JackpotID %>" data-baseid="<%= jackpot.BaseID %>" data-gameid="<%= game.ID %>"
                                                <%= jackpot.HiddenGameIDs.Contains(game.ID.ToString()) ? "checked" : string.Empty %> <%= DomainManager.AllowEdit() ? "" : "disabled = disabled" %> />Hide
                                        </li>
                                        <%
                                    }
                                %>
                            </ul>
                            
                        </td>
                        
                    </tr>
                    <%
                } 
              %>

        </tbody>

    </table>
    <div id="pagingContainer" class="game_list_bottom"></div>
    <br />
    <br />
    <br />
    <br />
</div>

<script language="javascript" type="text/javascript">
    var selectedPage = 1;
    var totalCount = <%= this.Model.Count %>;

    var pagingModel = {
        totalPages: 1,
        startPage: 1,
        visiblePages: 3,
        first: '<<',
        prev: '<',
        next: '>',
        last: '>>',
        paginationClass: 'pagination small',
        onPageClick: onPageClick
    };

    $(function () {
        var countPerPage = +$('#lstItemsPerPage').val();

        $("#jackpot-list tbody tr").each(function(index, item){
            if (index >= countPerPage){
                $(item).hide();
            }
        });

        updatePaging();
        updatePagingDetails();

        $('#lstItemsPerPage').change(function () {
            $('#pagingContainer').twbsPagination('destroy');

            var newContainer = $('#pagingContainer').clone();

            $('#pagingContainer').remove();

            $('#dvJackpotsFooter').append(newContainer);

            updatePaging();
            updateJackpotsPage();
        });

        initHideGames();
    });

    function openJackpotEditorDlg(baseId, jackpotId) {
        $('#dlgJackpotRegistration').html('<img src="/images/loading.icon.gif" />').dialog({
            width: 800,
            height: $(document.body).height() - 50,
            modal: true,
            resizable: false
        });

        var url = '<%= this.Url.ActionEx("JackpotEditorDialog").SafeJavascriptStringEncode() %>?baseId=' + baseId + '&jackpotId=' + jackpotId;
        $('#dlgJackpotRegistration').load(url);
    }

    function deleteJackpot(baseId, jackpotId) {
        if (window.confirm("You are going to delete this jackpot.\nPress \"OK\" to continue.") == false)
            return;
        var url = '<%= this.Url.ActionEx("DeleteJackpot").SafeJavascriptStringEncode() %>?baseId=' + baseId + '&jackpotId=' + jackpotId;
        $.getJSON(url, function (json) {
            if (!json.success) {
                alert(json.error);
                return;
            }
            $('#btnSearchJackpots').trigger('click');
        });
        
    }

    function onPageClick(e, page) {
        if (page != selectedPage) {
            selectedPage = page;
            
            updateJackpotsPage();
        }
    }

    function updatePaging(){
        var countPerPage = +$('#lstItemsPerPage').val();
        pagingModel.totalPages = 1;

        if (totalCount > countPerPage){
            pagingModel.totalPages = (totalCount % countPerPage == 0) ? (totalCount / countPerPage) : (parseInt(totalCount / countPerPage) + 1);
        }

        pagingModel.startPage = 1;
        selectedPage = 1;
        
        $('#pagingContainer').twbsPagination(pagingModel);
    }

    function updateJackpotsPage(){
        var countPerPage = +$('#lstItemsPerPage').val();

        var skip = (selectedPage - 1) * countPerPage;
        var take = skip + countPerPage;

        $("#jackpot-list tbody tr").each(function(index, item){
            if (index < skip || index >= take){
                $(item).hide();
            }else{
                $(item).show();
            }
        });

        updatePagingDetails();
    }

    function initHideGames(){
        $('.cbx-hide-game').click(function(){
            if (hideGamesFromCallback){
                hideGamesFromCallback = false;
                return;
            }

            var item = $(this);

            var gameId = item.attr('data-gameid');
            var jackpotId = item.attr('data-jackpotid');
            var baseId = item.attr('data-baseid');
            
            var hideUrl = '<%= this.Url.ActionEx("HideJackpotGame").SafeJavascriptStringEncode() %>';
            var showUrl = '<%= this.Url.ActionEx("ShowJackpotGame").SafeJavascriptStringEncode() %>';
            
            var url = item.is(':checked') ? hideUrl : showUrl;

            $.post(url,
                { gameId: gameId, jackpotId:jackpotId, baseId:baseId },
                function(data){
                    if(!data.success){
                        hideGamesFromCallback = true;
                        item.click();
                    }
                }, "json");
        });
    }

    function updatePagingDetails(){
        $('#pagingDetails').remove();
        var visibleItemsCount = $("#jackpot-list tbody tr:visible").length;
        $('#pagingContainer').append($('<span id="pagingDetails" />').text(visibleItemsCount + ' / ' + totalCount + ' jackpots in this page.'));
    }

    var hideGamesFromCallback = false;
</script>