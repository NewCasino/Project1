<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="CM.Web.UI" %>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>

<script runat="server">
public string[] TransactionTypes { get; protected set; }
public DateSelectorView DateSelect { get; protected set; }

protected override void OnInit(EventArgs e)
{
var gammingAccounts = GamMatrixClient.GetUserGammingAccounts(Profile.UserID);
List<string> types = new List<string> { "Deposit", "Withdraw", /*"BuddyTransfer"*/ };

if (gammingAccounts.Exists(a => a.Record.VendorID == VendorID.CasinoWallet))
types.Add("CasinoWalletCreditDebit");

if (gammingAccounts.Exists(a => a.Record.VendorID == VendorID.NetEnt))
types.Add("CasinoFPP");

if (gammingAccounts.Exists(a => a.Record.VendorID == VendorID.Affiliate))
types.Add("AffiliateFee");

if (gammingAccounts.Exists(a => a.Record.VendorID == VendorID.Microgaming))
types.Add("MicrogamingWalletCreditDebit");

if (gammingAccounts.Exists(a => a.Record.VendorID == VendorID.ViG))
types.Add("ViGWalletCreditDebit");

if (gammingAccounts.Exists(a => a.Record.VendorID == VendorID.IGT))
types.Add("IGTWalletCreditDebit");

TransactionTypes = types.ToArray();
DateSelect = new DateSelectorView();

base.OnInit(e);
}
</script>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div class="UserBox CenterBox">
<div class="BoxContent">
    <form action="<%= Url.RouteUrl("AccountStatement", new { @action = "Search" }) %>" method="post" id="formAccountStatement" class="GeneralForm TransactionHistoryForm">
        
    <fieldset>
        <legend class="hidden">
<%= this.GetMetadata(".Legend_Filter").SafeHtmlEncode()%>
</legend>

<ul class="FormList TransactionHistoryList">
<li class="FormItem FromDateItem">
<label class="FormLabel"><%= this.GetMetadata(".DateFrom_Label").SafeHtmlEncode()%></label>
                <ol class="CompositeInput DateInput THInput Cols-3 FromList">
<li class="Col DayCol">
<%: Html.DropDownList("filterDateFromDay", DateSelect.GetDayList(this.GetMetadata(".DOB_Day")), new Dictionary<string, object>() 
                        { 
                            { "class", "FormInput" },
                            { "id", "filterDateFromDay" },
                            { "required", "required" },
                            { "data-validator", ClientValidators.Create().Required(this.GetMetadata(".DOB_Empty")).Custom("validateFilterDateFrom") }
                        })%>
</li>
<li class="Col MonthCol">
                        <%: Html.DropDownList("filterDateFromMonth", DateSelect.GetMonthList(this.GetMetadata(".DOB_Month")), new Dictionary<string, object>() 
                        { 
                            { "class", "FormInput" },
                            { "id", "filterDateFromMonth" },
                            { "required", "required" },
                            { "data-validator", ClientValidators.Create().Required(this.GetMetadata(".DOB_Empty")).Custom("validateFilterDateFrom") }
                        })%>
</li>
<li class="Col YearCol">
                        <%: Html.DropDownList("filterDateFromYear", DateSelect.GetYearList(this.GetMetadata(".DOB_Year"), 10), new Dictionary<string, object>() 
                        { 
                            { "class", "FormInput" },
                            { "id", "filterDateFromYear" },
                            { "required", "required" },
                            { "data-validator", ClientValidators.Create().Required(this.GetMetadata(".DOB_Empty")).Custom("validateFilterDateFrom") }
                        })%>
</li>
</ol>
                <span class="FormStatus">Status</span>
<span class="FormHelp"></span>
</li>
            <li class="FormItem ToDateItem">
<label class="FormLabel"><%= this.GetMetadata(".DateTo_Label").SafeHtmlEncode()%></label>
                <ol class="CompositeInput DateInput THInput Cols-3 ToList">
<li class="Col DayCol">
<%: Html.DropDownList("filterDateToDay", DateSelect.GetDayList(this.GetMetadata(".DOB_Day")), new Dictionary<string, object>() 
                        { 
                            { "class", "FormInput" },
                            { "id", "filterDateToDay" },
                            { "required", "required" },
                            { "data-validator", ClientValidators.Create().Required(this.GetMetadata(".DOB_Empty")).Custom("validateFilterDateTo") }
                        })%>
</li>
<li class="Col MonthCol">
                        <%: Html.DropDownList("filterDateToMonth", DateSelect.GetMonthList(this.GetMetadata(".DOB_Month")), new Dictionary<string, object>() 
                        { 
                            { "class", "FormInput" },
                            { "id", "filterDateToMonth" },
                            { "required", "required" },
                            { "data-validator", ClientValidators.Create().Required(this.GetMetadata(".DOB_Empty")).Custom("validateFilterDateTo") }
                        })%>
</li>
<li class="Col YearCol">
                        <%: Html.DropDownList("filterDateToYear", DateSelect.GetYearList(this.GetMetadata(".DOB_Year"), 10), new Dictionary<string, object>() 
                        { 
                            { "class", "FormInput" },
                            { "id", "filterDateToYear" },
                            { "required", "required" },
                            { "data-validator", ClientValidators.Create().Required(this.GetMetadata(".DOB_Empty")).Custom("validateFilterDateTo") }
                        })%>
</li>
</ol>
                <span class="FormStatus">Status</span>
<span class="FormHelp"></span>
</li>
<li class="FormItem CurrencyItem" id="fldCurrency">
<label class="FormLabel" for="filterCurrency"><%= this.GetMetadata(".Type_Label").SafeHtmlEncode()%></label>
<%: Html.DropDownList("filterType", TransactionTypes.Select(t => new SelectListItem { Value = t, Text = this.GetMetadata(".Type_" + t) }), new Dictionary<string, object>() 
                { 
                    { "class", "FormInput" },
                    { "id", "filterType" }
                })%>
</li>
</ul>
<div class="AccountButtonContainer THButtonContainer">
<button id="btnSearchTransactionHistory" class="Button AccountButton THFilterBTN" type="submit">
<strong class="ButtonText"><%= this.GetMetadata(".Button_Filter").SafeHtmlEncode()%></strong>
</button>
</div>
    </fieldset>
    </form>

    <div class="TransactionListWraper" id="transaction-list-wrapper"></div>
<div class="NoTransactions Hidden" id="noTransactions">
<% Html.RenderPartial("/Components/StatusNotification", new StatusNotificationViewModel(StatusType.Info, this.GetMetadata(".No_Results"))); %>
</div>
</div>
</div>
<ui:MinifiedJavascriptControl ID="MinifiedJavascriptControl1" runat="server" Enabled="true" AppendToPageEnd="true">
<script language="javascript" type="text/javascript">
function validateFilterDateFrom() {
var day = $('#filterDateFromDay').val();
var month = $('#filterDateFromMonth').val();
var year = $('#filterDateFromYear').val();

return validateDate(day, month, year);
}

function validateFilterDateTo() {
var day = $('#filterDateToDay').val();
var month = $('#filterDateToMonth').val();
var year = $('#filterDateToYear').val();

if (validateDate(day, month, year) != true)
return;

var f_day = $('#filterDateFromDay').val();
var f_month = $('#filterDateFromMonth').val();
var f_year = $('#filterDateFromYear').val();

if (new Date(year, month, day) < new Date(f_year, f_month, f_day)) {
return '<%=this.GetMetadata(".EndTo_BeforeStartDate").SafeJavascriptStringEncode() %>';
}

return true;
}

function validateDate(day, month, year) {

if (day.length == 0 || month.length == 0 || year.length == 0)
return '<%= this.GetMetadata(".DOB_Empty").SafeJavascriptStringEncode() %>';

day = parseInt(day, 10);
month = parseInt(month, 10);
year = parseInt(year, 10);

var maxDay = 31;
switch (month) {
case 4: maxDay = 30; break;
case 6: maxDay = 30; break;
case 9: maxDay = 30; break;
case 11: maxDay = 30; break;

case 2:
{
if (year % 400 == 0 || year % 4 == 0)
maxDay = 29;
else
maxDay = 28;
break;
}
default:
break;
}
if (day > maxDay)
return '<%= this.GetMetadata(".DOB_Empty").SafeJavascriptStringEncode() %>';

return true;
}

$(document).ready(function () {
$(CMS.mobile360.Generic.init);

$('#formAccountStatement').initializeForm();

initDateValues();

$('#btnSearchTransactionHistory').click(function (e) {
e.preventDefault();
if (!$('#formAccountStatement').valid())
return;

var filterDateFrom = $("#filterDateFromMonth").val() + "/" + $("#filterDateFromDay").val() + "/" + $("#filterDateFromYear").val();
var filterDateTo = $("#filterDateToMonth").val() + "/" + $("#filterDateToDay").val() + "/" + $("#filterDateToYear").val();

$.ajax({
type: 'POST',
url: $('#formAccountStatement').attr('action'),
data: {
__RequestVerificationToken: $('#formAccountStatement input[name=__RequestVerificationToken]').val(),
filterDateFrom: filterDateFrom,
filterDateTo: filterDateTo,
filterType: $("#filterType").val()
},
success: filterResponse,
error: showErrorfunction,
dataType: 'html'
});

}).trigger('click');

function filterResponse(html) {
$('#transaction-list-wrapper').html(html);

$('#noTransactions').toggleClass('Hidden', !!$('.TransactionList li').length);
}

function showErrorfunction(XMLHttpRequest, textStatus, errorThrown) {
errorField.text(textStatus + errorThrown).show();
}


function initDateValues() {
var _date = new Date();

$("#filterDateToDay").val(supplementZero(_date.getDate()));
$("#filterDateToMonth").val(supplementZero(_date.getMonth() + 1));
$("#filterDateToYear").val(_date.getFullYear());

_date.setMonth(_date.getMonth() - 1);
$("#filterDateFromDay").val(supplementZero(_date.getDate()));
$("#filterDateFromMonth").val(supplementZero(_date.getMonth() + 1));
$("#filterDateFromYear").val(_date.getFullYear());
}

function supplementZero(val) {
if (val < 10) {
return "0" + val;
}

return val;
}
});
</script>
</ui:MinifiedJavascriptControl>
</asp:Content>

