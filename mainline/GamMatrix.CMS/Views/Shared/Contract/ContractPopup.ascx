<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<%@ Import Namespace="GmCore" %>

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
<div class="ContractPopup" id="ContractPopup">
<%=this.GetMetadata(".CustomCSS").HtmlEncodeSpecialCharactors() %>
<div class="main-pane">
    <ui:InputField ID="fldTermsConditions" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	        <LabelPart></LabelPart>
	        <ControlPart>
                <label for="btnTermsConditions"><%= this.GetMetadata(".TermsConditions_Label").SafeHtmlEncode()%></label>
                <a href="/<%=MultilingualMgr.GetCurrentCulture() %>/GenerateContract.ashx?userid=<%=Profile.UserID %>" target="_blank"><%= this.GetMetadata(".TermsConditions_Link").SafeHtmlEncode()%></a>
            </ControlPart>
        </ui:InputField>
     <%------------------------------------------
        contract validity
     -------------------------------------------%>
     <ui:InputField ID="fldContractValidity" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
        <LabelPart><%= this.GetMetadata("/Register/_PersionalInformation_ascx.ContractValidity_Label").SafeHtmlEncode()%></LabelPart>
        <ControlPart>
            <%: Html.DropDownList("contractValidity", GetContractValidity(), new 
            {
                @id = "ddlContractValidity2",
                @validator = ClientValidators.Create().Required(this.GetMetadata("/Register/_PersionalInformation_ascx.ContractValidity_Empty"))
            })%>
        </ControlPart>
    </ui:InputField>
    <div class="button-wraper">
	    <%=Html.Button(this.GetMetadata(".Button_Text").HtmlEncodeSpecialCharactors(),new {@id="buttonRenewContract" }) %>
    </div>
</div>
<script type="text/javascript">
	$(function() {
		var bd = top.document.body;
        if ($(bd).find("#ContractPopup").length == 0) {
            $("#ContractPopup").appendTo(bd);
        }

        $(bd).find("#ContractPopup").modalex(500, 300, true, bd);
        //$(bd).find("#simplemodal-container .simplemodal-close").css("display", "block");

        $('#buttonRenewContract').click(function () {
			$.post('<%= this.Url.RouteUrl("Profile", new { @action = "RenewContract" }).SafeJavascriptStringEncode() %>',
                { contractValidity: $('#ddlContractValidity2').val() },
                function (json) {
                    var $buttonRenewContract = $("#buttonRenewContract");
                    $buttonRenewContract.toggleLoadingSpin(false);

                    if (json.success) {
                        $("#simplemodal-container .simplemodal-close").trigger("click");
                        alert('<%=this.GetMetadata(".Success_Text").SafeJavascriptStringEncode() %>');
                    }
                    else {
                        alert(json.error);
                    }
                }, 'json').error(function () {
                $("#buttonRenewContract").toggleLoadingSpin(true);
            });
		});
	});
</script>
</div>
<% } %>