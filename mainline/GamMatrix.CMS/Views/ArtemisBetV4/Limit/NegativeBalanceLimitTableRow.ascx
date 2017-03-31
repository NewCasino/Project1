<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<GamMatrixAPI.NegativeBalanceLimitRequest>" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="Finance" %>
<script type="text/C#" runat="server">

</script>

<% if (this.Model.Record != null && this.Model.Record.State == NegativeBalanceLimitState.Enabled) { %>
<div class="holder-flex-100 <%= this.Model.GetType().Name %>">
    <div class="col-20"><%= this.GetMetadata("/Limit/_LimitTableRow_ascx.LimitType_NegativeBalance").SafeHtmlEncode() %></div>
    <div class="col-20"><%= this.Model.Record.CreditLimitAmount %></div>
    <div class="col-20"><%= this.GetMetadata("/Limit/_LimitTableRow_ascx.Status_Active").SafeHtmlEncode() %></div>
    <div class="col-20"><%= this.GetMetadata("/Limit/_LimitTableRow_ascx.Expiration_Never").SafeHtmlEncode() %></div>
    <div class="col-20"></div>
</div>
<%} %>