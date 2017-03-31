<%@ Page Language="C#" PageTemplate="/ProfileMaster.master" Inherits="CM.Web.ViewPageEx<Finance.PaymentMethod>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="Finance" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="System.Globalization" %>

<script language="C#" type="text/C#" runat="server">
    private GetTransInfoRequest _GetTransInfoRequest = null;
    private GetTransInfoRequest GetTransInfoRequest
    {
        get
        {
            if (_GetTransInfoRequest == null)
            {
                _GetTransInfoRequest = this.ViewData["getTransInfoRequest"] as GetTransInfoRequest;
            }
            return _GetTransInfoRequest;
        }
    }
    
    private PrepareTransRequest _PrepareTransRequest = null;
    private PrepareTransRequest PrepareTransRequest
    {
        get
        {
            if (_PrepareTransRequest == null)
            {
                _PrepareTransRequest = this.ViewData["prepareTransRequest"] as PrepareTransRequest;
            }
            return _PrepareTransRequest;
        }
    }
    
    private ProcessTransRequest _ProcessTransRequest = null;
    private ProcessTransRequest ProcessTransRequest
    {
        get
        {
            if (_ProcessTransRequest == null)
            {
                _ProcessTransRequest = this.ViewData["processTransRequest"] as ProcessTransRequest;
            }
            return _ProcessTransRequest;
        }
    }

    private EnterCashRequestBankInfo _EnterCashBankInfo = null;
    private EnterCashRequestBankInfo EnterCashBankInfo
    {
        get {
            if (_EnterCashBankInfo == null)
            {
                var list = GamMatrixClient.GetEnterCashBankInfo();
                _EnterCashBankInfo = list.FirstOrDefault(b => b.Id == bankID);
            }
            return _EnterCashBankInfo;
        }
    }

    private long bankID = 0;
    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);
        if (this.ViewData["bankID"] != null)
            long.TryParse(this.ViewData["bankID"].ToString(), out bankID);
    }
</script>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div id="deposit-wrapper" class="content-wrapper">
<%: Html.H1(this.GetMetadata(".HEAD_TEXT"))%>
<ui:Panel runat="server" ID="pnDeposit">

<% Html.RenderPartial("PaymentMethodDesc", this.Model); %>

<center>
<%: Html.WarningMessage(this.GetMetadata(".Message"))%>

<%: Html.H2(this.GetMetadata(".Table_Title"))%>
<table cellpadding="0" cellspacing="0" border="1" rules="all" class="confirmation_table entercash_information"> 
    <tr class="info_row_refcode">
        <td class="name"><%= this.GetMetadata(".TransferToBank").SafeHtmlEncode()%></td>
        <td class="value"><span><%=EnterCashBankInfo.Name.SafeHtmlEncode()%></span></td>
    </tr>
    <tr class="info_row_refcode">
        <td class="name"><%= this.GetMetadata(".ClearingNumber").SafeHtmlEncode()%></td>
        <td class="value"><span><%=EnterCashBankInfo.DomesticDepositInfo["clearing_number"]%></span></td>
    </tr>
    <tr class="info_row_refcode">
        <td class="name"><%= this.GetMetadata(".AccountNumber").SafeHtmlEncode()%></td>
        <td class="value"><span><%=EnterCashBankInfo.DomesticDepositInfo["account_number"]%></span></td>
    </tr>
    <tr class="info_row_refcode">
        <td class="name"><%= this.GetMetadata(".ReceiverName").SafeHtmlEncode()%></td>
        <td class="value"><span><%=EnterCashBankInfo.DomesticDepositInfo["beneficiary_name"]%></span></td>
    </tr>
    <tr class="info_row_refcode">
        <td class="name"><%= this.GetMetadata(".Amount").SafeHtmlEncode()%></td>
        <td class="value"><span><%= MoneyHelper.FormatWithCurrency(this.PrepareTransRequest.Record.RequestCurrency , this.PrepareTransRequest.Record.RequestAmount ) %></span></td>
    </tr>
    <tr class="info_row_refcode">
        <td class="name"><strong><%= this.GetMetadata(".Refcode").SafeHtmlEncode() %></strong></td>
        <td class="value refcode"><span style="margin-left: 10px;"><strong><%=this.ProcessTransRequest.ResponseFields["RefCode"].SafeHtmlEncode()%></strong></span></td>
    </tr>
</table>
</center>
</ui:Panel>
</div>
</asp:Content>

