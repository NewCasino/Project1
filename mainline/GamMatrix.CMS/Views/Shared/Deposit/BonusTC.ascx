<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<GamMatrixAPI.PrepareTransRequest>" %>

<%@ Import Namespace="GamMatrixAPI" %>
<script language="C#" runat="server" type="text/C#">
    private string GetTermsAndConditionsContent()
    {
        return this.GetMetadata(string.Format("/Metadata/Documents/{0}TermsAndConditions.DefaultHtml", this.Model.Record.CreditPayItemVendorID.ToString()));
    }

    private List<SelectListItem> GetRememberChoiceList()
    {
        List<SelectListItem> list = new List<SelectListItem>();
        list.Add(new SelectListItem() { Selected = true, Text = this.GetMetadata(".Do_Not_Remember"), Value = "0" });
        list.Add(new SelectListItem() { Text = this.GetMetadata(".Remember_For_1_Week"), Value = "7" });
        list.Add(new SelectListItem() { Text = this.GetMetadata(".Remember_For_1_Month"), Value = "30" });
        return list;
    }

</script>



<div class="deposit-bonus-tc">
<%: Html.H4( this.GetMetadata(".Bonus_Terms_Conditions") ) %>

<div class="tc-content">

<%= GetTermsAndConditionsContent() %>
</div>

<%
    string formActionUrl = string.Format("/Deposit/SaveBonusChoice?sid={0}&gammingAccountID={1}"
        , HttpUtility.UrlEncode(this.Model.Record.Sid)
        , this.Model.Record.CreditAccountID
        );
 %>
<form id="formBonusTC" method="post" action="<%= formActionUrl.SafeHtmlEncode() %>">

<center>
    <table>
        <tr>
            <td>
            <%: Html.Button( this.GetMetadata(".Button_Back"), new { @onclick = "returnPreviousDepositStep();return false;", @type="button" })%>
            </td>

            <td>
            <%: Html.Button(this.GetMetadata(".Button_Accept"), new { @id = "btnAcceptBonusTC" })%>
            </td>

            <td>
            <%: Html.Button(this.GetMetadata(".Button_Reject"), new { @id = "btnRejectnusTC" })%>
            </td>

            <td>
            <%: Html.Hidden( "accepted", false ) %>
            <%: Html.DropDownList( "rememberDays", GetRememberChoiceList()) %>
            </td>
        </tr>
    </table> 
</center>

</form>

</div>


<script language="javascript" type="text/javascript">
//<![CDATA[
function __saveBonusChoice(accepted) {
    var options = {
        dataType: "json",
        type: 'POST',
        success: function (json) {
            $('#btnAcceptBonusTC').toggleLoadingSpin(false);
            $('#btnRejectnusTC').toggleLoadingSpin(false);
            if (!json.success) {
                showDepositError(json.error);
                return;
            }
            showDepositConfirmation('<%= this.Model.Record.Sid.SafeJavascriptStringEncode() %>');
        },
        error: function (xhr, textStatus, errorThrown) {
            $('#btnAcceptBonusTC').toggleLoadingSpin(false);
            $('#btnRejectnusTC').toggleLoadingSpin(false);
            showDepositError(errorThrown);
        }
    };
    $('#formBonusTC').ajaxForm(options);
    $('#formBonusTC').submit();
}

$('#btnAcceptBonusTC').click(function (e) {
    e.preventDefault();
    $('#formBonusTC input[name="accepted"]').val('True');
    $(this).toggleLoadingSpin(true);
    __saveBonusChoice(true);
});

$('#btnRejectnusTC').click(function (e) {
    e.preventDefault();
    $('#formBonusTC input[name="accepted"]').val('False');
    $(this).toggleLoadingSpin(true);
    __saveBonusChoice(false);
});
//]]>
</script>