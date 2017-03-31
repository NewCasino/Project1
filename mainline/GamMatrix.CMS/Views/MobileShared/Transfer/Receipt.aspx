<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>
<%@ Import Namespace="Finance" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>

<script type="text/C#" runat="server">
	private GetTransInfoRequest getTransInfoRequest
	{
		get
		{
			return this.ViewData["getTransInfoRequest"] as GetTransInfoRequest;
		}
	}

	private ProcessTransRequest processTransRequest
	{
		get
		{
			return this.ViewData["processTransRequest"] as ProcessTransRequest;
		}
		
	}
	
    private string GetDebitMessage()
    {
        return string.Format(this.GetMetadata(".DebitAccount"), 
			this.GetMetadata(string.Format("/Metadata/GammingAccount/{0}.Display_Name",
			processTransRequest.Record.DebitPayItemVendorID.ToString()))
		);
    }

    private string GetCreditMessage()
    {
        return string.Format(this.GetMetadata(".CreditAccount"), 
			this.GetMetadata(string.Format("/Metadata/GammingAccount/{0}.Display_Name",
			processTransRequest.Record.CreditPayItemVendorID.ToString()))
		);
    }
</script>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>

<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
	<div class="Box">
		<div class="BoxContent">
			<% Html.RenderPartial("/Components/UserFlowStatus", new UserFlowStatusViewModel { FlowSteps = 2, CurrentStep = 2 }); %>
			<% Html.RenderPartial("/Components/StatusNotification", new StatusNotificationViewModel(StatusType.Success, this.GetMetadata(".Success_Message"))); %>

			<div class="MenuList L DetailContainer">
				<ol class="DetailPairs ProfileList">
					<li>
						<div class="ProfileDetail">
							<span class="DetailName"><%= this.GetMetadata(".Transaction_ID").SafeHtmlEncode()%></span> 
							<span class="DetailValue"><%= getTransInfoRequest.TransID.ToString().SafeHtmlEncode()%></span>
						</div>
					</li>
					<li>
						<div class="ProfileDetail">
							<span class="DetailName"><%= GetDebitMessage().SafeHtmlEncode()%></span> 
							<span class="DetailValue"><%= MoneyHelper.FormatWithCurrency(processTransRequest.Record.DebitRealCurrency,
														processTransRequest.Record.DebitRealAmount)%></span>
						</div>
					</li>
                    <% 
                    if (getTransInfoRequest.FeeData != null)
					{
                        foreach (TransFeeData fee in getTransInfoRequest.FeeData)
						{
				    %>
				    <li>
					    <div class="ProfileDetail">
						    <span class="DetailName"><%= this.GetMetadata(".Receipt_Fee")%></span> <span class="DetailValue"><%= MoneyHelper.FormatWithCurrency( getTransInfoRequest.PostingData[0].Record.Currency
																														      , getTransInfoRequest.PostingData[0].Record.Amount 
																														      ) %></span>
					    </div>
				    </li>
				    <%
						    }
					    }
				    %>
					<li>
						<div class="ProfileDetail">
							<span class="DetailName"><%= GetCreditMessage()%></span> 
							<span class="DetailValue"><%= MoneyHelper.FormatWithCurrency(processTransRequest.Record.CreditRealCurrency,
														processTransRequest.Record.CreditRealAmount)%></span>
						</div>
					</li>
				</ol>
			</div>
		</div>
	</div>
</asp:Content>

