<%@ Page Language="C#" PageTemplate="/ProfileMaster.master" Inherits="CM.Web.ViewPageEx<Finance.PaymentMethod>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="CM.db" %>
<%@ Import Namespace="CM.db.Accessor" %>

<script language="C#" type="text/C#" runat="server">
    protected override void OnPreRender(EventArgs e)
    {
        if (Settings.IsUKLicense && !IsAcceptUKTerms())
            Response.Redirect("/Deposit");
        base.OnPreRender(e);
    }
    protected bool IsAcceptUKTerms()
    {
        UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
        cmUser user = ua.GetByID(Profile.UserID);
        return user.IsTCAcceptRequired.HasFlag(TermsConditionsChange.UKLicense);
    }
    private bool SafeParseBoolString(string text, bool defValue)
    {
        if (string.IsNullOrWhiteSpace(text))
            return defValue;

        text = text.Trim();

        if (Regex.IsMatch(text, @"(YES)|(ON)|(OK)|(TRUE)|(\1)", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant | RegexOptions.Compiled))
            return true;

        if (Regex.IsMatch(text, @"(NO)|(OFF)|(FALSE)|(\0)", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant | RegexOptions.Compiled))
            return false;

        return defValue;
    }
    private static void GetEnterCashGetBankInfo()
    {
        List<EnterCashRequestBankInfo> list = GamMatrixClient.GetEnterCashBankInfo();
    }
    
    private PayCardInfoRec GetExistingPayCard()
    {
        return GamMatrixClient.GetPayCards(GamMatrixAPI.VendorID.Neteller)
            .OrderByDescending(e => e.Ins).FirstOrDefault();
    }
    
    
</script>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div id="deposit-wrapper" class="content-wrapper">
<%: Html.H1( string.Format( "{0} - {1}", this.GetMetadata(".HEAD_TEXT"), this.Model.GetTitleHtml()) ) %>
<ui:Panel runat="server" ID="pnDeposit">


<% Html.RenderPartial("PaymentMethodDesc", this.Model); %>

<div id="prepare_step">
<% GetEnterCashGetBankInfo(); %>
<% Html.RenderPartial("InputView", this.Model); %>

<%------------------------------------------
    Bonus
 -------------------------------------------%>
<ui:InputField ID="fldBonus" runat="server" ShowDefaultIndicator="false" BalloonArrowDirection="Left">
	<LabelPart></LabelPart>
	<ControlPart>
        <%: Html.CheckBox( "acceptBonus", true, new { @id = "btnAcceptBonus" }) %>
        <label for="btnAcceptBonus"><%= this.GetMetadata(".Bonus_Option").SafeHtmlEncode()%></label>
	</ControlPart>
</ui:InputField>

<center>
    <%: Html.Button( this.GetMetadata(".Button_Continue"), new { @type = "submit", @id="btnDepositEnvoy", @class="ContinueButton button" })%>
</center>
</div>



</ui:Panel>
</div>
<%  Html.RenderPartial("LocalConnection", this.ViewData); %>
    <style>
.ConfirmationBox {display: none;position: fixed;z-index: 999999;left: 0;top: 0;width: 100%;height: 100%;background: rgba(0,0,0,.7);}
.ConfirmationFrame,  .ConfirmationFrameData {height: 100%;position: relative;margin: 0 auto;}
.ConfirmationIframe {margin: 5%;height: 85%;width: 90%;height: 90%;background:#fff;}
.ConfirmationClose {display: block;background: #ffffff;background: url(data:image/svg+xml;base64,PD94bWwgdmVyc2lvbj0iMS4wIiA/Pgo8c3ZnIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyIgd2lkdGg9IjEwMCUiIGhlaWdodD0iMTAwJSIgdmlld0JveD0iMCAwIDEgMSIgcHJlc2VydmVBc3BlY3RSYXRpbz0ibm9uZSI+CiAgPGxpbmVhckdyYWRpZW50IGlkPSJncmFkLXVjZ2ctZ2VuZXJhdGVkIiBncmFkaWVudFVuaXRzPSJ1c2VyU3BhY2VPblVzZSIgeDE9IjAlIiB5MT0iMCUiIHgyPSIwJSIgeTI9IjEwMCUiPgogICAgPHN0b3Agb2Zmc2V0PSIwJSIgc3RvcC1jb2xvcj0iI2ZmZmZmZiIgc3RvcC1vcGFjaXR5PSIxIi8+CiAgICA8c3RvcCBvZmZzZXQ9IjEwMCUiIHN0b3AtY29sb3I9IiNjZWNlY2UiIHN0b3Atb3BhY2l0eT0iMSIvPgogIDwvbGluZWFyR3JhZGllbnQ+CiAgPHJlY3QgeD0iMCIgeT0iMCIgd2lkdGg9IjEiIGhlaWdodD0iMSIgZmlsbD0idXJsKCNncmFkLXVjZ2ctZ2VuZXJhdGVkKSIgLz4KPC9zdmc+);background: -moz-linear-gradient(top, #ffffff 0%, #cecece 100%);background: -webkit-gradient(linear, left top, left bottom, color-stop(0%, #ffffff), color-stop(100%, #cecece));background: -webkit-linear-gradient(top, #ffffff 0%, #cecece 100%);background: -o-linear-gradient(top, #ffffff 0%, #cecece 100%);background: -ms-linear-gradient(top, #ffffff 0%, #cecece 100%);background: linear-gradient(to bottom, #ffffff 0%, #cecece 100%);filter: progid:DXImageTransform.Microsoft.gradient( startColorstr='#ffffff', endColorstr='#cecece', GradientType=0 );font-weight: 700;height: 30px;width: 30px;position: absolute;top: 10px;right: 10px;border-radius: 50%;text-align: center;line-height: 30px;font-size: 16px;z-index: 998;}
.ConfirmationClose:hover {background: #ccc;}
.ConfirmationClose .CloseText {text-indent: 0;color: #333;}
    </style>
<div class="ConfirmationBox simplemodal-container deposit-confirm-container">
    <div class="ConfirmationFrame simplemodal-wrap">
        <div class="ConfirmationFrameData simplemodal-data">
            <iframe src="about:blank" name="ConfirmationIframe"  marginwidth="0"  marginheight="0" align="middle" scrolling="auto" frameborder="0" hspace="0" vspace="0" class="ConfirmationIframe" id="ConfirmationIframe" title="Confirmation Iframe" allowtransparency="true" border="0"></iframe>
        </div>
        <a href="javascript:void(0);" class="ConfirmationClose ClosePopup"><span class="CloseText"><%=this.GetMetadata(".Close_Text").DefaultIfNullOrEmpty("X") %></span></a>
    </div>
</div>
<script type="text/javascript">
    var paymentPopupEnable  = <%= SafeParseBoolString(Metadata.Get("/Metadata/Settings/Deposit.Comfirmation_EnablePopup"), true)  ? ((Metadata.Get("/Metadata/Settings/Deposit.Comfirmation_EnabledPopup_Vendors").Contains(this.Model.UniqueName) ) ? "true" : "false") : "false" %>;
    if (paymentPopupEnable) {
        $("#pnComfirmForm").attr("target", "ConfirmationIframe");
        $(".ConfirmationFrame").width($(".left-pane").width() + $(".content-wrapper").width());
    }
    var hidePopupFrame = function () {
        $(".ConfirmationBox.simplemodal-container").hide();
    };
    $(".ConfirmationClose").click(function(){hidePopupFrame();});
    //<![CDATA[
    function __onBtnDepositConfirmClicked() {
        $('#deposit-block-dialog').modalex(400, 150, false);
        $('#deposit-block-dialog').parents("#simplemodal-container").addClass("deposit-block-dialog-container");
        if (paymentPopupEnable) {
            $(".ConfirmationBox.simplemodal-container").appendTo("body").show();
            //$(".ConfirmationBox.simplemodal-container").click(function () {
            //    hidePopupFrame();
            //});
        }
    } 
</script>
<script type="text/javascript">
$(function () {
    <% if( !string.Equals( this.Model.UniqueName, "Envoy_FundSend", StringComparison.InvariantCultureIgnoreCase) )
        { %>
        $('#fldCurrencyAmount').remove();
    <% }
    else
    { %>
        $('#ddlCurrency > option[value!="EUR"]').remove();
        $('#ddlCurrency').trigger('change');
    <% } %>

    $(document).bind("GAMING_ACCOUNT_SEL_CHANGED",function(e, data){
        if(data.VendorID=="CasinoWallet")
        {
            $("#fldBonus").hide();
            $("#fldBonus").find("#btnAcceptBonus").removeAttr("checked");
        }
        else
        {
            $("#fldBonus").show();
            $("#fldBonus").find("#btnAcceptBonus").attr("checked","true");
        }
    });

    $('#btnDepositEnvoy').click(function (e) {
        e.preventDefault();

        var url = '<%= this.Url.RouteUrl( "Deposit", new { @action = "PrepareEnvoyTransaction", @paymentMethodName = this.Model.UniqueName }).SafeJavascriptStringEncode() %>';
        $('#formPrepareDeposit').attr('action', url);
        $('#formPrepareDeposit').attr('method', 'post');
        if(paymentPopupEnable){
            $('#formPrepareDeposit').attr('target', 'ConfirmationIframe');
        }else{
            $('#formPrepareDeposit').attr('target', '_blank');
        }
        $('#formPrepareDeposit').off('submit');

        if (!$('#formPrepareDeposit').valid()) {
            return false;
        }

        $('#fldBonus :hidden[name="acceptBonus"]').appendTo($('#formPrepareDeposit'));

        if (paymentPopupEnable) {
            $(".ConfirmationBox.simplemodal-container").appendTo("body").show();
            $("#ConfirmationIframe").css("background","#fff");
            $(".ConfirmationBox.simplemodal-container").click(function () {
                hidePopupFrame();
            });
            $('#formPrepareDeposit').get(0).submit();
        }
        else
        {
            $('#formPrepareDeposit').get(0).submit();
            $(this).toggleLoadingSpin(true);
            setTimeout(function () {
                self.location = '<%= this.Url.RouteUrl( "Deposit", new { @action = "Done", paymentMethodName = this.Model.UniqueName}).SafeJavascriptStringEncode() %>';
            }, 1000);
        }
    });
});
</script>
<% Html.RenderAction("LimitSetPopup", "Deposit"); %>
<%  Html.RenderPartial("PrepareBodyPlus", this.ViewData ); %>
</asp:Content>