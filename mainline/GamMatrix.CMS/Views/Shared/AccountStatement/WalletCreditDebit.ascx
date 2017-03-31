<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>

<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="Finance" %>
<%@ Import Namespace="GmCore" %>

<script language="C#" type="text/C#" runat="server">
    private VendorID GetVendorID()
    {
        return (VendorID)this.ViewData["VendorID"];
    }
    private List<TransInfoRec> GetTransactions()
    {
        string cacheKey = string.Format("transaction_history_{0}_{1}_win_lost_{2}", Profile.UserID, this.GetVendorID(), this.Model);
        List<TransInfoRec> records = HttpRuntime.Cache[cacheKey] as List<TransInfoRec>;
        if (records != null)
            return records;
        
        TransSelectParams transSelectParams = new TransSelectParams()
        {
            ByTransTypes = true,
            ParamTransTypes = new List<TransType> { TransType.WalletCredit, TransType.WalletDebit },
            ByUserID = true,
            ParamUserID = Profile.UserID,
            ByTransStatuses = true,
            ParamTransStatuses = new List<TransStatus>
            {
                TransStatus.Success,
            }
        };
        DateTime dtFrom = new DateTime(1900, 1, 1);
        DateTime dtTo = new DateTime(1900, 1, 1);
        if (this.ViewData["FilterDateFrom"] != null && !string.IsNullOrEmpty(this.ViewData["FilterDateFrom"].ToString()))
        {
            if (DateTime.TryParse(this.ViewData["FilterDateFrom"].ToString(), out dtFrom))
            {
                transSelectParams.ByCompleted = true;
                transSelectParams.ParamCompletedFrom = dtFrom;
            }
        }
        if (this.ViewData["FilterDateTo"] != null && !string.IsNullOrEmpty(this.ViewData["FilterDateTo"].ToString()))
        {
            if (DateTime.TryParse(this.ViewData["FilterDateTo"].ToString(), out dtTo))
            {
                transSelectParams.ByCompleted = true;
                transSelectParams.ParamCompletedTo = dtTo;
            }
        }

        if (transSelectParams.ParamCompletedTo < transSelectParams.ParamCompletedFrom)
        {
            return new List<TransInfoRec>();
        }

        using (GamMatrixClient client = GamMatrixClient.Get() )
        {
            GetTransRequest getTransRequest1 = new GetTransRequest()
            {
                SelectionCriteria = transSelectParams,
                PagedData = new PagedDataOfTransInfoRec
                {
                    PageSize = int.MaxValue,
                    PageNumber = 0,
                }
            };
            GetTransRequest getTransRequest2 = ObjectHelper.DeepClone<GetTransRequest>(getTransRequest1);
            getTransRequest1.SelectionCriteria.ByCreditPayItemVendorID = true;
            getTransRequest1.SelectionCriteria.ParamCreditPayItemVendorID = this.GetVendorID();
            getTransRequest2.SelectionCriteria.ByDebitPayItemVendorID = true;
            getTransRequest2.SelectionCriteria.ParamDebitPayItemVendorID = this.GetVendorID();

            List<GetTransRequest> resp = client.MultiRequest<GetTransRequest>(new List<HandlerRequest>()
            {
                getTransRequest1,
                getTransRequest2,
            });
            getTransRequest1 = resp[0];
            getTransRequest2 = resp[1];

            if (getTransRequest1.PagedData.Records != null &&
                getTransRequest2.PagedData.Records != null)
            {
                records = getTransRequest1.PagedData.Records.Union(getTransRequest2.PagedData.Records)
                            .OrderByDescending(r => r.ID)
                            .ToList();
            }
            else if (getTransRequest1.PagedData.Records != null)
                records = getTransRequest1.PagedData.Records;
            else if (getTransRequest2.PagedData.Records != null)
                records = getTransRequest2.PagedData.Records;
            else
                records = new List<TransInfoRec>();
                
            HttpRuntime.Cache.Insert(cacheKey
                , records
                , null
                , DateTime.Now.AddMinutes(2)
                , Cache.NoSlidingExpiration
                );

            return records;
        }
    }

    private string GetAccountName(TransInfoRec trans)
    {
        if( trans.TransType == TransType.WalletCredit )
            return this.GetMetadata(string.Format("/Metadata/GammingAccount/{0}.Display_Name"
                , trans.CreditPayItemVendorID.ToString()
                ));
        return this.GetMetadata(string.Format("/Metadata/GammingAccount/{0}.Display_Name"
                , trans.DebitPayItemVendorID.ToString()
                ));
    }

    private string GetStatusHtml(TransInfoRec trans)
    {
        return string.Format("<span class=\"{0}\">{1}</span>"
            , trans.TransStatus.ToString().ToLowerInvariant()
            , this.GetMetadata(string.Format(".Status_{0}", trans.TransStatus.ToString())).SafeHtmlEncode()
            );
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
</script>

<table cellpadding="0" cellspacing="0" border="0" class="transaction-table">
    <thead>
        <tr>
            <th class="col-1"><span><%= this.GetMetadata(".ListHeader_TransactionID").SafeHtmlEncode()%></span></th>
            <th class="col-2"><span><%= this.GetMetadata(".ListHeader_Date").SafeHtmlEncode()%></span></th>
            <th class="col-3"><span><%= this.GetMetadata(".ListHeader_Account").SafeHtmlEncode()%></span></th>
            <th class="col-4"><span><%= this.GetMetadata(".ListHeader_Amount").SafeHtmlEncode()%></span></th>
            <th class="col-5"><span><%= this.GetMetadata(".ListHeader_Description").SafeHtmlEncode()%></span></th>
            <th class="col-6"><span><%= this.GetMetadata(".ListHeader_Status").SafeHtmlEncode()%></span></th>
        </tr>
    </thead>
    <tbody>

<% 
    bool isAlternate = true;
    const decimal ENTRY_COUNT_PER_PAGE = 100.0M;
    List<TransInfoRec> transactions = GetTransactions();
    int totalPages = 0;
    int pageIndex = 0;
    if (transactions.Count > 0)
    {
        totalPages = (int)Math.Ceiling(transactions.Count / ENTRY_COUNT_PER_PAGE);
        if (int.TryParse(this.ViewData["pageIndex"] as string, out pageIndex))
        {
            if (pageIndex >= totalPages)
                pageIndex = totalPages - 1;
        }
    }
    if (transactions.Count > 0)
    {
        // pagination
        foreach (TransInfoRec trans in transactions.Skip((int)ENTRY_COUNT_PER_PAGE*pageIndex).Take((int)ENTRY_COUNT_PER_PAGE) )
        {
            isAlternate = !isAlternate;
            if ((trans.TransType == TransType.WalletCredit && trans.CreditRealAmount > 0) || (trans.TransType != TransType.WalletCredit && trans.DebitRealAmount > 0)){
            %>
            <tr <%= isAlternate ? "class=\"odd\"" : "" %>>
                <td class="col-1"><span><%= trans.TransID.ToString()%></span></td>
                <td class="col-2 col-time" date-time="<%= GetTimeForJavaScript(trans.TransCompleted) %>"><span><%= trans.TransCompleted.ToString("dd/MM/yyyy HH:mm")%></span></td>
                <td class="col-3"><span><%= GetAccountName(trans).SafeHtmlEncode()%></span></td>
                <% if (trans.TransType == TransType.WalletCredit)
                   { %>
                    <td class="col-4"><span class="credit-amount"><%= MoneyHelper.FormatWithCurrency(trans.CreditRealCurrency, trans.CreditRealAmount)%></span></td>
                <% }
                   else
                   { %>
                    <td class="col-4"><span class="debit-amount">- <%= MoneyHelper.FormatWithCurrency(trans.DebitRealCurrency, trans.DebitRealAmount)%></span></td>
                <% } %>
                <td class="col-5"><span><%= trans.TransNote.SafeHtmlEncode()%></span></td>
                <td class="col-6"><%= GetStatusHtml(trans)%></td>
            </tr>
<%       }
        }
    } %>

    </tbody>
    <tfoot>
    </tfoot>
</table>

<% using (Html.BeginRouteForm("AccountStatement", new { @action = "Search" }, FormMethod.Post, new { @id = "formWalletCreditDebit" }))
       { %>
       <%: Html.Hidden("filterDateFrom", this.ViewData["FilterDateFrom"])%>
       <%: Html.Hidden("filterDateTo", this.ViewData["FilterDateTo"])%>
       <%: Html.Hidden("filterType", this.ViewData["filterType"])%>
       <%: Html.Hidden("pageIndex", pageIndex)%>
<% } %>

<div class="pagination-wrapper">
    <% for (int i = 0; i < totalPages; i++)
       { %>
        <a <%= (i == pageIndex) ? "class=\"current\"" : "" %> target="_self" href="#" <%= (i == pageIndex) ? "return false;" : string.Format("onclick=\"__searchWalletCreditDebit({0}); return false;\"", i) %>>
            <span><%= (i+1).ToString() %></span>
        </a>       
    <% } %>
</div>

<script language="javascript" type="text/javascript">
    function __searchWalletCreditDebit(pageIndex) {
        var container = $('table.transaction-table').parent();
        container.children().hide();
        container.append($('<img src="/images/icon/loading.gif" />'));
        $('#formWalletCreditDebit input[name="pageIndex"]').val(pageIndex);
        var options = {
            type: 'POST',
            dataType: 'html',
            success: function (html) {
                container.html(html);
            }
        };
        $('#formWalletCreditDebit').ajaxForm(options);
        $('#formWalletCreditDebit').submit();
    }
</script>