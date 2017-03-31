<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="CM.Web.UI" %>

<script runat="server">
private List<PayCardInfoRec> PayCards { get; set; }

protected override void OnInit(EventArgs e)
    {
this.PayCards = GamMatrixClient.GetPayCards(VendorID.Neteller)
            .Where(p => !p.IsDummy)
            .ToList();
        base.OnInit(e);
    }
</script>

<div class="NetellerWithdrawal">
    <fieldset>
    <legend class="Hidden">
    <%= this.GetMetadata(".WithdrawToNeteller").SafeHtmlEncode()%>
    </legend>
    <p class="SubHeading WithdrawSubHeading">
    <%= this.GetMetadata(".WithdrawToNeteller").SafeHtmlEncode()%>
    </p>

<% if (PayCards.Count > 0)
{%>
<div class="TabContent">
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
{%>
<div class="TabContent">
<%---------------------------------------------------------------
Register paycard
----------------------------------------------------------------%>
<ul class="FormList">
<li class="FormItem" id="Li1">
<label class="FormLabel" for="withdrawIdentityNumber">
<%= this.GetMetadata(".AccountID").SafeHtmlEncode()%>
</label>
<%: Html.TextBox("identityNumber", string.Empty, new Dictionary<string, object>()  
{ 
{ "class", "FormInput" },
{ "dir", "ltr" },
{ "maxlength", "12" },
{ "placeholder", this.GetMetadata(".AccountID") },
{ "data-validator", ClientValidators.Create()
.Required(this.GetMetadata(".AccountID_Empty"))
.Custom("validateNetellerAccountID") },
{ "autocomplete", "off" },
})%>
<span class="FormStatus">Status</span>
<span class="FormHelp"></span>

<ui:MinifiedJavascriptControl ID="MinifiedJavascriptControl1" runat="server" Enabled="true" AppendToPageEnd="true">
<script type="text/javascript">
//<![CDATA[
function validateNetellerAccountID() {
var value = this;
var account_ret = /^(.{12,12})$/.test(value);
var email_ret = /^([a-zA-Z0-9_-])+@([a-zA-Z0-9_-])+((\.[a-zA-Z0-9_-]{2,3}){1,2})$/.test(value);
if (!account_ret && !email_ret)
return '<%= this.GetMetadata(".AccountID_Invalid").SafeJavascriptStringEncode() %>';
return true;
}
//]]>
</script>
</ui:MinifiedJavascriptControl>
</li>
</ul>
</div>
<% } %>
</fieldset>
</div>