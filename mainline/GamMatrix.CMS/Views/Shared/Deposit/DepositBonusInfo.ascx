<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>
<%@ Import Namespace="GamMatrixAPI" %>
<script language="C#" type="text/C#" runat="server">
    private VendorID GetVendor() { return (VendorID)this.ViewData["VendorID"]; }
    private decimal GetBonusAmount() 
    {
        try
        {
            return (decimal)this.ViewData["BonusAmount"];
        }
        catch
        {
            return 0.00M;
        }
    }
    private string GetBonusCurrency() { return this.ViewData["BonusCurrency"] as string; }
</script>

<%---------------------------------------
    NetEnt Casino
 --------------------------------------%>
<% if( this.Model == VendorID.NetEnt && GetBonusAmount() > 0.00M )
   { %>
   <%= string.Format(this.GetMetadata(".Bonus_Amount"), GetBonusCurrency(), GetBonusAmount()).HtmlEncodeSpecialCharactors()  %>
<% } %>



<%---------------------------------------
    Bonus Code
 --------------------------------------%>
 <% if( this.Model == VendorID.NetEnt ||
        this.Model == VendorID.OddsMatrix ||
        this.Model == VendorID.MergeNetwork ||
        this.Model == VendorID.CakeNetwork ||
        this.Model == VendorID.CasinoWallet )
    { %>
<% } %>