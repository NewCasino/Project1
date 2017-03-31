<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<GamMatrix.CMS.Models.MobileShared.Components.ProfileAddressInputViewModel>" %>
<%@ Import Namespace="System.Globalization" %>

<script type="text/C#" runat="server">
protected override void OnPreRender(EventArgs e)
{
fldCountry.Visible = Model.InputSettings.IsCountryVisible;
scriptCountry.Visible = Model.InputSettings.IsCountryVisible;

fldMobile.Visible = Model.InputSettings.IsMobileVisible;
scriptMobile.Visible = Model.InputSettings.IsMobileVisible;

fldAddress1.Visible = Model.InputSettings.IsAddress1Visible;
scriptAddress1.Visible = Model.InputSettings.IsAddress1Visible;

fldAddress2.Visible = Model.InputSettings.IsAddress2Visible;

fldCity.Visible = Model.InputSettings.IsCityVisible;
scriptCity.Visible = Model.InputSettings.IsCityVisible;

fldPostalCode.Visible = Model.InputSettings.IsPostalCodeVisible;
scriptPostalCode.Visible = Model.InputSettings.IsPostalCodeVisible;

base.OnPreRender(e);
}
</script>

<ul class="FormList">
<%------------------------------------------
        Country
        -------------------------------------------%>
<li class="FormItem" id="fldCountry" runat="server">
<label class="FormLabel" for="registerCountry"><%= this.GetMetadata(".Country_Label").SafeHtmlEncode()%></label>

<%: Html.DropDownList("country", this.Model.GetCountrySelect(this.GetMetadata(".Country_Select")), new Dictionary<string, object>()
        { 
            { "class", "FormInput" },
            { "id", "registerCountry" },
            { "required", "required" },
            { "data-validator", ClientValidators.Create().Required(this.GetMetadata(".Country_Empty")) }
})%>
<span class="FormStatus">Status</span>
<span class="FormHelp"></span>
</li>
    <ui:MinifiedJavascriptControl ID="scriptCountry" runat="server" Enabled="true" AppendToPageEnd="true" EnableObfuscation="true">
    <script type="text/javascript">
        $(function () {
var input = $('#registerCountry'),
map = <%= this.Model.GetCountryJSON() %>;

setTimeout(function(){
if (input.val())
 trigger();
}, 100);

            input.change(trigger);

function trigger(){
$(document).trigger('COUNTRY_SELECTION_CHANGED', map[input.val()]);
}

            //<%-- preselect the country by IP --%>
            $.getJSON( '/Profile/GetIPLocation', function(json){
                if( !json.success || !json.data.found ) return;
                $('#registerCountry').val( json.data.countryID ).trigger('change');
                if( json.data.isCountryRegistrationBlocked ){
                    self.location = '<%= this.Url.RouteUrl( "Register", new { @action = "CountryBlocked" }).SafeJavascriptStringEncode()  %>';
                }
            });
        });
        </script>
    </ui:MinifiedJavascriptControl>

<%------------------------------------------
        Address Line 1
        -------------------------------------------%>
<li class="FormItem" id="fldAddress1" runat="server">
<label class="FormLabel" for="registerAddress1"><%= this.GetMetadata(".Address1_Label").SafeHtmlEncode()%></label>
        <%: Html.TextBox("address1", Model.InputSettings.Address1, new Dictionary<string, object>()  
        { 
            { "class", "FormInput" },
            { "id", "registerAddress1" },
            { "maxlength", "100" },
            { "placeholder", this.GetMetadata(".Address_Choose") },
            { "required", "required" },
            { "data-validator", ClientValidators.Create()
.RequiredIf( "isAddress1Required", this.GetMetadata(".Address1_Empty"))
.MinLength(2, this.GetMetadata(".Address_MinLength").SafeHtmlEncode()) }
        }) %>
<span class="FormStatus">Status</span>
<span class="FormHelp"></span>
</li>
<ui:MinifiedJavascriptControl runat="server" ID="scriptAddress1" AppendToPageEnd="true" Enabled="false">
<script type="text/javascript">
function isAddress1Required() {
return <%= this.Model.InputSettings.IsAddress1Required.ToString().ToLowerInvariant() %>;
}
</script>
</ui:MinifiedJavascriptControl>

    <%------------------------------------------
        Street Name
        -------------------------------------------%>
<li class="FormItem" id="fldStreetName" runat="server">
<label class="FormLabel" for="registerStreetName"><%= this.GetMetadata(".StreetName_Label").SafeHtmlEncode()%></label>
        <%: Html.TextBox("streetname", Model.InputSettings.StreetName, new Dictionary<string, object>()  
        { 
            { "class", "FormInput" },
            { "id", "registerStreetName" },
            { "maxlength", "100" },
            { "placeholder", this.GetMetadata(".StreetName_Choose") },
            { "required", "required" },
            { "data-validator", ClientValidators.Create()
.RequiredIf( "isStreetRequired", this.GetMetadata(".StreetName_Empty"))
.MinLength(2, this.GetMetadata(".StreetName_MinLength").SafeHtmlEncode()) }
        }) %>
<span class="FormStatus">Status</span>
<span class="FormHelp"></span>
</li>
<ui:MinifiedJavascriptControl runat="server" ID="scriptStreetName" AppendToPageEnd="true" Enabled="false">
<script type="text/javascript">
    function isStreetRequired() {
        return <%= this.Model.InputSettings.IsStreetRequired.ToString().ToLowerInvariant() %>;
}
</script>
</ui:MinifiedJavascriptControl>

    <%------------------------------------------
        Street Number
        -------------------------------------------%>
<li class="FormItem" id="fldStreetNumber" runat="server">
<label class="FormLabel" for="registerStreetNumber"><%= this.GetMetadata(".StreetNumber_Label").SafeHtmlEncode()%></label>
        <%: Html.TextBox("streetname", Model.InputSettings.StreetNumber, new Dictionary<string, object>()  
        { 
            { "class", "FormInput" },
            { "id", "registerStreetNumber" },
            { "maxlength", "100" },
            { "placeholder", this.GetMetadata(".StreetNumber_Choose") },
            { "required", "required" },
            { "data-validator", ClientValidators.Create()
.RequiredIf( "isStreetRequired", this.GetMetadata(".StreetNumber_Empty"))
.Number(this.GetMetadata(".StreetNumber_Incorrect")) }
        }) %>
<span class="FormStatus">Status</span>
<span class="FormHelp"></span>
</li>
<ui:MinifiedJavascriptControl runat="server" ID="scriptStreetNumber" AppendToPageEnd="true" Enabled="false">
<script type="text/javascript">
    function isStreetRequired() {
        return <%= this.Model.InputSettings.IsStreetRequired.ToString().ToLowerInvariant() %>;
    }
</script>
</ui:MinifiedJavascriptControl>

<%------------------------------------------
        Address Line 2
        -------------------------------------------%>
<li class="FormItem" id="fldAddress2" runat="server">
<label class="FormLabel" for="registerAddress2"><%= this.GetMetadata(".Address2_Label").SafeHtmlEncode()%></label>
        <%: Html.TextBox("address2", Model.InputSettings.Address2, new Dictionary<string, object>()  
        { 
            { "class", "FormInput" },
            { "id", "registerAddress2" },
            { "placeholder", this.GetMetadata(".Address_Choose") }
        }) %>
<span class="FormStatus">Status</span>
<span class="FormHelp"></span>
</li>

    <%------------------------------------------
        City
        -------------------------------------------%>
<li class="FormItem" id="fldCity" runat="server">
<label class="FormLabel" for="registerCity"><%= this.GetMetadata(".City_Label").SafeHtmlEncode()%></label>
        <%: Html.TextBox("city", Model.InputSettings.City, new Dictionary<string, object>()  
        { 
            { "class", "FormInput" },
            { "id", "registerCity" },
            { "placeholder", this.GetMetadata(".City_Choose") },
            { "data-validator", ClientValidators.Create()
.RequiredIf( "isCityRequired", this.GetMetadata(".City_Empty"))
.MinLength(2, this.GetMetadata(".City_MinLength").SafeHtmlEncode()) }
        }) %>
<span class="FormStatus">Status</span>
<span class="FormHelp"></span>
</li>
    <ui:MinifiedJavascriptControl runat="server" ID="scriptCity" AppendToPageEnd="true" Enabled="false">
<script type="text/javascript">
function isCityRequired() {
return <%= this.Model.InputSettings.IsCityRequired.ToString().ToLowerInvariant() %>;
}
</script>
    </ui:MinifiedJavascriptControl>

    <%------------------------------------------
        Postal code
        -------------------------------------------%>
<li class="FormItem" id="fldPostalCode" runat="server">
<label class="FormLabel" for="registerPostalCode"><%= this.GetMetadata(".PostalCode_Label").SafeHtmlEncode()%></label>
        <%: Html.TextBox("postalCode", Model.InputSettings.Zip, new Dictionary<string, object>()  
        { 
            { "class", "FormInput" },
                    { "maxlength", "10" },
            { "id", "registerPostalCode" },
            { "placeholder", this.GetMetadata(".PostalCode_Choose") },
            { "data-validator", ClientValidators.Create()
.RequiredIf( "isPostalCodeRequired", this.GetMetadata(".PostalCode_Empty")) }
        }) %>
<span class="FormStatus">Status</span>
<span class="FormHelp"></span>
</li>
    <ui:MinifiedJavascriptControl runat="server" ID="scriptPostalCode" AppendToPageEnd="true" Enabled="false">
<script type="text/javascript">
function isPostalCodeRequired() {
return <%= this.Model.InputSettings.IsPostalCodeRequired.ToString().ToLowerInvariant() %>;
}
</script>
    </ui:MinifiedJavascriptControl>

<%------------------------------------------
        Mobile
        -------------------------------------------%>
<li class="FormItem" id="fldMobile" runat="server">
<label class="FormLabel" for="registerMobile"><%= this.GetMetadata(".Mobile_Label").SafeHtmlEncode()%></label>
<ol class="CompositeInput PhoneInput">
<li class="Col CPIPrefix">
<%: Html.DropDownList("mobilePrefix", this.Model.GetMobilePrefixList(this.GetMetadata(".PhonePrefix_Select")), new Dictionary<string, object>()
                { 
                    { "class", "FormInput" },
                    { "id", "registerMobilePrefix" },
                    { "required", "required" },
                    { "data-validator", ClientValidators.Create()
.RequiredIf( "isMobileRequired",this.GetMetadata(".PhonePrefix_Empty")) }

                })%>
</li>
<li class="Col CPINumber">
<%: Html.TextBox("mobile", Model.InputSettings.Mobile, new Dictionary<string, object>()
                { 
                    { "class", "FormInput" },
                    { "id", "registerMobile" },
                    { "required", "required" },
{ "type", "text" },
                    { "maxlength", "30" },
                    { "placeholder", this.GetMetadata(".Mobile_Choose") },
                    { "data-validator", ClientValidators.Create()
.RequiredIf( "isMobileRequired", this.GetMetadata(".Mobile_Empty"))
.Digits(this.GetMetadata(".Mobile_Incorrect"))
.Custom("validateRegistrationMobile")
.Rangelength(7, 30, this.GetMetadata(".Mobile_Incorrect").SafeHtmlEncode()) }
}) %>
</li>
</ol>
<span class="FormStatus">Status</span>
<span class="FormHelp"></span>
</li>

<ui:MinifiedJavascriptControl ID="scriptMobile" runat="server" Enabled="true" AppendToPageEnd="true" EnableObfuscation="true">
<script type="text/javascript">
$(function () {
new CMS.views.RestrictedInput('#registerMobile', CMS.views.RestrictedInput.digits);

$(document).bind('COUNTRY_SELECTION_CHANGED', function (el, data) {
console.log(data);
$('#registerMobilePrefix').val(data.p);
});
});

function isMobileRequired() {
return <%= this.Model.InputSettings.IsMobileRequired.ToString().ToLowerInvariant() %>;
}

function validateRegistrationMobile() {
if ( $('#registerMobile').val() != '' && $('#registerMobilePrefix').val() == '')
return '<%= this.GetMetadata(".PhonePrefix_Empty").SafeJavascriptStringEncode() %>';

return true;
}
</script>
</ui:MinifiedJavascriptControl>
</ul>