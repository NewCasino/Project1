<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="CM.Web.UI" %>

<script type="text/c#" runat="server">
private SelectList GetContractValidity()
{
    string [] paths = Metadata.GetChildrenPaths("/Metadata/ContractValidity");

    var list = paths.Select(p => new { Key = this.GetMetadata(p, ".Value"), Value = this.GetMetadata(p, ".Text") }).ToList();

    return new SelectList(list, "Key", "Value");
}

private bool isShowContract
{
    get
    {
        if (Profile.IsAuthenticated && Settings.EnableContract)
        {
            var contractRequest = GamMatrixClient.GetUserLicenseLTContractValidityRequest(Profile.UserID);
            if (contractRequest != null && (!contractRequest.IsValid || (contractRequest.IsValid && contractRequest.LastLicense != null && contractRequest.LastLicense.ContractExpiryDate > DateTime.Now)))
            {
                return false;
            }

            return true;
        }
        else
        {
            return false;
        }
    }
}
</script>

<% if (isShowContract)
{ %>
<div class="ContractPopupMask">
<div class="ContractPopup" id="ContractPopup">
<%=this.GetMetadata(".CustomCSS").HtmlEncodeSpecialCharactors() %>
    <ul class="FormList">
    <li class="FormItem" id="fldTermsConditions" runat="server">
		<label for="btnTermsConditions">
			<%= this.GetMetadata(".TermsConditions_Label").SafeHtmlEncode()%> 
			<a href="/<%=MultilingualMgr.GetCurrentCulture() %>/GenerateContract.ashx?userid=<%=Profile.UserID %>" target="_blank"><%= this.GetMetadata(".TermsConditions_Link").SafeHtmlEncode()%> </a>
		</label>
		<span class="FormStatus">Status</span>
		<span class="FormHelp"></span>
	</li>
     <%------------------------------------------
        contract validity
     -------------------------------------------%>
    <li class="FormItem" id="fldContractValidity" runat="server">
		<label class="FormLabel" for="ddlContractValidity2"><%= this.GetMetadata("/Register/_PersionalInformation_ascx.ContractValidity_Label").SafeHtmlEncode()%></label>
		<%: Html.DropDownList("contractValidity", GetContractValidity(), new 
            {
                @id = "ddlContractValidity2",
                @validator = ClientValidators.Create().Required(this.GetMetadata("/Register/_PersionalInformation_ascx.ContractValidity_Empty"))
            })%>
		<span class="FormStatus">Status</span>
		<span class="FormHelp"></span>
	</li>
    </ul>
    <div class="button-wraper">
        <a href="javascript:void(0);" class="AccountButton Button" id="buttonRenewContract"><%=this.GetMetadata(".Button_Text").SafeHtmlEncode() %></a>
    </div>
<script type="text/javascript">
	$(function() {
		var $bd = $(document);
		if ($bd.find(".ContractPopupMask").length == 0) {
		    $(".ContractPopupMask").appendTo($bd);
            
		}

		var $container = $(".ContractPopup", $bd);
		$(".ContractPopupMask").width($bd.width());
		$(".ContractPopupMask").height($bd.height());
		$(".ContractPopupMask").css("opacity", 1);
		var left = ($(window).width() - $container.width()) / 2;
		var top = ($(window).height() - $container.height()) / 2;
		if (left < 0) left = 0;
		if (top < 0) top = 0;
		$container.css('left', left).css('top', top);

        $('#buttonRenewContract').click(function () {
			$.post('<%= this.Url.RouteUrl("Profile", new { @action = "RenewContract" }).SafeJavascriptStringEncode() %>',
                { contractValidity: $('#ddlContractValidity2').val() },
                function (json) {
                    var $buttonRenewContract = $("#buttonRenewContract");

                    if (json.success) {
                        $(".ContractPopupMask").hide();
                        alert('<%=this.GetMetadata(".Success_Text").SafeJavascriptStringEncode() %>');
                    }
                    else {
                        alert(json.error);
                    }
                }, 'json').error(function () {
            });
		});
	});
</script>
</div>
</div>
<% } %>