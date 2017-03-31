<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<CM.db.cmUser>" %>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="GmCore" %>
<script language="C#" type="text/C#" runat="server">
    private SelectList GetPhonePrefixList()
    {
        var list = CountryManager.GetAllPhonePrefix().Select(p => new { Key = p, Value = p }).ToList();
        list.Insert(0, new { Key = string.Empty, Value = this.GetMetadata(".PhonePrefix_Select") });
        string selectedValue = null;
        if (this.Model != null)
        {
            selectedValue = this.Model.PhonePrefix;
        }
        return new SelectList(list, "Key", "Value", selectedValue);
    }

    private SelectList GetRegionList()
    {
        int countryID = 0;
        if (this.Model != null)
        {
            countryID = this.Model.CountryID;
        }

        var regions = CountryManager.GetCountryRegions(countryID)
                    .Select(r => new { @Text = r.GetDisplayName(), @Value = r.ID })
                    .OrderBy(r => r.Text)
                    .ToArray();
        return new SelectList(regions, "Value", "Text", (this.Model != null) ? this.Model.RegionID : null);
    }

    private SelectList GetCountryList()
    {
        var list = CountryManager.GetAllCountries()
                    .Where(c => (c.UserSelectable || this.Model != null) && c.InternalID > 0 )
                    .Select(c => new { Key = c.InternalID.ToString(), Value = c.DisplayName })
                    .OrderBy(c => c.Value)
                    .ToList();
        list.Insert(0, new { Key = "", Value = this.GetMetadata(".Country_Select") });


        object selectedValue = null;


        if (this.Model != null)
            selectedValue = this.Model.CountryID;

        return new SelectList(list
            , "Key"
            , "Value"
            , selectedValue
            );
    }
    private string GetMobile() {
        return (this.Model == null && string.IsNullOrEmpty(Request["mobile"])) ? string.Empty : (this.Model != null ? this.Model.Mobile : Request["mobile"] .ToString());
    }
    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);

        fldPostalCode.ShowDefaultIndicator = Settings.Registration.IsPostalCodeRequired;
    }

    private string GetCountryJson()
    {
        StringBuilder json = new StringBuilder();
        json.AppendLine("var countries = {");
        foreach (CountryInfo countryInfo in CountryManager.GetAllCountries())
        {
            json.AppendFormat(CultureInfo.InvariantCulture, "'{0}':{{PC:'{1}',CC:'{2}'}},"
                , countryInfo.InternalID
                , countryInfo.PhoneCode.SafeJavascriptStringEncode()
                , countryInfo.CurrencyCode.SafeJavascriptStringEncode()
                );
        }
        if (json[json.Length - 1] == ',')
            json.Remove(json.Length - 1, 1);
        json.AppendLine("};");
        return json.ToString();
    }

    private bool IsScriptCountryVisible { get { return this.Model == null || this.Model.CountryID < 1; } }
    private bool IsRegionVisible { get { return this.Model != null || Settings.Registration.IsRegionVisible; } }
    private bool IsAddress1Visible { get { return Settings.Registration.IsAddress1Visible; } }
    private bool IsAddress1Required { get { return Settings.Registration.IsAddress1Required; } }
    private bool IsAddress2Visible { get { return this.Model != null || Settings.Registration.IsAddress2Visible; } }
    private bool IsCityVisible { get { return this.Model != null || Settings.Registration.IsCityVisible; } }
    private bool IsCityRequired { get { return this.Model != null || Settings.Registration.IsCityRequired; } }
    private bool IsPostalCodeVisible { get { return this.Model != null || Settings.Registration.IsPostalCodeVisible; } }
    private bool IsPostalCodeRequired { get { return this.Model != null || Settings.Registration.IsPostalCodeRequired; } }
    private bool IsMobileVisible { get { return this.Model != null || Settings.Registration.IsMobileVisible; } }
    private bool IsMobileRequired { get { return this.Model != null || Settings.Registration.IsMobileRequired; } }
    private bool IsRepeatMobileVisible { get { return  this.Model == null && Settings.Registration.IsRepeatMobileVisible; } }
    private bool IsPhoneVisible { get { return this.Model != null || Settings.Registration.IsPhoneVisible; } }
    private bool IsEnabledDKPopup { get {  return  this.GetMetadata("/Register/_DKVerifyFrame_aspx.EnabledVerifyFrame").DefaultIfNullOrEmpty("No").Equals("yes", StringComparison.InvariantCultureIgnoreCase);} }
    private string CurrentCountryId { get {
            return this.GetMetadata("/Register/_DKVerifyFrame_aspx.CurrentCountryId").DefaultIfNullOrEmpty(Profile.IpCountryID.ToString());
        } }

    private bool IsStreetVisible { get { return Settings.Registration.IsStreetVisible;  } }
    private bool IsStreetRequired {get {return Settings.Registration.IsStreetRequired; }}

    //private bool SafeParseBoolString(string text, bool defValue)
    //{
    //    if (string.IsNullOrWhiteSpace(text))
    //        return defValue;

    //    text = text.Trim();

    //    if (Regex.IsMatch(text, @"(YES)|(ON)|(OK)|(TRUE)|(\1)", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant | RegexOptions.Compiled))
    //        return true;

    //    if (Regex.IsMatch(text, @"(NO)|(OFF)|(FALSE)|(\0)", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant | RegexOptions.Compiled))
    //        return false;

    //    return defValue;
    //}
    protected override void OnPreRender(EventArgs e)
    {
        scriptCountry.Visible = this.IsScriptCountryVisible;
        scriptReqCountry.Visible = !string.IsNullOrEmpty(Request["country"]);

        scriptDKCheck.Visible = Settings.IsDKLicense;
        // dev mode
        //scriptDKCheck.Visible = true;
        fldRegion.Visible = this.IsRegionVisible;
        scriptRegion.Visible = this.IsRegionVisible;

        fldAddress1.Visible = this.IsAddress1Visible;
        fldAddress1.ShowDefaultIndicator = this.IsAddress1Required;
        scriptAddress1.Visible = this.IsAddress1Visible;

        fldStreetName.Visible = this.IsStreetVisible;
        fldStreetName.ShowDefaultIndicator = this.IsStreetRequired;
        scriptStreetName.Visible = this.IsStreetVisible;

        fldStreetNumber.Visible = this.IsStreetVisible;
        fldStreetNumber.ShowDefaultIndicator = this.IsStreetRequired;
        scriptStreetNumber.Visible = this.IsStreetVisible;

        fldAddress2.Visible = this.IsAddress2Visible;

        fldCity.Visible = this.IsCityVisible;
        scriptCity.Visible = this.IsCityVisible;
        fldCity.ShowDefaultIndicator = this.IsCityRequired;

        fldPostalCode.Visible = this.IsPostalCodeVisible;
        scriptPostalCode.Visible = this.IsPostalCodeVisible;
        fldPostalCode.ShowDefaultIndicator = this.IsPostalCodeRequired;

        fldMobile.Visible = this.IsMobileVisible;
        scriptMobile.Visible = this.IsMobileVisible;
        fldMobile.ShowDefaultIndicator = this.IsMobileRequired;
        scriptReqMobile.Visible = !string.IsNullOrEmpty(Request["mobilePrefix"]);

        fldRepeatMobile.Visible = this.IsRepeatMobileVisible;

        fldPhone.Visible = this.IsPhoneVisible;
        scriptPhone.Visible = this.IsPhoneVisible;

        TaxCode.Visible = false; //this.Model == null || this.Model.CountryID == 112 ;
        scriptTaxCode.Visible = false; //this.Model == null || this.Model.CountryID == 112;


        base.OnPreRender(e);
    }
</script>


<%------------------------------------------
    Country_Select 
 -------------------------------------------%>
<ui:InputField ID="fldCountry" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
    <LabelPart><%= this.GetMetadata(".Country_Label").SafeHtmlEncode() %></LabelPart>
    <ControlPart>
        <%: Html.DropDownList("country", GetCountryList(), new
            {
                @id = "ddlCountry",
                @validator = ClientValidators.Create()
                    .Required(this.GetMetadata(".Country_Empty"))
            })%>
    </ControlPart>
</ui:InputField>
<ui:MinifiedJavascriptControl runat="server" ID="scriptDKCheck" AppendToPageEnd="true" Enabled="false">
<script type="text/javascript">
    var isEnabledDKPopup = <%=IsEnabledDKPopup.ToString().ToLower()%>;
    var ipCountryId = <%=CurrentCountryId%>;
    var dkIframeSrc = "/Register/DkVerifyFrame";
    var isForceDKCheck = <%=Settings.IsDKLicense.ToString().ToLower()%>;
    function DKCheck(countryId) {
        //console.log(countryId);
        if(ipCountryId==64 || isForceDKCheck){
            if (countryId == 64 ) {
                if(isEnabledDKPopup)
                    $("#fldHasDKAccount,#fldPersonalID,#fldDOBPlace,#fldUsername,#fldPassword,#fldRepeatPassword,#fldSecurityQuestion,#fldSecurityAnswer").hide();
                $("#fldCPRNumber").show();
            } else  {
                if(isEnabledDKPopup)
                    $("#fldHasDKAccount,#fldUsername,#fldPassword,#fldRepeatPassword,#fldSecurityQuestion,#fldSecurityAnswer").show();
                $("#fldCPRNumber").hide();
                if(  $("#btnHasDKAccount").attr("checked") =="checked")
                    $("#fldDOBPlace").show();
                else
                    $("#fldPersonalID").show();
            }
        }else{
            if (countryId == 64 ) {
                $("#fldDOBPlace,#fldCPRNumber").show();
            }else{
                $("#fldDOBPlace,#fldCPRNumber").hide();            
            }
        }
    }
    function DKCheckPopup() {
        var $iframe = $("<iframe id=\"nemid_iframe\" name=\"nemid_iframe\"  scrolling=\"no\" frameborder=\"0\"  style=\"width:500px;height:450px;border:0\" src=" + dkIframeSrc + " ></iframe>");
        $iframe.modalex($iframe.width(), $iframe.height(), true, top.document.body);
        //$(".simplemodal-close").hide();
    }
    $(document).bind('COUNTRY_SELECTION_CHANGED_DKPOPUPCLOSE', function (e, data) { 
        $.modal.close();
    });
    $(document).bind('COUNTRY_SELECTION_CHANGED_DKCHECK', function (e, data) {
        DKCheck(data);
    });
    $(document).bind('COUNTRY_SELECTION_CHANGED_DKPOPUP', function (e, data) {
        DKCheckPopup();
    });
    </script>
</ui:MinifiedJavascriptControl>
<ui:MinifiedJavascriptControl runat="server" ID="scriptCountry" AppendToPageEnd="true" Enabled="false">
<script type="text/javascript"> 
$(function () {
    $('#ddlCountry').change( function(){
        try{$("#ddlCountry").val(ipCountryId);}catch(err){}
        <%= GetCountryJson() %>
    var country = countries[$(this).val()];
        var params = { ID: $(this).val(), CountryCode:'', PhoneCode:'', LegalAge:18 };
        if( country != null ){
            params.CurrencyCode = country.CC;
            params.PhoneCode = country.PC;
            if(params.ID==74)
                params.LegalAge = 21; ;
            $(document).trigger('COUNTRY_SELECTION_CHANGED_DKCHECK', params.ID);
        }
        $(document).trigger('COUNTRY_SELECTION_CHANGED', params);
    });

    setTimeout( function(){ $('#ddlCountry').trigger('change'); }, 1000);
    $.getJSON( '/Profile/GetIPLocation', function(json){
        if( !json.success || !json.data.found ) return;
        $('#ddlCountry').val( json.data.countryID ).trigger('change');
        if( json.data.isCountryRegistrationBlocked ){
            setTimeout( function(){
                alert('<%= this.GetMetadata("/Register/_CountryBlockedView_ascx.Blocked_Message").SafeJavascriptStringEncode() %>');
            }, 0);            
        }
    }); 
}); 
</script>
</ui:MinifiedJavascriptControl>
<ui:MinifiedJavascriptControl runat="server" ID="scriptReqCountry" AppendToPageEnd="true" Enabled="false">
<script type="text/javascript">
    $(function () { 
        $('#ddlCountry').val('<%=Request["country"].ToString()%>').trigger('change');
    }); 
</script>
</ui:MinifiedJavascriptControl>
 






<%------------------------------------------
    Region / State (The RegionID is not updatable now by GmCore API )
 -------------------------------------------%>
<ui:InputField ID="fldRegion" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left" >
    <LabelPart><%= this.GetMetadata(".Region_Label").SafeHtmlEncode()%></LabelPart>
    <ControlPart>
        <%: Html.DropDownList("regionID", GetRegionList(), new
            {
                @id = "ddlRegion",
                @validator = ClientValidators.Create()
                    .RequiredIf("validateRegion", this.GetMetadata(".Region_Empty"))
            })%>
    </ControlPart>
</ui:InputField>
<ui:MinifiedJavascriptControl runat="server" ID="scriptRegion" AppendToPageEnd="true" Enabled="false">
<script type="text/javascript">
$(function () {
    $('#fldRegion').hide();
    $(document).bind('COUNTRY_SELECTION_CHANGED', function (e, data) {
        $('#ddlRegion').data('countryID', data.ID);
        $('#ddlRegion').empty();
        if (data.ID > 0) {
            var url = '<%= this.Url.RouteUrl( "Register", new { @action = "GetRegionsByCountry" }).SafeJavascriptStringEncode()  %>';
            jQuery.getJSON(url
                , { countryID: data.ID }
                , function (json) {
                    if (!json.success) {
                        //alert(json.error);
                        return;
                    }

                    if (json.countryID == $('#ddlRegion').data('countryID') ) {
                        $('#ddlRegion').empty();
                        if (json.regions.length > 0) {
                            $('<option value=""></option>').appendTo($('#ddlRegion')).text('<%= this.GetMetadata(".Region_Select").SafeJavascriptStringEncode() %>').attr('value', '');
                            for (var i = 0; i < json.regions.length; i++) {
                                var $option = $('<option></option>').appendTo('#ddlRegion');
                                $option.text(json.regions[i].DisplayName).attr('value', json.regions[i].ID);
                            }
                            $('#fldRegion').show();
                            $('#ddlRegion').val('<%= (this.Model == null || !this.Model.RegionID.HasValue)  ? "" : this.Model.RegionID.Value.ToString() %>');
                        }
                        else {
                            $('#fldRegion').hide();
                        }
                    }
                }); <%-- End of getJSON --%> 
        }
        else{
            $('#ddlRegion').empty();
            $('#fldRegion').hide();
        }
    }); <%-- End of COUNTRY_SELECTION_CHANGED --%> 
});

function validateRegion() {
    return $('option', $('#ddlRegion')).length > 0;
}
</script>
</ui:MinifiedJavascriptControl>



<%------------------------------------------
    Address 1
 -------------------------------------------%>
<ui:InputField ID="fldAddress1" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
    <LabelPart><%= this.GetMetadata(".Address1_Label").SafeHtmlEncode() %></LabelPart>
    <ControlPart>
        <%: Html.TextBox( "address1", (this.Model == null) ? string.Empty : this.Model.Address1, new 
        {
            @maxlength = "100",
            @id = "txtAddress1",
            @validator = ClientValidators.Create()
                .RequiredIf( "isAddress1Required", this.GetMetadata(".Address1_Empty"))
                .MinLength( 2, this.GetMetadata(".Address_MinLength"))
        }
            ) %>
    </ControlPart>
</ui:InputField>
<ui:MinifiedJavascriptControl runat="server" ID="scriptAddress1" AppendToPageEnd="true" Enabled="false">
<script type="text/javascript">
function isAddress1Required() {
    return <%= this.IsAddress1Required.ToString().ToLowerInvariant() %>;
}
</script>
</ui:MinifiedJavascriptControl>

<%------------------------------------------
    Street Name
 -------------------------------------------%>
<ui:InputField ID="fldStreetName" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
    <LabelPart><%= this.GetMetadata(".StreetName_Label").SafeHtmlEncode() %></LabelPart>
    <ControlPart>
        <%: Html.TextBox( "streetname", (this.Model == null) ? string.Empty : this.Model.StreetName, new 
        {
            @maxlength = "100",
            @id = "txtStreetName",
            @validator = ClientValidators.Create()
                .RequiredIf( "isStreetNameRequired", this.GetMetadata(".StreetName_Empty"))
                .MinLength( 2, this.GetMetadata(".StreetName_MinLength"))
        }
            ) %>
    </ControlPart>
</ui:InputField>
<ui:MinifiedJavascriptControl runat="server" ID="scriptStreetName" AppendToPageEnd="true" Enabled="false">
<script type="text/javascript">
function isStreetNameRequired() {
    return <%= this.IsStreetRequired.ToString().ToLowerInvariant() %>;
}
</script>
</ui:MinifiedJavascriptControl>

<%------------------------------------------
    Street Number
 -------------------------------------------%>
<ui:InputField ID="fldStreetNumber" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
    <LabelPart><%= this.GetMetadata(".StreetNumber_Label").SafeHtmlEncode() %></LabelPart>
    <ControlPart>
        <%: Html.TextBox( "streetnumber", (this.Model == null) ? string.Empty : this.Model.StreetNumber, new 
        {
            @maxlength = "100",
            @id = "txtStreetNumber",
            @validator = ClientValidators.Create()
                .RequiredIf( "isStreetNumberRequired", this.GetMetadata(".StreetNumber_Empty"))
                .Number(this.GetMetadata(".StreetNumber_Incorrect"))
        }
            ) %>
    </ControlPart>
</ui:InputField>
<ui:MinifiedJavascriptControl runat="server" ID="scriptStreetNumber" AppendToPageEnd="true" Enabled="false">
<script type="text/javascript">
function isStreetNumberRequired() {
    return <%= this.IsStreetRequired.ToString().ToLowerInvariant() %>;
}
</script>
</ui:MinifiedJavascriptControl>

<%------------------------------------------
    Address 2
 -------------------------------------------%>
<ui:InputField ID="fldAddress2" runat="server" BalloonArrowDirection="Left">
    <LabelPart><%= this.GetMetadata(".Address2_Label").SafeHtmlEncode() %></LabelPart>
    <ControlPart>
        <%: Html.TextBox("address2", (this.Model == null) ? string.Empty : this.Model.Address2, new 
        {
            @maxlength = "100",
            @id = "txtAddress2",
            @validator = ClientValidators.Create().MinLength( 2, this.GetMetadata(".Address_MinLength"))
        }
            ) %>
    </ControlPart>
</ui:InputField>

<%------------------------------------------
    City
 -------------------------------------------%>
<ui:InputField ID="fldCity" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
    <LabelPart><%= this.GetMetadata(".City_Label").SafeHtmlEncode() %></LabelPart>
    <ControlPart>
        <%: Html.TextBox("city", (this.Model == null) ? string.Empty : this.Model.City, new 
        {
            @maxlength = "50",
            @id = "txtCity",
            @validator = ClientValidators.Create()
                .RequiredIf( "isCityRequired", this.GetMetadata(".City_Empty"))
                .MinLength(2, this.GetMetadata(".City_MinLength"))
        }
            ) %>
    </ControlPart>
</ui:InputField>
<ui:MinifiedJavascriptControl runat="server" ID="scriptCity" AppendToPageEnd="true" Enabled="false">
<script type="text/javascript">
function isCityRequired() {
    return <%= this.IsCityRequired.ToString().ToLowerInvariant() %>;
}
</script>
</ui:MinifiedJavascriptControl>


<%------------------------------------------
    PostalCode
 -------------------------------------------%>
<ui:InputField ID="fldPostalCode" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
    <LabelPart><%= this.GetMetadata(".PostalCode_Label").SafeHtmlEncode() %></LabelPart>
    <ControlPart>
        <%: Html.TextBox("postalCode", (this.Model == null) ? string.Empty : this.Model.Zip, new {@maxlength = "10",
            @id = "txtPostalCode",
            @validator = ClientValidators.Create().RequiredIf("isPostalCodeRequired", this.GetMetadata(".PostalCode_Empty"))
        }
            ) %>
    </ControlPart>
</ui:InputField>
<ui:MinifiedJavascriptControl runat="server" ID="scriptPostalCode" AppendToPageEnd="true" Enabled="false">
<script type="text/javascript">
function isPostalCodeRequired() {
    return <%= this.IsPostalCodeRequired.ToString().ToLowerInvariant() %>;
}
</script>
</ui:MinifiedJavascriptControl>

<%------------------------------------------
    TaxCode
 -------------------------------------------%>
<ui:InputField ID="TaxCode" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
    <LabelPart><%= this.GetMetadata(".TaxCode_Label").SafeHtmlEncode() %></LabelPart>
    <ControlPart>
        <%: Html.TextBox("taxCode", (this.Model == null) ? string.Empty : this.Model.TaxCode , new 
        { 
            @maxlength = "20",
            @id = "txtTaxCode",
            @validator = ClientValidators.Create().Required(this.GetMetadata(".TaxCode_Empty"))
        }
     ) %>
    </ControlPart>
</ui:InputField>
<ui:MinifiedJavascriptControl runat="server" ID="scriptTaxCode" AppendToPageEnd="true" Enabled="false">
<script type="text/javascript">
    $(function () {
        $(document).bind('COUNTRY_SELECTION_CHANGED', function (e, data) {
            if( data.ID == '112'){ $("#TaxCode").show();}else{$("#TaxCode").hide();}
        });
        $('#TaxCode').hide();
    });
</script>
</ui:MinifiedJavascriptControl>


<%------------------------------------------
    Mobile
 -------------------------------------------%>
<ui:InputField ID="fldMobile" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
    <LabelPart><%= this.GetMetadata(".Mobile_Label").SafeHtmlEncode() %></LabelPart>
    <ControlPart>
        <%: Html.DropDownList( "mobilePrefix", GetPhonePrefixList(), new { @id = "ddlMobilePrefix", @class = "ddlPhonePrefix" })%>
        <%: Html.TextBox("mobile", GetMobile(), new 
        {
            @maxlength = "30",
            @id = "txtMobile",
            @class = "tbPhoneCode",
            @validator = ClientValidators.Create()
                .RequiredIf( "isMobileRequired", this.GetMetadata(".Mobile_Empty"))
                .MinLength(7, this.GetMetadata(".Mobile_Incorrect"))
                .Number(this.GetMetadata(".Mobile_Incorrect"))
                .Custom("validateMobileNumber")
        }
    ) %>
    </ControlPart>
</ui:InputField>
<ui:MinifiedJavascriptControl runat="server" ID="scriptMobile" AppendToPageEnd="true" Enabled="false">
<script type="text/javascript">
$(function () {
    $(document).bind('COUNTRY_SELECTION_CHANGED', function (e, data) {
        if (data.ID > 0)
            $('#ddlMobilePrefix').val(data.PhoneCode);
    });
});

function isMobileRequired() {
    return <%= this.IsMobileRequired.ToString().ToLowerInvariant() %>;
}

function validateMobileNumber() {
    var value = this;
    if (value.length > 0) {
        if( $('#ddlMobilePrefix').val() == '' )
            return '<%= this.GetMetadata(".PhonePrefix_Empty").SafeJavascriptStringEncode() %>';
        <%if (Settings.Registration.DisallowDuplicateMobile) { %>
        return validateMobileUnique();
        <%}%>
    }
    return true;
}
function validateMobileUnique()
{
    var _m_field = $('#txtMobile').parents('.inputfield');
    _m_field.addClass('validating');
    var errorMsg = '';
    var _m_url = '<%=this.Url.RouteUrl("Register", new { @action = "VerifyUniqueMobile" }).SafeJavascriptStringEncode()%>';
    var _m_data = { "mobilePrefix": $('#ddlMobilePrefix').val(), "mobile": $('#txtMobile').val(), "message" : '<%=this.GetMetadata(".Mobile_Exist").SafeJavascriptStringEncode()%>'};
    $.ajax({
        type: "POST",
        async: false,
        url: _m_url,
        cache: false,
        data: _m_data,
        success: function (_json) {
            if (!_json.success)
                errorMsg = _json.error;
        }
    });
    _m_field.removeClass('validating');
    if (errorMsg != '')
        return errorMsg;
    return true;
}
</script>
</ui:MinifiedJavascriptControl>
<ui:MinifiedJavascriptControl runat="server" ID="scriptReqMobile" AppendToPageEnd="true" Enabled="false">
<script type="text/javascript">
    $(function () {        
        $('#ddlMobilePrefix').val('<%=Request["mobilePrefix"].ToString()%>');        
    }); 
</script>
</ui:MinifiedJavascriptControl> 

<%------------------------------------------
    Repeat Mobile
 -------------------------------------------%>
<ui:InputField ID="fldRepeatMobile" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	<LabelPart><%= this.GetMetadata(".RepeatMobile_Label").SafeHtmlEncode()%></LabelPart>
	<ControlPart>
		<%: Html.TextBox("repeatMobile", null, new
        {
            @maxlength = "50",
            @id = "txtRepeatMobile",
            @validator = ClientValidators.Create()
                .EqualTo("#txtMobile", this.GetMetadata(".RepeatMobile_NotMatch"))
        }
        )%>
	</ControlPart>
</ui:InputField>

<%------------------------------------------
    Phone
 -------------------------------------------%>
<ui:InputField ID="fldPhone" runat="server" BalloonArrowDirection="Left">
    <LabelPart><%= this.GetMetadata(".Phone_Label").SafeHtmlEncode() %></LabelPart>
    <ControlPart>
        <%: Html.DropDownList("phonePrefix", GetPhonePrefixList(), new { @id = "ddlPhonePrefix", @class = "ddlPhonePrefix" })%>
        <%: Html.TextBox("phone", (this.Model == null) ? string.Empty : this.Model.Phone, new 
        {
            @maxlength = "30",
            @id = "txtPhone",
            @class = "tbPhoneCode",
            @validator = ClientValidators.Create()
                .MinLength(7, this.GetMetadata(".Phone_Incorrect"))
                .Number(this.GetMetadata(".Phone_Incorrect"))
                .Custom("validatePhoneNumber")
        }
            ) %>
    </ControlPart>
</ui:InputField>
<ui:MinifiedJavascriptControl runat="server" ID="scriptPhone" AppendToPageEnd="true" Enabled="false">
<script type="text/javascript">
$(function () {
    $(document).bind('COUNTRY_SELECTION_CHANGED', function (e, data) {
        if (data.ID > 0)
            $('#ddlPhonePrefix').val(data.PhoneCode);
    });
});

function validatePhoneNumber() {
    var value = this;
    if (value.length > 0) {
        if ($('#ddlPhonePrefix').val() == '')
            return '<%= this.GetMetadata(".PhonePrefix_Empty").SafeJavascriptStringEncode() %>';
    }
    return true;
}
</script>
</ui:MinifiedJavascriptControl>

