<%@ Page Language="C#" PageTemplate="/RootMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


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
                <a class="BreadLink url" href="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/Transfer/.Url") %>" itemprop="url" title="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/ResponsibleGaming/.Title") %>">
                    <span itemprop="title"><%= this.GetMetadata("/Metadata/Breadcrumbs/Home/Transfer/.Name") %></span>
                </a>
            </li>
        </ul>
    </div>
<% if (Profile.IsAuthenticated)
   { %>
        <% Html.RenderPartial("Dialog", this.ViewData.Merge()); %>
<% }
   else
   { %>
        <% Html.RenderPartial("Anonymous", this.ViewData.Merge()); %>
<% } %>

<script type="text/javascript">
    $(function () {
        function getIframeDocument(ifm) {
            try {
                var f = ifm;
                return f && typeof (f) == 'object' && f.contentDocument || f.contentWindow && f.contentWindow.document || f.document;
            }
            catch (e) {
                return { location: null };
            }
        };

        var $iframe = null;
        var iframes = self.parent.document.getElementsByTagName("iframe");
        for (var i = 0; i < iframes.length; i++) {
            try{
                if (document.location.toString() == getIframeDocument(iframes[i]).location.toString()) {
                    $iframe = $(iframes[i]);
                    break;
                }                
            }catch(err){

            }
        }

        setInterval(function () {
            var h = $('#transfer-wrapper').height();
            $iframe.height(h);
        }, 500);

    });    
</script>
</asp:Content>

