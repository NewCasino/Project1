<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<CM.db.cmUser>" %>
<%@ Import Namespace="CM.db" %>
<%@ Import Namespace="GmCore" %>
<script language="C#" type="text/C#" runat="server">
private string GetCountry()
{
    CountryInfo country = CountryManager.GetAllCountries().FirstOrDefault(c => c.InternalID == this.Model.CountryID);
    if (country != null)
        return country.DisplayName;
    return string.Empty;
}

private string GetRegion()
{
    cmRegion region = CountryManager.GetCountryRegions(this.Model.CountryID).FirstOrDefault(r => r.ID == this.Model.RegionID);
    if (region != null)
        return region.GetDisplayName();
    return string.Empty;
}

private SelectList GetCurrencyList()
{
    var list = GamMatrixClient.GetSupportedCurrencies()
                    .FilterForCurrentDomain()
                    .Select(c => new { Key = c.Code, Value = c.GetDisplayName() })
                    .ToList();
    return new SelectList(list
        , "Key"
        , "Value"
        , this.Model.PreferredCurrency
        );
}

private bool isShowContract
{
    get
    {
        if (Profile.IsAuthenticated && Settings.EnableContract)
        {
            var contractRequest = GamMatrixClient.GetUserLicenseLTContractValidityRequest(this.Model.ID);
            if (contractRequest != null && contractRequest.LastLicense != null && contractRequest.LastLicense.ContractExpiryDate > DateTime.Now)
            {
                return true;
            }
        }

        return false;
    }
}

protected override void OnLoad(EventArgs e)
{
    fldAffiliateMarker.Visible = !Settings.DisableUpdateAffiliateCode;
    base.OnLoad(e);
}
</script>

<% using (Html.BeginRouteForm("Profile", new { @action = "UpdateProfile" }, FormMethod.Post, new { @id = "formUpdateProfile" }))
   { %>


<table id="profile_table" cellpadding="0" cellspacing="0" border="0">
    <tr>
        <td valign="top" class="profile_table_col-1">
<%------------------------------------------
    AffiliateMarker
-------------------------------------------%>
<ui:InputField ID="fldAffiliateMarker" runat="server" ShowDefaultIndicator="false" BalloonArrowDirection="Left">
<LabelPart><%= this.GetMetadata(".AffiliateMarker_Label").SafeHtmlEncode() %></LabelPart>
<ControlPart>
	<%: Html.TextBox("affiliateMarker", this.Model.AffiliateMarker , new { 
        @maxlength = 64,
        @id = "txtAffiliateMarker"
    })%>
</ControlPart>
</ui:InputField>

<%------------------------------------------
    Username
 -------------------------------------------%>
<ui:InputField ID="fldUsernameReadonly" runat="server" ShowDefaultIndicator="false" BalloonArrowDirection="Left">
	<LabelPart><%= this.GetMetadata(".Username_Label").SafeHtmlEncode() %></LabelPart>
	<ControlPart>
		<%: Html.TextBox("username", this.Model.Username, new { @readonly = "readonly" })%>
	</ControlPart>
</ui:InputField>

<%------------------------------------------
    User ID
 -------------------------------------------%>
<ui:InputField ID="fldUserIDReadonly" runat="server" ShowDefaultIndicator="false" BalloonArrowDirection="Left">
	<LabelPart><%= this.GetMetadata(".UserID_Label").SafeHtmlEncode() %></LabelPart>
	<ControlPart>
		<%: Html.TextBox("userid", this.Model.ID, new { @readonly = "readonly" })%>
	</ControlPart>
</ui:InputField>


<% Html.RenderPartial("/Register/PersionalInformation", this.Model); %>


<%------------------------------------------
    Email
 -------------------------------------------%>
<ui:InputField ID="fldEmail" runat="server" ShowDefaultIndicator="false" BalloonArrowDirection="Left">
	<LabelPart><%= this.GetMetadata(".Email_Label").SafeHtmlEncode()%></LabelPart>
	<ControlPart>
		<%: Html.TextBox("email", this.Model.Email, new { @readonly = "readonly" })%>
	</ControlPart>
</ui:InputField>


<% Html.RenderPartial("/Register/AdditionalInformation", this.Model); %>

        </td>
        <td valign="top" class="profile_table_col-2"> 
<% Html.RenderPartial("/Register/AddressInformation", this.Model); %>
<% Html.RenderPartial("/Register/AccountInformation", this.Model); %>


        </td>
    </tr>
    <tr>
        <td colspan="2">

        <div class="button-wrapper">
        <%: Html.Button(this.GetMetadata(".Button_Update"), new { @id = "btnUpdateProfile" })%>
        <% if (isShowContract)
        { %>
         <a class="ContractLinkButton button" href="/<%=this.Model.Language %>/GenerateContract.ashx?userid=<%=this.Model.ID %>" target="_blank"><%= this.GetMetadata(".Contract_Link").SafeHtmlEncode()%></a>
        <% } %>
        </div>

        </td>
    </tr>
</table>
<% } // form %>


<ui:MinifiedJavascriptControl runat="server" ID="scriptPersonalID" AppendToPageEnd="true" Enabled="false">
<script type="text/javascript">
$(function () {

    <%-- disable the fields which are not updatable --%>
    <% if (!string.IsNullOrWhiteSpace(this.Model.AffiliateMarker)){%>
    $('#fldAffiliateMarker input').attr('readonly', true);
    <%}%>
<% if ( this.Model.CountryID == 112 )
    { 
        if(!string.IsNullOrWhiteSpace(this.Model.TaxCode))
        {%>
    $('#TaxCode input').attr({readonly:"readonly",id:"readOnly_TaxCode",name:"readOnly_TaxCode"});
    <%  } %>
    $('#TaxCode').show();
<% } %>
<% if( !string.IsNullOrWhiteSpace(this.Model.Title) )
   { %>
   $('#fldTitle select').attr('disabled', true);
<% } %> 
<% if( !string.IsNullOrWhiteSpace(this.Model.FirstName) && !this.Model.FirstName.ContainSpecialCharactors() )
   { %>
   $('#fldFirstName input').attr('readonly', true);
<% } %>
<% if( !string.IsNullOrWhiteSpace(this.Model.Surname) && !this.Model.Surname.ContainSpecialCharactors() )
   { %>
   $('#fldSurname input').attr('readonly', true);
<% } %>
<% if( !string.IsNullOrWhiteSpace(this.Model.Email) )
   { %>
   $('#fldEmail input').attr('readonly', true);
<% } %>
<% if( this.Model.Birth.HasValue )
   { %>
   $('#fldDOB select').attr('disabled', true);
<% } %>
<% if(this.Model.RegionID.HasValue && this.Model.RegionID>0){%>
    $('#fldRegion select').attr('disabled', true);
<% }%>

<% if( this.Model.CountryID > 0 )
   { %>
   $('#fldCountry select').attr('disabled', true);
<% } else{
    if(this.Model.RegionID==null || this.Model.RegionID==0){%>
    $('#fldRegion select').attr('disabled', false);
<%  }
   } %>

    $('#formUpdateProfile').initializeForm();

    $('#btnUpdateProfile').click(function (e) {
        e.preventDefault();

        if (!$('#formUpdateProfile').valid())
            return;


        $(this).toggleLoadingSpin(true);
        var options = {
            dataType: "html",
            type: 'POST',
            success: function (html) {
                $('#btnUpdateProfile').toggleLoadingSpin(false);
                $('#formUpdateProfile').parent().html(html);
            },
            error: function (xhr, textStatus, errorThrown) {
                alert(errorThrown);
                $('#btnUpdateProfile').toggleLoadingSpin(false);
            }
        };
        $('#formUpdateProfile').ajaxForm(options);
        $('#formUpdateProfile').submit();
    });
});
</script>
</ui:MinifiedJavascriptControl>