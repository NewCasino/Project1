<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="CM.Web.UI" %>

<script runat="server">
private List<PayCardInfoRec> PayCards { get; set; }

protected override void OnInit(EventArgs e)
    {
this.PayCards = GamMatrixClient.GetPayCards(VendorID.UiPas)
            .Where(p => !p.IsDummy)
            .ToList();
        base.OnInit(e);
    }
</script>

<div class="UiPasWithdrawal">
    <fieldset>
    <legend class="Hidden">
    <%= this.GetMetadata(".WithdrawToUiPas").SafeHtmlEncode()%>
    </legend>
    <p class="SubHeading WithdrawSubHeading">
    <%= this.GetMetadata(".WithdrawToUiPas").SafeHtmlEncode()%>
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
.Custom("validateUiPasAccountID") },
{ "autocomplete", "off" },
})%>
<span class="FormStatus">Status</span>
<span class="FormHelp"></span>

<ui:MinifiedJavascriptControl ID="MinifiedJavascriptControl1" runat="server" Enabled="true" AppendToPageEnd="true">
<script type="text/javascript">
    //<![CDATA[
    function validateUiPasAccountID() {
        var value = this;
        var ret = /^(.{12,12})$/.exec(value);
        if (ret == null || ret.length == 0)
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