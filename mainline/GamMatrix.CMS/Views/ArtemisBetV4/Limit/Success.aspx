<%@ Page Language="C#" PageTemplate="/ProfileMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div id="limit-wrapper" class="content-wrapper">
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
<%: Html.H1(this.GetMetadata(".HEAD_TEXT")) %>
<ui:Panel runat="server" ID="pnLimit">
        <%: Html.SuccessMessage(this.GetMetadata(".Message")) %>
        <%: Html.Button( this.GetMetadata(".Button_Back"), new { @onclick = "self.location = '/Limit'; return false;" }) %>
</ui:Panel>

</div>
<% if(!string.IsNullOrWhiteSpace(Request.QueryString["ref"])){ %>
   
<script type="text/javascript">
    $(function () {
        window.setTimeout(window.location.href = '<%=Request.QueryString["ref"].SafeJavascriptStringEncode()%>', 5000);
    });

</script>
<% }%>

<ui:MinifiedJavascriptControl runat="server">
<script type="text/javascript">
    $('body').addClass('LimitPages');
</script>
</ui:MinifiedJavascriptControl>

</asp:Content>

