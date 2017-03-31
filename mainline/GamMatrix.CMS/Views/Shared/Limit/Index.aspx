<%@ Page Language="C#" PageTemplate="/ProfileMaster.master" Inherits="CM.Web.ViewPageEx<List<GamMatrixAPI.HandlerRequest>>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="GamMatrixAPI" %>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div id="limit-wrapper" class="content-wrapper">
<%: Html.H1(this.GetMetadata(".HEAD_TEXT")) %>
<ui:Panel runat="server" ID="pnLimit">


<table cellpadding="0" cellspacing="0" border="1" class="limit-table">
    <thead>
        <tr>
            <th class="col-1"><span><%= this.GetMetadata(".ListHeader_LimitType").SafeHtmlEncode()%></span></th>
            <th class="col-2"><span><%= this.GetMetadata(".ListHeader_Amount").SafeHtmlEncode()%></span></th>
            <th class="col-3"><span><%= this.GetMetadata(".ListHeader_Status").SafeHtmlEncode()%></span></th>
            <th class="col-4"><span><%= this.GetMetadata(".ListHeader_Expires").SafeHtmlEncode()%></span></th>
            <th class="col-5"><span></span></th>
        </tr>
    </thead>
    <tbody>
        <% foreach (HandlerRequest response in this.Model)
           {
               if (response.GetType().Name == "NegativeBalanceLimitRequest")
               {%>
        <%--<% Html.RenderPartial("NegativeBalanceLimitTableRow", (NegativeBalanceLimitRequest)response); %>--%>
             <%}
               else if (Settings.Limitation.Deposit_MultipleSet_Enabled && response.GetType().Name == "GetUserRgDepositLimitListRequest")
               {%>
        <% Html.RenderPartial("DepositLimitList", (GetUserRgDepositLimitListRequest)response); %>
             <%} else { %>
        <% Html.RenderPartial("LimitTableRow", response); %>
             <%}           
           } %>
    </tbody>
    </table>

</ui:Panel>

</div>

<script type="text/javascript">
    $(function () {
        $('table.limit-table tbody tr:nth-child(odd)').addClass('odd');
    });
</script>
</asp:Content>

