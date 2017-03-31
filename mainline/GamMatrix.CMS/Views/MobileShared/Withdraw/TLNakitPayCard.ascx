<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="CM.Web.UI" %>
<%@ Import Namespace="GmCore" %>

<script runat="server">
    public List<PayCardInfoRec> ExistingPayCards { get; protected set; }

    public bool HasExistingPayCards()
    {
        return (ExistingPayCards != null && ExistingPayCards.Count > 0);
    }

    protected IEnumerable<PayCardInfoRec> GetPayCards(VendorID vendorID)
    {
        return GamMatrixClient.GetPayCards(vendorID)
            .Where(c => !c.IsDummy)
            .OrderByDescending(c => c.Ins);
    }

    protected override void OnInit(EventArgs e)
    {
        ExistingPayCards = GetPayCards(VendorID.TLNakit).ToList();
        base.OnInit(e);
    }
</script>

<div class="TLNakitWithdrawal">
    <fieldset>
        <legend class="Hidden">
            <%= this.GetMetadata(".TLNakitAccount").SafeHtmlEncode() %>
        </legend>
        <p class="SubHeading WithdrawSubHeading">
            <%= this.GetMetadata(".TLNakitAccount").SafeHtmlEncode()%>
        </p>

        <% if (HasExistingPayCards())
           { %>
        <div class="TabContent" id="tabExistingCard">
            <ul class="PayCardList">
                <% foreach (PayCardInfoRec card in ExistingPayCards)
                   {  %>
                <li>
                    <input type="radio" name="payCardID" class="FormRadio" id="btnPayCard_<%: card.ID %>" value="<%: card.ID %>" checked="checked" />
                    <label for="btnPayCard_<%: card.ID %>"><%= card.DisplayNumber.SafeHtmlEncode() %></label>
                </li>
                <% } %>
                <li>
                    <input type="radio" name="payCardID" class="FormRadio" id="btnNewPayCard" value="0" />
                    <label for="btnNewPayCard"><%= this.GetMetadata(".WithdrawToAnotherAccount_Label").SafeHtmlEncode()%> </label>
                </li>
            </ul>
        </div>
        <% }
           //else
           { %>
        <div class="TabContent" id="tabRegisterCard">
            <ul class="FormList">
                <li class="FormItem" id="fldRegisterPayCard">
                    <label class="FormLabel" for="withdrawIdentityNumber"><%= this.GetMetadata(".TLNakitUsername_Label").SafeHtmlEncode()%> </label>
                    <%: Html.TextBox("identityNumber", string.Empty, new Dictionary<string, object>()  
                        { 
                            { "class", "FormInput" },
                            { "dir", "ltr" },
                            { "maxlength", "50" },
{ "placeholder", this.GetMetadata(".TLNakitUsername_Label") },
{ "required", "required" },
{ "data-validator", ClientValidators.Create().RequiredIf("isUsernameRequired", this.GetMetadata(".TLNakitUsername_Empty")) },
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
<% if (HasExistingPayCards())
   { %>
<ui:MinifiedJavascriptControl ID="MinifiedJavascriptControl1" runat="server" Enabled="true" AppendToPageEnd="true">
    <script type="text/javascript">
        function isUsernameRequired() {
            return $('input[name="payCardID"]:checked').val() == 0;
        }

        $(function () {
            $('#tabRegisterCard input').bind('focus', function (data) {
                $('#btnNewPayCard').prop('checked', true);
            });
        });
    </script>
</ui:MinifiedJavascriptControl>
<%} %>
<%else %>
<%{ %>
<ui:MinifiedJavascriptControl ID="MinifiedJavascriptControl2" runat="server" Enabled="true" AppendToPageEnd="true">
    <script type="text/javascript">
        function isUsernameRequired() {
            return true;
        }
    </script>
</ui:MinifiedJavascriptControl>
<%} %>