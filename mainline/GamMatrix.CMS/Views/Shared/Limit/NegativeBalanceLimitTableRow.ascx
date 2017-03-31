<%--@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<GamMatrixAPI.NegativeBalanceLimitRequest>" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="Finance" %>
<script type="text/C#" runat="server">

</script>

<% if (this.Model.Record != null && this.Model.Record.State == NegativeBalanceLimitState.Enabled) { %>
<tr class="<%= this.Model.GetType().Name %>">
    <td class="col-1"><%= this.GetMetadata("/Limit/_LimitTableRow_ascx.LimitType_NegativeBalance").SafeHtmlEncode() %></td>
    <td class="col-2"><%= this.Model.Record.CreditLimitAmount %></td>
    <td class="col-3"><%= this.GetMetadata("/Limit/_LimitTableRow_ascx.Status_Active").SafeHtmlEncode() %></td>
    <td class="col-4"><%= this.GetMetadata("/Limit/_LimitTableRow_ascx.Expiration_Never").SafeHtmlEncode() %></td>
    <td class="col-5"></td>
</tr>
<%} --%>