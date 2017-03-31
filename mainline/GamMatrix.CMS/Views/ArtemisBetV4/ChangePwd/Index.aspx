<%@ Page Language="C#" PageTemplate="/ProfileMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">

</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
  <div class="Breadcrumbs" role="navigation">
        <ul class="BreadMenu Container" role="menu">
            <li class="BreadItem" role="menuitem" itemtype="http://data-vocabulary.org/Breadcrumb" itemscope="itemscope">
                <a class="BreadLink url" href="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/.Url") %>" itemprop="url" title="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/.Title") %>">
                    <span itemprop="title"><%= this.GetMetadata("/Metadata/Breadcrumbs/Home/.Name") %></span>
                </a>
            </li>
            <li class="BreadItem BreadCurrent" role="menuitem" itemtype="http://data-vocabulary.org/Breadcrumb" itemscope="itemscope">
                <a class="BreadLink url" href="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/ChangePwd/.Url") %>" itemprop="url" title="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/ResponsibleGaming/.Title") %>">
                    <span itemprop="title"><%= this.GetMetadata("/Metadata/Breadcrumbs/Home/ChangePwd/.Name") %></span>
                </a>
            </li>
        </ul>
    </div>
<div id="changepwd-wrapper" class="content-wrapper">
<h1 id="ProfileTitle" class="ProfileTitle"> <%: this.GetMetadata(".HEAD_TEXT") %> </h1>
<ui:Panel runat="server" ID="pnChangePwd">


<%
    if (Profile.IsAuthenticated)
        Html.RenderPartial("InputView", this.ViewData);
    else
        Html.RenderPartial("Anonymous", this.ViewData);
%>

</ui:Panel>

</div>

<ui:MinifiedJavascriptControl runat="server">
<script type="text/javascript">
jQuery('body').addClass('ProfilePage ChangePass');
jQuery('.inner').addClass('ProfileContent ChangePassContent');
jQuery('.sidemenu li').addClass('PMenuItem');
jQuery('.sidemenu li span').addClass('PMenuLinkContainer');
jQuery('.sidemenu li span a').addClass('ProfileMenuLinks');
setTimeout(function(){
jQuery('.ProfileContent').prepend(jQuery('#ProfileTitle'));
},1);
</script>
</ui:MinifiedJavascriptControl>

</asp:Content>

