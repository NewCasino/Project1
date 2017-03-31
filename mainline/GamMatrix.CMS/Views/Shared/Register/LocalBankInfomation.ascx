<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>

<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="GmCore" %>

<script language="C#" type="text/C#" runat="server">
    private int _MaxLengthOfNameOnAccount = -1;
    private int MaxLengthOfNameOnAccount
    {
        get
        {
            if (_MaxLengthOfNameOnAccount == -1)
            {
                var t = this.GetMetadata(".NameOnAccount_MaxLength").DefaultIfNullOrWhiteSpace("30");
                int.TryParse(t, out _MaxLengthOfNameOnAccount);
                if (_MaxLengthOfNameOnAccount == -1)
                    _MaxLengthOfNameOnAccount = 30;
            }

            return _MaxLengthOfNameOnAccount;
        }
    }
    
    private List<SelectListItem> GetBanks()
    {
        List<SelectListItem> list = new List<SelectListItem>();
        if (this.ViewData["BankList"] != null)
        {
            list = this.ViewData["BankList"] as List<SelectListItem>;
        }
        else
        {
            GetBanksFromMetadata(out list);
        }
        
        return list;
    }
    
    private void GetBanksFromMetadata(out List<SelectListItem> list)
    {
        list = new List<SelectListItem>();
        string[] bankPaths = Metadata.GetChildrenPaths("Metadata/PaymentMethod/LocalBank/Bank/202");
        if (bankPaths == null || bankPaths.Length == 0)
            return;
        
        foreach (string bankPath in bankPaths)
        {
            string bank = bankPath.Substring(bankPath.LastIndexOf("/") + 1);
            list.Add(new SelectListItem()
            {
                Value = bank,
                Text = Metadata.Get(System.IO.Path.Combine(bankPath, ".DisplayName")).DefaultIfNullOrWhiteSpace(bank),
            });
        }
    }
</script>


<%------------------------------------------
    Bank_Select 
 -------------------------------------------%>
<ui:InputField ID="fldBank" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
    <LabelPart><%= this.GetMetadata(".Bank_Label").SafeHtmlEncode()%></LabelPart>
    <ControlPart>
        <%: Html.DropDownList("bank", GetBanks(), new
            {
                @id = "ddlBank",
                @validator = ClientValidators.Create()
                    .Required(this.GetMetadata(".Bank_Empty"))
            })%>
    </ControlPart>
</ui:InputField>
<ui:MinifiedJavascriptControl runat="server" ID="scriptBank" AppendToPageEnd="true" Enabled="false">
<script type="text/javascript">
$(function () {
    $('#ddlBank').change( function(){
       
    });
}); 
</script>
</ui:MinifiedJavascriptControl>



<%------------------------------------------
    Bank Account No.
 -------------------------------------------%>
<ui:InputField ID="fldBankAccountNo" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
    <LabelPart><%= this.GetMetadata(".BankAccountNo_Label").SafeHtmlEncode()%></LabelPart>
    <ControlPart>
        <%: Html.TextBox("bankAccountNo", "", new 
		{
            @maxlength = 16,
            @id = "txtBankAccountNo",
            @validator = ClientValidators.Create()
                .Required(this.GetMetadata(".BankAccountNo_Empty"))
                .MinLength(4, this.GetMetadata(".BankAccountNo_Length"))
                .Custom("validateBankAccountNo")
		}) %>
    </ControlPart>
</ui:InputField>
<ui:MinifiedJavascriptControl runat="server" ID="scriptBankAccountNo" AppendToPageEnd="true" Enabled="false">
<script type="text/javascript">
    function validateBankAccountNo() {
        return true;
    }
</script>
</ui:MinifiedJavascriptControl>


<%------------------------------------------
    Name of Account
 -------------------------------------------%>
<ui:InputField ID="fldNameOfAccount" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
    <LabelPart><%= this.GetMetadata(".NameOfAccount_Label").SafeHtmlEncode()%></LabelPart>
    <ControlPart>
        <%: Html.TextBox("nameOfAccount", "", new 
		{
            @maxlength = MaxLengthOfNameOnAccount,
            @minlength = 2,
            @id = "txtNameOfAccount",
            @validator = ClientValidators.Create()
                .Required(this.GetMetadata(".NameOfAccount_Empty"))
                .MinLength(4, this.GetMetadata(".NameOfAccount_Length"))
		}) %>       
    </ControlPart>
</ui:InputField>
<ui:MinifiedJavascriptControl runat="server" ID="scriptNameOfAccount" AppendToPageEnd="true" Enabled="false">
<script type="text/javascript">
    
</script>
</ui:MinifiedJavascriptControl>