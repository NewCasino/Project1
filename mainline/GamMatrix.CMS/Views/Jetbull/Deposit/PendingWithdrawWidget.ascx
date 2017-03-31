<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="Finance" %>
<%@ Import Namespace="GamMatrixAPI" %>

<script runat="server">
    private List<TransInfoRec> _Transactions = null;
    private List<TransInfoRec> GetTransactions()
    {
        TransSelectParams transSelectParams = new TransSelectParams()
        {
            ByTransTypes = true,
            ParamTransTypes = new List<TransType> { TransType.Withdraw },
            ByUserID = true,
            ParamUserID = Profile.UserID,
            ByTransStatuses = true,
            ParamTransStatuses = new List<TransStatus>
                {
                    TransStatus.Pending,
                }
        };

        using (GamMatrixClient client = GamMatrixClient.Get())
        {
            GetTransRequest getTransRequest = client.SingleRequest<GetTransRequest>(new GetTransRequest()
            {
                SelectionCriteria = transSelectParams,
                PagedData = new PagedDataOfTransInfoRec
                {
                    PageSize = int.MaxValue,
                    PageNumber = 0,
                }
            });

            if (getTransRequest != null &&
                getTransRequest.PagedData != null &&
                getTransRequest.PagedData.Records != null &&
                getTransRequest.PagedData.Records.Count > 0)
            {
                return getTransRequest.PagedData.Records
                    .ToList();
            }
        }

        return new List<TransInfoRec>();
    }
    private string GetTimeForJavaScript(DateTime dateTime)
    {
        return string.Format("\"Year\":{0}, \"Month\":{1}, \"Day\":{2}, \"Hour\":{3}, \"Minute\":{4}, \"Second\":{5}",
            dateTime.Year,
            dateTime.Month,
            dateTime.Day,
            dateTime.Hour,
            dateTime.Minute,
            dateTime.Second).SafeHtmlEncode();
    }
    private string GetAccountName(TransInfoRec trans)
    {
        return string.Format(this.GetMetadata("/PendingWithdrawal/_Index_aspx.FromAccount")
           , this.GetMetadata(string.Format("/Metadata/GammingAccount/{0}.Display_Name", trans.DebitPayItemVendorID.ToString()))
           );
    }
    private string GetStatusHtml(TransInfoRec trans)
    {
        return string.Format("<span>{0}</span>"
            , this.GetMetadata(string.Format("/PendingWithdrawal/_Index_aspx.Status_{0}", trans.TransStatus.ToString())).SafeHtmlEncode()
            );
    }
    private bool IsRollbackButtonVisible(TransInfoRec trans)
    {
        if (trans.TransStatus == TransStatus.Pending &&
            trans.TransType == TransType.Withdraw)
        {
            if (Settings.PendingWithdrawal_EnableApprovement)
                return !trans.ApprovalStatus;

            return trans.CreditPayItemVendorID != VendorID.PaymentTrust
                   && trans.CreditPayItemVendorID != VendorID.PayPoint
                   && trans.CreditPayItemVendorID != VendorID.Envoy
                   && trans.CreditPayItemVendorID != VendorID.Bank
                   && trans.DebitPayItemVendorID != VendorID.PaymentTrust
                   && trans.DebitPayItemVendorID != VendorID.PayPoint
                   && trans.DebitPayItemVendorID != VendorID.Envoy
                   && trans.DebitPayItemVendorID != VendorID.Bank;
        }
        return false;
    }
    private string GetMessage(TransInfoRec trans)
    {
        string accountName = this.GetMetadata(string.Format("/Metadata/GammingAccount/{0}.Display_Name", trans.DebitPayItemVendorID.ToString()));
        string format = this.GetMetadata(".Success");

        return string.Format(format
            , trans.DebitRealAmount
            , trans.DebitRealCurrency
            , accountName
            );
    }
    private bool showWidget { get; set; }
    protected override void OnLoad(EventArgs e)
    {
        if (Profile.IsAuthenticated)
            _Transactions = GetTransactions();

        showWidget = Regex.IsMatch(this.GetMetadata("/Metadata/Settings.ShowPendingWithdrawInDeposit"), "[yes|true|1]", RegexOptions.IgnoreCase);
        base.OnLoad(e);
    }
</script>

<% if (showWidget && _Transactions != null && _Transactions.Count > 0)
   {%>
    <div class="pendingwithdraw-wraper" id="pendingwithdraw-wraper">
        <%: Html.H1(this.GetMetadata(".Label"))%>
        <center>
            <%: Html.InformationMessage( this.GetMetadata(".Message") , true ) %>
        </center>
        <div class="sec-transactionlist">
            <table cellpadding="0" cellspacing="0" border="0" class="transaction-table">
                <thead>
                    <tr>
                        <th class="col-1"><span><%= this.GetMetadata(".ListHeader_TransactionID").SafeHtmlEncode()%></span></th>
                        <th class="col-2"><span><%= this.GetMetadata(".ListHeader_Date").SafeHtmlEncode()%></span></th>
                        <th class="col-3"><span><%= this.GetMetadata(".ListHeader_Account").SafeHtmlEncode()%></span></th>
                        <th class="col-4"><span><%= this.GetMetadata(".ListHeader_Amount").SafeHtmlEncode()%></span></th>
                        <th class="col-5"><span><%= this.GetMetadata(".ListHeader_Description").SafeHtmlEncode()%></span></th>
                        <th class="col-6"><span><%= this.GetMetadata(".ListHeader_Status").SafeHtmlEncode()%></span></th>
                        <th class="col-7"></th>
                    </tr>
                </thead>
                <tbody>

            <% 
                bool isAlternate = true;
                foreach (TransInfoRec trans in _Transactions)
                {
                    isAlternate = !isAlternate; %>
                    <tr id="<%= trans.TransID.ToString() %>" class="trans-item <%= isAlternate ? "odd" : "" %> <%= trans.TransStatus.ToString().ToLowerInvariant() %>">
                        <td class="col-1"><span><%= trans.TransID.ToString() %></span></td>
                        <td class="col-2 col-time" date-time="<%= GetTimeForJavaScript(trans.TransCreated) %>"><span><%= trans.TransCreated.ToString("dd/MM/yyyy HH:mm")%></span></td>
                        <td class="col-3"><span><%= GetAccountName(trans).SafeHtmlEncode() %></span></td>
                        <td class="col-4"><span><%= MoneyHelper.FormatWithCurrency( trans.DebitRealCurrency, trans.DebitRealAmount) %></span></td>
                        <td class="col-5"><span><%= trans.CreditPayItemName %></span></td>
                        <td class="col-6">
                            <%= GetStatusHtml(trans) %>
                        </td>
                        <td>
                            <% if (this.IsRollbackButtonVisible(trans))
                               { %>
                                    <%: Html.Button(this.GetMetadata(".Button_Rollback"), new{@sid=trans.Sid,@success=GetMessage(trans)})%>
                            <% } %>
                        </td>
                    </tr>
            <%  } %>

                </tbody>
            </table>
            <div class="control_bar"><span class="icon">▼</span></div>
        </div>
        <script type="text/ecmascript">
            $(function () {
                var wraper = $("#pendingwithdraw-wraper"),
                    bar = $(".control_bar", wraper).hide();
                bar.click(function(){
                    if (bar.hasClass("expand")) {
                        bar.removeClass("expand");
                        $(".icon", bar).html("▼");
                    } else {
                        bar.addClass("expand");
                        $(".icon", bar).html("▲");
                    }
                    pendingWithdraw_Resize(5);
                });
                function pendingWithdraw_Resize(size) {
                    var arrItem = $(".sec-transactionlist .trans-item", wraper);
                    if (arrItem.length >= size) {
                        $.each(arrItem, function (i, opt) {
                            var self = $(opt);
                            self.show();
                            if (i > (size - 1) && !bar.hasClass("expand")) {
                                self.hide();
                            }
                        });
                    }
                    if (arrItem.length > 5)
                        bar.show();
                    else
                        bar.hide();
                    if (!wraper.hasClass("active")) wraper.addClass("active");
                }
                pendingWithdraw_Resize(5);
                $(".sec-transactionlist .button").click(function (e) {
                    var self = $(this);
                    self.toggleLoadingSpin(true);
                    e.preventDefault();

                    $.post("/_RollBackWithdraw.ashx", { sid: self.attr("sid") }, function (rlt) {
                        rlt = eval("("+rlt+")");
                        if (rlt.success) {
                            alert(self.attr("success"));
                            $("#" + rlt.transID).remove();

                            if ($(".sec-transactionlist .trans-item", wraper).length === 0)
                                wraper.remove();
                            BalanceList && BalanceList.refresh && BalanceList.refresh(false);
                        } else {
                            alert($("<div>" + "<%=this.GetMetadata(".failure").SafeHtmlEncode() %>" + "</div>").text());
                        }
                        pendingWithdraw_Resize(5);
                        self.toggleLoadingSpin(false);
                    });
                });
            });
        </script>
    </div>
<%} %>
