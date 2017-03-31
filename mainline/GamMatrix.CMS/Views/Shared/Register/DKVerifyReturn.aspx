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
        if (this.Model == null || string.IsNullOrEmpty(this.Model.CPR) || string.IsNullOrEmpty(this.Model.PID) || ( this.Model  != null && this.Model.ErrorDetails != null && !string.IsNullOrEmpty(this.Model.ErrorDetails)) )
          {
            if(  this.Model  != null && !string.IsNullOrEmpty( this.Model.ErrorDetails) ){
               %> alert("<%=this.Model.ErrorDetails.SafeJavascriptStringEncode().Replace("\r\n", " ").Replace("\n", " ")  %>");
           <% }
              %>  
            parent.window.$(parent.document).trigger('COUNTRY_SELECTION_CHANGED_DKPOPUPCLOSE');  
        <%}else{%>
            if ($(top.document).find("#txtUsername").val() == "<%=  this.Model.CPR  %>") {
                $(top.document).find("#txtUsername").val("<%= this.Model.PID  %>");
                parent.window.$(parent.document).trigger('COUNTRY_SELECTION_CHANGED_DKPOPUPCLOSE');
                parent.window.$(parent.document).trigger('REGISTER_FORM_SUBMIT');
            } else {
                parent.window.$(parent.document).trigger('COUNTRY_SELECTION_CHANGED_DKPOPUPCLOSE');
                alert("<%=this.GetMetadata("/Register/_PersionalInformation_ascx.CPRNumber_Different").SafeJavascriptStringEncode()%>");
                $(top.document).find('#btnRegisterUser').toggleLoadingSpin(false);
            }
            //$(top.document).find("#txtPassword,#txtRepeatPassword").val("<%=  (DateTime.Now.Ticks.ToString() + this.Model.CPR)  %>");
            //$(top.document).find("#txtPersonalID").val("<%=  this.Model.CPR  %>");
            //$(top.document).find("#ddlSecurityQuestion").val($(top.document).find("#ddlSecurityQuestion option").eq(1).val());
            //$(top.document).find("#fldSecurityAnswer input").val("<%=  !string.IsNullOrEmpty(this.Model.Email) ? this.Model.Email:this.Model.CPR %>");

            //$(top.document).find("#btnRegisterUser").click();
        <%}%>
    </script>
</asp:content>
