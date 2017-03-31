<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<GamMatrix.CMS.Models.MobileShared.Deposit.EnterCashBankSelectorViewModel>" %>

<div class="EnterCashBankContainer Hidden" id="enterCashBankContainer">
    <ul class="BankFields">
        <li class="FormItem">
            <label class="FormLabel" for="depositEnterCashBankID"><%= this.GetMetadata(".BankID_Label").SafeHtmlEncode() %></label>
            <%: Html.DropDownList("enterCashBankID", Model.GetEnterCashBankList(), new Dictionary<string, object>()  
                            { 
                                { "class", "FormInput" },
                                { "id", "depositEnterCashBankID" },
                                { "dir", "ltr" },
                                { "required", "required" },
                            }) %>

            <span class="FormStatus">Status</span>
            <span class="FormHelp"></span>
        </li>
    </ul>
</div>

<ui:MinifiedJavascriptControl ID="MinifiedJavascriptControl1" runat="server" Enabled="true" AppendToPageEnd="true">
    <script type="text/javascript">
        var EnterCashBankSelector = (function () {//internal classes in closure
            function EnterCashBankSelector() {
                <%=this.Model.GetEnterCashBankInfoJson() %>

                var hiddenStyle = 'Hidden';

                var enterCashBankContainer = $('#enterCashBankContainer');

                var selector = $('.FormInput', enterCashBankContainer),
                    currentData = {};

                var dispatcher = new CMS.utils.Dispatcher();

                function getEnterCashBankData() {
                    return currentData || {};
                }

                function selectItem(bankID) {
                    currentData = enterCashBankInfos[bankID];
                    
                    var bank = getEnterCashBankData();
                    dispatcher.trigger('change', bank);
                }

                selector.change(function () {
                    selectItem($(':selected', selector).val());
                });

                function toggleOptions(state) {
                    enterCashBankContainer.toggleClass(hiddenStyle, !state);
                }

                $(document).ready(function () {
                    var option = $('option', selector).eq(0);
                    selector.val(option.val());
                    selectItem(option.val());
                });

                return {
                    evt: dispatcher,
                    data: getEnterCashBankData,
                    toggle: toggleOptions
                }
            }

            return EnterCashBankSelector;
        })();
    </script>
</ui:MinifiedJavascriptControl>
