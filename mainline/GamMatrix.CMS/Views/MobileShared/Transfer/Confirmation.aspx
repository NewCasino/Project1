<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<GamMatrixAPI.PrepareTransRequest>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>
<%@ Import Namespace="Finance" %>

<script type="text/C#" runat="server">
    private string GetDebitMessage()
    {
        return string.Format(this.GetMetadata(".DebitAccount"), 
			this.GetMetadata(string.Format("/Metadata/GammingAccount/{0}.Display_Name",
			this.Model.Record.DebitPayItemVendorID.ToString()))
		);
    }

    private string GetCreditMessage()
    {
        return string.Format(this.GetMetadata(".CreditAccount"), 
			this.GetMetadata(string.Format("/Metadata/GammingAccount/{0}.Display_Name", 
			this.Model.Record.CreditPayItemVendorID.ToString()))
		);
    }
</script>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
	
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
	<div class="Box">
		<div class="BoxContent">
			<% Html.RenderPartial("/Components/UserFlowStatus", new UserFlowStatusViewModel { FlowSteps = 2, CurrentStep = 1 }); %>
			<form action="<%= this.Url.RouteUrl("Transfer", new { @action = "Confirm", @sid = this.Model.Record.Sid }).SafeHtmlEncode() %>" method="post">
                
				<div class="MenuList L DetailContainer">
					<ol class="DetailPairs ProfileList">
						<li>
							<div class="ProfileDetail">
								<span class="DetailName"><%= GetDebitMessage().SafeHtmlEncode()%></span> 
								<span class="DetailValue"><%= MoneyHelper.FormatWithCurrency(this.Model.Record.DebitRealCurrency, 
															this.Model.Record.DebitRealAmount)%></span>
							</div>
						</li>
                        <%
						if (this.Model.FeeList != null && this.Model.FeeList.Count > 0)
						{
							foreach (var fee in this.Model.FeeList)
							{
					    %>
					    <li>
						    <div class="ProfileDetail">
							    <span class="DetailName"><%= this.GetMetadata(".Fee").SafeHtmlEncode()%></span>
                                <span class="DetailValue"><%= MoneyHelper.FormatWithCurrency(fee.RealCurrency, fee.RealAmount)%></span>
						    </div>
					    </li>
					    <%
							    }
						    }
					    %>
						<li>
							<div class="ProfileDetail">
								<span class="DetailName"><%= GetCreditMessage()%></span> 
								<span class="DetailValue"><%= MoneyHelper.FormatWithCurrency(this.Model.Record.CreditRealCurrency, 
															this.Model.Record.CreditRealAmount)%></span>
							</div>
						</li>
					</ol>
				</div>
				<% Html.RenderPartial("/Components/ForfeitBonusWarning", new ForfeitBonusWarningViewModel(this.Model.Record.DebitPayItemVendorID, this.Model.Record.DebitRealAmount)); %>
				<% Html.RenderPartial("/Components/UserFlowNavigation", new UserFlowNavigationViewModel { NextName = this.GetMetadata(".Button_Confirm") }); %>
			</form>
			<script type="text/javascript">
				$(CMS.mobile360.Generic.input);
			</script>
		</div>
	</div>
</asp:Content>