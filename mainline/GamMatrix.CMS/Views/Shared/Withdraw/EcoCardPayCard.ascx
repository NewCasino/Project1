<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>



<%---------------------------------------------------------------
EcoCard
----------------------------------------------------------------%>
<ui:TabbedContent ID="tabbedPayCards" runat="server">
    <Tabs>

    <%---------------------------------------------------------------
            Existing Cards
    ----------------------------------------------------------------%>
    <ui:Panel runat="server" ID="tabRecentCards" Caption="<%$ Metadata:value(.Tab_ExistingPayCards) %>">
        <%---------------------------------------------------------------
        EcoCard
        ----------------------------------------------------------------%>
        <form id="formEcoCardPayCard" onsubmit="return false">

            <ui:InputField ID="fldExistingPayCard" runat="server" ShowDefaultIndicator="false" BalloonArrowDirection="Left">
	            <LabelPart><%= this.GetMetadata(".WithdrawTo").SafeHtmlEncode()%></LabelPart>
	            <ControlPart>
                    <ul id="paycards-selector">
            
                    </ul>
                    <%: Html.Hidden("existingPayCardID", "", new 
                    { 
                        @id = "hExistingPayCardID",
                        @validator = ClientValidators.Create().Required(this.GetMetadata(".ExistingCard_Empty")) 
                    }) %>
                </ControlPart>
            </ui:InputField>

            <script id="pay-card-template" type="text/html">
            <#
                var d=arguments[0];

                for(var i=0; i < d.length; i++)     
                {        
            #>
                <li>
                    <input type="radio" name="existingPayCard" value="<#= d[i].ID.htmlEncode() #>" id="payCard_<#= d[i].ID.htmlEncode() #>"/>
                    <label for="payCard_<#= d[i].ID.htmlEncode() #>" dir="ltr">
                        <#= d[i].DisplayNumber.htmlEncode() #>
                    </label>
                </li>

            <#  }  #>
            </script>   


            <center>
                <%: Html.Button(this.GetMetadata(".Button_Back"), new { @type = "button", @onclick = string.Format("$(this).toggleLoadingSpin(true);self.location='{0}';return false;", this.Url.RouteUrl("Withdraw", new { @action = "Index" }).SafeJavascriptStringEncode()) })%>
                <%: Html.Button(this.GetMetadata(".Button_Continue"), new { @id="btnWithdrawWithEcoCardPayCard" })%>
            </center>
        </form>

    </ui:Panel>


</Tabs>
</ui:TabbedContent>

<script language="javascript" type="text/javascript">
$(document).ready(function () {
    $('#formEcoCardPayCard').initializeForm();

    __populatePayCards( <% Html.RenderAction("GetPayCards", new { vendorID = this.Model.VendorID });  %> );

    $('#btnWithdrawWithEcoCardPayCard').click(function (e) {
        e.preventDefault();

        if (!isWithdrawInputFormValid() )
            return;

        $('#btnWithdrawWithEcoCardPayCard').toggleLoadingSpin(true);
        tryToSubmitWithdrawInputForm($('#fldExistingPayCard input[name="existingPayCardID"]').val()
        , function () { $('#btnWithdrawWithEcoCardPayCard').toggleLoadingSpin(false); });
    });


    
});
    
function __populatePayCards(json) {
    if (!json.success) {
        showWithdrawError(json.error);
        return;
    }
    $('#hExistingPayCardID').val('');
    $('#paycards-selector').html($('#pay-card-template').parseTemplate(json.payCards));
    $('#paycards-selector input[name="existingPayCard"]').click(function () {
        $('#hExistingPayCardID').val($(this).val());
        InputFields.fields['fldExistingPayCard'].validator.element($('#hExistingPayCardID'));
    });

    $('#tabbedPayCards').showTab('tabRecentCards', true);
    $('#tabbedPayCards').selectTab('tabRecentCards');

    if( $('#paycards-selector :checked').length == 0 )
        $('#paycards-selector input:first').trigger('click');
};
</script>