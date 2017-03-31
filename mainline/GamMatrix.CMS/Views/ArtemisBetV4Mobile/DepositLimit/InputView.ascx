<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<GamMatrixAPI.RgDepositLimitInfoRec>" %>
<%@ Import Namespace="CM.Web.UI" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>

<script type="text/C#" runat="server">
    private SelectList GetCurrencyList()
    {
        string currency = this.Model != null ? this.Model.Currency : String.Empty;

        var list = GamMatrixClient.GetSupportedCurrencies()
        .FilterForCurrentDomain()
        .Select(c => new { Key = c.Code, Value = c.GetDisplayName() })
        .ToList();
        if (list.Count > 1 && this.Model == null)
            list.Insert(0, new { Key = "", Value = this.GetMetadata(".Currency_Select") });
        return new SelectList(list
        , "Key"
        , "Value"
                    , currency
        );
    }

    private string GetAmount()
    {
        return this.Model != null ? this.Model.Amount.ToString() : String.Empty;
    }

    private string GetLimitPeriod(RgDepositLimitPeriod period)
    {
        string check = "checked=\"checked\"";

        if (this.Model != null && this.Model.Period == period)
            return check;
        else if(period == SpecifiedPeriod)
            return check;
        else if (period == RgDepositLimitPeriod.Daily)
            return check;
        return String.Empty;
    }
    private bool GetRemoved()
    {
        return this.Model != null && this.Model.UpdateFlag && this.Model.UpdatePeriod == RgDepositLimitPeriod.None;
    }

    private RgDepositLimitPeriod? _SpecifiedPeriod = null;
    private RgDepositLimitPeriod SpecifiedPeriod
    {
        get
        {
            if (!_SpecifiedPeriod.HasValue)
            {
                RgDepositLimitPeriod period = RgDepositLimitPeriod.None;
                if (this.ViewData["Period"] != null)
                    Enum.TryParse(this.ViewData["Period"].ToString(), out period);

                if (period == RgDepositLimitPeriod.None && this.Model != null && this.Model.Period != RgDepositLimitPeriod.None)
                    period = this.Model.Period;

                _SpecifiedPeriod = period;    
            }
            return _SpecifiedPeriod.Value;
        }
    }
</script>

<form id="depositLimit" class="FormList DepositLimitForm" action="<%= Url.RouteUrl("DepositLimit", new { @action = "Apply", @depositLimitPeriod = SpecifiedPeriod }, Request.Url.Scheme) %>" method="post">

    <fieldset>
        <legend class="hidden">
            <%= this.GetMetadata(".HEAD_TEXT").SafeHtmlEncode()%>
    </legend>

        <ul class="FormList DepositLimitList">
            <li class="FormItem LimitCurrencyItem">
                <label class="FormLabel" for="limitCurrency"><%= this.GetMetadata(".Currency_Label").SafeHtmlEncode()%></label>
                <%: Html.DropDownList("currency", GetCurrencyList(), new Dictionary<string, object>() 
                { 
                { "class", "FormInput" },
                { "id", "limitCurrency" },
                { "required", "required" },
                { "data-validator", ClientValidators.Create().Required(this.GetMetadata(".Currency_Empty")) }
                })%>
                <span class="FormStatus">Status</span>
                <span class="FormHelp"></span>
            </li>
            <li class="FormItem LimitAmountItem">
                <label class="FormLabel" for="limitAmount"><%= this.GetMetadata(".Amount_Label").SafeHtmlEncode()%></label>
                <%: Html.TextBox("amount", GetAmount(), new Dictionary<string, object>()
                { 
                { "class", "FormInput" },
                { "id", "limitAmount" },
                { "required", "required" },
                { "maxlength", "30" },
                { "placeholder", this.GetMetadata(".Amount_Choose") },
                { "data-validator", ClientValidators.Create().Required(this.GetMetadata(".Amount_Empty")).Custom("InputView.validateAmount") }
                }) %>
                <span class="FormStatus">Status</span>
                <span class="FormHelp"></span>
            </li>

<li class="FormItem PeriodItem">
<span class="FormLabel"><%= this.GetMetadata(".Period_Label").SafeHtmlEncode()%></span>
<ul class="FormList" id="limitPeriod">
<li class="FormItem">
<input class="FormRadio" type="radio" name="depositLimitPeriod" value="Daily" id="limitDaily" <%= GetLimitPeriod(RgDepositLimitPeriod.Daily) %> />
<label class="FormBulletLabel" for="limitDaily"><%= this.GetMetadata(".Period_Daily").SafeHtmlEncode()%></label>
</li>
<li class="FormItem">
<input class="FormRadio" type="radio" name="depositLimitPeriod" value="Weekly" id="limitWeekly"  <%= GetLimitPeriod(RgDepositLimitPeriod.Weekly) %> />
<label class="FormBulletLabel" for="limitWeekly"><%= this.GetMetadata(".Period_Weekly").SafeHtmlEncode()%></label>
</li>
<li class="FormItem">
<input class="FormRadio" type="radio" name="depositLimitPeriod" value="Monthly" id="limitMonthly"  <%= GetLimitPeriod(RgDepositLimitPeriod.Monthly) %> />
<label class="FormBulletLabel" for="limitMonthly"><%= this.GetMetadata(".Period_Monthly").SafeHtmlEncode()%></label>
</li>
</ul>
</li>
</ul>
    </fieldset>
    <% if (GetRemoved())
       {
           Html.RenderPartial("/Components/StatusNotification", new StatusNotificationViewModel(StatusType.Info, this.GetMetadata("/DepositLimit/_DisplayView_ascx.Limit_Removed")));
       }
       else
       {
           if (this.Model != null)
           { %>
    <ul class="Cols-2 DepositLimitBTNs">
        <li class="Col">
            <% } %>
            <div class="AccountButtonContainer">
                <button class="Button AccountButton LimitSubmitBTN SubmitRegister" type="submit" id="limitSubmit">
                    <strong class="ButtonText"><%= this.GetMetadata(".Button_Submit").SafeHtmlEncode()%></strong>
                </button>
            </div>
            <% if (this.Model != null)
               { %>
        </li>
        <li class="Col">
            <div class="AccountButtonContainer SettingsLimitBTNs">
                <button class="Button AccountButton LimitRemoveBTN" type="submit" id="limitRemove">
                    <strong class="ButtonText"><%= this.GetMetadata(".Button_Remove").SafeHtmlEncode()%></strong>
                </button>
            </div>
        </li>
    </ul>
    <% }
} %>
</form>

<%--<ui:MinifiedJavascriptControl ID="MinifiedJavascriptControl1" runat="server" Enabled="false" AppendToPageEnd="true">--%>
<script type="text/javascript">
    function InputView() {
        new CMS.views.AmountInput('#limitAmount');

        $('#limitRemove').click(function () {
            $('#depositLimit').attr('action', '<%= this.Url.RouteUrl( "DepositLimit", new { @action="Remove", @depositLimitPeriod = SpecifiedPeriod } ).SafeJavascriptStringEncode() %>');
        });
    }

    InputView.validateAmount = function () {
        var value = parseFloat(this, 10);
        if (isNaN(value) || value <= 0)
            return '<%= this.GetMetadata(".Amount_Empty").SafeJavascriptStringEncode() %>';
        return true;
    }

    $(function () {
        new InputView();
    });
</script>
<%--</ui:MinifiedJavascriptControl>--%>