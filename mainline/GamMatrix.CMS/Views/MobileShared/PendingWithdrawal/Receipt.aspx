<%@ Page Language="C#" PageTemplate="/InfoMaster.master" Inherits="CM.Web.ViewPageEx<GamMatrixAPI.GetTransInfoRequest>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>

<script language="C#" type="text/C#" runat="server">
    private string GetMessage()
    {
        string accountName = this.GetMetadata(string.Format("/Metadata/GammingAccount/{0}.Display_Name", this.Model.TransData.DebitPayItemVendorID.ToString()));
        string format = this.GetMetadata(".Message");

        return string.Format(format
            , this.Model.TransData.DebitRealAmount
            , this.Model.TransData.DebitRealCurrency
            , accountName
            );
    }
</script>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
   <% Html.RenderPartial("/Components/StatusNotification", new StatusNotificationViewModel(StatusType.Success, GetMessage()) { IsHtml = true }); %>
</asp:Content>

