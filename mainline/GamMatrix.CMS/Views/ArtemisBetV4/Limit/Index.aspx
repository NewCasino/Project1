<%@ Page Language="C#" PageTemplate="/ProfileMaster.master" Inherits="CM.Web.ViewPageEx<List<GamMatrixAPI.HandlerRequest>>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="GamMatrixAPI" %>

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
                <a class="BreadLink url" href="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/Limit/.Url") %>" itemprop="url" title="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/ResponsibleGaming/.Title") %>">
                    <span itemprop="title"><%= this.GetMetadata("/Metadata/Breadcrumbs/Home/Limit/.Name") %></span>
                </a>
            </li>
        </ul>
    </div>
<div id="limit-wrapper" class="content-wrapper limit-wrapper">
<h1 id="ProfileTitle" class="ProfileTitle LimitTitle"> <%: this.GetMetadata(".HEAD_TEXT") %> </h1>
<ui:Panel runat="server" ID="pnLimit">

<div class="limit-table">
    <div class="holder-flex-100 tableHead">
            <div class="col-20"><span><%= this.GetMetadata(".ListHeader_LimitType").SafeHtmlEncode()%></span></div>
            <div class="col-20"><span><%= this.GetMetadata(".ListHeader_Amount").SafeHtmlEncode()%></span></div>
            <div class="col-20"><span><%= this.GetMetadata(".ListHeader_Status").SafeHtmlEncode()%></span></div>
            <div class="col-20"><span><%= this.GetMetadata(".ListHeader_Expires").SafeHtmlEncode()%></span></div>
            <div class="col-20"><span></span></div>
    </div>

        <% foreach (HandlerRequest response in this.Model)
           {
               if (response.GetType().Name == "NegativeBalanceLimitRequest")
               {%>
        <% Html.RenderPartial("NegativeBalanceLimitTableRow", (NegativeBalanceLimitRequest)response); %>
             <%}
               else { %>
        <% Html.RenderPartial("LimitTableRow", response); %>
             <%}           
           } %>
</div>

</ui:Panel>

</div>


<ui:MinifiedJavascriptControl runat="server">
<script type="text/javascript">
 $(function () {
        $('table.limit-table tbody tr:nth-child(odd)').addClass('odd');
    });

jQuery('body').addClass('LimitPages');
jQuery('.inner').addClass('LimitContent');
jQuery('.MainProfile').addClass('MainLimits');
jQuery('.sidemenu li').addClass('PMenuItem');
jQuery('.sidemenu li span').addClass('PMenuLinkContainer');
jQuery('.sidemenu li span a').addClass('ProfileMenuLinks');

setTimeout(function(){
jQuery('.ProfileContent').prepend(jQuery('#ProfileTitle'));
},1);
</script>
</ui:MinifiedJavascriptControl>

</asp:Content>

