<%@ Page Language="C#" PageTemplate="/RootMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="CM.db" %>
<%@ Import Namespace="CM.db.Accessor" %>
<%@ Import Namespace="Finance" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="GamMatrixAPI" %>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<%
if(Profile.IsAuthenticated)
{
UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
cmUser user = ua.GetByID(Profile.UserID);
bool hasPersonalID = !String.IsNullOrEmpty(user.PersonalID);

    var paymentlist = PaymentMethodManager.GetPaymentMethods().Where(p => p.SupportWithdraw
            && GmCore.DomainConfigAgent.IsWithdrawEnabled(p)
            && p.WithdrawSupportedCountries.Exists(Profile.UserCountryID)
            ).ToList();
    foreach(var payment in paymentlist)
    {
                bool isWithdrawEnabled = GmCore.DomainConfigAgent.IsWithdrawEnabled(payment);
                bool isSupportWithdraw = payment.SupportWithdraw;
                bool isVailable = payment.IsAvailable;
                bool isSupportCountry = payment.SupportedCountries.Exists(Profile.UserCountryID);
%>
                <div>payment: <%=payment.UniqueName%></div>
                <div>isWithdrawEnabled: <%=isWithdrawEnabled%></div>
                <div>isSupportWithdraw: <%=isSupportWithdraw%></div>
                <div>isVailable: <%=isVailable%></div>
                <div>isSupportCountry: <%=isSupportCountry%></div>
                <div>PersonalID: <%=user.PersonalID%></div>
                <br/><br />
                <%--<div>hasPersonalID: <%=hasPersonalID%></div>
                <div>UserCountryID: <%=Profile.UserCountryID%></div>--%>
                
<%
    }

} 
else 
{
%>
<h1>user is not logged in</h1>
<%
}
%>
</asp:Content>

