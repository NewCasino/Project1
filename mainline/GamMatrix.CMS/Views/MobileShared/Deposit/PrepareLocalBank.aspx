<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<GamMatrix.CMS.Models.MobileShared.Deposit.Prepare.PrepareLocalBankViewModel>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>

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

    private List<SelectListItem> GetBankList()
    {
        string[] bankPaths = Metadata.GetChildrenPaths("Metadata/PaymentMethod/LocalBank/Bank/" + Profile.UserCountryID);
        if (bankPaths == null || bankPaths.Length == 0)
            throw new InvalidOperationException("There is no bank for your country.");

        List<SelectListItem> list = new List<SelectListItem>();
        foreach (string bankPath in bankPaths)
        {
            string bank = bankPath.Substring(bankPath.LastIndexOf("/") + 1);
            list.Add(new SelectListItem()
            {
                Value = bank,
                Text = Metadata.Get(System.IO.Path.Combine(bankPath, ".DisplayName")).DefaultIfNullOrWhiteSpace(bank),
            });
        }

        return list;
    }
</script>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
    <div class="Box CenterBox DepositBox">
<div class="BoxContent">
    <form action="<%= this.Url.RouteUrl("Deposit"
        , new { @action = "ConfirmLocalBank"//"ProcessLocalBankTransaction"//"PrepareTransaction"
        , @paymentMethodName = this.Model.PaymentMethod.UniqueName }).SafeHtmlEncode() %>" method="post" id="formPrepareMoneybookers">
        
        <% Html.RenderPartial("/Components/UserFlowStatus", new UserFlowStatusViewModel { FlowSteps = 4, CurrentStep = 2 }); %>
        <% Html.RenderPartial("/Components/MultiFormState", Model.StateVars); %>
        
        <ul>
        <%------------------------------------------
        Bank
        -------------------------------------------%>
        <li class="FormItem">
        <label><%= this.GetMetadata(".Bank_Label").SafeHtmlEncode()%></label>
            <%: Html.DropDownList("bank", GetBankList(), this.Model.PayCard != null ? this.Model.PayCard.BankName : "",
            new Dictionary<string, object>() 
            { 
                { "class", "FormInput" }, 
                { "id", "ddlBank2" }, 
                { this.Model.PayCard != null ? "disabled" : "data-dummy", this.Model.PayCard != null ? "disabled" : "dummy" }, 
                { "onchange", "onBankChange()" } 
            })%>
            <%-- We need another hide field for the Bank ID 
            because the Bank ID value will not be included in POST request if the dropdownlist is disabled. --%>
            <%: Html.Hidden("bankName", this.Model.PayCard != null ? this.Model.PayCard.BankName : "")%>
            <script type="text/javascript">
                function onBankChange() {
                    $("input[name='bankName']").val($("#ddlBank2").val());
                }
            </script>
        </li>

        <%------------------------
            Name on Account
            -------------------------%>    
        <li class="FormItem">
        <label><%= this.GetMetadata(".NameOnAccount_Label").SafeHtmlEncode()%></label>
                <%: Html.TextBox("nameOnAccount", this.Model.PayCard != null ? this.Model.PayCard.OwnerName : "",
                new Dictionary<string, object>()
                { 
                    { "id", "txtNameOnAccount2" },
                    { "class", "FormInput"},
                    { "maxlength", MaxLengthOfNameOnAccount },
                    { this.Model.PayCard != null ? "readonly" : "data-dummy", this.Model.PayCard != null ? "readonly" : "dummy" },
                    { "data-validator", CM.Web.UI.ClientValidators.Create()
                        .Required(this.GetMetadata(".NameOnAccount_Empty")) }
                }
                )%>
    </li>

        <%------------------------
            Bank Account No
            -------------------------%>    
        <li class="FormItem">
        <label><%= this.GetMetadata(".BankAccountNo_Label").SafeHtmlEncode()%></label>
                <%: Html.TextBox("bankAccountNo", this.Model.PayCard != null ? this.Model.PayCard.BankAccountNo : "",
                new Dictionary<string, object>()
                { 
                    { "id", "txtBankAccountNo2" },
                    {"class", "FormInput" },
                    { "maxlength", 16 },
                    { "dir", "ltr" },
                    { this.Model.PayCard != null ? "readonly" : "data-dummy", this.Model.PayCard != null ? "readonly" : "dummy" },
                    { "data-validator", CM.Web.UI.ClientValidators.Create()
                        .Required(this.GetMetadata(".BankAccountNo_Empty"))
                        .Custom("__validateAccountNo") }
                }
                )%>
        <span class="FormStatus"></span>
        <span class="FormHelp"></span>
        </li>

        <ui:MinifiedJavascriptControl ID="scriptMobile" runat="server" Enabled="true" AppendToPageEnd="true" EnableObfuscation="true">
        <script type="text/javascript">
            function __validateAccountNo() {
                var errorMsg = '';
                var _m_url = '<%=this.Url.RouteUrl("Deposit", new { @action = "VerifyUniqueLocalBankAccountNumber" }).SafeJavascriptStringEncode()%>';
                var _m_data = {
                    "bankAccountNumber": $('#txtBankAccountNo2').val()
                    , "message": '<%=this.GetMetadata(".Mobile_Exist").SafeJavascriptStringEncode()%>'
                };
                $.ajax({
                    type: "POST",
                    async: false,
                    url: _m_url,
                    cache: false,
                    data: _m_data,
                    success: function (_json) {
                        if (!_json.success)
                            errorMsg = _json.error;
                    }
                });
                if (errorMsg != '')
                    return errorMsg;
                return true;
            }
        </script>
        </ui:MinifiedJavascriptControl>

        <%------------------------
                Citizen ID
            -------------------------%>    
        <%--<ui:InputField ID="fldCitizenID2" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
        <LabelPart><%= this.GetMetadata(".CitizenID_Label").SafeHtmlEncode()%></LabelPart>
        <ControlPart>
                <%: Html.TextBox("citizenID", "", new 
                {
                    @id = "txtCitizenID2",
                    @maxlength = 16,
                    @dir = "ltr",
                    @readonly = "readonly",
                    @validator = ClientValidators.Create()
                        .Required(this.GetMetadata(".CitizenID_Empty"))
                } 
                )%>
        </ControlPart>
        </ui:InputField>--%>

        </ul>
        <input type="hidden" value="<%= this.Model.PayCard != null ? this.Model.PayCard.ID.ToString() : "" %>" name="payCardID" id="hpayCardID" />

    <% Html.RenderPartial("/Components/UserFlowNavigation", new GamMatrix.CMS.Models.MobileShared.Components.UserFlowNavigationViewModel()); %>

    </form>
            </div>
        </div>
</asp:Content>



