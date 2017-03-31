<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>

<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="Finance" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Net" %>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="System.Configuration" %>
<%@ Import Namespace="System.Runtime.Serialization" %>
<%@ Import Namespace="System.Runtime.Serialization.Json" %>


<script language="C#" type="text/C#" runat="server">
    static readonly string ReportGamblingHistoryURL = ConfigurationManager.AppSettings["Reporting.GamblingHistoryURL"];

    [DataContract]
    private sealed class GamblingTransactionResponse
    {
        [DataMember(Name = "IsSuccess")]
        public bool Success { get; set; }

        [DataMember(Name = "ErrorMessage")]
        public string ErrorMessage { get; set; }

        [DataMember(Name = "RecordCount")]
        public long TotalCount { get; set; }

        [DataMember(Name = "Data")]
        public GamblingTransaction [] Data { get; set; }
    }

    [DataContract]
    private sealed class GamblingTransaction
    {
        [DataMember(Name = "TransID")]
        public long TransID { get; set; }

        [DataMember(Name = "TransType")]
        public TransType TransType { get; set; }

        [DataMember(Name = "Account")]
        public long AccountID { get; set; }

        [DataMember(Name = "Amount")]
        public decimal Amount { get; set; }

        [DataMember(Name = "Balance")]
        public decimal Balance { get; set; }

        [DataMember(Name = "Description")]
        public string Description { get; set; }

        [DataMember(Name = "TransCompleted")]
        public DateTime Time { get; set; }

        [IgnoreDataMember]
        public string Currency { get; set; }

        [IgnoreDataMember]
        public string AccountName { get; set; }
    }


    private int PageIndex { get; set; }
    private int TotalPageCount { get; set; }
    private GamblingTransaction[] Data { get; set; }
        
    private void GetGamblingTransactions()
    {
        const int PAGE_SIZE = 500;

        PageIndex = 1;
        if( this.ViewData["pageIndex"] != null )
        {
            int pageIdx;
            if (int.TryParse(this.ViewData["pageIndex"].ToString(), NumberStyles.Integer, CultureInfo.InvariantCulture, out pageIdx))
                PageIndex = pageIdx;
        }
    
        DateTime dtFrom = new DateTime(1900, 1, 1);
        DateTime dtTo = new DateTime(1900, 1, 1);
        if (this.ViewData["FilterDateFrom"] != null && !string.IsNullOrEmpty(this.ViewData["FilterDateFrom"].ToString()))
        {
            if (!DateTime.TryParse(this.ViewData["FilterDateFrom"].ToString(), out dtFrom))
                return;
        }
        if (this.ViewData["FilterDateTo"] != null && !string.IsNullOrEmpty(this.ViewData["FilterDateTo"].ToString()))
        {
            if (!DateTime.TryParse(this.ViewData["FilterDateTo"].ToString(), out dtTo))
                return;
        }

        if (dtTo < dtFrom)
        {
            return;
        }

        if (string.IsNullOrWhiteSpace(ReportGamblingHistoryURL))
            throw new Exception("`Reporting.GamblingHistoryURL` is missing in configuration.");
    
        string url = string.Format(ReportGamblingHistoryURL
            , Uri.EscapeUriString(dtFrom.ToString("yyyy-MM-dd HH:mm:ss"))
            , Uri.EscapeUriString(dtTo.ToString("yyyy-MM-dd HH:mm:ss"))
            , PageIndex
            , PAGE_SIZE
            , Profile.UserID
            );

        GamblingTransactionResponse gtr;
        using( WebClient client = new WebClient() )
        {
            byte[] bytes;
            try
            {
                bytes = client.DownloadData(url);
            }
            catch(WebException ex)
            {
                Logger.Exception(ex);
                HttpWebResponse res = (HttpWebResponse)ex.Response;
                throw new Exception(string.Format("HTTP {0} error from reporting system.", (int)res.StatusCode));
            }

            DataContractJsonSerializer serilizer = new DataContractJsonSerializer(typeof(GamblingTransactionResponse)
                , new DataContractJsonSerializerSettings()
                {
                    IgnoreExtensionDataObject = true,
                    UseSimpleDictionaryFormat = true,
                });
            using( MemoryStream ms = new MemoryStream(bytes))
            {
                try
                {
                    gtr = serilizer.ReadObject(ms) as GamblingTransactionResponse;
                }
                catch(Exception ex)
                {
                    Logger.Exception(ex);
                    throw new Exception("Unexpected result returned from reporting system");
                }

                if( gtr == null )
                    throw new Exception("null is returned from reporting system");

                if (!gtr.Success)
                    throw new Exception(string.Format("Reporting failed : {0}", gtr.ErrorMessage));

                Data = gtr.Data;
                if (Data != null)
                {
                    TotalPageCount = (int)Math.Ceiling(gtr.TotalCount / (PAGE_SIZE * 1.0M));

                    var dic = GamMatrixClient.GetUserGammingAccounts(Profile.UserID)
                        .ToDictionary(a => a.ID, a => a);

                    foreach (var tran in Data)
                    {
                        AccountData account;
                        if (dic.TryGetValue(tran.AccountID, out account))
                        {
                            tran.AccountName = this.GetMetadata(string.Format("/Metadata/GammingAccount/{0}.Display_Name", account.Record.VendorID.ToString()));
                            tran.Currency = account.Record.Currency;
                        }
                        else
                            tran.AccountName = tran.AccountID.ToString();
                    }
                }
            }
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
    
    protected override void OnPreRender(EventArgs e)
    {
        try
        {
            GetGamblingTransactions();
        }
        catch(Exception ex)
        {
            this.ViewData["ErrorMessage"] = ex.Message;
        }
        base.OnPreRender(e);
    }
</script>



<ol class="CardList TransactionList">

    <% 
    if (Data != null)
    {
        foreach (var trans in Data)
        {
            %>
    <li>
		<div class="CardHeader">
			<span class="HeaderLable"><%= this.GetMetadata(".ListHeader_TransactionID").SafeHtmlEncode()%></span><span class="HeaderValue"><%= trans.TransID.ToString()%></span>
			<span class="HeaderLable"><%= this.GetMetadata(".ListHeader_Date").SafeHtmlEncode()%></span><span class="HeaderValue"><%= trans.Time.ToString("dd/MM/yyyy HH:mm")%></span>
		</div>
        <table class="DetailTable Cols-4">
			<tr>
				<th class="col-account"><%= this.GetMetadata(".ListHeader_Account").SafeHtmlEncode()%></th>
				<th><%= this.GetMetadata(".ListHeader_Amount").SafeHtmlEncode()%></th>
                <th><%= this.GetMetadata(".ListHeader_Balance").SafeHtmlEncode()%></th>
				<th><%= this.GetMetadata(".ListHeader_Description").SafeHtmlEncode()%></th>
				
			</tr>
			<tr>
				<td class="col-account"><%= trans.AccountName.SafeHtmlEncode()%></td>
				<% if (trans.TransType == TransType.WalletCredit)
                   { %>
                <td class="col-account"><span class="credit-amount"><%= MoneyHelper.FormatWithCurrency( trans.Currency, trans.Amount)%></span></td>
                <% }
                   else
                   { %>
                <td class="col-account"><span class="debit-amount">- <%= MoneyHelper.FormatWithCurrency( trans.Currency, trans.Amount)%></span></td>
                <% } %>
                <td><%= MoneyHelper.FormatWithCurrency( trans.Currency, trans.Balance)%></td>
				<td><%= trans.Description.SafeHtmlEncode()%></td>
			</tr>
		</table>
    </li>            
<%       
        }
    } %>
</ol>