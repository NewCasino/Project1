<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>


<div class="payment-method_desc">
    <img class="thumb" src="<%= this.Model.GetImageUrl().SafeHtmlEncode() %>" border="0" alt="<%= this.Model.GetTitleHtml().SafeHtmlEncode() %>" />
    <%= this.Model.GetDescriptionHtml() %>
    <div style="clear:both"></div>
</div>