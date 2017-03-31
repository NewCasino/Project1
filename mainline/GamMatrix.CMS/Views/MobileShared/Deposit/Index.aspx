<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>

<script type="text/C#" runat="server">
    protected bool IsStyle2() {
        return Settings.MobileV2.IsV2DepositProcessEnabled;
    }
    protected override void OnPreRender(EventArgs e)
    {
        base.OnPreRender(e);
        //V2Style.Visible =  IsStyle2();
    }
</script>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>

<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
	<div id="DepositOptionsList" class="UserBox CenterBox DepositOptionsList <%= (!IsStyle2() ? "" : "StyleV2") %>" data-step="1">
        <div class="BoxContent <%= (!IsStyle2() ? "DepositContent" : "DepositContent_V2") %>" id="DepositContent">
            <% if (!IsStyle2()) { %>
			    <% Html.RenderPartial("/Components/UserFlowStatus", new UserFlowStatusViewModel() { FlowSteps = 4 }); %>
            <% } %>

			<% 
                if (IsStyle2())
                {
                    Html.RenderPartial("PaymentMethodListV2", this.ViewData.Merge(new { }));
                }
                else
                {
                    Html.RenderPartial("PaymentMethodList", this.ViewData.Merge(new { }));
                } %>
		</div>
	</div>
    <% Html.RenderPartial("/Deposit/UKTermsConditions", this.ViewData.Merge(new { })); %>
    <% Html.RenderPartial("SetLimitPopup", this.ViewData.Merge(new { })); %>
    <script>
        var isStyleV2 = <%=IsStyle2() ? "true" : "false" %>;
        if(isStyleV2){
            $("body").addClass("StyleV2").addClass("DepositPage_V2");
        }
    </script>
</asp:Content>

