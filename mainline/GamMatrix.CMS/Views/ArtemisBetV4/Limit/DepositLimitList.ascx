<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<GamMatrixAPI.GetUserRgDepositLimitListRequest>" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="Finance" %>

<script type="text/C#" runat="server">
    private string AttachParams(string url)
    {
        if (string.IsNullOrWhiteSpace(url) || string.IsNullOrWhiteSpace(Request.Url.Query) || Request.Url.Query.Length<2)
            return url;
        
        return url.IndexOf("?") >= 0 ? (url + Request.Url.Query.Substring(1)) : (url + Request.Url.Query);
    }
    private string GetLimitType()
    {
        return this.GetMetadata(".LimitType_Deposit");
    }
    private string GetLimitType(RgDepositLimitPeriod period)
    {
        return this.GetMetadata(string.Format(".LimitType_Deposit_{0}", period.ToString())).DefaultIfNullOrEmpty(GetLimitType());
    }

    private string GetSettingUrl(RgDepositLimitInfoRec rec = null)
    {
        string url;
        if (rec == null)
            url = this.Url.RouteUrl("Limit", new { @action = "Deposit" }) + Request.Url.Query;
        else
        {
            url = this.Url.RouteUrl("Limit", new { @action = "Deposit", @period = rec.Period.ToString(), @limitID=rec.ID });
        }

        return AttachParams(url);
    }
    private string GetSettingUrl(RgDepositLimitPeriod period = RgDepositLimitPeriod.None)
    {
        string url;
        if (period == RgDepositLimitPeriod.None)
            url = this.Url.RouteUrl("Limit", new { @action = "Deposit" });
        else
        {
            url = this.Url.RouteUrl("Limit", new { @action = "Deposit", @period = period.ToString()});
        }

        return AttachParams(url);
    }

    private string GetAmountText(RgDepositLimitInfoRec rec)
    {
        string period = string.Format(".Period_{0}", rec.Period.ToString());
        return string.Format(CultureInfo.InvariantCulture, "{0} / {1}"
            , MoneyHelper.FormatWithCurrencySymbol(rec.Currency, rec.Amount)
            , this.GetMetadata(period)
            );
    }

    private string GetQueuedAmountText(RgDepositLimitInfoRec rec)
    {
        string period = string.Format(".Period_{0}", rec.UpdatePeriod.ToString());
        if (rec.UpdateFlag)
        {
            if (rec.UpdatePeriod.ToString() != "None")
            {
                return string.Format(CultureInfo.InvariantCulture, "{0} / {1}"
                    , MoneyHelper.FormatWithCurrencySymbol(rec.UpdateCurrency, rec.UpdateAmount)
                    , this.GetMetadata(period)
                    );
            }
            else
            {
                return this.GetMetadata(".No_Limit");
            }
        }
        return string.Empty;
    }

    private string GetValidityText(RgDepositLimitInfoRec rec)
    {
        string year = rec.ExpiryDate.ToString("dd/MM/yyyy", CultureInfo.InvariantCulture);
        if (rec.ExpiryDate.Year > 3000)
            return this.GetMetadata(".Expiration_Never");
        return this.GetMetadataEx(".Expiry_Date", year);
    }

    private string GetQueuedValidityText(RgDepositLimitInfoRec rec)
    {
        string year = rec.ExpiryDate.ToString("dd/MM/yyyy", CultureInfo.InvariantCulture);
        if (rec.ExpiryDate.Year > 3000)
            return this.GetMetadata(".Expiration_Never");
        return this.GetMetadataEx(".Valid_From", year);
    }

    private bool HasQueuedItem(RgDepositLimitInfoRec rec)
    {
        return rec.UpdateFlag;
    }

    private bool IsButtonAvaliable(RgDepositLimitInfoRec rec)
    {
        return !rec.UpdateFlag;
    }

    private List<RgDepositLimitPeriod> GetPeriods()
    {
        List<RgDepositLimitPeriod> list = new List<RgDepositLimitPeriod>();
        list.Add(RgDepositLimitPeriod.Daily);
        list.Add(RgDepositLimitPeriod.Weekly);
        list.Add(RgDepositLimitPeriod.Monthly);
        return list;
    }
</script>

<% 
foreach (RgDepositLimitPeriod period in GetPeriods()) {
    if (this.Model.DepositLimitRecords != null && this.Model.DepositLimitRecords.Exists(r => r.Period == period))
    {
        RgDepositLimitInfoRec rec = this.Model.DepositLimitRecords.FirstOrDefault(r => r.Period == period);
        %>

<tr class="<%= this.Model.GetType().Name %>">
    <td class="col-1"><%= GetLimitType(period).SafeHtmlEncode()%></td>
    <td class="col-2"><%= GetAmountText(rec).SafeHtmlEncode() %></td>
    <td class="col-3"><%= this.GetMetadata(".Status_Active").SafeHtmlEncode() %></td>
    <td class="col-4"><%= GetValidityText(rec).SafeHtmlEncode()%></td>
    <td class="col-5">
        <% if (IsButtonAvaliable(rec))
           { %>
        <%: Html.Button(this.GetMetadata(".Button_Setting"), new { @type = "button", @onclick = string.Format("self.location='{0}';", GetSettingUrl(rec)) })%>
        <% } %>
    </td>
</tr>

<%-----------------
    Queued Item
-----------------%>
    <% if( HasQueuedItem(rec) )
       { %>
<tr class="<%= this.Model.GetType().Name %>">
    <td class="col-1"><%= GetLimitType(period).SafeHtmlEncode()%></td>
    <td class="col-2"><%= GetQueuedAmountText(rec).SafeHtmlEncode()%></td>
    <td class="col-3"><%= this.GetMetadata(".Status_Queued").SafeHtmlEncode() %></td>
    <td class="col-4"><%= GetQueuedValidityText(rec)%></td>
    <td class="col-5">
        <% if (IsButtonAvaliable(rec))
           { %>
        <%: Html.Button(this.GetMetadata(".Button_Setting"), new { @type="button", @onclick = string.Format( "self.location='{0}';", GetSettingUrl(rec)) } )%>
        <% } %>
    </td>
</tr>
    <% } %>

<%
    }
    else
    { %>
<tr class="<%= this.Model.GetType().Name %>">
    <td class="col-1"><%= GetLimitType(period).SafeHtmlEncode()%></td>
    <td class="col-2"><%= this.GetMetadata(".No_Limit").SafeHtmlEncode() %></td>
    <td class="col-3"><%= this.GetMetadata(".Status_Active").SafeHtmlEncode() %></td>
    <td class="col-4"><%= this.GetMetadata(".Expiration_Never").SafeHtmlEncode() %></td>    
    <td class="col-5">
        <%: Html.Button(this.GetMetadata(".Button_Setting"), new { @type="button", @onclick = string.Format( "self.location='{0}';", GetSettingUrl(period)) } )%>
    </td>
</tr>
 <% }
} 
%>