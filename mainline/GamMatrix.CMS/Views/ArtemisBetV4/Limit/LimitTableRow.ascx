<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<GamMatrixAPI.HandlerRequest>" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="Finance" %>
<script type="text/C#" runat="server">
    private string GetLimitType()
    {
        switch( this.Model.GetType().Name )
        {
            case "GetUserRgDepositLimitRequest":
                return this.GetMetadata(".LimitType_Deposit");

            case "GetUserRgLossLimitRequest":
                return this.GetMetadata(".LimitType_Loss");

            case "GetUserRgWageringLimitRequest":
                return this.GetMetadata(".LimitType_Wagering");

            case "GetUserRgSessionLimitRequest":
                return this.GetMetadata(".LimitType_SessionTime");
                
            default:
                return string.Empty;
        }
    }

    private string GetSettingUrl()
    {
        switch (this.Model.GetType().Name)
        {
            case "GetUserRgDepositLimitRequest":
                return "/Limit/Deposit" + Request.Url.Query;

            case "GetUserRgLossLimitRequest":
                return "/Limit/Loss" + Request.Url.Query;

            case "GetUserRgWageringLimitRequest":
                return "/Limit/Wagering" + Request.Url.Query;

            case "GetUserRgSessionLimitRequest":
                return "/Limit/Session" + Request.Url.Query;

            default:
                return string.Empty;
        }
    }

    private string GetAmountText()
    {
        switch (this.Model.GetType().Name)
        {
            case "GetUserRgDepositLimitRequest":
            case "GetUserRgLossLimitRequest":
            case "GetUserRgWageringLimitRequest":
                {
                    dynamic obj = this.Model;
                    string period = string.Format(".Period_{0}", obj.Record.Period.ToString());
                    return string.Format(CultureInfo.InvariantCulture, "{0} / {1}"
                        , MoneyHelper.FormatWithCurrencySymbol(obj.Record.Currency, obj.Record.Amount)
                        , this.GetMetadata(period)
                        );
                }
            default:
                break;
        }

        GetUserRgSessionLimitRequest getUserRgSessionLimitRequest = this.Model as GetUserRgSessionLimitRequest;
        if (getUserRgSessionLimitRequest != null && getUserRgSessionLimitRequest.Record != null)
        {
            return string.Format(CultureInfo.InvariantCulture, "{0} {1}"
                , getUserRgSessionLimitRequest.Record.Amount / 60
                , this.GetMetadata(".Period_Minute")
                );
        }
        return string.Empty;
    }

    private string GetQueuedAmountText()
    {
        switch (this.Model.GetType().Name)
        {
            case "GetUserRgDepositLimitRequest":
            case "GetUserRgLossLimitRequest":
            case "GetUserRgWageringLimitRequest":
                {
                    dynamic obj = this.Model;
                    string period = string.Format(".Period_{0}", obj.Record.UpdatePeriod.ToString());
                    if (obj.Record.UpdateFlag)
                    {
                        if (obj.Record.UpdatePeriod.ToString() != "None")
                        {
                            return string.Format(CultureInfo.InvariantCulture, "{0} / {1}"
                                , MoneyHelper.FormatWithCurrencySymbol(obj.Record.UpdateCurrency, obj.Record.UpdateAmount)
                                , this.GetMetadata(period)
                                );
                        }
                        else
                        {
                            return this.GetMetadata(".No_Limit");
                        }
                    }
                    break;
                }
            default:
                break;
        }

        GetUserRgSessionLimitRequest getUserRgSessionLimitRequest = this.Model as GetUserRgSessionLimitRequest;
        if (getUserRgSessionLimitRequest != null && getUserRgSessionLimitRequest.Record != null)
        {
            if (getUserRgSessionLimitRequest.Record.UpdateFlag)
            {
                if (getUserRgSessionLimitRequest.Record.UpdateAmount > 0)
                {
                    return string.Format(CultureInfo.InvariantCulture, "{0} {1}"
                        , getUserRgSessionLimitRequest.Record.UpdateAmount / 60
                        , this.GetMetadata(".Period_Minute")
                        );
                }
                else
                {
                    return this.GetMetadata(".No_Limit");
                }
            }
        }
        return string.Empty;
    }

    private string GetValidityText()
    {
        switch (this.Model.GetType().Name)
        {
            case "GetUserRgDepositLimitRequest":
            case "GetUserRgLossLimitRequest":
            case "GetUserRgWageringLimitRequest":
                {
                    dynamic obj = this.Model;
                    string year = obj.Record.ExpiryDate.ToString("dd/MM/yyyy", CultureInfo.InvariantCulture);
                    if (obj.Record.ExpiryDate.Year > 3000)
                        return this.GetMetadata(".Expiration_Never");
                    return this.GetMetadataEx(".Expiry_Date", year);
                }
            default:
                break;
        }

        GetUserRgSessionLimitRequest getUserRgSessionLimitRequest = this.Model as GetUserRgSessionLimitRequest;
        if (getUserRgSessionLimitRequest != null && getUserRgSessionLimitRequest.Record != null)
        {
            if (getUserRgSessionLimitRequest.Record.ExpiryDate.Year > 3000)
                return this.GetMetadata(".Expiration_Never");
            return this.GetMetadataEx(".Expiry_Date"
                , getUserRgSessionLimitRequest.Record.ExpiryDate.ToString("dd/MM/yyyy", CultureInfo.InvariantCulture)
                );
        }
        return string.Empty;
    }

    private string GetQueuedValidityText()
    {
        switch (this.Model.GetType().Name)
        {
            case "GetUserRgDepositLimitRequest":
            case "GetUserRgLossLimitRequest":
            case "GetUserRgWageringLimitRequest":
                {
                    dynamic obj = this.Model;
                    string year = obj.Record.ExpiryDate.ToString("dd/MM/yyyy", CultureInfo.InvariantCulture);
                    if (obj.Record.ExpiryDate.Year > 3000)
                        return this.GetMetadata(".Expiration_Never");
                    return this.GetMetadataEx(".Valid_From"
                        , year
                        );
                }
            default:
                break;
        }

        GetUserRgSessionLimitRequest getUserRgSessionLimitRequest = this.Model as GetUserRgSessionLimitRequest;
        if (getUserRgSessionLimitRequest != null && getUserRgSessionLimitRequest.Record != null)
        {
            if (getUserRgSessionLimitRequest.Record.ExpiryDate.Year > 3000)
                return this.GetMetadata(".Expiration_Never");
            return this.GetMetadataEx(".Valid_From"
                , getUserRgSessionLimitRequest.Record.ExpiryDate.ToString("dd/MM/yyyy", CultureInfo.InvariantCulture)
                );
        }
        return string.Empty;
    }

    private bool HasQueuedItem()
    {
        dynamic obj = this.Model;
        return obj.Record.UpdateFlag;
    }

    private bool IsButtonAvaliable()
    {
        dynamic obj = this.Model;
        return !obj.Record.UpdateFlag;
    }
</script>

<% int count = 0; %>
<% if (ObjectHelper.GetFieldValue(this.Model, "Record") == null)
   { %>

<div class=" holder-flex-100 <%= this.Model.GetType().Name %>">
    <div class="col-20"><%= GetLimitType().SafeHtmlEncode()%></div>
    <div class="col-20"><%= this.GetMetadata(".No_Limit").SafeHtmlEncode() %></div>
    <div class="col-20"><%= this.GetMetadata(".Status_Active").SafeHtmlEncode() %></div>
    <div class="col-20"><%= this.GetMetadata(".Expiration_Never").SafeHtmlEncode() %></div>    
    <div class="col-20">
        <%: Html.Button(this.GetMetadata(".Button_Setting"), new { @type="button", @onclick = string.Format( "self.location='{0}';", GetSettingUrl()) } )%>
    </div>
</div>


<% } else { %>

<div class=" holder-flex-100 <%= this.Model.GetType().Name %>">
    <div class="col-20"><%= GetLimitType().SafeHtmlEncode()%></div>
    <div class="col-20"><%= GetAmountText().SafeHtmlEncode() %></div>
    <div class="col-20"><%= this.GetMetadata(".Status_Active").SafeHtmlEncode() %></div>
    <div class="col-20"><%= GetValidityText().SafeHtmlEncode()%></div>
    <div class="col-20">
        <% if (IsButtonAvaliable())
           { %>
        <%: Html.Button(this.GetMetadata(".Button_Setting"), new { @type = "button", @onclick = string.Format("self.location='{0}';", GetSettingUrl()) })%>
        <% } %>
    </div>
</div>

<%-----------------
    Queued Item
-----------------%>
    <% if( HasQueuedItem() )
       { %>
<div class=" holder-flex-100 <%= this.Model.GetType().Name %>">
    <div class="col-20"><%= GetLimitType().SafeHtmlEncode()%></div>
    <div class="col-20"><%= GetQueuedAmountText().SafeHtmlEncode()%></div>
    <div class="col-20"><%= this.GetMetadata(".Status_Queued").SafeHtmlEncode() %></div>
    <div class="col-20"><%= GetQueuedValidityText()%></div>
    <div class="col-20">
        <% if (IsButtonAvaliable())
           { %>
        <%: Html.Button(this.GetMetadata(".Button_Setting"), new { @type="button", @onclick = string.Format( "self.location='{0}';", GetSettingUrl()) } )%>
        <% } %>
    </div>
</div>
    <% } %>


        


<% } %>