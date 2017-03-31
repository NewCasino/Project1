<%@ Page Language="C#" Inherits="CM.Web.ViewPageEx<GamMatrix.CMS.Integration.OAuth.RegisterDkVerifyModel>" PageTemplate="/RootMaster.master" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>" %>

<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="CM.db" %>
<%@ Import Namespace="CM.db.Accessor" %>
<%@ Import Namespace="BLToolkit.Data" %>
<%@ Import Namespace="BLToolkit.DataAccess" %>

<asp:content contentplaceholderid="cphHead" runat="Server">
    <style>
        html, html > body {
            background: transparent;
        }
    </style>
</asp:content>
<asp:content contentplaceholderid="cphMain" runat="Server"> 
    <%

        string str = !string.IsNullOrEmpty(Model.GeneratedHTML) && Model.GeneratedHTML.Length > 0
            ? Model.GeneratedHTML.Replace("\\\"", "\"").Replace("\\r\\n", "") : "";
        if (str.StartsWith("\""))
        {
            str = str.Substring(1, str.Length - 1);
        }
        if (str.EndsWith("\""))
        {
            str = str.Substring(0, str.Length - 1);
        }
        Response.Write(str);
        %>

 
</asp:content>
