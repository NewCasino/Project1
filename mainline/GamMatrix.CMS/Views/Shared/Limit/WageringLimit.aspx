<%@ Page Language="C#" PageTemplate="/ProfileMaster.master" Inherits="CM.Web.ViewPageEx<GamMatrixAPI.RgWageringLimitInfoRec>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>" %>

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
            if (this.Model.ExpiryDate.Date == DateTime.MaxValue.Date)
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

        if (!updatedLimit)
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

<asp:content contentplaceholderid="cphHead" runat="Server">
</asp:content>


<asp:content contentplaceholderid="cphMain" runat="Server">
<div id="limit-wrapper" class="content-wrapper">
<%: Html.H1(this.GetMetadata(".HEAD_TEXT")) %>
<ui:Panel runat="server" ID="pnLimit">


<form action="/Limit/SetWageringLimit<%=Request.Url.Query.SafeHtmlEncode() %>" id="formWageringLimit" target="_self" method="post">
    <div id="wagering-limit">
        <p><%= this.GetMetadata(".Introduction").SafeHtmlEncode() %></p>


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
        <%: Html.Hidden("currency", "EUR", new { 
                @id = "txtCurrentVal"
        })%>
        <ui:MinifiedJavascriptControl runat="server" AppendToPageEnd="true" Enabled="true">
        <script type="text/javascript">
        $("input[name='currency']").val($('#ddlCurrency').val());
        function onCurrencyChange() {
            $("input[name='currency']").val($('#ddlCurrency').val());
        }
        </script>
        </ui:MinifiedJavascriptControl>

        <%------------------------------------------
            Amount
         -------------------------------------------%>
        <ui:InputField ID="fldWageringLimitAmount" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	        <LabelPart><%= this.GetMetadata(".Amount_Label").SafeHtmlEncode()%></LabelPart>
	        <ControlPart>
                <%: Html.AnonymousCachedPartial("/Components/Amount", this.ViewData)%>
	        </ControlPart>
        </ui:InputField>

        <ui:MinifiedJavascriptControl runat="server" AppendToPageEnd="true" Enabled="true">
        <script type="text/javascript">
            // <%-- Format the input amount to comma seperated amount --%>
            var pAmount = <%=(this.Model == null) ? "0" : this.Model.Amount.ToString(System.Globalization.CultureInfo.InvariantCulture) %>;
            if(pAmount != 0){
                $('#txtAmount').val(formatAmount(pAmount, true));
                $('#txtAmount').data('fillvalue',pAmount);
                $("input[name='amount']").val(pAmount );
                $('#txtAmount').attr('disabled',true).attr('readonly',true);
            }
            $('#txtAmount').css("text-align","right") ;
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


        <center>
            <ui:Button runat="server" Text="<%$ Metadata:value(.Button_Back) %>" id="btnLimitBack" CssClass="BackButton button" onclick="self.location='/Limit'" type="button"></ui:Button>
            <ui:Button runat="server" Text="<%$ Metadata:value(.Button_Submit) %>" id="btnSubmitWageringLimit" CssClass="ContinueButton button" type="submit"></ui:Button>
            <ui:Button runat="server" Text="<%$ Metadata:value(.Button_Change) %>" id="btnChangeWageringLimit" CssClass="ContinueButton button" type="button"></ui:Button>
            <ui:Button runat="server" Text="<%$ Metadata:value(.Button_Remove) %>" id="btnRemoveWageringLimit" CssClass="ContinueButton button" type="submit"></ui:Button>
        </center>

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
                    $('#txtAmount').attr('disabled', false).attr('readonly', false);
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
    });
</script>
</ui:MinifiedJavascriptControl>
</asp:content>

