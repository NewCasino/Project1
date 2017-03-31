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
        if(  this.Model  != null && !string.IsNullOrEmpty( this.Model.ErrorDetails) ){
               %> alert("<%=this.Model.ErrorDetails.SafeJavascriptStringEncode().Replace("\r\n", " ").Replace("\n", " ")  %>");
           <% }
              
              %>  
        parent.window.$(parent.document).trigger('DKCHECK_LOGIN_POPUPCLOSE');
        top.window.location.reload();
 
    </script>
</asp:content>
