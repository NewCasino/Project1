<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>

<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="Finance" %>
<%@ Import Namespace="GmCore" %>

<script language="C#" type="text/C#" runat="server">
    private List<TransInfoRec> GetTransactions()
    {
        TransSelectParams transSelectParams = new TransSelectParams()
        {
            ByTransTypes = true,
            ParamTransTypes = new List<TransType> { TransType.Vendor2User },
            ByUserID = true,
            ParamUserID = Profile.UserID,
            ByTransStatuses = true,
            ParamTransStatuses = new List<TransStatus>
            {
                TransStatus.Success,
            },
            ByDebitVendorOwnedPayItemVendorID = true,
            ParamDebitVendorOwnedPayItemVendorID = VendorID.NetEnt,
            ByDebitPayableTypes = true,
            ParamDebitPayableTypes = new List<PayableType>
            {
                PayableType.CasinoFPP,
            },
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
                return getTransRequest.PagedData.Records;
            }
        }

        return new List<TransInfoRec>();
    }

    private string GetAccountName(TransInfoRec trans)
    {
        return string.Format(this.GetMetadata(".ToAccount")
           , this.GetMetadata(string.Format("/Metadata/GammingAccount/{0}.Display_Name", trans.CreditPayItemVendorID.ToString()))
           );
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
    foreach (TransInfoRec trans in GetTransactions())
    {
        isAlternate = !isAlternate; %>
        <tr <%= isAlternate ? "class=\"odd\"" : "" %>>
            <td class="col-1"><span><%= trans.TransID.ToString() %></span></td>
            <td class="col-2 col-time" date-time="<%= GetTimeForJavaScript(trans.TransCompleted) %>"><span><%= trans.TransCompleted.ToString("dd/MM/yyyy HH:mm")%></span></td>
            <td class="col-3"><span><%= GetAccountName(trans).SafeHtmlEncode() %></span></td>
            <td class="col-4"><span><%= MoneyHelper.FormatWithCurrency( trans.CreditRealCurrency, trans.CreditRealAmount) %></span></td>
            <td class="col-5"><span><%= trans.DebitPayItemName.SafeHtmlEncode() %></span></td>
            <td class="col-6"><%= GetStatusHtml(trans) %></td>
        </tr>
<%  } %>

    </tbody>
    <tfoot>
    </tfoot>
</table>