<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="Finance" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="System.Linq" %>
<script language="C#" type="text/C#" runat="server">
    private List<TransInfoRec> GetTransactions()
    {
        TransSelectParams transSelectParams = new TransSelectParams()
        {
            ByTransTypes = true,
            ParamTransTypes = new List<TransType> { TransType.Deposit, TransType.Vendor2User },
            ByUserID = true,
            ParamUserID = Profile.UserID,
            ByTransStatuses = true,
            ParamTransStatuses = new List<TransStatus>
            {
                TransStatus.Success,
            },
            ByDebitPayableTypes = true,
        };

        transSelectParams.ParamDebitPayableTypes = Enum.GetNames(typeof(PayableType))
            .Select(t => (PayableType)Enum.Parse(typeof(PayableType), t))
            .Where(t => t != PayableType.AffiliateFee && t != PayableType.CasinoFPP)
            .ToList();

        DateTime dtFrom = new DateTime(1900,1,1);
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
                return getTransRequest.PagedData.Records.Where(r => r.CreditRealAmount > 0M).ToList();
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

<div class="transaction-table">
    <div class="holder-flex-100 tableHead">
            <div class="col-20"><span><%= this.GetMetadata(".ListHeader_TransactionID").SafeHtmlEncode()%></span></div>
            <div class="col-20"><span><%= this.GetMetadata(".ListHeader_Date").SafeHtmlEncode()%></span></div>
            <div class="col-15"><span><%= this.GetMetadata(".ListHeader_Account").SafeHtmlEncode()%></span></div>
            <div class="col-15"><span><%= this.GetMetadata(".ListHeader_Amount").SafeHtmlEncode()%></span></div>
            <div class="col-15"><span><%= this.GetMetadata(".ListHeader_Description").SafeHtmlEncode()%></span></div>
            <div class="col-15"><span><%= this.GetMetadata(".ListHeader_Status").SafeHtmlEncode()%></span></div>
    </div>

<% 
    bool isAlternate = true;
    foreach (TransInfoRec trans in GetTransactions())
    {
        isAlternate = !isAlternate; %>
         <div class="holder-flex-100">
            <div class="col-20"><span><%= trans.TransID.ToString() %></span></div>
            <div class="col-20" date-time="<%= GetTimeForJavaScript(trans.TransCompleted) %>"><span><%= trans.TransCompleted.ToString("dd/MM/yyyy HH:mm")%></span></div>
            <div class="col-15"><span><%= GetAccountName(trans).SafeHtmlEncode() %></span></div>
            <div class="col-15"><span><%= MoneyHelper.FormatWithCurrency( trans.CreditRealCurrency, trans.CreditRealAmount) %></span></div>
            <div class="col-15"><span><%= (trans.TransType == TransType.Vendor2User) ? trans.Note.SafeHtmlEncode(): trans.DebitPayItemName.SafeHtmlEncode()%></span></div>
            <div class="col-15"><%= GetStatusHtml(trans) %></div>
        </div>
<%  } %>

</div>