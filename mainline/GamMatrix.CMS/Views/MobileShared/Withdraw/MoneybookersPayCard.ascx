<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="Finance" %>
<%@ Import Namespace="CM.Web.UI" %>

<script type="text/C#" runat="server">
    private List<PayCardInfoRec> PayCards { get; set; }

    protected override void OnInit(EventArgs e)
    {
this.PayCards = GamMatrixClient.GetPayCards(VendorID.Moneybookers)
            .Where(p => !p.IsDummy)
            .ToList();
        base.OnInit(e);
    }
</script>

<div class="MoneybookersWithdrawal">
    <fieldset>
    <legend class="Hidden">
    <%= this.GetMetadata(".Moneybookers").SafeHtmlEncode() %>
    </legend>
    <p class="SubHeading WithdrawSubHeading">
    <%= this.GetMetadata(".Moneybookers").SafeHtmlEncode()%>
    </p>

<% if (PayCards.Count > 0)
{%>
<div class="TabContent" id="tabExistingCard">
        <%---------------------------------------------------------------
            Existing paycards
        ----------------------------------------------------------------%>
    <ul class="PayCardList">
            <% var first = true;
foreach (PayCardInfoRec card in this.PayCards)
{  %>
    <li>
                    <input type="radio" name="payCardID" class="FormRadio" id="payCard_<%: card.ID %>" value="<%: card.ID %>" <%= first ? "checked=\"checked\"" : "" %>  />
                    <label for="payCard_<%: card.ID %>"><%= card.DisplayNumber.SafeHtmlEncode()%></label>
                </li>
<% first = false;
} %>
    </ul>
</div>
<% }
else
{ %>
    <div class="TabContent" id="tabRegisterCard">
        <ul class="FormList">
    <li class="FormItem" id="Li1">
    <label class="FormLabel" for="withdrawIdentityNumber">
                <%= this.GetMetadata(".MoneybookersEmail").SafeHtmlEncode()%>
                </label>
                <%: Html.TextBox("identityNumber", string.Empty, new Dictionary<string, object>()  
                    { 
                        { "class", "FormInput" },
                        { "id", "withdrawIdentityNumber" },
                        { "dir", "ltr" },
                        { "maxlength", "50" },
{ "placeholder", this.GetMetadata(".MoneybookersEmail") },
{ "data-validator", ClientValidators.Create()
.Required(this.GetMetadata(".MoneybookersEmail_Empty"))
.Email(this.GetMetadata(".MoneybookersEmail_Invalid")) },
                        { "autocomplete", "off" },
                    })%>
<span class="FormStatus">Status</span>
<span class="FormHelp"></span>
    </li>
    </ul>
</div>
<% } %>
    </fieldset>
</div>