<%@ Page Language="C#" PageTemplate="/RootMaster.master" Inherits="CM.Web.ViewPageEx<GamMatrixAPI.PrepareTransRequest>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="Finance" %>
<%@ Import Namespace="CM.db" %>
<%@ Import Namespace="CM.db.Accessor" %>
<script language="C#" type="text/C#" runat="server">
    private string GetIntro()
    {
        if (this.Model == null)
            return string.Empty;
        return this.GetMetadataEx(".Intro"
            , MoneyHelper.FormatWithCurrency(this.Model.Record.CreditCurrency, this.Model.Record.CreditAmount)
            , this.GetMetadata("/Metadata/Settings.Operator_DisplayName")
            );
    }

    private string GetStep3()
    {
        return this.GetMetadataEx(".Step3", this.GetMetadata("/Metadata/Settings.Operator_DisplayName") );
    }

    public string GetTimestamp()
    {
        DateTime now = DateTime.Now;
        return string.Format("{0:0000}{1:00}{2:00}{3:00}{4:00}{5:00}"
            , now.Year
            , now.Month
            , now.Day
            , now.Hour
            , now.Minute
            , now.Second
            );
    }

    public string ConvertToJavaLanguageCode(string code)
    {
        switch (code.ToLowerInvariant())
        {
            case "en":
            case "en-gb":
            case "en-us":
            case "en-uk":
                return "en_GB";

            case "zh":
            case "zh-cn":
                return "zh_CN";

            case "fr":
                return "fr_FR";

            case "he":
                return "iw_IL";

            case "it":
                return "it_IT";

            case "pt":
                return "pt_BR";

            case "es":
                return "es_ES";

            case "de":
                return "de_DE";

            case "el":
                return "el_GR";

            case "pl":
                return "pl_PL";

            case "cs":
                return "cs_CZ";

            case "ru":
                return "ru_RU";

            default:
                return code;
        }
    }
</script>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
<link rel="stylesheet" type="text/css" href="//cdn.everymatrix.com/Generic/entropay.css" />
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">

<div id="entropay">
    <div class="title"><%= this.GetMetadata(".Title").SafeHtmlEncode() %></div>
    <div class="intro"><%= GetIntro().HtmlEncodeSpecialCharactors()%></div>

    
    <div class="steps">
        <div class="how-it-works"><%= this.GetMetadata(".How_It_Works").SafeHtmlEncode() %></div>
        <div class="step">
            <div class="icon"><span>1</span></div>
            <div class="desc"><%= this.GetMetadata(".Step1").HtmlEncodeSpecialCharactors() %></div>
        </div>
        <div class="step">
            <div class="icon"><span>2</span></div>
            <div class="desc"><%= this.GetMetadata(".Step2").HtmlEncodeSpecialCharactors() %></div>
        </div>
        <div class="step">
            <div class="icon"><span>3</span></div>
            <div class="desc"><%= GetStep3().HtmlEncodeSpecialCharactors()%></div>
        </div>
    </div>

    <div class="safe-way">
        <%= this.GetMetadata(".Safe_Way").SafeHtmlEncode() %>
    </div>
    <div class="already_entropay_user">
        <strong><%= this.GetMetadata(".Already_EntroPay_User").SafeHtmlEncode()%></strong>
        <a href="<%= this.Url.RouteUrl("Deposit", new { @action = "Prepare", @paymentMethodName = "PT_EntroPay" }).SafeHtmlEncode() %>" target="_top"><%= this.GetMetadata(".Click_Here").SafeHtmlEncode()%></a>
    </div>
    
    
<form id="formRegisterEntroPay" method="post" enctype="application/x-www-form-urlencoded" action="<%= Settings.EntroPay_RegistrationUrl.SafeHtmlEncode() %>">
    <input type="hidden" name="method" value="start" />
    <input type="hidden" name="referrerID" value="<%= Settings.EntroPay_ReferrerID.SafeHtmlEncode() %>" />
    <input type="hidden" name="timestamp" value="<%= GetTimestamp().SafeHtmlEncode() %>" />

    <% if (Profile.IsAuthenticated)
       {
           UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
           cmUser user = ua.GetByID(Profile.UserID);

           string countryCode = string.Empty;
           var country = CountryManager.GetAllCountries().FirstOrDefault(c => c.InternalID == user.CountryID);
           if (country != null)
               countryCode = country.ISO_3166_Name;
           %>
    <input type="hidden" name="emailVerified" value="<%= user.IsEmailVerified.ToString().ToLowerInvariant() %>" />
    <input type="hidden" name="pref_currency" value="<%= user.Currency.SafeHtmlEncode() %>" />
    <input type="hidden" name="pref_language" value="<%= ConvertToJavaLanguageCode( user.Language ) %>" />
    <input type="hidden" name="aff_email" value="<%= user.Email.SafeHtmlEncode() %>" />
    <input type="hidden" name="aff_title" value="<%= (user.Gender == "Mr") ? "Mr" : "Ms" %>" />
    <input type="hidden" name="aff_firstName" value="<%= user.FirstName.Truncate(30).SafeHtmlEncode() %>" />
    <input type="hidden" name="aff_lastName" value="<%= user.Surname.Truncate(30).SafeHtmlEncode() %>" />
    <% if (user.Birth.HasValue)
        { %>
    <input type="hidden" name="aff_dobDay" value="<%= user.Birth.Value.Day.ToString("00") %>" />
    <input type="hidden" name="aff_dobMonth" value="<%= user.Birth.Value.Month.ToString("00") %>" />
    <input type="hidden" name="aff_dobYear" value="<%= user.Birth.Value.Year.ToString("00") %>" />
    <% } %>        
    <input type="hidden" name="aff_address1" value="<%= user.Address1.Truncate(60).SafeHtmlEncode() %>" />
    <input type="hidden" name="aff_address2" value="<%= user.Address2.Truncate(60).SafeHtmlEncode() %>" /> 
    <input type="hidden" name="aff_state" value="<%= user.State.Truncate(20).SafeHtmlEncode() %>" /> 
    <input type="hidden" name="aff_zipCode" value="<%= user.Zip.Truncate(10).SafeHtmlEncode() %>" />
    <input type="hidden" name="aff_country" value="<%= countryCode.SafeHtmlEncode() %>" /> 
    <input type="hidden" name="aff_phoneCountryCode" value="<%= user.PhonePrefix.SafeHtmlEncode() %>" /> 
    <input type="hidden" name="aff_phoneNumber" value="<%= user.Phone.Truncate(15).SafeHtmlEncode() %>" /> 

    <% } %>


    <button class="register-entropay" type="submit">
        <%= this.GetMetadata(".Register_EntroPay").SafeHtmlEncode() %>
    </button>
</form>

</div>

<script language="javascript" type="text/javascript">
    try { self.parent.redirectToReceiptPage(); } catch (e) { }
    try { self.opener.redirectToReceiptPage(); } catch (e) { }
</script>


</asp:Content>

