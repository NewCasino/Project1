<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>" %>

<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="Finance" %>
<%@ Import Namespace="CM.db" %>
<%@ Import Namespace="CM.db.Accessor" %>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>

<script language="C#" type="text/C#" runat="server">
    private GetTransInfoRequest GetTransactionInfo()
    {
        return this.ViewData["getTransInfoRequest"] as GetTransInfoRequest;
    }

    private PrepareTransRequest GetPrepareTransRequest()
    {
        return this.ViewData["prepareTransRequest"] as PrepareTransRequest;
    }

    private ProcessTransRequest GetProcessTransRequest()
    {
        return this.ViewData["processTransRequest"] as ProcessTransRequest;
    }
    private string GetDebitMessage()
    {
        return string.Format(this.GetMetadata(".DebitAccount")
        , this.GetMetadata(string.Format("/Metadata/GammingAccount/{0}.Display_Name", GetProcessTransRequest().Record.DebitPayItemVendorID.ToString()))
        );
    }
    private string GetCreditMessage()
    {
        UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
        cmUser user = ua.GetByID(GetProcessTransRequest().Record.ContraUserID);
        return string.Format(this.GetMetadata(".CreditAccount")
        , string.Format("{0} {1}({2})", user.FirstName, user.Surname, user.Username)
        , this.GetMetadata(string.Format("/Metadata/GammingAccount/{0}.Display_Name", GetProcessTransRequest().Record.CreditPayItemVendorID.ToString()))
        );
    }
</script>

<asp:content contentplaceholderid="cphHead" runat="Server">
</asp:content>


<asp:content contentplaceholderid="cphMain" runat="Server">
        <% Html.RenderPartial("/Components/UserFlowStatus", new UserFlowStatusViewModel { FlowSteps = 4, CurrentStep = 4 }); %>
<div class="UserBox TransferBox CenterBox">
    <div class="BoxContent"> 
        <% Html.RenderPartial("/Components/StatusNotification", new StatusNotificationViewModel(StatusType.Success, this.GetMetadata(".Message"))); %>

    <%------------------------
    The confirmation table
    ------------------------%>
        <div class="MenuList L DetailContainer">
				<ol class="DetailPairs ProfileList">
					<li>
						<div class="ProfileDetail">
							<span class="DetailName">
                                <%= this.GetMetadata(".Transaction_ID").SafeHtmlEncode() %></span> 
							<span class="DetailValue"><%= GetTransactionInfo().TransID.ToString() %></span>
						</div>
					</li>
					<li>
						<div class="ProfileDetail">
							<span class="DetailName"><%= GetDebitMessage().SafeHtmlEncode()%></span> 
							<span class="DetailValue"><%= MoneyHelper.FormatWithCurrency(GetProcessTransRequest().Record.DebitRealCurrency
            , GetProcessTransRequest().Record.DebitRealAmount)%></span>
						</div>
					</li>
					<li>
						<div class="ProfileDetail">
							<span class="DetailName"><%= GetCreditMessage().SafeHtmlEncode()%></span> 
							<span class="DetailValue"><%= MoneyHelper.FormatWithCurrency(GetProcessTransRequest().Record.CreditRealCurrency
            , GetProcessTransRequest().Record.CreditRealAmount)%></span>
						</div>
					</li></ol>
			</div>
    <%--<center> 
    <button type="submit" class="Button RegLink DepLink BackLink" id="btnBuddyTransferPrint" @onclick = "window.print(); return false;">
    <span class="ButtonText"><%= this.GetMetadata(".Button_Print").SafeHtmlEncode()%></span>
    </button>   
    </center>--%>
    </div>
</div>


<script language="javascript" type="text/javascript">
    $(window).load(function () {
        $(document).trigger("BALANCE_UPDATED");
        <%=this.GetMetadata(".Receipt_Script").SafeJavascriptStringEncode()%>
    });
</script>
</asp:content>

