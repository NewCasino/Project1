<%@ Page Language="C#" PageTemplate="/ProfileMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>" %>


<asp:content contentplaceholderid="cphHead" runat="Server">

</asp:content>


<asp:content contentplaceholderid="cphMain" runat="Server">
<div class="Breadcrumbs" role="navigation">
        <ul class="BreadMenu Container" role="menu">
            <li class="BreadItem" role="menuitem" itemtype="http://data-vocabulary.org/Breadcrumb" itemscope="itemscope">
                <a class="BreadLink url" href="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/.Url") %>" itemprop="url" title="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/.Title") %>">
                    <span itemprop="title"><%= this.GetMetadata("/Metadata/Breadcrumbs/Home/.Name") %></span>
                </a>
            </li>
            <li class="BreadItem BreadCurrent" role="menuitem" itemtype="http://data-vocabulary.org/Breadcrumb" itemscope="itemscope">
                <a class="BreadLink url" href="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/WithdrawPage/.Url") %>" itemprop="url" title="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/ResponsibleGaming/.Title") %>">
                    <span itemprop="title"><%= this.GetMetadata("/Metadata/Breadcrumbs/Home/WithdrawPage/.Name") %></span>
                </a>
            </li>
        </ul>
    </div>
<div id="withdraw-wrapper" class="content-wrapper">
<%: Html.H1(this.GetMetadata(".HEAD_TEXT"))%>
<ui:Panel runat="server" ID="pnWithdraw">
    <div id="error_step">
    <center>
        <br />
        <%: Html.ErrorMessage(
            (this.ViewData["ErrorMessage"] as string).DefaultIfNullOrEmpty(
                    this.Request["ErrorMessage"].DefaultIfNullOrEmpty( this.GetMetadata(".Message") ) 
                           )
            ) %>
    </center>
    </div>
</ui:Panel>

</div>
<script>
    try {
        if (top.location.href != self.location.href) {
            if ($(".ConfirmationBox.simplemodal-container", parent.document.body).length > 0) {
                $(".ConfirmationBox.simplemodal-container", parent.document.body).hide();
                top.location.href = self.location.href;
            }
        }
    } catch (err) { console.log(err); }

</script>

<ui:MinifiedJavascriptControl runat="server">
<script type="text/javascript">
    jQuery('body').addClass('WithdrawPage');
</script>
</ui:MinifiedJavascriptControl>

</asp:content>

