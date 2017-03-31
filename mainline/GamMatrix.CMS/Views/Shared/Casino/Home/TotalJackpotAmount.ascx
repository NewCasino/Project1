<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>
<%@ Import Namespace="Casino" %>

<script language="C#" type="text/C#" runat="server">
    private string Currency
    {
        get 
        {
            if (!string.IsNullOrWhiteSpace(this.ViewData["Currency"] as string))
                return this.ViewData["Currency"] as string;

            if (Profile.IsAuthenticated)
                return Profile.UserCurrency;

            return "EUR";
        }
    }

    private string GetCurrencySymbol()
    {
        string path = string.Format("/Metadata/Currency/{0}.Symbol", this.Currency);
        return Metadata.Get(path).DefaultIfNullOrEmpty(this.Currency);
    }
</script>

<div id="casino-total-jackpot-amount">
    <div class="text"><%= this.GetMetadata(".TotaJackpots").SafeHtmlEncode() %></div>
    <div class="currency"><%= this.GetCurrencySymbol().SafeHtmlEncode() %></div>
    <div class="amount"><%= GameManager.GetTotalJackpotAmount(this.Currency).ToString("N2") %></div>
</div>