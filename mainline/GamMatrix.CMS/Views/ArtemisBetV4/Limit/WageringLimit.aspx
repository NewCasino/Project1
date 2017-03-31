<%@ Page Language="C#" PageTemplate="/ProfileMaster.master" Inherits="CM.Web.ViewPageEx<GamMatrixAPI.RgWageringLimitInfoRec>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GmCore" %>

<%--
1. (Record == null) : No limit; Show "Submit" button
2. (Record != null && !Record.UpdateFlag) : Has a limit;  Show "Remove" / "Change" button
3. (Record != null && Record.UpdateFlag && Record.UpdatePeriod == None ) : The limit is schedualed to be removed
4. (Record != null && Record.UpdateFlag && Record.UpdatePeriod != None ) : The limit is schedualed to be changed
 --%>

 <script language="C#" type="text/C#" runat="server">
    private SelectList GetCurrencyList(string currency = null)
    {
        var list = GamMatrixClient.GetSupportedCurrencies()
                        .FilterForCurrentDomain()
                        .Select(c => new { Key = c.Code, Value = c.GetDisplayName() })
                        .ToList();
        string selectedValue = null;
        if (!string.IsNullOrWhiteSpace(currency))
            selectedValue = currency;
        else if (this.Model != null)
            selectedValue = this.Model.Currency;
        else if (Profile.IsAuthenticated)
            selectedValue = ProfileCommon.Current.UserCurrency;
        
        return new SelectList(list
            , "Key"
            , "Value"
            , selectedValue
            );
    }

    private string GetExpirationDate()
    {
        if (this.Model != null)
        {
            if(this.Model.ExpiryDate.Date == DateTime.MaxValue.Date)
                return this.GetMetadata(".No_Expiration");

            return this.Model.ExpiryDate.ToString("dd/MM/yyyy");
        }
        return string.Empty;
    }
    
    private string GetPeriodRadioAttribute(RgWageringLimitPeriod rgWageringLimitPeriod
        , bool updatedLimit = false)
    {
        if (this.Model == null)
            return (rgWageringLimitPeriod == RgWageringLimitPeriod.Daily) ? "checked=\"checked\"" : string.Empty;

        if( !updatedLimit )
            return (this.Model.Period == rgWageringLimitPeriod) ? "checked=\"checked\" disabled=\"disabled\"" : "disabled=\"disabled\"";
        return (this.Model.UpdatePeriod == rgWageringLimitPeriod) ? "checked=\"checked\" disabled=\"disabled\"" : "disabled=\"disabled\"";
    }

    private bool IsRemoved()
    {
        if (this.Model == null)
            return false;
        return this.Model.UpdateFlag && this.Model.UpdatePeriod == RgWageringLimitPeriod.None;
    }

    private bool IsScheduled()
    {
        if (this.Model == null)
            return false;
        return this.Model.UpdateFlag && this.Model.UpdatePeriod != RgWageringLimitPeriod.None;
    }

    protected override void OnPreRender(EventArgs e)
    {
        base.OnPreRender(e);

        fldExpirationDate.Visible = this.Model != null;
        if (this.Model != null)
        {
            btnSubmitWageringLimit.Style["display"] = "none";
        }
        btnChangeWageringLimit.Visible = this.Model != null && !this.Model.UpdateFlag;
        btnRemoveWageringLimit.Visible = this.Model != null && !this.Model.UpdateFlag;
    }
</script>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
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
                <a class="BreadLink url" href="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/Limit/.Url") %>" itemprop="url" title="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/ResponsibleGaming/.Title") %>">
                    <span itemprop="title"><%= this.GetMetadata("/Metadata/Breadcrumbs/Home/Limit/.Name") %></span>
                </a>
            </li>
        </ul>
    </div>
<div id="limit-wrapper" class="content-wrapper">
<%: Html.H1(this.GetMetadata(".HEAD_TEXT")) %>
<ui:Panel runat="server" ID="pnLimit">


<form action="/Limit/SetWageringLimit" id="formWageringLimit" target="_self" method="post">

<div id="wagering-limit">
<div class="message information"><%= this.GetMetadata(".Introduction").SafeHtmlEncode() %></div>


<%------------------------------------------
    Currency
 -------------------------------------------%>
<ui:InputField ID="fldWageringLimitCurrency" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
<LabelPart><%= this.GetMetadata(".Currency_Label").SafeHtmlEncode()%></LabelPart>
<ControlPart>
        <%: Html.DropDownList("currency"
        , GetCurrencyList()
        , (new Dictionary<string, object>()
        { 
            { "id", "ddlCurrency" },
            { "validator", ClientValidators.Create().Required(this.GetMetadata(".Currency_Empty")) },
        }).SetDisabled(this.Model != null))%>
</ControlPart>
</ui:InputField>

<%------------------------------------------
    Amount
 -------------------------------------------%>
<ui:InputField ID="fldWageringLimitAmount" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
<LabelPart><%= this.GetMetadata(".Amount_Label").SafeHtmlEncode()%></LabelPart>
<ControlPart>
        <%: Html.TextBox("amount"
            , ((this.Model == null) ? string.Empty : this.Model.Amount.ToString())
            , (new Dictionary<string, object>()  
    { 
    { "id", "txtWageringLimitAmount" },
    { "onchange", "onAmountChange" },
    { "onblur", "onAmountChange" },
    { "onfocus", "onAmountFocus" },
    { "dir", "ltr" },
                { "style", "text-align:right" },
    { "validator", ClientValidators.Create().Required(this.GetMetadata(".Amount_Empty")).Custom("validateAmount") }
    }).SetReadOnly(this.Model!= null)
            )%>
</ControlPart>
</ui:InputField>

<ui:MinifiedJavascriptControl runat="server" AppendToPageEnd="true" Enabled="true">
<script type="text/javascript">
    // <%-- Format the input amount to comma seperated amount --%>
    function formatAmount(num) {
        num = num.toString().replace(/\$|\,/g, '');
        if (isNaN(num)) num = '0';
        sign = (num == (num = Math.abs(num)));
        num = Math.floor(num * 100 + 0.50000000001);
        cents = num % 100;
        num = Math.floor(num / 100).toString();
        if (cents < 10) cents = '0' + cents;
        for (var i = 0; i < Math.floor((num.length - (1 + i)) / 3); i++)
            num = num.substring(0, num.length - (4 * i + 3)) + ',' + num.substring(num.length - (4 * i + 3));
        return num + '.' + cents;
    }
    function onAmountChange() {
        $('#txtWageringLimitAmount').val(formatAmount($('#txtWageringLimitAmount').val()));
    };
    function onAmountFocus() {
        $('#txtWageringLimitAmount').val($('#txtWageringLimitAmount').val().replace(/\$|\,/g, '')).select();
    }
    function validateAmount() {
        var value = this;
        value = value.replace(/\$|\,/g, '');
        if (isNaN(value) || parseFloat(value, 10) <= 0)
            return '<%= this.GetMetadata(".Amount_Empty").SafeJavascriptStringEncode() %>';
        return true;
    }
</script>
</ui:MinifiedJavascriptControl>

<%------------------------------------------
    Period
 -------------------------------------------%>
<ui:InputField ID="fldWageringLimitPeriod" runat="server" ShowDefaultIndicator="false" BalloonArrowDirection="Left">
<LabelPart><%= this.GetMetadata(".Period_Label").SafeHtmlEncode()%></LabelPart>
<ControlPart>
        <ul style="list-style-type:none; margin:0px; padding:0px;">
            <li><input type="radio" name="wageringLimitPeriod" id="wageringLimitPeriod_daily" value="Daily" 
            <%= GetPeriodRadioAttribute( RgWageringLimitPeriod.Daily, false) %> />
                <label for="wageringLimitPeriod_daily"><%= this.GetMetadata(".Period_Daily").SafeHtmlEncode()%></label></li>
            <li><input type="radio" name="wageringLimitPeriod" id="wageringLimitPeriod_weekly" value="Weekly" 
            <%= GetPeriodRadioAttribute( RgWageringLimitPeriod.Weekly, false) %>/>
                <label for="wageringLimitPeriod_weekly"><%= this.GetMetadata(".Period_Weekly").SafeHtmlEncode()%></label></li>
            <li><input type="radio" name="wageringLimitPeriod" id="wageringLimitPeriod_monthly" value="Monthly" 
            <%= GetPeriodRadioAttribute( RgWageringLimitPeriod.Monthly, false) %>/>
                <label for="wageringLimitPeriod_monthly"><%= this.GetMetadata(".Period_Monthly").SafeHtmlEncode()%></label></li>
        </ul>
</ControlPart>
</ui:InputField>

<%------------------------------------------
    Expiration date
 -------------------------------------------%>
<ui:InputField ID="fldExpirationDate" runat="server" ShowDefaultIndicator="false" BalloonArrowDirection="Left">
<LabelPart><%= this.GetMetadata(".ExpirationDate_Label").SafeHtmlEncode()%></LabelPart>
<ControlPart>
        <%: Html.TextBox("expirationDate" , GetExpirationDate() , new { @readonly = "readonly" })%>
</ControlPart>
</ui:InputField>


<div class="Box Container deposit-limit-btns LimitBTNS" id="LimitBTNS">


<ui:Button runat="server" Text="<%$ Metadata:value(.Button_Back) %>" id="btnLimitBack" onclick="self.location='/Limit'" type="button"></ui:Button>
<ui:Button runat="server" Text="<%$ Metadata:value(.Button_Submit) %>" id="btnSubmitWageringLimit" type="submit"></ui:Button>
<ui:Button runat="server" Text="<%$ Metadata:value(.Button_Change) %>" id="btnChangeWageringLimit" type="button"></ui:Button>
<ui:Button runat="server" Text="<%$ Metadata:value(.Button_Remove) %>" id="btnRemoveWageringLimit" type="submit"></ui:Button>

</div>

<ui:MinifiedJavascriptControl runat="server" AppendToPageEnd="true" Enabled="true">
<script type="text/javascript">
    $(function () {
        $('#btnSubmitWageringLimit').click(function (e) {
            if (!validateAmount()) {
                e.preventDefault();
                return;
            }
            $(this).toggleLoadingSpin(true);
        });
        $('#btnChangeWageringLimit').click(function (e) {
            e.preventDefault();
            $(this).hide();
            $('#btnSubmitWageringLimit').show();
            $('#btnRemoveWageringLimit').hide();
            $('#ddlCurrency').attr('disabled', false);
            $('#txtWageringLimitAmount').attr('readonly', false);
            $('#fldWageringLimitPeriod input').attr('disabled', false);
        });

        $('#btnRemoveWageringLimit').click(function (e) {
            if (window.confirm('<%= this.GetMetadata(".Confirmation_Message").SafeJavascriptStringEncode() %>') != true) {
                e.preventDefault();
                return;
            }
            $(this).toggleLoadingSpin(true);
            $('#formWageringLimit').attr('action', '/Limit/RemoveWageringLimit');
        });
    });
</script>
</ui:MinifiedJavascriptControl>



</div>

</form>

</ui:Panel>

</div>


<ui:MinifiedJavascriptControl runat="server" AppendToPageEnd="true" Enabled="true">
<script type="text/javascript">
    $(function () {
        $('#formWageringLimit').initializeForm();
        $('body').addClass('LimitPages');
    });
</script>
</ui:MinifiedJavascriptControl>

</asp:Content>

