<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<GamMatrix.CMS.Models.MobileShared.Components.ProfileAdditionalInputViewModel>" %>
<%@ Import Namespace="CM.Web.UI" %>

<script type="text/C#" runat="server">
	protected override void OnPreRender(EventArgs e)
    {
		fldTermsConditions.Visible = Model.InputSettings.IsTermsConditionsVisible;
		fldNewsOffers.Visible = Model.InputSettings.IsAllowNewsEmailVisible;
		fldSmsOffer.Visible = Model.InputSettings.IsAllowSmsOffersVisible;
	}
</script>

<ul class="FormList FormProfileAdditional">
	<li class="FormItem" id="fldTermsConditions" runat="server">
		<%: Html.CheckBox("acceptTermsConditions", false, new Dictionary<string, object>
			{ 
				{ "class", "FormCheck" },
				{ "id", "registerTermsConditions" },
				{ "required", "required" },
				{ "data-validator", ClientValidators.Create().Required(this.GetMetadata(".TermsConditions_Error")) },
			})%>
		<label for="registerTermsConditions" class="FormCheckLabel">
			<%= this.GetMetadata(".TermsConditions_Label").SafeHtmlEncode()%> 
			<a href="<%= Url.RouteUrl("TermsConditions").SafeHtmlEncode()%>"><%= this.GetMetadata(".TermsConditions_Link").SafeHtmlEncode()%> </a>
		</label>
		<span class="FormStatus">Status</span>
		<span class="FormHelp"></span>
	</li>
	<li class="FormItem" id="fldNewsOffers" runat="server">
		<%: Html.CheckBox("allowNewsEmail", Model.InputSettings.AllowNewsEmail.HasValue ? Model.InputSettings.AllowNewsEmail.Value : true, new Dictionary<string, object>
			{ 
				{ "class", "FormCheck" },
				{ "id", "registerAllowNewsEmail" },
			})%>
		<label for="registerAllowNewsEmail" class="FormCheckLabel">
			<%= this.GetMetadata(".NewsOffers_Label").SafeHtmlEncode()%> 
		</label>
		<span class="FormStatus">Status</span>
		<span class="FormHelp"></span>
	</li>
	<li class="FormItem" id="fldSmsOffer" runat="server">
		<%: Html.CheckBox("allowSmsOffer", Model.InputSettings.AllowSmsOffer.HasValue ? Model.InputSettings.AllowSmsOffer.Value : true, new Dictionary<string, object>
			{ 
				{ "class", "FormCheck" },
				{ "id", "registerAllowSmsOffer" },
			})%>
		<label for="registerAllowSmsOffer" class="FormCheckLabel">
			<%= this.GetMetadata(".SmsOffers_Label").SafeHtmlEncode()%> 
		</label>
		<span class="FormStatus">Status</span>
		<span class="FormHelp"></span>
	</li>
</ul>