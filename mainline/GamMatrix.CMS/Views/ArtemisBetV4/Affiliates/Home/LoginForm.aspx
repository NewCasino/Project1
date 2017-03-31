<%@ Page Language="C#" PageTemplate="/RootMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
<style type="text/css">
@import url(//cdn.everymatrix.com/ArtemisBetV3/accountwidget.css);
html, body { background-image:none !important; background-color:transparent !important; }
</style>
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<form target="_blank" method="post" action="http://affiliates.artemisbet100.com/user/login.do">
<div id="header">
    <div id="login-box">
<%: Html.LinkButton(this.GetMetadata(".LINK_REGISTER")
                                    , new { @class = "join_now", @href = "http://affiliates.artemisbet100.com/user/register.do", @target = "_blank" }
            )%>  
        <div id="login-pane">
            <div class="username_wrap">
                <%: Html.TextboxEx("username", "", this.GetMetadata(".Username_Wartermark"))%>
            </div>
            <div class="password_wrap">
                <%: Html.TextboxEx("password", "", this.GetMetadata(".Password_Wartermark"), new { type = "password" })%>
            </div>
            <div class="login_btn">
                <%: Html.Button( this.GetMetadata(".Login_Btn_Text"), new { @type = "submit" }) %>
            </div>
            <div style="clear:both"></div>
        </div>  
    
    </div>
</div>
</form>
<ui:MinifiedJavascriptControl runat="server" Enabled="true" AppendToPageEnd="true">
<script type="text/javascript"> 
$("body").addClass("affiliatePage").addClass("iframeWidget");
</script>
</ui:MinifiedJavascriptControl>
</asp:Content>

