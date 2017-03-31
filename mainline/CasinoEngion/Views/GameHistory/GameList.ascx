<%@ Control Language="C#" Inherits="System.Web.Mvc.ViewUserControl<DataTable>" %>
<%@ Import Namespace="System.Data" %>
<script language="C#" type="text/C#" runat="server">

</script>

<style type="text/css">
    #table-game-list
    {
        white-space: normal;
    }
    .styledTable table#table-game-list
    {
        white-space: normal;
    }
    #table-game-list tbody td { font-size:1em; cursor:pointer; }
    #table-game-list .logo { display:block; width:60px; height:60px; }
    #table-game-list .thumbnail { display:block; width:120px; height:70px; }
    #table-game-list .override { color:Red; }
    #table-game-list .override img { border:solid 1px red; }
    #table-game-list tbody tr td:first-child.override > div  { background-color:red; }

    h1.table-game-history-gamename
    {
        display:none;
    }
</style>

<form id="formPagination" method="post" target="_blank" enctype="application/x-www-form-urlencoded">    
    <input type="hidden" name="filteredVendorID" value="<%= this.ViewData["filteredVendorID"] %>" />
    <input type="hidden" name="filteredDateFrom" value="<%= this.ViewData["filteredDateFrom"] %>" />
    <input type="hidden" name="filteredDateTo" value="<%= this.ViewData["filteredDateTo"] %>" />
    <input type="hidden" name="filteredUserID" value="<%= this.ViewData["filteredUserID"] %>" />
    <input type="hidden" name="pageSize" value="<%= this.ViewData["pageSize"] %>" />
    <input type="hidden" name="pageIndex" value="<%= this.ViewData["pageIndex"] %>" />
</form>

<p>

<%
    int pageIndex = (int)this.ViewData["pageIndex"];
    int pageCount = (int)this.ViewData["pageCount"];
    for (int i = 1; i <= pageCount; i++)
    {
        string cssClass = (i == pageIndex) ? "pagination_current" : "pagination_button";
        %>
        <a href="javascript:void(0)" class="<%=cssClass %>" pageIndex="<%= i %>"><%= i %></a>
        <%
    }
%>

<span style="margin-left:10px"><%= this.ViewData["currentRecords"] %> / <%= this.ViewData["totalRecords"]%> games in this page.</span>

</p>

<div class="styledTableV2">
    <table id="table-game-list" cellpadding="3" cellspacing="0">
        <thead>
            <tr>
                <th class="ui-state-default">ID</th>
                <th class="ui-state-default">Name</th>                
            </tr>
        </thead>
        <tbody>
            <% 
                int index = 0;
                foreach (DataRow dr in this.Model.Rows)
                {
                    index++;
                    %>
                    
                    <tr data-id="<%=dr["ID"] %>" class="<%= (index % 2 == 0) ? "odd" : "even" %>">
                        <td valign="middle" align="center">
                            <%=dr["ID"] %>
                        </td>
                        <td valign="middle" align="center">
                            <%=dr["GameName"] %>
                        </td>                        
                    </tr>
            <%  } %>
        </tbody>

    </table>
</div>

<p>
<%
    for (int i = 1; i <= pageCount; i++)
    {
        string cssClass = (i == pageIndex) ? "pagination_current" : "pagination_button";
        %>
        <a href="javascript:void(0)" class="<%=cssClass %>" pageIndex="<%= i %>"><%= i %></a>
        <%
    }
%>
<span style="margin-left:10px"><%= this.ViewData["currentRecords"] %> / <%= this.ViewData["totalRecords"]%> games in this page.</span>
</p>

<form>

</form>

<script type="text/javascript">
    var preid = 0;

    $(function () {
        $('a.pagination_button').click(function (e) {
            e.preventDefault();
            $('#formPagination').attr('action', '<%= this.Url.ActionEx("GameHistoryList").SafeJavascriptStringEncode() %>');
            $('#formPagination input[name="pageIndex"]').val($(this).attr('pageIndex'));
            var options = {
                dataType: 'html',
                success: function (html) {
                    $('#game-history-list-wrapper').html(html);
                }
            };
            $("#formPagination").ajaxSubmit(options);
            $('#game-history-list-wrapper').html('<img src="/images/loading.icon.gif" />');
        });
        
        $('#table-game-list tr').click(function (e) {
            e.preventDefault();
            $this = $(this);
            var id = $this.data('id');
            if ($('#table-game-list tr.log_detials').length > 0) {
                $('#table-game-list tr.log_detials').removeClass('log_detials').addClass('unactivated_log_detials').slideUp('fast', function () {
                    try {
                        $('#table-game-list tr.unactivated_log_detials').remove();
                        if (preid != id) {
                            ShowDetails($this, id);
                        }
                    } catch (ex) {
                        debugger;
                        var s = "";
                    }
                    preid = id;
                });
            }
            else {
                ShowDetails($this, id);
                preid = id;
            }
        });

        function ShowDetails($ele,id)
        {
            $ele.after($('<tr class="log_detials"><td style="border:1px solid #333333" valign="middle" colspan="2"><div id="game-history-details-wrapper"></div></td></tr>'));
            $('#table-game-list tr.log_detials').slideDown();
            var url = '<%=this.Url.RouteUrl("GameHistory",new{action="GameChangeDetails", @domainID = DomainManager.CurrentDomainID}) %>?gameID=' + id;
            var options = {
                dataType: 'html',
                success: function (html) {
                    $('#game-history-details-wrapper').html(html);
                }
            };
            $('#game-history-details-wrapper').html('<img src="/images/loading.icon.gif" />').load(url);
        }

        function SetTableSize()
        {
            $('.table-game-history').width($('#wrapper').width());
        }

        SetTableSize();
    });    
</script>