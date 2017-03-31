<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<CM.db.cmUser>" %>
<%@ Import Namespace="CM.db" %>

<script type="text/C#" runat="server">
	private string GetFormattedBirth()
	{
		if (Model.Birth == null)
			return string.Empty;
		
		return String.Format(
			"{0}-{1:00}-{2:00}",
			this.Model.Birth.Value.Year,
			this.Model.Birth.Value.Month,
			this.Model.Birth.Value.Day
		);
	}

	private string GetFormattedMobile()
	{
		if (!String.IsNullOrEmpty(this.Model.Mobile))
			return "(" + this.Model.MobilePrefix + ")" + this.Model.Mobile;
		return String.Empty;
	}

	private string GetFormattedPhone()
	{
		if (!String.IsNullOrEmpty(this.Model.Phone))
			return "(" + this.Model.PhonePrefix + ")" + this.Model.Phone;
		return String.Empty;
	}
	
	private string GetCountryName()
	{
		CountryInfo country = CountryManager.GetAllCountries().FirstOrDefault(c => c.InternalID == this.Model.CountryID);
		if (country != null)
			return country.DisplayName;
		return String.Empty;
	}

	private string GetRegionName()
	{
		cmRegion region = CountryManager.GetCountryRegions(this.Model.CountryID).FirstOrDefault(r => r.ID == this.Model.RegionID);
		if (region != null)
			return region.RegionName;
		return String.Empty;
	}
	private string GetLanguageName()
	{
		LanguageInfo language = SiteManager.Current.GetSupporttedLanguages().FirstOrDefault(l => l.LanguageCode == this.Model.Language);
		if (language != null)
			return language.DisplayName;
		return String.Empty;
	}

	private bool IsSecondFactorAuthenticationEnabled
	{
	    get 
	    {
	        return Settings.Session.SecondFactorAuthenticationEnabled;
	    }
	}
</script>

<div class="MenuList L DetailContainer">
	<ol class="SideMenuList DetailPairs ProfileList <% if (Settings.MobileV2.IsV2ProfileEnabled) { %> ProfileList_V2 <% } %>">
		<li class="ProfileItem ProfileView-Username">
			<div class="ProfileDetail">
				<span class="DetailName"><%= this.GetMetadata(".Username_Label").SafeHtmlEncode()%></span> <span class="DetailValue"><%= this.Model.Username.SafeHtmlEncode()%></span>
			</div>
		</li>
		<li class="ProfileItem ProfileView-UserID">
			<div class="ProfileDetail">
				<span class="DetailName"><%= this.GetMetadata(".UserID_Label").SafeHtmlEncode()%></span> <span class="DetailValue"><%= this.Model.ID%></span>
			</div>
		</li>
		<li class="ProfileItem ProfileView-Title">
			<div class="ProfileDetail">
				<span class="DetailName"><%= this.GetMetadata(".Title_Label").SafeHtmlEncode()%></span> <span class="DetailValue"><%= this.Model.Title.SafeHtmlEncode()%></span>
			</div>
		</li>
		<li class="ProfileItem ProfileView-Firstname">
			<div class="ProfileDetail">
				<span class="DetailName"><%= this.GetMetadata(".Firstname_Label").SafeHtmlEncode()%></span> <span class="DetailValue"><%= this.Model.FirstName.SafeHtmlEncode()%></span>
			</div>
		</li>
		<li class="ProfileItem ProfileView-Surname">
			<div class="ProfileDetail">
				<span class="DetailName"><%= this.GetMetadata(".Surname_Label").SafeHtmlEncode()%></span> <span class="DetailValue"><%= this.Model.Surname.SafeHtmlEncode() %></span>
			</div>
		</li>
		<li class="ProfileItem ProfileView-Currency">
			<div class="ProfileDetail">
				<span class="DetailName"><%= this.GetMetadata(".Currency_Label").SafeHtmlEncode()%></span> <span class="DetailValue"><%= this.Model.Currency.SafeHtmlEncode() %></span>
			</div>
		</li>
		<li class="ProfileItem ProfileView-Email">
			<div class="ProfileDetail">
				<span class="DetailName"><%= this.GetMetadata(".Email_Label").SafeHtmlEncode()%></span> <span class="DetailValue"><%= this.Model.Email.SafeHtmlEncode() %></span>
			</div>
		</li>
		<li class="ProfileItem ProfileView-DOB">
			<div class="ProfileDetail">
				<span class="DetailName"><%= this.GetMetadata(".DOB_Label").SafeHtmlEncode()%></span> <span class="DetailValue"><%= GetFormattedBirth()%></span>
			</div>
		</li>
		<li class="ProfileItem ProfileView-Country">
			<div class="ProfileDetail">
				<span class="DetailName"><%= this.GetMetadata(".Country_Label").SafeHtmlEncode()%></span> <span class="DetailValue"><%= GetCountryName().SafeHtmlEncode()%></span>
			</div>
		</li>
		<li class="ProfileItem ProfileView-Region">
			<div class="ProfileDetail">
				<span class="DetailName"><%= this.GetMetadata(".Region_Label").SafeHtmlEncode()%></span> <span class="DetailValue"><%= GetRegionName().SafeHtmlEncode()%></span>
			</div>
		</li>
		<li class="ProfileItem ProfileView-Address1">
			<div class="ProfileDetail">
				<span class="DetailName"><%= this.GetMetadata(".Address1_Label").SafeHtmlEncode()%></span> <span class="DetailValue"><%= this.Model.Address1.SafeHtmlEncode() %></span>
			</div>
		</li>
		<li class="ProfileItem ProfileView-Address2">
			<div class="ProfileDetail">
				<span class="DetailName"><%= this.GetMetadata(".Address2_Label").SafeHtmlEncode()%></span> <span class="DetailValue"><%= this.Model.Address2.SafeHtmlEncode() %></span>
			</div>
		</li>
		<li class="ProfileItem ProfileView-City">
			<div class="ProfileDetail">
				<span class="DetailName"><%= this.GetMetadata(".City_Label").SafeHtmlEncode()%></span> <span class="DetailValue"><%= this.Model.City.SafeHtmlEncode() %></span>
			</div>
		</li>
		<li class="ProfileItem ProfileView-PostalCode">
			<div class="ProfileDetail">
				<span class="DetailName"><%= this.GetMetadata(".PostalCode_Label").SafeHtmlEncode()%></span> <span class="DetailValue"><%= this.Model.Zip.SafeHtmlEncode() %></span>
			</div>
		</li>
		<li class="ProfileItem ProfileView-Mobile">
			<div class="ProfileDetail">
				<span class="DetailName"><%= this.GetMetadata(".Mobile_Label").SafeHtmlEncode()%></span> <span class="DetailValue"><%= GetFormattedMobile()%></span>
			</div>
		</li>
		<li class="ProfileItem ProfileView-Phone">
			<div class="ProfileDetail">
				<span class="DetailName"><%= this.GetMetadata(".Phone_Label").SafeHtmlEncode()%></span> <span class="DetailValue"><%= GetFormattedPhone()%></span>
			</div>
		</li>
		<li class="ProfileItem ProfileView-SecurityQuestion">
			<div class="ProfileDetail">
				<span class="DetailName"><%= this.GetMetadata(".SecurityQuestion_Label").SafeHtmlEncode()%></span> <span class="DetailValue"><%= this.Model.SecurityQuestion.SafeHtmlEncode()%></span>
			</div>
		</li>
		<li class="ProfileItem ProfileView-SecurityAnswer">
			<div class="ProfileDetail">
				<span class="DetailName"><%= this.GetMetadata(".SecurityAnswer_Label").SafeHtmlEncode()%></span> <span class="DetailValue"><%= this.Model.SecurityAnswer.SafeHtmlEncode()%></span>
			</div>
		</li>
		<li class="ProfileItem ProfileView-Language">
			<div class="ProfileDetail">
				<span class="DetailName"><%= this.GetMetadata(".Language_Label").SafeHtmlEncode()%></span> <span class="DetailValue"><%= GetLanguageName().SafeHtmlEncode()%></span>
			</div>
		</li>
		<li class="ProfileItem ProfileView-NewsOffers">
			<div class="ProfileDetail">
				<span class="DetailName"><%= this.GetMetadata(".NewsOffers_Label").SafeHtmlEncode()%></span> <span class="DetailValue"><%= this.GetMetadata(string.Format(".Option_{0}", Model.AllowNewsEmail ? "Yes" : "No")).SafeHtmlEncode()%></span>
			</div>
		</li>
		<li class="ProfileItem ProfileView-SmsOffers">
			<div class="ProfileDetail">
				<span class="DetailName"><%= this.GetMetadata(".SmsOffers_Label").SafeHtmlEncode()%></span> <span class="DetailValue"><%= this.GetMetadata(string.Format(".Option_{0}", Model.AllowSmsOffer ? "Yes" : "No")).SafeHtmlEncode()%></span>
			</div>
		</li>
	</ol>

	<div class="AccountButtonContainer ProfileBTNs">
		<a href="<%= Url.RouteUrl("ChangeEmail", new { @action = "Index" }, Request.Url.Scheme)%>" class="Button AccountButton ProfileBTN ChangeEmailBTN"> 
            <span class="ButtonIcon ProfileIcon icon-pencil"> </span>
            <strong class="ButtonText"><%= this.GetMetadata(".Button_ChangeEmail").SafeHtmlEncode()%></strong> 
		</a>
	
		<a href="<%= Url.RouteUrl("Profile", new{ @action = "Edit" }, Request.Url.Scheme) %>" class="Button AccountButton ProfileBTN UpdateProfileBTN"> 
            <span class="ButtonIcon ProfileIcon icon-user-add"> </span>
            <strong class="ButtonText"><%= this.GetMetadata(".Button_Update").SafeHtmlEncode()%></strong> 
		</a>

		<a href="javascript:void(0);" class="Button AccountButton ProfileBTN ResetSecondFactorVerifiedBTN"> 
            <span class="ButtonIcon ProfileIcon icon-user-add"> </span>
            <strong class="ButtonText"><%= this.GetMetadata(".Button_ResetSecondFactorVerified").SafeHtmlEncode()%></strong> 
		</a>
		<span class="FormHelp FormError" id="ResetSecondFactorVerifiedMessage" style="position:relative;width:auto;"></span>
	</div>
	<script type="text/javascript">
	<%if (IsSecondFactorAuthenticationEnabled) { %>
    $('.ResetSecondFactorVerifiedBTN').click(function(e) {
        e.preventDefault();
        $('#ResetSecondFactorVerifiedMessage').hide();
        var _self = $(this);
        $.post('<%= this.Url.RouteUrl("Profile", new { @action = "ResetSecondFactorVerified" }).SafeJavascriptStringEncode() %>',
        { userID: '<%=this.Model.ID%>' },
        function (json) {
            if (json.success) {
                var hasSmartphone_cookie_name = 'hsp_<%=this.Model.Username.ToLowerInvariant() %>';console.log(hasSmartphone_cookie_name);
                $.cookie(hasSmartphone_cookie_name, null, {path: '/'});
                $('#ResetSecondFactorVerifiedMessage').html('<%=this.GetMetadata(".ResetSecondFactor_Success").SafeJavascriptStringEncode() %>').css('background', '#0ab330').show();
            }
            else {
                $('#ResetSecondFactorVerifiedMessage').html(json.error).css('background', '#af0000').show();
            }
        }, 'json').error(function () {
        });
    });
    <% } %>
	</script>
</div>