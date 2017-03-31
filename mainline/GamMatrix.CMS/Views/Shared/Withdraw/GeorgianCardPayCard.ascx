<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>

<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="Finance" %>

<script runat="server" type="text/C#">
    private PayCardInfoRec PayCard { get; set; }
    protected override void OnInit(EventArgs e)
    {
        List<PayCardInfoRec> payCards = GamMatrixClient.GetPayCards(VendorID.GeorgianCard);
        this.PayCard = payCards.Where(p => !p.IsDummy).OrderByDescending(p => p.ValidFrom).FirstOrDefault();

        if (this.PayCard == null)
        {
            this.PayCard = payCards.FirstOrDefault( p => p.IsDummy && p.SuccessDepositNumber > 0 );
        }

        if (this.PayCard == null)
        {
            throw new Exception("You have to deposit via GeogianCard at least for one time before you can withdraw.");
        }
        
        base.OnInit(e);
    }
</script>

<%---------------------------------------------------------------
GOORGIAN CARD
----------------------------------------------------------------%>
<ui:TabbedContent ID="tabbedPayCards" runat="server">
    <Tabs>

    <%---------------------------------------------------------------
            Existing Cards
    ----------------------------------------------------------------%>
    <ui:Panel runat="server" ID="tabRecentCards" Caption="<%$ Metadata:value(.Tab_ExistingPayCards) %>">
        <%---------------------------------------------------------------
        Georgian Card
        ----------------------------------------------------------------%>

        
        <form id="formGeorgianCardPayCard" onsubmit="return false">
            

            <% if( !this.PayCard.IsDummy )
               { %>
            <ui:InputField ID="fldExistingPayCard" runat="server" ShowDefaultIndicator="false" BalloonArrowDirection="Left">
	            <LabelPart><%= this.GetMetadata(".WithdrawTo").SafeHtmlEncode()%></LabelPart>
	            <ControlPart>
                    <%: Html.TextBox("identityNumber", this.PayCard.DisplayNumber, new 
                        { 
                            @dir = "ltr",
                            @readonly = "readonly",
                        } 
                        )%>   
                </ControlPart>
            </ui:InputField>
            <% } %>
            <center>
                <%: Html.Button(this.GetMetadata(".Button_Back"), new { @type = "button", @onclick = string.Format("$(this).toggleLoadingSpin(true);self.location='{0}';return false;", this.Url.RouteUrl("Withdraw", new { @action = "Index" }).SafeJavascriptStringEncode()) })%>
                <%: Html.Button(this.GetMetadata(".Button_Continue"), new { @id="btnWithdrawWithGeorgianCardPayCard" })%>
            </center>
        </form>

    </ui:Panel>


</Tabs>
</ui:TabbedContent>

<script type="text/javascript">
    $(function () {
        $('#tabbedPayCards').selectTab('tabRecentCards');
        $('#formGeorgianCardPayCard').initializeForm();

        $('#btnWithdrawWithGeorgianCardPayCard').click(function (e) {
            e.preventDefault();

            if (!isWithdrawInputFormValid() )
                return;

            $('#btnWithdrawWithGeorgianCardPayCard').toggleLoadingSpin(true);
            tryToSubmitWithdrawInputForm( '<%= this.PayCard.ID %>'
            , function () { $('#btnWithdrawWithGeorgianCardPayCard').toggleLoadingSpin(false); });
        });
    });
    
</script>