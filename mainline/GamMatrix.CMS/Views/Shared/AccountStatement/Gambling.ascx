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

public class WebDownload : WebClient
{
    public WebDownload() { }

    protected override WebRequest GetWebRequest(Uri address)
    {
        var request = base.GetWebRequest(address);
        if (request != null)
        {
            request.Timeout = 60000;
        }
        return request;
    }
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
    using (WebDownload client = new WebDownload())
    {
        byte[] bytes;
        try
        {
            bytes = client.DownloadData(url);
        }
        catch(Exception ex)
        {
            Logger.Warning("AccountStatement", "Failed to call reporting URL:{0}. {1}", url, ex.Message);
            throw new Exception("Unexpected error occurred in reporting.");
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


<table cellpadding="0" cellspacing="0" border="0" class="transaction-table">
    <thead>
        <tr>
            <th class="col-1"><span><%= this.GetMetadata(".ListHeader_TransactionID").SafeHtmlEncode()%></span></th>
            <th class="col-2"><span><%= this.GetMetadata(".ListHeader_Date").SafeHtmlEncode()%></span></th>
            <th class="col-3"><span><%= this.GetMetadata(".ListHeader_Account").SafeHtmlEncode()%></span></th>
            <th class="col-4"><span><%= this.GetMetadata(".ListHeader_Amount").SafeHtmlEncode()%></span></th>
            <th class="col-5"><span><%= this.GetMetadata(".ListHeader_Balance").SafeHtmlEncode()%></span></th>
            <th class="col-6"><span><%= this.GetMetadata(".ListHeader_Description").SafeHtmlEncode()%></span></th>
        </tr>
    </thead>
    <tbody>


<% 
    if (Data != null && Data.Length > 0)
    {
        bool isAlternate = false;
        // pagination
        foreach (var trans in Data)
        {
            isAlternate = !isAlternate;
            //if ((trans.TransType == TransType.WalletCredit && trans.CreditRealAmount > 0) || (trans.TransType != TransType.WalletCredit && trans.DebitRealAmount > 0)){
            %>
            <tr <%= isAlternate ? "class=\"odd\"" : "" %>>
                <td class="col-1" style="text-align:left"><span><%= trans.TransID.ToString()%></span></td>
                <td class="col-2 col-time"><span><%= trans.Time.ToString("dd/MM/yyyy HH:mm")%></span></td>
                <td class="col-3"><span><%= trans.AccountName.SafeHtmlEncode()%></span></td>
                <% if (trans.TransType == TransType.WalletCredit)
                   { %>
                    <td class="col-4"><span class="credit-amount"><%= MoneyHelper.FormatWithCurrency( trans.Currency, trans.Amount)%></span></td>
                <% }
                   else
                   { %>
                    <td class="col-4"><span class="debit-amount">- <%= MoneyHelper.FormatWithCurrency( trans.Currency, trans.Amount)%></span></td>
                <% } %>
                <td class="col-5"><span><%= MoneyHelper.FormatWithCurrency( trans.Currency, trans.Balance)%></span></td>
                <td class="col-6"><span><%= trans.Description.SafeHtmlEncode()%></span></td>
            </tr>
<%       
        }
    }  %>

    </tbody>
    <tfoot>
    </tfoot>
</table>
        <% if (this.ViewData["ErrorMessage"] != null) { %>
                <%= Html.ErrorMessage(this.ViewData["ErrorMessage"] as string)  %>
        <% } else if (Data == null || Data.Length == 0) { %>
                <%= Html.InformationMessage(this.GetMetadata(".No_Record"))  %>
        <% } %>

<% using (Html.BeginRouteForm("AccountStatement", new { @action = "Search" }, FormMethod.Post, new { @id = "formGambling" }))
       { %>
       <%: Html.Hidden("filterDateFrom", this.ViewData["FilterDateFrom"])%>
       <%: Html.Hidden("filterDateTo", this.ViewData["FilterDateTo"])%>
       <%: Html.Hidden("filterType", this.ViewData["filterType"])%>
       <%: Html.Hidden("pageIndex", PageIndex)%>
<% } %>

<div class="pagination-wrapper">
    <% for (int i = 1; i <= TotalPageCount; i++)
       { %>
        <a <%= (i == PageIndex) ? "class=\"current\"" : "" %> target="_self" href <%= (i == PageIndex) ? string.Empty : string.Format("onclick=\"__searchGambling({0}); return false;\"", i) %>>
            <span><%= (i).ToString() %></span>
        </a>       
    <% } %>
</div>

<script type="text/javascript">
    function __searchGambling(pageIndex) {
        var container = $('#formGambling').parent();
        container.children().hide();
        container.append($('<img src="/images/icon/loading.gif" />'));
        $('#formGambling input[name="pageIndex"]').val(pageIndex);
        var options = {
            type: 'POST',
            dataType: 'html',
            success: function (html) {
                container.html(html);
            }
        };
        $('#formGambling').ajaxForm(options);
        $('#formGambling').submit();
    }
</script>