<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<GamMatrix.CMS.Models.MobileShared.Withdraw.TLNakitPayCardViewModel>" %>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="CM.Web.UI" %>

<div class="TLNakitWithdrawal">
    <fieldset>
	    <legend class="Hidden">
		    <%= this.GetMetadata(".TLNakitAccount").SafeHtmlEncode() %>
	    </legend>
	    <p class="SubHeading WithdrawSubHeading">
		    <%= this.GetMetadata(".TLNakitAccount").SafeHtmlEncode()%>
	    </p>

		<% if (Model.HasExistingPayCards()) 
			{ %>
		<div class="TabContent" id="tabExistingCard">
			<ul class="PayCardList">
				<% foreach (PayCardInfoRec card in Model.ExistingPayCards)
                    {  %>
			        <li>
                        <input type="radio" name="payCardID" id="btnPayCard_<%: card.ID %>" value="<%: card.ID %>" checked="checked" />
                        <label for="btnPayCard_<%: card.ID %>"><%= card.DisplayNumber.SafeHtmlEncode() %></label>
                    </li>
                <% } %>
			</ul>
		</div>
		<% }
			else
			{ %>
		<div class="TabContent" id="tabRegisterCard">
			<ul class="FormList">
				<li class="FormItem" id="fldRegisterPayCard">
			        <label class="FormLabel" for="withdrawIdentityNumber"> <%= this.GetMetadata(".TLNakitUsername_Label").SafeHtmlEncode()%> </label>
                    <%: Html.TextBox("identityNumber", string.Empty, new Dictionary<string, object>()  
                        { 
                            { "class", "FormInput" },
                            { "dir", "ltr" },
                            { "maxlength", "50" },
							{ "placeholder", this.GetMetadata(".TLNakitUsername_Label") },
							{ "required", "required" },
							{ "data-validator", ClientValidators.Create().Required(this.GetMetadata(".TLNakitUsername_Empty")) },
                            { "autocomplete", "off" },
                        }) %>
					<span class="FormStatus">Status</span>
					<span class="FormHelp"></span>
		        </li>
			</ul>
		</div>
		<% } %>
	</fieldset>
</div>