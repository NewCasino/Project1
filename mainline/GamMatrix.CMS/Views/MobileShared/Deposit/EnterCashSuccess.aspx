<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>

<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>

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

<asp:Content ID="Content1" ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ID="Content2" ContentPlaceHolderID="cphMain" Runat="Server">
    <div class="UserBox DepositBox CenterBox">
	<div class="BoxContent">
		<% Html.RenderPartial("/Components/StatusNotification", new StatusNotificationViewModel(StatusType.Info, this.GetMetadata(".Message"))); %>

        <div class="MenuList L DetailContainer">
			<ol class="DetailPairs ProfileList">
				<li>
					<div class="ProfileDetail">
						<span class="DetailName"><%= this.GetMetadata(".TransferToBank").SafeHtmlEncode() %></span> <span class="DetailValue"><%= EnterCashBankInfo.Name.SafeHtmlEncode() %></span>
					</div>
				</li>
				<li>
					<div class="ProfileDetail">
						<span class="DetailName"><%= this.GetMetadata(".ClearingNumber").SafeHtmlEncode() %></span> <span class="DetailValue"><%= EnterCashBankInfo.DomesticDepositInfo["clearing_number"] %></span>
					</div>
				</li>
				<li>
					<div class="ProfileDetail">
						<span class="DetailName"><%= this.GetMetadata(".AccountNumber").SafeHtmlEncode() %></span> <span class="DetailValue"><%= EnterCashBankInfo.DomesticDepositInfo["account_number"] %></span>
					</div>
				</li>
                <li>
					<div class="ProfileDetail">
						<span class="DetailName"><%= this.GetMetadata(".ReceiverName").SafeHtmlEncode() %></span> <span class="DetailValue"><%= EnterCashBankInfo.DomesticDepositInfo["beneficiary_name"] %></span>
					</div>
				</li>
                <li>
					<div class="ProfileDetail">
						<span class="DetailName"><%= this.GetMetadata(".Amount").SafeHtmlEncode() %></span> <span class="DetailValue"><%= MoneyHelper.FormatWithCurrency(this.PrepareTransRequest.Record.RequestCurrency , this.PrepareTransRequest.Record.RequestAmount ) %></span>
					</div>
				</li>
                <li>
					<div class="ProfileDetail">
						<span class="DetailName"><strong><%= this.GetMetadata(".Refcode").SafeHtmlEncode() %></strong></span> <span class="DetailValue"><strong><%= this.ProcessTransRequest.ResponseFields["RefCode"].SafeHtmlEncode() %></strong></span>
					</div>
				</li>
			</ol>
		</div>
    </div>
</div>
<script type="text/javascript">
    (function ($) {
        var cmsViews = CMS.views;

        cmsViews.BackBtn = function (selector) {
            $(selector).click(function () {
                window.location = '/Deposit';
                return false;
            });
        }
    })(jQuery);

    $(CMS.mobile360.Generic.init);
</script>
</asp:Content>

