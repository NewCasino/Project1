<%@ Page Language="C#" PageTemplate="/ProfileMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>

<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="GamMatrixAPI" %>
<script language="C#" type="text/C#" runat="server">
    private SelectListItem [] GetMonthList()
    {
        List<SelectListItem> list = new List<SelectListItem>();
        
        DateTime date = DateTime.Now;
        for (int i = 0; i < 6; i++)
        {
            list.Add(new SelectListItem()
            {
                Text = string.Format( "{0} / {1}"
                    , CultureInfo.CurrentCulture.DateTimeFormat.GetMonthName(date.Month)
                    , date.Year
                    ),
                Value = date.ToString("yyyyMM")
            });
            date = date.AddMonths(-1);
        }

        list[0].Selected = true;
        list.Insert( 0, new SelectListItem()
        {
            Text = this.GetMetadata(".All"),
            Value = string.Empty
        });
        return list.ToArray();
    }

    private SelectListItem[] GetTypeList()
    {
        var gammingAccounts = GamMatrixClient.GetUserGammingAccounts( Profile.UserID );
        List<SelectListItem> list = new List<SelectListItem>();
        list.Add(new SelectListItem()
        {
            Text = this.GetMetadata(".Type_Deposit"),
            Value = "Deposit",
            Selected = true,
        });

        list.Add(new SelectListItem()
        {
            Text = this.GetMetadata(".Type_Withdraw"),
            Value = "Withdraw",
        });

        list.Add(new SelectListItem()
        {
            Text = this.GetMetadata(".Type_Transfer"),
            Value = "Transfer",
        });

        list.Add(new SelectListItem()
        {
            Text = this.GetMetadata(".Type_BuddyTransfer"),
            Value = "BuddyTransfer",
        });

        if (gammingAccounts.Exists(a => a.Record.VendorID == VendorID.NetEnt))
        {
            list.Add(new SelectListItem()
            {
                Text = this.GetMetadata(".Type_CasinoFPP"),
                Value = "CasinoFPP",
            });
        }
        
        if( gammingAccounts.Exists( a => a.Record.VendorID == VendorID.Affiliate ) )
        {
            list.Add(new SelectListItem()
            {
                Text = this.GetMetadata(".Type_AffiliateFee"),
                Value = "AffiliateFee",
            });
        }

        // 4.Which Vendors have WalletCredit and WalletDebit transactions? I can see Microgaming transaction on DEV in user shema.
        // Cake, MergeNetwork, Microgaming, NetEnt (casino module for StarVenusCasino), OnGame (transparent purse solution) , ViG (live casino) + there will be more: IGT and CTXM
        if (gammingAccounts.Exists(a => a.Record.VendorID == VendorID.CakeNetwork))
        {
            list.Add(new SelectListItem()
            {
                Text = this.GetMetadata(".Type_CakeNetworkWalletCreditDebit"),
                Value = "CakeNetworkWalletCreditDebit",
            });
        }

        if (gammingAccounts.Exists(a => a.Record.VendorID == VendorID.MergeNetwork))
        {
            list.Add(new SelectListItem()
            {
                Text = this.GetMetadata(".Type_MergeNetworkWalletCreditDebit"),
                Value = "MergeNetworkWalletCreditDebit",
            });
        }

        if (gammingAccounts.Exists(a => a.Record.VendorID == VendorID.Microgaming))
        {
            list.Add(new SelectListItem()
            {
                Text = this.GetMetadata(".Type_MicrogamingWalletCreditDebit"),
                Value = "MicrogamingWalletCreditDebit",
            });
        }

        if (gammingAccounts.Exists(a => a.Record.VendorID == VendorID.ViG))
        {
            list.Add(new SelectListItem()
            {
                Text = this.GetMetadata(".Type_ViGWalletCreditDebit"),
                Value = "ViGWalletCreditDebit",
            });
        }

        if (gammingAccounts.Exists(a => a.Record.VendorID == VendorID.IGT))
        {
            list.Add(new SelectListItem()
            {
                Text = this.GetMetadata(".Type_IGTWalletCreditDebit"),
                Value = "IGTWalletCreditDebit",
            });
        }


        return list.ToArray();
    }
</script>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
<script type="text/javascript" src="/js/plugin.js"></script>
<script type="text/javascript" src="/js/date.js"></script>
  
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
 <div class="Breadcrumbs" role="navigation">
        <ul class="BreadMenu Container" role="menu">
            <li class="BreadItem" role="menuitem" itemtype="http://data-vocabulary.org/Breadcrumb" itemscope="itemscope">
                <a class="BreadLink url" href="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/.Url") %>" itemprop="url" title="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/.Title") %>">
                    <span itemprop="title"><%= this.GetMetadata("/Metadata/Breadcrumbs/Home/.Name") %></span>
                </a>
            </li>
            <li class="BreadItem BreadCurrent" role="menuitem" itemtype="http://data-vocabulary.org/Breadcrumb" itemscope="itemscope">
                <a class="BreadLink url" href="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/TransactionHistory/.Url") %>" itemprop="url" title="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/ResponsibleGaming/.Title") %>">
                    <span itemprop="title"><%= this.GetMetadata("/Metadata/Breadcrumbs/Home/TransactionHistory/.Name") %></span>
                </a>
            </li>
        </ul>
    </div>
<div id="accountstatement-wrapper" class="content-wrapper">
<h1 id="ProfileTitle" class="ProfileTitle"> <%: this.GetMetadata(".HEAD_TEXT") %> </h1>
<ui:Panel runat="server" ID="pnAccountStatement">
<%= this.GetMetadata(".Info_HTML").HtmlEncodeSpecialCharactors() %>
<ui:FieldSet runat="server">
    <% using (Html.BeginRouteForm("AccountStatement", new { @action = "Search" }, FormMethod.Post, new { @id = "formAccountStatement" }))
       { %>
        
        <ui:InputField ID="fldFilterDateFrom" runat="server" ShowDefaultIndicator="false" BalloonArrowDirection="Left">
        <LabelPart><%= this.GetMetadata(".DateFrom_Label").SafeHtmlEncode()%></LabelPart>
        <ControlPart>
               <%: Html.TextBox("filterDateFrom", "", new { @id = "filterDateFrom", @validator = ClientValidators.Create().Date(this.GetMetadata(".Date_Invalid")) })%>
        </ControlPart>
        </ui:InputField>

        <ui:InputField ID="fldFilterDateTo" runat="server" ShowDefaultIndicator="false" BalloonArrowDirection="Left">
        <LabelPart><%= this.GetMetadata(".DateTo_Label").SafeHtmlEncode()%></LabelPart>
        <ControlPart>
               <%: Html.TextBox("filterDateTo", "", new { @id = "filterDateTo", @validator = ClientValidators.Create().Date(this.GetMetadata(".Date_Invalid")) })%>
        </ControlPart>
        </ui:InputField>

        <ui:InputField ID="fldFilterType" runat="server" ShowDefaultIndicator="false" BalloonArrowDirection="Left">
        <LabelPart><%= this.GetMetadata(".Type_Label").SafeHtmlEncode()%></LabelPart>
        <ControlPart>
               <%: Html.DropDownList("filterType", GetTypeList())%>
        </ControlPart>
        </ui:InputField>

        <div class="button-wrapper">
            <%: Html.Button( this.GetMetadata(".Button_Filter"), new { @id = "btnSearchTransactionHistory" }) %>        
        </div>
    <% } %>
</ui:FieldSet>

<div id="transaction-list-wrapper">
</div>

</ui:Panel>
</div>
<%Html.RenderPartial("/Components/DatePicker"); %>

<script language="javascript" type="text/javascript">
    function getDateStringForDatepicker(date) {
        return date.getMonth() + 1 + "/" + date.getDate() + "/" + date.getFullYear();
    }

    function initDateValues() {
        var filterDateFrom = $("#filterDateFrom");
        var filterDateTo = $("#filterDateTo");
        var dateFrom = filterDateFrom.val().trim();
        var dateTo = filterDateTo.val().trim();
        try {
            if (dateFrom == "" && dateTo == "") {
                var _date = new Date();
                filterDateFrom.val(getDateStringForDatepicker(new Date().setMonth(_date.getMonth() - 1)));
                filterDateTo.val(getDateStringForDatepicker(new Date().setDate(_date.getDate() + 1)));
            }
            else if (dateFrom != "" && dateTo == "") {
                var _date = new Date(dateFrom);
                filterDateTo.val(getDateStringForDatepicker(new Date(_date.setMonth(_date.getMonth() + 1))));
            }
            else if (dateFrom == "" && dateTo != "") {
                var _date = new Date(dateTo);
                filterDateFrom.val(getDateStringForDatepicker(new Date(_date.setMonth(_date.getMonth() - 1))));
            }
        }
        catch (ex) {
            var _date = new Date();
            filterDateFrom.val(getDateStringForDatepicker(new Date(_date.setMonth(_date.getMonth() - 1))));
            filterDateTo.val(getDateStringForDatepicker(new Date()));
        }
    }

    function onTransactionsLoad() {
        var t = $("#transaction-list-wrapper .transaction-table");
        if(t.children(".holder-flex-100").length <2 && $("#transaction-list-wrapper .transaction-table tbody").children().length == 0){
            t.html('<%= this.GetMetadata(".NoResult") %>');
        }
        $.each(t.find("td.col-time"), function (i, n) {
            var t = $(n);
            var s = t.data("time") || t.attr("date-time");
            var dateJson = $.parseJSON('{' + s + '}');
            var d = new Date(dateJson.Year, dateJson.Month - 1, dateJson.Day, dateJson.Hour, dateJson.Minute, dateJson.Second);
            d = d.convertUTCTimeToLocalTime(d);
            var s = d.format("dd/mm/yyyy hh:nn");
            t.find("span").html(d.format("dd/mm/yyyy hh:nn"));
        });
    }
    $(document).ready(function () {
        $('#formAccountStatement').initializeForm();

        initDateValues();

        $("#filterDateFrom").datepickerEx({
            changeMonth: true,
            changeYear: true
        });
        $("#filterDateTo").datepickerEx({
            changeMonth: true,
            changeYear: true
        });

        $("#filterDateFrom").keydown(function (e) {
            if (e.which == 8 || e.which == 46) {
                $(this).val('');
            }
            else
                return false;
        });
        $("#filterDateTo").keydown(function (e) {
            if (e.which == 8 || e.which == 46) {
                $(this).val('');
            }
            else
                return false;
        });

        $('#btnSearchTransactionHistory').click(function (e) {
            e.preventDefault();

            initDateValues();

            if (!$('#formAccountStatement').valid())
                return;
            var dateFrom = new Date($("#filterDateFrom").val());
            var dateTo = new Date($("#filterDateTo").val());
            if(dateFrom > dateTo){
                $("#transaction-list-wrapper .transaction-table").html('<%= this.GetMetadata(".DataCompare_Error").SafeHtmlEncode() %>');
                return;
            }
            $(this).toggleLoadingSpin(true);

            var options = {
                type: 'POST',
                dataType: 'html',
                success: function (html) {
                    $('#btnSearchTransactionHistory').toggleLoadingSpin(false);
                    $('#transaction-list-wrapper').html(html);

                    onTransactionsLoad();
                }
            };
            $('#formAccountStatement').ajaxForm(options);
            $('#formAccountStatement').submit();
        }).trigger('click');
    });    
</script>
<%  Html.RenderPartial("IndexBodyPlus", this.ViewData ); %>


<ui:MinifiedJavascriptControl runat="server">
<script type="text/javascript">
jQuery('body').addClass('TransferPage TransferHistory');
jQuery('.inner').addClass('ProfileContent TransferContent TransferHistoryContent');
jQuery('.MainProfile').addClass('MainWithdraw MainTransfer MainTransferHistory');
jQuery('.sidemenu li').addClass('PMenuItem');
jQuery('.sidemenu li span').addClass('PMenuLinkContainer');
jQuery('.sidemenu li span a').addClass('ProfileMenuLinks');
setTimeout(function(){
jQuery('.ProfileContent').prepend(jQuery('#ProfileTitle'));
},1);
$(function(){
    $("#filterType option[value='BuddyTransfer']").remove();
});
</script>
</ui:MinifiedJavascriptControl>
</asp:Content>

