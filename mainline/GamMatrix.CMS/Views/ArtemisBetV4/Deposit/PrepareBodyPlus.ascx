<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>

<% if( this.Model.Category == Finance.PaymentMethodCategory.CreditCard ){%>
<ui:Message id="cCCardWarning" runat="server" Text="<%$ Metadata:value(.Warning) %>" Type="Warning"  />
<script>$(function(){$("#fldCurrencyAmount").after($("#cCCardWarning"));$("#cCCardWarning").show();});</script>
<%} %>
<ui:MinifiedJavascriptControl runat="server">
<script type="text/javascript">
jQuery('body').addClass('DepositPage').addClass('DepositStep2');
</script>
</ui:MinifiedJavascriptControl>