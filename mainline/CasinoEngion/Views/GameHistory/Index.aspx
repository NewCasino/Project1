<%@ Page Title="Casino Engine - Configuration" Language="C#" MasterPageFile="~/Views/Shared/Default.Master" 
    Inherits="System.Web.Mvc.ViewPage<CE.db.ceDomainConfigEx>" %>
<%@ Import Namespace="CE.db.Accessor" %>
<%@ Import Namespace="GamMatrixAPI" %>

<script language="C#" type="text/C#" runat="server">
    private VendorID[] GetVendors()
    {
        DomainConfigAccessor dca = DomainConfigAccessor.CreateInstance<DomainConfigAccessor>();
        var domain = dca.GetByDomainID(DomainManager.CurrentDomainID);
        if (domain != null && DomainManager.CurrentDomainID != Constant.SystemDomainID)
        {
            CasinoVendorAccessor cva = CasinoVendorAccessor.CreateInstance<CasinoVendorAccessor>();
            return cva.GetEnabledVendors(DomainManager.CurrentDomainID).ToArray();
        }
        return GlobalConstant.AllVendors;
    }

    private SelectList GetVendorList()
    {
        VendorID[] vendors = GetVendors();
        
        var vs = from v in vendors
                 let value = v.ToString()
                 orderby value
                 select new
                 {
                     Key = ((int)v).ToString(),
                     Value = value
                 };
        
        return new SelectList(vs, "Key", "Value", string.Empty);
    }
    
    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);        
    }
</script>

<asp:Content ID="Content1" ContentPlaceHolderID="phMain" runat="server">

<style type="text/css" media="all">
    #game-history-list-wrapper
    {
        width:100%;
        display:block;
    }
    .filter-wrapper
    {
        border:1px dotted #DDDDDD;
        padding: 5px 15px;
    }
    .filter-fields
    {
        border:1px dotted #DDDDDD;
        padding: 5px 15px;
    }
    .filter-table td
    {
        padding-right: 15px;
    }
    .date-inputbox
    {
        text-align:center;
        width: 80px;
    }
    .table-game-history
    {
    }
        .table-game-history td
        {
            vertical-align:top;
        }
.pagination_button { cursor:pointer; width:20px; line-height:20px; height:20px; text-decoration:none; display:inline-block; overflow:hidden; text-align:center; vertical-align:middle; color:#B8EC79; background-color:#111; }
.pagination_current { cursor:default; width:20px; line-height:20px; height:20px; text-decoration:none; display:inline-block; overflow:hidden; text-align:center; vertical-align:middle; color:#111; background-color:#B8EC79; }
</style>

<div class="filter-wrapper">
<form method="post" action="<%= this.Url.ActionEx("GameHistoryList").SafeHtmlEncode() %>" enctype="application/x-www-form-urlencoded"
    id="formSearchGameHistoryList">
    <div class="filter-fields">
    <table class="filter-table"><tr>        
        <td>
        <strong>From</strong> <input class="date-inputbox" type="text" id="dateFrom" name="filteredDateFrom" />&nbsp;&nbsp;00:00:00
        </td>
        <td>
            <strong>To</strong> <input class="date-inputbox" type="text" id="dateTo" name="filteredDateTo" />&nbsp;&nbsp;00:00:00
        </td>
        <td>
        <strong>Vendor</strong> <%: Html.DropDownList("filteredVendorID", GetVendorList(), new { @class = "filter_ddl" })%>
        </td>
        <td>
            <strong>UserID</strong> <input type="text" id="txtUserID" name="filteredUserID" />
        </td>
    </tr></table>
    </div>
    <input type="hidden" name="pageSize" value="15" />
    <p>
        <button type="button" id="btnSearch">Search</button>
    </p>
</form>
</div>
<hr />
<table class="table-game-history">
    <tr>
        <td>
            <div id="game-history-list-wrapper"></div>
        </td>
    </tr>
</table>
    <form id="formLoadDetails" method="post" target="_blank" enctype="application/x-www-form-urlencoded">    
    </form>
    <script type="text/javascript">
        $(function () {
            function getDateString(date) {
                return date.getMonth() + 1 + "/" + date.getDate() + "/" + date.getFullYear();
            }
            
            var _d1 = new Date();
            var _d2 = new Date();
            _d2.setMonth(_d1.getMonth() - 1);
            $('#dateFrom').val(getDateString(_d2));
            _d2.setMonth(_d1.getMonth());
            _d2.setDate(_d1.getDate() + 1);
            $('#dateTo').val(getDateString(_d2));

            $('#filteredVendorID').prepend('<option value="0" selected="selected">All</option>');
            $('#dateFrom').attr("readonly", "readonly").datepicker();
            $('#dateTo').attr("readonly", "readonly").datepicker();
            $('#btnSearch').button({
                icons: {
                    primary: "ui-icon-search"
                }
            }).click(function (e) {
                e.preventDefault();
                var options = {
                    dataType: 'html',
                    success: function (html) {
                        $('#game-history-list-wrapper').html(html);
                    }
                };
                $('#game-history-list-wrapper').html('<img src="/images/loading.icon.gif" />');
                $("#formSearchGameHistoryList").ajaxSubmit(options);
            });
        });        
    </script>
</asp:Content>