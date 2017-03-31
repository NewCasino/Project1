<%@ Page Language="C#" Inherits="CM.Web.ViewPageEx<GamMatrix.CMS.Integration.OAuth.VerifyUserLoginResponse>" PageTemplate="/RootMaster.master" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>" %>

<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="CM.db" %>
<%@ Import Namespace="CM.db.Accessor" %>
<%@ Import Namespace="BLToolkit.Data" %>
<%@ Import Namespace="BLToolkit.DataAccess" %>

<asp:content ID="Content1" contentplaceholderid="cphHead" runat="Server">
    <style>
        html, html > body {
            background:transparent ;
        }
    </style>
</asp:content>
<asp:content ID="Content2" contentplaceholderid="cphMain" runat="Server"> 
    <script> 
        <%
        if (this.Model == null || string.IsNullOrEmpty(this.Model.CPR) || string.IsNullOrEmpty(this.Model.PID))
          {
            if(  this.Model  != null && !string.IsNullOrEmpty( this.Model.ErrorDetails) ){
               %> alert("<%=this.Model.ErrorDetails.SafeJavascriptStringEncode() %>");
           <% }
              %>  
            parent.window.$(parent.document).trigger('COUNTRY_SELECTION_CHANGED_DKPOPUPCLOSE');  
        <%}else{%>
            if ($(top.document).find("#txtUsername").val() == "<%=  this.Model.CPR  %>") {
                $(top.document).find("#txtUsername").val("<%= this.Model.PID  %>");
                $(parent.document).trigger('COUNTRY_SELECTION_CHANGED_DKPOPUPCLOSE');
                $(parent.document).trigger('REGISTER_FORM_SUBMIT');
            } else {
                $(parent.document).trigger('COUNTRY_SELECTION_CHANGED_DKPOPUPCLOSE');
                alert("<%=this.GetMetadata("/Register/_PersionalInformation_ascx.CPRNumber_Different").SafeJavascriptStringEncode()%>");
                $(top.document).find('#btnRegisterUser').toggleLoadingSpin(false);
            }
        <%}%>
    </script>
</asp:content>
