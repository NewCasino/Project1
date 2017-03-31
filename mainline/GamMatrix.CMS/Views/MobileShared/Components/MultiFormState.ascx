<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Dictionary<string, string>>" %>
<script type="text/C#" runat="server"> 
    protected string paymentMethodName
    {
        get
        {
            var path = Request.Path;
            if (path.IndexOf("eposit/Prepare/") > 0)
            {
                return path.Substring(path.IndexOf("/Prepare/") + 9, path.Length - path.IndexOf("/Prepare/") - 9);
            }
            else
            {
                return "";
            }
        }
    }

    private Finance.PaymentMethod paymentMethod = null;
    protected override void OnPreRender(EventArgs e)
    {
        base.OnPreRender(e);
        if (Settings.MobileV2.IsV2DepositProcessEnabled && !string.IsNullOrEmpty(paymentMethodName))
        {
            paymentMethod = Finance.PaymentMethodManager.GetPaymentMethods()
                    .FirstOrDefault(p => string.Equals(p.UniqueName, paymentMethodName, StringComparison.InvariantCultureIgnoreCase)); 
        }
    }
</script> 
<%
    // If deposit V2 is enabled, then there is no need for state vars in prepare step, but it should appear Deposit/AccountView.ascx partial
    if (Settings.MobileV2.IsV2DepositProcessEnabled && !string.IsNullOrEmpty(paymentMethodName) && paymentMethod != null)
    {
        Html.RenderPartial("/Deposit/AccountView", this.ViewData.Merge(new { StyleV2 = Settings.MobileV2.IsV2DepositProcessEnabled, DepositModel = paymentMethod }));
    }
    else
    { 
        foreach (KeyValuePair<string, string> stateVar in Model)
        {
            if (!string.IsNullOrEmpty(stateVar.Value))
            { 
            %><input id="<%= stateVar.Key %>" name="<%= stateVar.Key %>" type="hidden" value="<%= stateVar.Value %>" /><%
            } 
        }
    } 
%> 
<%------------------------------------------
    IovationBlackbox
 -------------------------------------------%>
  <%if (Settings.IovationDeviceTrack_Enabled){ %>
        <% Html.RenderPartial("/Components/IovationTrack", this.ViewData);  %>
 <%} %>
      