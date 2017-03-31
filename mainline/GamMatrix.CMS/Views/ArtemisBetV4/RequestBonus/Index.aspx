<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>
" MetaKeywords="
<%$ Metadata:value(.Keywords)%>
" MetaDescription="
<%$ Metadata:value(.Description)%>
"%>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server"></asp:Content>

<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div class="Box BonusContainnerBox RequestBonusContainnerBox">
<h2 class="SubHeader">
<a class="SHToggle ToggleButton" href="#">
<span class="ToggleArrow">&ndash;</span>
<span class="SHText">
<%= this.GetMetadata(".Request_Bonus")%></span>
</a>
</h2>
<div class="BoxContent ToggleContent Container">
<div class="RequestBonusContent">
<h5>
<%=this.GetMetadata(".RequestBonus_Content").HtmlEncodeSpecialCharactors() %></h5>
<div class="AccountButtonContainer">
<ul class="DepLinks Container">
<li class="DepItem">
<button type="submit" class="Button RegLink DepLink BackLink" id="requestCasinoBonus">
<span class="ButtonText">
<%= this.GetMetadata(".Button_RequestCasinoBonus").SafeHtmlEncode()%></span>
</button>
</li>
<li class="DepItem">
<button type="submit" class="Button RegLink DepLink NextStepLink" id="requestSportBonus">
<span class="ButtonText">
<%= this.GetMetadata(".Button_RequestSportBonus").SafeHtmlEncode()%></span>
</button>
</li>
</ul>
</div>
</div>
<div class="StatusContainer" style="display:none;">
<div class="StatusBackground">
<div class="StatusIcon">Status</div>

<div class="StatusMessage"></div>

</div>
</div>
</div>
</div>
<script type="text/javascript">
    function SendCompensationBonusEmail(source) {
        $.get('/RequestBonus/SendEmail/' + source,
        null,
        function (data) {
            if (data.success) {
                $('.StatusMessage').html('<%= this.GetMetadata(".Email_Success_Information").SafeJavascriptStringEncode() %>');
                $('.StatusContainer').addClass('SuccessStatus');
                $('.RequestBonusContent').hide();
                $('.StatusContainer').show();
            } else {
                $('.StatusMessage').html('<%= this.GetMetadata(".Email_Failure_Information").SafeJavascriptStringEncode() %>');
                $('.StatusContainer').addClass('ErrorStatus');
                $('.RequestBonusContent').hide();
                $('.StatusContainer').show();
            }
        }, "json");        
    }

    $(function() {
        $('#requestCasinoBonus').click(function() {
            SendCompensationBonusEmail('Casino');
        });
        $('#requestSportBonus').click(function() {
            SendCompensationBonusEmail('Sports');
        });        
    });
</script>
</asp:Content>