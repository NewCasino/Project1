<%@ Page Language="C#" PageTemplate="/RootMaster.master" Inherits="CM.Web.ViewPageEx<GamMatrixAPI.PrepareTransRequest>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="Finance" %>
<%@ Import Namespace="CM.db" %>
<%@ Import Namespace="CM.db.Accessor" %>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
    <style type="text/css">
        body
        {
            margin: 0;
            padding: 0;
        }
        .error_message{
            background-color:#FFF;
            border-top:1px solid #D1D1D1;
            border-left:1px solid #D1D1D1;
            border-right:1px solid #D1D1D1;
            display:block;
            height:50px;
            margin:8px 8px -8px;
            padding:0;
            width:500px;
        }
        .error_text{margin:5px 10px 0; font-size:14px; text-align:left; color:#ff0000;}
        .error_text a{color:#FF0000;text-decoration:underline;}
    </style>
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div class="error_message"><div class="error_text"><%=this.GetMetadata(".Message").HtmlEncodeSpecialCharactors() %></div></div>
<div class="DeclindedPanel"></div>
<iframe frameborder="0" scrolling="no" width="516px" height="488px" style="width:516px;height:488px;overflow:hidden;" src="<%=this.GetMetadata("/Metadata/Settings.DeclindedDeposit_SuggestionUrl").SafeHtmlEncode()%>"></iframe>
</asp:Content>

