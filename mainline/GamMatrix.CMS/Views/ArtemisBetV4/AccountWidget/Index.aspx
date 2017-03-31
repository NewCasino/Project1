<%@ Page Language="C#" PageTemplate="/RootMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
  <base target=_top>
</asp:Content>
<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div id="header">
  <% if (!Profile.IsAuthenticated){%>
  
    <%--: Html.CachedPartial("/Head/LoginPane", this.ViewData.Merge(new {@RefreshTarget = "top"})) --%>
<%--    
<div class="login-links">
        <%: Html.CachedPartial("/Head/ForgotPassword", this.ViewData.Merge()) %>
    </div>
--%>
  <% }else{ %>
  <div class="userarea-box TopLinks">
    <%: Html.CachedPartial("/Head/Logout", this.ViewData) %>
    <%: Html.CachedPartial("/Head/Transfer", this.ViewData) %>
    <%: Html.CachedPartial("/Head/Deposit", this.ViewData) %>
    <%: Html.CachedPartial("/Head/Myaccount", this.ViewData) %> 
    <%: Html.CachedPartial("/Head/Messages", this.ViewData) %> 
    <% Html.RenderPartial("/Head/Welcome", this.ViewData); %>
  </div> 
  <% Html.RenderPartial("/Messages/MessagesCount", this.ViewData); %> 
  <%} %>
</div>
<%
        string url = Request.QueryString["url"];
       url= url.Replace(@"/","").ToLower();
%>
<script type="text/javascript"> 
$(function(){
$("body").addClass("<%=url%>");
});
$("a.OpenLogin").click(function(e) {
            e.preventDefault();
                $("iframe.LoginDialog").remove();
                $('<iframe style="border:0px;width:400px;height:300px;display:none" frameborder="0" scrolling="no" src="/Login/Dialog?_=635960470713328192" allowTransparency="true" class="LoginDialog"></iframe>').appendTo(top.document.body);
                var $iframe = $("iframe.LoginDialog", top.document.body).eq(0);
                $iframe.modalex($iframe.width(), $iframe.height(), true, top.document.body);
            });
</script>
<ui:MinifiedJavascriptControl runat="server" Enabled="true" AppendToPageEnd="true">
<script type="text/javascript"> 
if( $.browser.mobile){$('input').bind('focus', function(e){ e.preventDefault();$(this).prev().blur().focus();});}
$("body").addClass("iframeWidget");
document.domain = $("body").data("cookiedomain");
</script>
</ui:MinifiedJavascriptControl>
</asp:Content>

