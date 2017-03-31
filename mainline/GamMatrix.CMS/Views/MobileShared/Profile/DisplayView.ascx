<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<CM.db.cmUser>" %>
<%@ Import Namespace="CM.db" %>
<%@ Import Namespace="GmCore"  %>

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

	private string Passport
    {
        get 
        {
            if (Profile.IsAuthenticated && this.Model.PassportID > 0) 
            {
                var resp = GamMatrixClient.GetUserImageRequest(Profile.UserID, this.Model.PassportID);
                if (resp != null && resp.Image != null)
                {
                    return string.Format("data:{0};base64,{1}", resp.Image.ImageContentType, Convert.ToBase64String(resp.Image.ImageFile));
                }
                else
                {
                    return string.Empty;
                }
            } 
            else 
            {
                return string.Empty;
            }
        }
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
		<% if (Settings.Registration.IsPassportVisible)
        { %> 
		<li class="ProfileItem ProfileView-Passport">
			<div class="ProfileDetail">
				<span class="DetailName"><%= this.GetMetadata(".Passport_Label").SafeHtmlEncode() %></span> <span class="DetailValue"></span>
                <div class="PassportBox">
                <div class="PassportImage"><%= !string.IsNullOrEmpty(this.Passport) ? string.Format("<img src='{0}' />", this.Passport) : string.Empty %></div>
                </div>
			</div>
		</li>
        <% } %>
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
        <% if (isShowContract)
        { %>
        <a href="/<%=this.Model.Language %>/GenerateContract.ashx?userid=<%=this.Model.ID %>" class="Button AccountButton ProfileBTN ContractBTN"> 
            <span class="ButtonIcon ProfileIcon icon-user-contract"> </span>
            <strong class="ButtonText"><%= this.GetMetadata(".Button_Contract").SafeHtmlEncode()%></strong> 
		</a>
        <% } %>
	</div>
</div>