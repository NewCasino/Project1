<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


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
                <a class="BreadLink url" href="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/ContactUs/.Url") %>" itemprop="url" title="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/ResponsibleGaming/.Title") %>">
                    <span itemprop="title"><%= this.GetMetadata("/Metadata/Breadcrumbs/Home/ContactUs/.Name") %></span>
                </a>
            </li>
        </ul>
    </div>
    <div id="contactus-wrapper" class="content-wrapper contactus-wrapper">
        <%: Html.H1(this.GetMetadata(".HEAD_TEXT")) %>
            <ui:Panel runat="server" ID="pnContactUs">
                <div class="BoxInformation"><%=this.GetMetadata(".Information_HTML").HtmlEncodeSpecialCharactors()%></div>
                <% Html.RenderPartial("InputView", this.ViewData); %>
            </ui:Panel>
    </div>
    <ui:MinifiedJavascriptControl ID="MinifiedJavascriptControl1" runat="server" AppendToPageEnd="true">
        <script type="text/javascript">
            jQuery('body').addClass("AuthenticatedProfile");
        </script>
    </ui:MinifiedJavascriptControl>

</asp:Content>
