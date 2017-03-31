<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<GamMatrixAPI.RgDepositLimitInfoRec>" %>
<%@ Import Namespace="GmCore"  %>
<%@ Import Namespace="GamMatrixAPI"  %>

<script language="C#" type="text/C#" runat="server">
    private SelectList GetCurrencyList(string currency = null)
    {
        var list = GamMatrixClient.GetSupportedCurrencies()
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
    
    private string GetPeriodRadioAttribute(RgDepositLimitPeriod rgDepositLimitPeriod
        , bool updatedLimit = false)
    {
        if (this.Model == null)
            return (rgDepositLimitPeriod == RgDepositLimitPeriod.Daily) ? "checked=\"checked\"" : string.Empty;

        if( !updatedLimit )
            return (this.Model.Period == rgDepositLimitPeriod) ? "checked=\"checked\" disabled=\"disabled\"" : "disabled=\"disabled\"";
        return (this.Model.UpdatePeriod == rgDepositLimitPeriod) ? "checked=\"checked\" disabled=\"disabled\"" : "disabled=\"disabled\"";
    }

    private bool IsRemoved()
    {
        if (this.Model == null)
            return false;
        return this.Model.UpdateFlag && this.Model.UpdatePeriod == RgDepositLimitPeriod.None;
    }

    private bool IsScheduled()
    {
        if (this.Model == null)
            return false;
        return this.Model.UpdateFlag && this.Model.UpdatePeriod != RgDepositLimitPeriod.None;
    }
</script>

<% using( Html.BeginRouteForm( "DepositLimitation", new { @action="Apply"}, FormMethod.Post, new { @id="formDepositLimit"}) )
   { %>

<div id="deposit-limit">
<p><%= this.GetMetadata(".Introduction").SafeHtmlEncode() %></p>



<%------------------------------------------
    Currency
 -------------------------------------------%>
<ui:InputField ID="fldDepositLimitCurrency" runat="server" ShowDefaultIndicator="false" BalloonArrowDirection="Left">
	<LabelPart><%= this.GetMetadata(".Currency_Label").SafeHtmlEncode()%></LabelPart>
	<ControlPart>
        <%: Html.DropDownList( "currency", GetCurrencyList(), new 
        {
            @id = "ddlCurrency",
            @validator = ClientValidators.Create().Required(this.GetMetadata(".Currency_Empty")),
        })%>
	</ControlPart>
</ui:InputField>


<%------------------------------------------
    Amount
 -------------------------------------------%>
<ui:InputField ID="fldDepositLimitAmount" runat="server" ShowDefaultIndicator="false" BalloonArrowDirection="Left">
	<LabelPart><%= this.GetMetadata(".Amount_Label").SafeHtmlEncode()%></LabelPart>
	<ControlPart>
        <%: Html.TextBox("amount"
            , ((this.Model == null) ? string.Empty : this.Model.Amount.ToString())
            , new 
            {
                @id = "txtDepositLimitAmount",
                @onchange = "onAmountChange()", 
                @onblur = "onAmountChange()", 
                @onfocus = "onAmountFocus()",
                @validator = ClientValidators.Create().Required(this.GetMetadata(".Amount_Empty")).Custom("validateAmount"),
                @dir = "ltr",
                @style = "text-align:right",
            }
         )%>
	</ControlPart>
</ui:InputField>
<script language="javascript" type="text/javascript">
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
    $('#txtDepositLimitAmount').val(formatAmount($('#txtDepositLimitAmount').val()));
};
function onAmountFocus() {
    $('#txtDepositLimitAmount').val($('#txtDepositLimitAmount').val().replace(/\$|\,/g, '')).select();
}
function validateAmount(){
    var value = this;
    value = value.replace(/\$|\,/g, '');
    if ( isNaN(value) || parseFloat(value, 10) <= 0 )
        return '<%= this.GetMetadata(".Amount_Empty").SafeJavascriptStringEncode() %>';
    return true;
}
<% if( this.Model != null )
   { %>
   
       $(document).ready(function () {
           $('#fldDepositLimitCurrency select').attr('disabled', true);
           $('#fldDepositLimitAmount input').attr('readonly', true);
       });
<% } %>
</script>

<%------------------------------------------
    Period
 -------------------------------------------%>
<ui:InputField ID="fldDepositLimitPeriod" runat="server" ShowDefaultIndicator="false" BalloonArrowDirection="Left">
	<LabelPart><%= this.GetMetadata(".Period_Label").SafeHtmlEncode()%></LabelPart>
	<ControlPart>
        <ul style="list-style-type:none; margin:0px; padding:0px;">
            <li><input type="radio" name="depositLimitPeriod" id="depositLimitPeriod_daily" value="Daily" 
            <%= GetPeriodRadioAttribute( RgDepositLimitPeriod.Daily, false) %> />
                <label for="depositLimitPeriod_daily"><%= this.GetMetadata(".Period_Daily").SafeHtmlEncode()%></label></li>
            <li><input type="radio" name="depositLimitPeriod" id="depositLimitPeriod_weekly" value="Weekly" 
            <%= GetPeriodRadioAttribute( RgDepositLimitPeriod.Weekly, false) %>/>
                <label for="depositLimitPeriod_weekly"><%= this.GetMetadata(".Period_Weekly").SafeHtmlEncode()%></label></li>
            <li><input type="radio" name="depositLimitPeriod" id="depositLimitPeriod_monthly" value="Monthly" 
            <%= GetPeriodRadioAttribute( RgDepositLimitPeriod.Monthly, false) %>/>
                <label for="depositLimitPeriod_monthly"><%= this.GetMetadata(".Period_Monthly").SafeHtmlEncode()%></label></li>
        </ul>
	</ControlPart>
</ui:InputField>


<%------------------------------------------
    Expiration date
 -------------------------------------------%>
 <% if (this.Model != null)
    { %>
<ui:InputField ID="fldExpirationDate" runat="server" ShowDefaultIndicator="false" BalloonArrowDirection="Left">
	<LabelPart><%= this.GetMetadata(".ExpirationDate_Label").SafeHtmlEncode()%></LabelPart>
	<ControlPart>
        <%: Html.TextBox("expirationDate" , GetExpirationDate() , new { @readonly = "readonly" })%>
	</ControlPart>
</ui:InputField>
<% } %>

<br />



<%------------------------------
    The limit is removed
 -------------------------------%>
<% if (IsRemoved())
   { %>
    <center>
    <%: Html.InformationMessage(this.GetMetadata(".Limit_Removed"))%>
    <br />
    </center>
<% } %>

<%------------------------------
    the limit is not removed but scheduled
 -------------------------------%>
 <%
else if (IsScheduled())
{ %>
    <center>
    <%: Html.InformationMessage(this.GetMetadata(".Limit_Scheduled"))%>
    <br />
    </center>
<%------------------------------------------
    New Currency
 -------------------------------------------%>
<ui:InputField ID="fldNewLimitCurrency" runat="server" ShowDefaultIndicator="false" BalloonArrowDirection="Left">
	<LabelPart><%= this.GetMetadata(".Currency_Label").SafeHtmlEncode()%></LabelPart>
	<ControlPart>
        <%: Html.DropDownList( "newLimitCurrency", GetCurrencyList(this.Model.UpdateCurrency), new 
        {
            @id = "ddlCurrency",
            @disabled = "disabled",
        })%>
	</ControlPart>
</ui:InputField>


<%------------------------------------------
    New Amount
 -------------------------------------------%>
<ui:InputField ID="fldNewLimitAmount" runat="server" ShowDefaultIndicator="false" BalloonArrowDirection="Left">
	<LabelPart><%= this.GetMetadata(".Amount_Label").SafeHtmlEncode()%></LabelPart>
	<ControlPart>
        <%: Html.TextBox("newLimitAmount"
            , this.Model.UpdateAmount.ToString()
            , new 
            {
                @readonly = "readonly",
                @dir = "ltr",
                @style = "text-align:right",
            }
         )%>
	</ControlPart>
</ui:InputField>

<%------------------------------------------
    New Period
 -------------------------------------------%>
<ui:InputField ID="fldNewLimitPeriod" runat="server" ShowDefaultIndicator="false" BalloonArrowDirection="Left">
	<LabelPart><%= this.GetMetadata(".Period_Label").SafeHtmlEncode()%></LabelPart>
	<ControlPart>
        <ul style="list-style-type:none; margin:0px; padding:0px;">
            <li><input type="radio" name="newLimitPeriod" id="Radio1" value="Daily" 
            <%= GetPeriodRadioAttribute( RgDepositLimitPeriod.Daily, true) %> />
                <label for="depositLimitPeriod_daily"><%= this.GetMetadata(".Period_Daily").SafeHtmlEncode()%></label></li>
            <li><input type="radio" name="newLimitPeriod" id="Radio2" value="Weekly" 
            <%= GetPeriodRadioAttribute( RgDepositLimitPeriod.Weekly, true) %>/>
                <label for="depositLimitPeriod_weekly"><%= this.GetMetadata(".Period_Weekly").SafeHtmlEncode()%></label></li>
            <li><input type="radio" name="newLimitPeriod" id="Radio3" value="Monthly" 
            <%= GetPeriodRadioAttribute( RgDepositLimitPeriod.Monthly, true) %>/>
                <label for="depositLimitPeriod_monthly"><%= this.GetMetadata(".Period_Monthly").SafeHtmlEncode()%></label></li>
        </ul>
	</ControlPart>
</ui:InputField>

<ui:InputField ID="fldValidFrom" runat="server" ShowDefaultIndicator="false" BalloonArrowDirection="Left">
	<LabelPart><%= this.GetMetadata(".ValidFrom_Label").SafeHtmlEncode()%></LabelPart>
	<ControlPart>
        <%: Html.TextBox("validFromDate", GetExpirationDate(), new { @readonly = "readonly" })%>
	</ControlPart>
</ui:InputField>


   <%
}
else
{ %>

<%------------------------------
    the limit not exist, not removed or not scheduled
 -------------------------------%>
<center>

    <%: Html.Button(this.GetMetadata(".Button_Submit"), new { @id = "btnSubmitDepositLimit" })%>

    
    <%
       if (this.Model != null && !this.Model.UpdateFlag)
       { %>
                <%: Html.Button(this.GetMetadata(".Button_Change"), new { @id = "btnChangeDepositLimit", @type="button" })%>
                <%: Html.Button(this.GetMetadata(".Button_Remove"), new { @id = "btnRemoveDepositLimit" })%>
                <script language="javascript" type="text/javascript">
                    $(function () { $('#btnSubmitDepositLimit').hide(); });
                </script>
    <% } %>
</center>
<% } %>


</div>

<% } %>


<script language="javascript" type="text/javascript">
    $(document).ready(function () {
        $('#formDepositLimit').initializeForm();

        $('#btnSubmitDepositLimit').click(function (e) {
            e.preventDefault();

            if (!$('#formDepositLimit').valid())
                return;

            $(this).toggleLoadingSpin(true);
            var options = {
                dataType: "html",
                type: 'POST',
                success: function (html) {
                    $('#btnSubmitDepositLimit').toggleLoadingSpin(false);
                    $('#formDepositLimit').parent().html(html);
                },
                error: function (xhr, textStatus, errorThrown) {
                    alert(errorThrown);
                    $('#btnSubmitDepositLimit').toggleLoadingSpin(false);
                }
            };
            $('#formDepositLimit').ajaxForm(options);
            $('#formDepositLimit').submit();
        });

        $('#btnChangeDepositLimit').click(function (e) {
            $('#fldDepositLimitCurrency select').attr('disabled', false);
            $('#fldDepositLimitAmount input').attr('readonly', false);
            $('#fldDepositLimitPeriod input').attr('disabled', false);
            $('#btnSubmitDepositLimit').show();
            $('#btnRemoveDepositLimit').hide();
            $(this).hide();
            e.preventDefault();
        });

        $('#btnRemoveDepositLimit').click(function (e) {
            e.preventDefault();

            if (window.confirm('<%= this.GetMetadata(".Confirmation_Message").SafeJavascriptStringEncode() %>') != true) {
                return;
            }

            $(this).toggleLoadingSpin(true);
            var options = {
                dataType: "html",
                type: 'POST',
                url: '<%= this.Url.RouteUrl( "DepositLimitation", new { @action="Remove" } ).SafeJavascriptStringEncode() %>',
                success: function (html) {
                    $('#btnRemoveDepositLimit').toggleLoadingSpin(false);
                    $('#formDepositLimit').parent().html(html);
                },
                error: function (xhr, textStatus, errorThrown) {
                    alert(errorThrown);
                    $('#btnRemoveDepositLimit').toggleLoadingSpin(false);
                }
            };
            $('#formDepositLimit').ajaxForm(options);
            $('#formDepositLimit').submit();
        });
    });
</script>