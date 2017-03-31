<%@ Page Language="C#" PageTemplate="/ProfileMaster.master" Inherits="CM.Web.ViewPageEx<Finance.PaymentMethod>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="CM.db" %>
<%@ Import Namespace="CM.db.Accessor" %>

<script language="C#" runat="server" type="text/C#">
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
    private string GetWarningMessage()
    {
        try
        {
            return string.Format(this.GetMetadata(".Warning_Message"), Profile.UserID);
        }
        catch
        {
            return this.GetMetadata(".Warning_Message");
        }
    }
</script>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div id="deposit-wrapper" class="content-wrapper">
<%: Html.H1( string.Format( "{0} - {1}", this.GetMetadata(".HEAD_TEXT"), this.Model.GetTitleHtml()) ) %>
<ui:Panel runat="server" ID="pnDeposit">


<% Html.RenderPartial("PaymentMethodDesc", this.Model); %>

<center>
<%: Html.WarningMessage( GetWarningMessage().HtmlEncodeSpecialCharactors(), true ) %>
</center>
<% if (this.Model.UniqueName.Equals("CEPBank", StringComparison.InvariantCulture)) 
   { %>
        <%= this.GetMetadata(".CEPBankInstruction").HtmlEncodeSpecialCharactors() %>
<%  }
    else 
    { %>    
        <%= this.GetMetadata(".Instruction").HtmlEncodeSpecialCharactors() %>
<%  } %>

</ui:Panel>
</div>
<% Html.RenderAction("LimitSetPopup", "Deposit"); %>
<%  Html.RenderPartial("PrepareBodyPlus", this.ViewData ); %>
</asp:Content>

