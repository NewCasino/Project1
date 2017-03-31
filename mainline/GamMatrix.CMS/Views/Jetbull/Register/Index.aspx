<%@ Page Language="C#" Inherits="CM.Web.ViewPageEx" PageTemplate="/DefaultMaster.master" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>" %>

<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="CM.db" %>
<%@ Import Namespace="CM.db.Accessor" %>
<%@ Import Namespace="BLToolkit.Data" %>
<%@ Import Namespace="BLToolkit.DataAccess" %>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
    
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">

<div id="register-wrapper" class="content-wrapper">
<%: Html.H1(this.GetMetadata(".HEAD_TEXT")) %>
<ui:Panel runat="server" ID="pnRegister">


<%
    if (Profile.IsAuthenticated)
        Response.Redirect( this.Url.RouteUrl( "Deposit", new { @action="Index" }), false );// logged in
    else if (string.IsNullOrWhiteSpace(Request.QueryString["l"]))
    {
        Html.RenderPartial("InputView");    %>
    <script language="javascript" type="text/javascript">
        //<![CDATA[
        var __Registration_Legal_Age = 18;

        $(document).ready(function () {
            $('#btnRegisterUser').before($('#fldTermsConditions').parent().detach());
            $('#fldTermsConditions').parent().wrap('<ul></ul>');

            $('#fldDOB').after($('#fldMobile').detach());
            $(document).bind("COUNTRY_SELECTION_CHANGED", function (e, data) {
                __Registration_Legal_Age = data.LegalAge;
            });
        });
    </script>
  <%}
    else
    {%>
    <style type="text/css">
        #register-wrapper
        {
            margin:0 auto;
            width: 60%;
            min-width:680px;
        }

        .reg_Panel
        {
            width:50%;
        }

        #fldFirstName #title {
            float: left;
            width: 28% !important;
        }
        #fldFirstName #txtFirstname {
            float: right !important;
            margin-right: 0 !important;
            width: 67% !important;
        }

    </style>
    <%
        Html.RenderPartial("InputViewLite");
    } 
%>

</ui:Panel>

</div>


</asp:Content>

