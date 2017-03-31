<%@ Page Language="C#" PageTemplate="/RootMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="CM.db" %>
<%@ Import Namespace="CM.db.Accessor" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GmCore" %>

<script language="C#" type="text/C#" runat="server">
    private string html { get; set; }

    private string GetCountry(int countryId)
    {
        CountryInfo country = CountryManager.GetAllCountries().FirstOrDefault(c => c.InternalID == countryId);
        if (country != null)
            return country.DisplayName;
        return string.Empty;
    }

    protected override void OnInit(EventArgs e)
    {
        cmUser user = null;
        GetUserLicenseLTContractValidityRequest _contract = null;
        string signingDate = DateTime.Now.ToString("dd/MM/yyyy"), expiryDate = string.Empty;
        if (!string.IsNullOrEmpty(Request.QueryString["userid"]))
        {
            long userId = -1L;
            long.TryParse(Request.QueryString["userid"], out userId);

            UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
            user = ua.GetByID(userId);
            
            _contract = GamMatrixClient.GetUserLicenseLTContractValidityRequest(userId);
            if (_contract != null && _contract.LastLicense != null)
            {
                signingDate = _contract.LastLicense.ContractSigningDate.ToString("dd/MM/yyyy");
                expiryDate = _contract.LastLicense.ContractExpiryDate.ToString("dd/MM/yyyy");
            }
        }

        /*if (_contract == null && !string.IsNullOrEmpty(Request.QueryString["contractValidity"]))
        {
            LicenseLTContractValidity licenseContractValidity = LicenseLTContractValidity.Unlimited;
            Enum.TryParse<LicenseLTContractValidity>(Request.QueryString["contractValidity"], out licenseContractValidity);
            switch (licenseContractValidity)
            {
                case LicenseLTContractValidity.Unlimited:
                    expiryDate = Metadata.Get(string.Format("/Metadata/ContractValidity/{0}.Text", licenseContractValidity));
                    break;
                case LicenseLTContractValidity.OneYear:
                    expiryDate = DateTime.Now.AddYears(1).ToString("dd/MM/yyyy");
                    break;
                case LicenseLTContractValidity.TwoYears:
                    expiryDate = DateTime.Now.AddYears(2).ToString("dd/MM/yyyy");
                    break;
                default:
                    expiryDate = string.Empty;
                    break;
            }
        }*/

        html = this.GetMetadata(".Html").Replace("[userID]", user != null ? user.ID.ToString() : "[userID]")
            .Replace("[SIGNING DATE]", signingDate)
            .Replace("[Name]", user != null ? user.FirstName : "[Name]")
            .Replace("[Surname]", user != null ? user.Surname : "[Surname]")
            .Replace("[Zip]", user != null ? user.Zip : "[Zip]")
            .Replace("[Birthdate]", user != null ? (user.Birth.HasValue ? user.Birth.Value.ToString("dd/MM/yyyy") : "[Birthdate]") : "[Birth Date]")
            .Replace("[Address]", user != null ? user.Address1 : "[Address]")
            .Replace("[City]", user != null ? user.City : "[City]")
            .Replace("[Country]", user != null ? GetCountry(user.CountryID) : "[Country]")
            .Replace("[Phone]", user != null ? string.Format("{0}-{1}", user.MobilePrefix, user.Mobile) : "[Phone]");
        
        base.OnInit(e);
    }
</script>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
<style type="text/css">
.contract_head{line-height: 30px; font-size: 16px;}
.contract_title {font-size: 28px; text-align: center; font-weight: bold; margin: 0.5em 0;}
.contract_subtitle {margin-bottom: 1em; font-size: 16px; text-align: center; }
.contract_body{line-height: 20px;}
.Bullet {margin-right: 15px; }
.contract_foot {font-size: 20px; font-weight: bold; line-height: 30px; margin: 0.5em 0 0 2em; }
.contract_sign{font-weight: normal; font-style: italic; }
</style>
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
    <%=html.HtmlEncodeSpecialCharactors() %>
</asp:Content>

