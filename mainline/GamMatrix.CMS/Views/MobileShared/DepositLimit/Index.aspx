<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<List<GamMatrixAPI.RgDepositLimitInfoRec>>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>

<script type="text/C#" runat="server">
    private List<RgDepositLimitPeriod> GetPeriods()
    {
        List<RgDepositLimitPeriod> list = new List<RgDepositLimitPeriod>();
        list.Add(RgDepositLimitPeriod.Daily);
        list.Add(RgDepositLimitPeriod.Weekly);
        list.Add(RgDepositLimitPeriod.Monthly);
        return list;
    }
</script>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>

<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
	<div class="UserBox CenterBox">
		<div class="BoxContent">
			<% 			

                if (Settings.Limitation.Deposit_MultipleSet_Enabled)
                {
                    Html.RenderPartial("/Components/SettingsNavigator", new SettingsNavigatorViewModel { CurrentTab = SettingsNavigatorViewModel.Sections.DepositLimit, HideSubHeading = true });
                    
                    foreach (RgDepositLimitPeriod period in GetPeriods())
                    {
                        %>
            <div class="Box BonusContainnerBox LimitContainnerBox">
                <h2 class="SubHeader"><a class="SHToggle ToggleButton" href="#"> <span class="ToggleArrow">&ndash;</span> <span class="SHText"><%= this.GetMetadata(string.Format(".{0}_Title", period.ToString())).DefaultIfNullOrWhiteSpace(period.ToString()).SafeHtmlEncode()%></span></a></h2>
                <div class="BoxContent Container ToggleContent">
                        <%
                        if (this.Model != null && this.Model.Exists(l => l.Period == period))
                            Html.RenderPartial("DisplayView", this.Model.FirstOrDefault(l => l.Period == period));
                        else
                            Html.RenderPartial("InputView", null, new ViewDataDictionary() { new KeyValuePair<string, object>("Period", period) });
                            %>
                </div>
            </div>  
                            <%
                    }
                }
                else
                {
                    Html.RenderPartial("/Components/SettingsNavigator", new SettingsNavigatorViewModel { CurrentTab = SettingsNavigatorViewModel.Sections.DepositLimit });
                    Html.RenderPartial("DisplayView", this.Model.FirstOrDefault());
                }
			%>
		</div>
	</div>
	<script type="text/javascript">
	    $(CMS.mobile360.Generic.init);
	    CMS.mobile360.views.ToggleContent.createFor('.LimitContainnerBox');
	</script>
</asp:Content>

