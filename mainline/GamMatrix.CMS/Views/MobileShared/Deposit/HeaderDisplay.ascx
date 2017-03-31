<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>

<div class="DepositType">
	<img src="<%= this.Model.GetImageUrl().SafeHtmlEncode() %>" alt="<%= this.Model.GetTitleHtml().SafeHtmlEncode() %>" />
	<p>
        <%= this.GetMetadataEx(".Html", this.Model.GetTitleHtml()).HtmlEncodeSpecialCharactors()%>
	</p>
</div>