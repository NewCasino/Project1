<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>

<script type="text/javascript">

    var g_Configurations = {};
    var g_FieldConfigurations = {};
    var g_CurrentConfiguration = null;
    
    function BankPayCard() {
        var cardActionSelector = new GenericTabSelector('#cardActionSelector'),
			currentAction = $('#tabExistingCard');

        function selectAction(data) {
            if (currentAction) {
                currentAction.addClass('Hidden');
                $('input, select', currentAction).attr('disabled', true);
            }

            currentAction = $(data.id);

            currentAction.removeClass('Hidden');
            $('input, select', currentAction).each(function (index, element) {
                element = $(element);
                if (!element.data('inactive')) 
                    element.attr('disabled', false);
            });

            if (data.id == '#tabExistingCard')
                $(':radio:first', '#tabExistingCard').click();
            else
                $('#hBankPayCardID').val('');
                
        }

        function removeItem(id) {
            $('[data-id="' + id + '"]', '#cardActionSelector').remove();
            $('#cardActionSelector').removeClass('Cols-2').addClass('Cols-1');
            $(id).remove();
        }

        // <%-- init tabs starts --%>
        var $list = $('div.BankWithdrawal ul.PayCardList li');
        if ($list.length > 0) {
            $(':radio', $list).click(function (e) {
                var json = $(this).data('json');
                $('#hBankPayCardID').val($(this).val());
                $(this).val($('#hBankPayCardID').val())
                activate($('#fldBankName2'), false);
                activate($('#fldBankCode2'), false);
                activate($('#fldBranchAddress2'), false);
                activate($('#fldBranchCode2'), false);
                activate($('#fldPayee2'), false);
                activate($('#fldPayeeAddress2'), false);
                activate($('#fldAccountNumber2'), false);
                activate($('#fldIBAN2'), false);
                activate($('#fldSWIFT2'), false);
                activate($('#fldCurrency2'), false);

                if (json.BankName.length > 0) {
                    activate($('#fldBankName2'), true, json.BankName);
                }
                if (json.BankCode.length > 0) {
                    activate($('#fldBankCode2'), true, json.BankCode);
                }
                if (json.BranchAddress.length > 0) {
                    activate($('#fldBranchAddress2'), true, json.BranchAddress);
                }
                if (json.BranchCode.length > 0) {
                    activate($('#fldBranchCode2'), true, json.BranchCode);
                }
                if (json.Payee.length > 0) {
                    activate($('#fldPayee2'), true, json.Payee);
                }
                if (json.PayeeAddress.length > 0) {
                    activate($('#fldPayeeAddress2'), true, json.PayeeAddress);
                }
                if (json.AccountNumber.length > 0) {
                    activate($('#fldAccountNumber2'), true, json.AccountNumber);
                }
                if (json.IBAN.length > 0) {
                    activate($('#fldIBAN2'), true, json.IBAN);
                }
                if (json.SWIFT.length > 0) {
                    activate($('#fldSWIFT2'), true, json.SWIFT);
                }
                if (json.Currency.length > 0) {
                    activate($('#fldCurrency2'), true, json.Currency);
                }

            });

            function activate(element, state, updateVal) {
                if (state)
                    element.show();
                else
                    element.hide();

                var input = $('.FormInput', element);
                input.attr('disabled', !state).data('inactive', !state);
                if (updateVal !== undefined)
                    input.val(updateVal);
            }

            $(document).ready(function () {
                $(':radio:first', $list.eq(0)).click();
            });

            if ($list.length.length >= 3) 
                removeItem('#tabRegisterCard');
        }
        else 
            removeItem('#tabExistingCard');
        // <%-- init tabs ends --%>

        cardActionSelector.evt.bind('select', selectAction);
        selectAction(cardActionSelector.select(0));


        // <%-- on country selected --%>
        $('#ddlBankCountry').change(function () {
            var countryID = $(this).val();
            var json = $(this).data('json');
            var type = json[countryID];
            if( type == null ){
                return;
            }

            var cfg = g_Configurations[countryID];
            var cfgField = null;
            if(g_FieldConfigurations[countryID]){
                var cfgField = g_FieldConfigurations[countryID][type];
            }

            /* <%-- merging fields and validation configs --%> */
            if (cfg == null) {
                if (cfgField == null) {
                    cfgField = new CountryBankConfiguration();

                    LoadDefaultFieldsConfig(cfgField, type);
                }

                g_CurrentConfiguration = cfgField;
            }
            else
            {
                if (cfgField == null) {
                    cfgField = new CountryBankConfiguration();

                    LoadDefaultFieldsConfig(cfgField, type);
                }
                
                //copy all relevant fields to general settings
                cfg.showBankName = cfgField.showBankName;
                cfg.showBankCode = cfgField.showBankCode;
                cfg.showBranchAddress = cfgField.showBranchAddress;
                cfg.showBranchCode = cfgField.showBranchCode;
                cfg.isBranchCodeRequired = cfgField.isBranchCodeRequired;
                cfg.showPayee = cfgField.showPayee;
                cfg.showPayeeAddress = cfgField.showPayeeAddress;
                cfg.showAccountNumber = cfgField.showAccountNumber;
                cfg.showIBAN = cfgField.showIBAN;
                cfg.showSWIFT = cfgField.showSWIFT;
                cfg.showCheckDigits = cfgField.showCheckDigits;
                cfg.showPersonalIDNumber = cfgField.showPersonalIDNumber;
                cfg.currencyOptions = cfgField.currencyOptions;
                cfg.onChangeOfAccountNumber = cfgField.onChangeOfAccountNumber;
                
                if (cfgField.maxLengthOfSWIFT && cfgField.maxLengthOfSWIFT > 0)
                    cfg.maxLengthOfSWIFT = cfgField.maxLengthOfSWIFT;
                if (cfgField.exampleOfSWIFT && cfgField.exampleOfSWIFT.length > 0)
                    cfg.exampleOfSWIFT = cfgField.exampleOfSWIFT;
                if (cfgField.validationExpressionOfSWIFT)
                    cfg.validationExpressionOfSWIFT = cfgField.validationExpressionOfSWIFT;
                if (cfgField.maxLengthOfPayee && cfgField.maxLengthOfPayee > 0)
                    cfg.maxLengthOfPayee = cfgField.maxLengthOfPayee;
                if (cfgField.maxLengthOfIBAN && cfgField.maxLengthOfIBAN > 0)
                    cfg.maxLengthOfIBAN = cfgField.maxLengthOfIBAN;
                if (cfgField.exampleOfIBAN && cfgField.exampleOfIBAN.length > 0)
                    cfg.exampleOfIBAN = cfgField.exampleOfIBAN;
                if (cfgField.validationExpressionOfIBAN)
                    cfg.validationExpressionOfIBAN = cfgField.validationExpressionOfIBAN;
                if (cfgField.validationExpressionOfBankCode)
                    cfg.validationExpressionOfBankCode = cfgField.validationExpressionOfBankCode;
                if (cfgField.maxLengthOfBankCode && cfgField.maxLengthOfBankCode > 0)
                    cfg.maxLengthOfBankCode = cfgField.maxLengthOfBankCode;
                if (cfgField.maxLengthOfAccountNumber && cfgField.maxLengthOfAccountNumber > 0)
                    cfg.maxLengthOfAccountNumber = cfgField.maxLengthOfAccountNumber;
                if (cfgField.validationExpressionOfAccountNumber)
                    cfg.validationExpressionOfAccountNumber = cfgField.validationExpressionOfAccountNumber;

                g_CurrentConfiguration = cfg;
            }

            g_CurrentConfiguration.vendorID = type;

            $('#hBankPayCardVendorID').val(g_CurrentConfiguration.vendorID);

            $('#fldBankName').css('display', g_CurrentConfiguration.showBankName ? '' : 'none');
            $('#fldBankCode').css('display', g_CurrentConfiguration.showBankCode ? '' : 'none');
            $('#fldBranchAddress').css('display', g_CurrentConfiguration.showBranchAddress ? '' : 'none');
            $('#fldBranchCode').css('display', g_CurrentConfiguration.showBranchCode ? '' : 'none');
            $('#fldPayee').css('display', g_CurrentConfiguration.showPayee ? '' : 'none');
            $('#fldPayeeAddress').css('display', g_CurrentConfiguration.showPayeeAddress ? '' : 'none');
            $('#fldAccountNumber').css('display', g_CurrentConfiguration.showAccountNumber ? '' : 'none');
            $('#fldIBAN').css('display', g_CurrentConfiguration.showIBAN ? '' : 'none');
            $('#fldSWIFT').css('display', g_CurrentConfiguration.showSWIFT ? '' : 'none');
            $('#fldCheckDigits').css('display', g_CurrentConfiguration.showCheckDigits ? '' : 'none');
            $('#fldPersonalIDNumber').css('display', g_CurrentConfiguration.showPersonalIDNumber ? '' : 'none');

            if (g_CurrentConfiguration.currencyOptions.length == 0) {
                $('#fldPayCardCurrency').hide();
                $('#fldPayCardCurrency select[name="currency"]').empty();
            }
            else {
                $('#fldPayCardCurrency').show();
                $('#fldPayCardCurrency select[name="currency"]').empty();
                for (var i = 0; i < g_CurrentConfiguration.currencyOptions.length; i++) {
                    $('<option />')
                        .text(g_CurrentConfiguration.currencyOptions[i])
                        .attr('value', g_CurrentConfiguration.currencyOptions[i])
                        .appendTo($('#fldPayCardCurrency select[name="currency"]'));
                }
            }

            $('div.BankWithdrawal').clearFormErrors();
            $('#fldBankName input[type="text"]').val('');
            $('#fldBankCode input[type="text"]').val('');
            $('#fldBranchAddress input[type="text"]').val('');
            $('#fldBranchCode input[type="text"]').val('');
            $('#fldAccountNumber input[type="text"]').val(g_CurrentConfiguration.prefillOfAccountNumber);
            //if (g_CurrentConfiguration.showIBAN)
            //    $('#fldIBAN input[type="text"]').val(g_CurrentConfiguration.prefillOfIBAN);
            //else
            $('#fldIBAN input[type="text"]').val('');
            $('#fldSWIFT input[type="text"]').val('');
            $('#fldCheckDigits input[type="text"]').val('');
            $('#fldPersonalIDNumber input[type="text"]').val('');
            if (g_CurrentConfiguration.showPayee)
                $('#fldPayee input[type="text"]').val('<%= Profile.DisplayName.SafeJavascriptStringEncode() %>');
            else
                $('#fldPayee input[type="text"]').val('');
            $('#fldPayeeAddress input[type="text"]').val('');
            if (g_CurrentConfiguration.exampleOfIBAN) {
                //$('#fldIBAN input[type="text"]').attr('placeholder', g_CurrentConfiguration.exampleOfIBAN);
                $('#fldIBAN span.FormHelp').text('Example: ' + g_CurrentConfiguration.exampleOfIBAN);
            }
            if (g_CurrentConfiguration.exampleOfAccountNumber)
                $('#fldAccountNumber span.FormHelp').text('Example: ' + g_CurrentConfiguration.exampleOfAccountNumber);
            if (g_CurrentConfiguration.exampleOfSWIFT) {
                //$('#fldSWIFT input[type="text"]').attr('placeholder', g_CurrentConfiguration.exampleOfSWIFT);
                $('#fldSWIFT span.FormHelp').text('Example: ' + g_CurrentConfiguration.exampleOfSWIFT);
            }

            setTimeout(function () {
                $('#fldBankName input[type="text"]').attr('maxLength', g_CurrentConfiguration.maxLengthOfBankName.toString());
                $('#fldBankCode input[type="text"]').attr('maxLength', g_CurrentConfiguration.maxLengthOfBankCode.toString());
                $('#fldBranchAddress input[type="text"]').attr('maxLength', g_CurrentConfiguration.maxLengthOfBranchAddress.toString());
                $('#fldBranchCode input[type="text"]').attr('maxLength', g_CurrentConfiguration.maxLengthOfBranchCode.toString());
                $('#fldPayee input[type="text"]').attr('maxLength', g_CurrentConfiguration.maxLengthOfPayee.toString());
                $('#fldPayeeAddress input[type="text"]').attr('maxLength', g_CurrentConfiguration.maxLengthOfPayeeAddress.toString());
                $('#fldAccountNumber input[type="text"]').attr('maxLength', g_CurrentConfiguration.maxLengthOfAccountNumber.toString());
                $('#fldIBAN input[type="text"]').attr('maxlength', g_CurrentConfiguration.maxLengthOfIBAN);
                $('#fldSWIFT input[type="text"]').attr('maxLength', g_CurrentConfiguration.maxLengthOfSWIFT);
                $('#fldCheckDigits input[type="text"]').attr('maxLength', g_CurrentConfiguration.maxLengthOfCheckDigits.toString());
                $('#fldPersonalIDNumber input[type="text"]').attr('maxLength', g_CurrentConfiguration.maxLengthOfPersonalIDNumber.toString());
            }, 0);

            // <%-- Warning message --%>
            $('#msgTurkeyWarning').css('display', (countryID == 223) ? '' : 'none');
        }).trigger('change');
    };

    function LoadDefaultFieldsConfig(cfg, type) {
        if( type == 'Envoy' ){
            cfg.vendorID = 'Envoy';
            cfg.showBankName = true;
            cfg.showBankCode = true;
            cfg.showBranchAddress = true;
            cfg.showBranchCode = true;
            cfg.showPayee = true;
            cfg.showPayeeAddress = false;
            cfg.showAccountNumber = true;
            cfg.showSWIFT = true;
        }
        else if( type == 'ClassicInternationalBank' ) {
            cfg.vendorID = 'Bank';
            cfg.showBankName = true;
            cfg.showBankCode = true;
            cfg.showBranchAddress = true;
            cfg.showBranchCode = true;
            cfg.showPayee = true;
            cfg.showPayeeAddress = false;
            cfg.showAccountNumber = true;
            cfg.showIBAN = false;
            cfg.showSWIFT = true;
        }
        else if( type == 'ClassicEECBank' ) {
            cfg.vendorID = 'Bank';
            cfg.showBankName = false;
            cfg.showBranchAddress = false;
            cfg.showAccountNumber = false;
            cfg.showPayee = true;
            cfg.showPayeeAddress = false;
            cfg.showIBAN = true;
            cfg.showSWIFT = true;
        }
        else if( type == 'InPay' ) {
            cfg.vendorID = 'InPay';
            cfg.showBankName = true;
            cfg.showBranchAddress = true;
            cfg.showAccountNumber = false;
            cfg.showPayee = true;
            cfg.showPayeeAddress = true;
            cfg.showIBAN = true;
            cfg.showSWIFT = true;
        }
        else if( type == 'EnterCash' ) {
            cfg.vendorID = 'EnterCash';
            cfg.showBankName = false;
            cfg.showBranchAddress = false;
            cfg.showAccountNumber = false;
            cfg.showPayee = false;
            cfg.showPayeeAddress = false;
            cfg.showIBAN = false;
            cfg.showSWIFT = false;
        }
    }

    function CountryBankConfiguration() {
        this.vendorID = 'Envoy';

        this.showBankName = false;
        this.showBankCode = false;
        this.showBranchAddress = false;
        this.showBranchCode = false;
        this.isBranchCodeRequired = false;
        this.showPayee = false;
        this.showPayeeAddress = false;
        this.showAccountNumber = false;
        this.showIBAN = false;
        this.showSWIFT = false;
        this.showCheckDigits = false;
        this.showPersonalIDNumber = false;
        this.currencyOptions = [];

        this.maxLengthOfBankName = 50;
        this.maxLengthOfBankCode = 50;
        this.maxLengthOfBranchAddress = 50;
        this.maxLengthOfBranchCode = 50;
        this.maxLengthOfPayee = 35;
        this.maxLengthOfPayeeAddress = 50;
        this.maxLengthOfAccountNumber = 50;
        this.maxLengthOfIBAN = 34;
        this.maxLengthOfSWIFT = 11;
        this.maxLengthOfCheckDigits = 20;
        this.maxLengthOfPersonalIDNumber = 255;

        this.validationExpressionOfBankName = null;
        this.validationExpressionOfBankCode = null;
        this.validationExpressionOfBranchAddress = null;
        this.validationExpressionOfBranchCode = null;
        this.validationExpressionOfPayee = null;
        this.validationExpressionOfPayeeAddress = null;
        this.validationExpressionOfAccountNumber = null;
        this.validationExpressionOfIBAN = null;
        this.validationExpressionOfSWIFT = /^(([a-z]|[0-9]){8,11})$/i;
        this.validationExpressionOfCheckDigits = null;
        this.validationExpressionOfPersonalIDNumber = null;

        this.prefillOfIBAN = '';
        this.prefillOfAccountNumber = '';

        this.exampleOfIBAN = '';
        this.exampleOfAccountNumber = '';
        this.exampleOfSWIFT = '';

        this.onChangeOfAccountNumber = null;

        this.initEUFormat = function(){
            this.showBankName = true;
            this.showBankCode = false;
            this.showBranchAddress = true;
            this.showPayee = true;
            this.showIBAN = true;
            this.showSWIFT = true;
            return this;
        };
    }

    /* <%-- Croatia --%> */
    var cfgEnvoy = new CountryBankConfiguration();
    var cfgInPay = new CountryBankConfiguration();
    var cfg = new CountryBankConfiguration();

    g_FieldConfigurations['60']={};
    g_FieldConfigurations['60']['Envoy'] = cfgEnvoy;
    cfgEnvoy.showBankName = true;
    cfgEnvoy.showBranchAddress = true;
    cfgEnvoy.showPayee = true;
    cfgEnvoy.showIBAN = true;
    cfgEnvoy.showSWIFT = true;

    g_FieldConfigurations['60']['InPay'] = cfgInPay;
    LoadDefaultFieldsConfig(cfgInPay, 'InPay'); //setting defaults
    cfgInPay.showPayeeAddress = false;
    cfgInPay.showBranchAddress = false;
    cfgInPay.showAccountNumber = false;
    cfgInPay.showIBAN = true;

    g_Configurations['60'] = cfg;
    cfg.maxLengthOfIBAN = 21;
    cfg.validationExpressionOfIBAN = /^(HR)\d{19,19}$/i;
    cfg.exampleOfIBAN = 'HR1210010051863000160';
    cfg.prefillOfIBAN = 'HR';
    cfg.validationExpressionOfSWIFT = /^(([a-z]|[0-9]){8,11})$/i;
    cfg.exampleOfSWIFT = 'CDBSHR2XXXX';

    /* <%-- Bosnia and Herzegovina --%> */
    var cfgEnvoy = new CountryBankConfiguration();
    var cfgInPay = new CountryBankConfiguration();
    var cfg = new CountryBankConfiguration();

    g_FieldConfigurations["34"]={};
    g_FieldConfigurations['34']['Envoy'] = cfgEnvoy;
    cfgEnvoy.showBankName = true;
    cfgEnvoy.showBranchAddress = true;
    cfgEnvoy.showPayee = true;
    cfgEnvoy.showIBAN = true;
    cfgEnvoy.showSWIFT = true;
    
    g_FieldConfigurations['34']['InPay'] = cfgInPay;
    LoadDefaultFieldsConfig(cfgInPay, 'InPay'); //setting defaults
    cfgInPay.showBranchAddress = false;
    cfgInPay.showAccountNumber = false;
    cfgInPay.showIBAN = true;

    g_Configurations['34'] = cfg;
    cfg.maxLengthOfIBAN = 20;
    cfg.exampleOfIBAN = "BA391290079401028494";
    cfg.prefillOfIBAN = 'BA';
    cfg.validationExpressionOfIBAN = /^(BA)\d{18,18}$/i;
    cfg.validationExpressionOfSWIFT = /^(([a-z]|[0-9]){8,11})$/i;
    cfg.exampleOfSWIFT = 'BOIRBA22';

    /* <%-- Mauritius --%> */
    var cfgEnvoy = new CountryBankConfiguration();
    var cfgInPay = new CountryBankConfiguration();
    var cfg = new CountryBankConfiguration();

    g_FieldConfigurations["141"]={};
    g_FieldConfigurations['141']['Envoy'] = cfgEnvoy;
    cfgEnvoy.showBankName = true;
    cfgEnvoy.showBranchAddress = true;
    cfgEnvoy.showPayee = true;
    cfgEnvoy.showIBAN = true;
    cfgEnvoy.showSWIFT = true;
    
    g_FieldConfigurations['141']['InPay'] = cfgInPay;
    LoadDefaultFieldsConfig(cfgInPay, 'InPay'); //setting defaults
    cfgInPay.showBranchAddress = false;
    cfgInPay.showAccountNumber = false;
    cfgInPay.showIBAN = true;

    g_Configurations['141'] = cfg;
    cfg.maxLengthOfIBAN = 30;
    cfg.exampleOfIBAN = "MU17BOMM0101101030300200000MUR";
    cfg.prefillOfIBAN = 'MU';
    cfg.validationExpressionOfIBAN = /^(MU)\d{28,28}$/i;
    cfg.validationExpressionOfSWIFT = /^(([a-z]|[0-9]){8,11})$/i;
    cfg.exampleOfSWIFT = 'BARBMUMUXXX';

    /* <%-- Saudi Arabia --%> */
    var cfgEnvoy = new CountryBankConfiguration();
    var cfgInPay = new CountryBankConfiguration();
    var cfg = new CountryBankConfiguration();

    g_FieldConfigurations["191"]={};
    g_FieldConfigurations['191']['Envoy'] = cfgEnvoy;
    cfgEnvoy.showBankName = true;
    cfgEnvoy.showBranchAddress = true;
    cfgEnvoy.showPayee = true;
    cfgEnvoy.showIBAN = true;
    cfgEnvoy.showSWIFT = true;

    g_FieldConfigurations['191']['InPay'] = cfgInPay;
    LoadDefaultFieldsConfig(cfgInPay, 'InPay'); //setting defaults
    cfgInPay.showBranchAddress = false;
    cfgInPay.showAccountNumber = false;
    cfgInPay.showIBAN = true;

    g_Configurations['191'] = cfg;
    cfg.maxLengthOfIBAN = 24;
    cfg.exampleOfIBAN = "SA0380000000608010167519";
    cfg.prefillOfIBAN = 'SA';
    cfg.validationExpressionOfIBAN = /^(SA)\d{22,22}$/i;
    cfg.validationExpressionOfSWIFT = /^(([a-z]|[0-9]){8,11})$/i;
    cfg.exampleOfSWIFT = 'AFEXSAJ1XXX';

    /* <%-- Switzerland --%> */
    var cfgEnvoy = new CountryBankConfiguration();
    var cfgInPay = new CountryBankConfiguration();
    var cfg = new CountryBankConfiguration();

    g_FieldConfigurations["212"]={};
    g_FieldConfigurations['212']['Envoy'] = cfgEnvoy;
    cfgEnvoy.showBankName = true;
    cfgEnvoy.showBranchAddress = true;
    cfgEnvoy.showPayee = true;
    cfgEnvoy.showIBAN = true;
    cfgEnvoy.showSWIFT = true;
    cfgEnvoy.showBankCode = false;
    cfgEnvoy.showBranchCode = false;
    cfgEnvoy.showAccountNumber = false;
    cfgEnvoy.showIBAN = true;
    cfgEnvoy.maxLengthOfIBAN = 21;
    cfgEnvoy.exampleOfIBAN = "CH100023000A109822346";
    cfgEnvoy.validationExpressionOfIBAN = /^(CH)\d{9,9}([a-z]|[A-Z]|[0-9]{1,1})\d{8,8}([a-z]|[A-Z]|[0-9]{1,1})$/i;
    
    g_FieldConfigurations['212']['InPay'] = cfgInPay;
    LoadDefaultFieldsConfig(cfgInPay, 'InPay'); //setting defaults
    cfgInPay.showPayeeAddress = false;
    cfgInPay.showBranchAddress = false;
    cfgInPay.showAccountNumber = false;
    cfgInPay.showIBAN = true;

    g_Configurations['212'] = cfg;
    cfg.maxLengthOfIBAN = 21;
    cfg.exampleOfIBAN = "CH9300762011623852957";
    cfg.prefillOfIBAN = 'CH';
    cfg.validationExpressionOfIBAN = /^(CH)\d{9,9}([a-z]|[A-Z]|[0-9]{1,1})\d{8,8}([a-z]|[A-Z]|[0-9]{1,1})$/i;
    cfg.validationExpressionOfSWIFT = /^(([a-z]|[0-9]){8,11})$/i;
    cfg.exampleOfSWIFT = 'ARBSCHZZ';

    /* <%-- Monaco --%> */
    var cfgEnvoy = new CountryBankConfiguration();
    var cfgInPay = new CountryBankConfiguration();
    var cfg = new CountryBankConfiguration();

    g_FieldConfigurations['146']={};
    g_FieldConfigurations['146']['Envoy'] = cfgEnvoy;
    LoadDefaultFieldsConfig(cfgEnvoy, 'Envoy'); //setting defaults
    cfgEnvoy.showBankCode = false;
    cfgEnvoy.showBranchCode = false;
    cfgEnvoy.showAccountNumber = false;
    cfgEnvoy.showIBAN = true;
    cfgEnvoy.maxLengthOfIBAN = 27;
    
    g_FieldConfigurations['146']['InPay'] = cfgInPay;
    LoadDefaultFieldsConfig(cfgInPay, 'InPay'); //setting defaults
    cfgInPay.showPayeeAddress = false;
    cfgInPay.showBranchAddress = false;
    cfgInPay.showAccountNumber = false;
    cfgInPay.showIBAN = true;

    g_Configurations['146'] = cfg;
    cfg.maxLengthOfIBAN = 27;
    cfg.exampleOfIBAN = "MC1112739000700011111000079";
    cfg.prefillOfIBAN = 'MC';
    cfg.validationExpressionOfIBAN = /^(MC)\d{25,25}$/i;
    cfg.exampleOfSWIFT = 'CRESMCMX';

    /* <%-- Mayotte --%> */
    var cfgInPay = new CountryBankConfiguration();
    var cfg = new CountryBankConfiguration();

    g_FieldConfigurations["142"]={};
    g_FieldConfigurations['142']['InPay'] = cfgInPay;
    LoadDefaultFieldsConfig(cfgInPay, 'InPay'); //setting defaults
    cfgInPay.showPayeeAddress = false;
    cfgInPay.showBranchAddress = false;
    cfgInPay.showAccountNumber = false;
    cfgInPay.showIBAN = true;

    g_Configurations['142'] = cfg;
    cfg.maxLengthOfIBAN = 27;
    cfg.validationExpressionOfIBAN = /^(FR)\d{18,18}$/i;
    cfg.prefillOfIBAN = 'FR';
    cfg.exampleOfIBAN = 'FR1420041010050500013M02606';
    cfg.exampleOfSWIFT = 'BFCOYTYT';

    /* <%-- Montenegro --%> */
    var cfgInPay = new CountryBankConfiguration();
    var cfg = new CountryBankConfiguration();

    g_FieldConfigurations["248"]={};
    g_FieldConfigurations['248']['InPay'] = cfgInPay;
    LoadDefaultFieldsConfig(cfgInPay, 'InPay'); //setting defaults
    cfgInPay.showBranchAddress = false;
    cfgInPay.showAccountNumber = false;
    cfgInPay.showIBAN = true;

    g_Configurations['248'] = cfg;
    cfg.maxLengthOfIBAN = 22;
    cfg.validationExpressionOfIBAN = /^(ME)\d{20,20}$/i;
    cfg.prefillOfIBAN = 'ME';
    cfg.exampleOfIBAN = 'ME25505000012345678951';
    cfg.exampleOfSWIFT = 'BFCOYTYT';

    /* <%-- San Marino --%> */
    var cfgInPay = new CountryBankConfiguration();
    var cfg = new CountryBankConfiguration();

    g_FieldConfigurations["189"]={};
    g_FieldConfigurations['189']['InPay'] = cfgInPay;
    LoadDefaultFieldsConfig(cfgInPay, 'InPay'); //setting defaults
    cfgInPay.showPayeeAddress = false;
    cfgInPay.showBranchAddress = false;
    cfgInPay.showAccountNumber = false;
    cfgInPay.showIBAN = true;

    g_Configurations['189'] = cfg;
    cfg.maxLengthOfIBAN = 27;
    cfg.validationExpressionOfIBAN = /^(SM)\d{25,25}$/i;
    cfg.prefillOfIBAN = 'SM';
    cfg.exampleOfIBAN = 'SM86U0322509800000000270100';
    cfg.exampleOfSWIFT = 'MAOISMSM001';
    
    /* <%-- St Pierre and Miquelon --%> */
    var cfgInPay = new CountryBankConfiguration();
    var cfg = new CountryBankConfiguration();

    g_FieldConfigurations["206"]={};
    g_FieldConfigurations['206']['InPay'] = cfgInPay;
    LoadDefaultFieldsConfig(cfgInPay, 'InPay'); //setting defaults
    cfgInPay.showPayeeAddress = false;
    cfgInPay.showBranchAddress = false;
    cfgInPay.showAccountNumber = false;
    cfgInPay.showIBAN = true;

    g_Configurations['206'] = cfg;
    cfg.maxLengthOfIBAN = 27;
    cfg.validationExpressionOfIBAN = /^(FR)([a-z]|[0-9]){25,25}$/i;
    cfg.exampleOfIBAN = 'FR1420041010050500013M02606';
    cfg.prefillOfIBAN = 'FR';
    cfg.exampleOfSWIFT = 'BDILPMPM';
    
    /* <%-- Kazakhstan  --%> */
    var cfg = new CountryBankConfiguration();

    g_Configurations['116'] = cfg;
    cfg.maxLengthOfIBAN = 20;
    cfg.validationExpressionOfIBAN = /^(KZ)\d{18,18}$/i;
    cfg.prefillOfIBAN = 'KZ';
    cfg.exampleOfIBAN = 'KZ86125KZT5004100100';
    cfg.exampleOfSWIFT = 'CITIKZKA';
    
    /* <%-- Kuwait  --%> */
    var cfg = new CountryBankConfiguration();

    g_Configurations['119'] = cfg;
    cfg.maxLengthOfIBAN = 30;
    cfg.validationExpressionOfIBAN = /^(KW)\d{28,28}$/i;
    cfg.prefillOfIBAN = 'KW';
    cfg.exampleOfIBAN = 'KW81CBKU0000000000001234560101';
    cfg.exampleOfSWIFT = 'BBKUKWKW';
    
    /* <%-- Andorra  --%> */
    var cfgInPay = new CountryBankConfiguration();
    var cfg = new CountryBankConfiguration();

    g_FieldConfigurations["12"]={};
    g_FieldConfigurations['12']['InPay'] = cfgInPay;
    LoadDefaultFieldsConfig(cfgInPay, 'InPay'); //setting defaults
    cfgInPay.showBranchAddress = false;
    cfgInPay.showAccountNumber = false;
    cfgInPay.showIBAN = true;

    g_Configurations['12'] = cfg;
    cfg.maxLengthOfIBAN = 24;
    cfg.validationExpressionOfIBAN = /^(AD)\d{22,22}$/i;
    cfg.prefillOfIBAN = 'AD';
    cfg.exampleOfIBAN = 'AD1200012030200359100100 ';
    cfg.exampleOfSWIFT = 'BACAADAD';
    
    /* <%-- Faroe Islands  --%> */
    var cfgInPay = new CountryBankConfiguration();
    var cfg = new CountryBankConfiguration();

    g_FieldConfigurations["77"]={};
    g_FieldConfigurations['77']['InPay'] = cfgInPay;
    LoadDefaultFieldsConfig(cfgInPay, 'InPay'); //setting defaults
    cfgInPay.showBranchAddress = false;
    cfgInPay.showAccountNumber = false;
    cfgInPay.showIBAN = true;

    g_Configurations['77'] = cfg;
    cfg.maxLengthOfIBAN = 18;
    cfg.validationExpressionOfIBAN = /^(FO)\d{16,16}$/i;
    cfg.prefillOfIBAN = 'FO';
    cfg.exampleOfIBAN = 'FO6264600001631634';
    cfg.exampleOfSWIFT = 'FIFBFOTX';
    
    /* <%-- Georgia  --%> */
    var cfgInPay = new CountryBankConfiguration();
    var cfg = new CountryBankConfiguration();

    g_FieldConfigurations["87"]={};
    g_FieldConfigurations['87']['InPay'] = cfgInPay;
    LoadDefaultFieldsConfig(cfgInPay, 'InPay'); //setting defaults
    cfgInPay.showBranchAddress = false;
    cfgInPay.showAccountNumber = false;
    cfgInPay.showIBAN = true;

    g_Configurations['87'] = cfg;
    cfg.maxLengthOfIBAN = 22;
    cfg.validationExpressionOfIBAN = /^(GE)\d{20,20}$/i;
    cfg.prefillOfIBAN = 'GE';
    cfg.exampleOfIBAN = 'GE29NB0000000101904917';
    cfg.exampleOfSWIFT = 'BAGAGE22BOG';
    
    /* <%-- Greenland  --%> */
    var cfgInPay = new CountryBankConfiguration();
    var cfg = new CountryBankConfiguration();

    g_FieldConfigurations["92"]={};
    g_FieldConfigurations['92']['InPay'] = cfgInPay;
    LoadDefaultFieldsConfig(cfgInPay, 'InPay'); //setting defaults
    cfgInPay.showBranchAddress = false;
    cfgInPay.showAccountNumber = false;
    cfgInPay.showIBAN = true;

    g_Configurations['92'] = cfg;
    cfg.maxLengthOfIBAN = 18;
    cfg.validationExpressionOfIBAN = /^(GL)\d{16,16}$/i;
    cfg.prefillOfIBAN = 'GL';
    cfg.exampleOfIBAN = 'GL8964710001000206';
    cfg.exampleOfSWIFT = 'GRENGLGX';
    
    /* <%-- Israel --%> */
    var cfgEnvoy = new CountryBankConfiguration();
    var cfgInPay = new CountryBankConfiguration();
    var cfg = new CountryBankConfiguration();

    g_FieldConfigurations["111"]={};
    g_FieldConfigurations['111']['Envoy'] = cfgEnvoy;
    cfgEnvoy.showBankName = true;
    cfgEnvoy.showBranchAddress = true;
    cfgEnvoy.showPayee = true;
    cfgEnvoy.showIBAN = true;
    cfgEnvoy.showSWIFT = true;

    g_FieldConfigurations['111']['InPay'] = cfgInPay;
    LoadDefaultFieldsConfig(cfgInPay, 'InPay'); //setting defaults
    cfgInPay.showBranchAddress = false;
    cfgInPay.showAccountNumber = false;
    cfgInPay.showIBAN = true;

    g_Configurations['111'] = cfg;
    cfg.maxLengthOfIBAN = 23;
    cfg.exampleOfIBAN = "IL620108000000099999999";
    cfg.prefillOfIBAN = 'IL';
    cfg.validationExpressionOfIBAN = /^(IL)\d{21,21}$/i;
    cfg.validationExpressionOfSWIFT = /^(([a-z]|[0-9]){8,11})$/i;
    cfg.exampleOfSWIFT = 'ISRAILIJ';

    /* <%-- Pakistan --%> */
    var cfgEnvoy = new CountryBankConfiguration();
    var cfg = new CountryBankConfiguration();
    g_FieldConfigurations["169"]={};
    g_FieldConfigurations['169']['Envoy'] = cfgEnvoy;
    g_Configurations['169'] = cfg;
    cfgEnvoy.showBankName = true;
    cfgEnvoy.showBranchAddress = true;
    cfgEnvoy.showPayee = true;
    cfgEnvoy.showIBAN = true;
    cfgEnvoy.showSWIFT = true;

    cfg.maxLengthOfIBAN = 24;
    cfg.exampleOfIBAN = "PK36SCBL0000001123456702";
    cfg.prefillOfIBAN = 'PK';
    cfg.validationExpressionOfIBAN = /^(PK)\d{22,22}$/i;
    cfg.validationExpressionOfSWIFT = /^(([a-z]|[0-9]){8,11})$/i;
    cfg.exampleOfSWIFT = 'ABPAPKKALHR';

    /* <%-- Liechtenstein --%> */
    var cfgEnvoy = new CountryBankConfiguration();
    var cfgInPay = new CountryBankConfiguration();
    var cfg = new CountryBankConfiguration();

    g_FieldConfigurations["127"]={};
    g_FieldConfigurations['127']['Envoy'] = cfgEnvoy;
    cfgEnvoy.showBankName = true;
    cfgEnvoy.showBranchAddress = true;
    cfgEnvoy.showPayee = true;
    cfgEnvoy.showIBAN = true;
    cfgEnvoy.showSWIFT = true;
    
    g_FieldConfigurations['127']['InPay'] = cfgInPay;
    LoadDefaultFieldsConfig(cfgInPay, 'InPay'); //setting defaults
    cfgInPay.showPayeeAddress = false;
    cfgInPay.showBranchAddress = false;
    cfgInPay.showAccountNumber = false;
    cfgInPay.showIBAN = true;

    g_Configurations['127'] = cfg;
    cfg.maxLengthOfIBAN = 21;
    cfg.validationExpressionOfIBAN = /^(LI)([a-z]|[0-9]){19,19}$/i;
    cfg.exampleOfIBAN = 'LI21088100002324013AA';
    cfg.prefillOfIBAN = 'LI';
    cfg.validationExpressionOfSWIFT = /^(([a-z]|[0-9]){8,11})$/i;
    cfg.exampleOfSWIFT = 'VOAGLI22XXX';

    /* <%-- French Guiana --%> */
    var cfgEnvoy = new CountryBankConfiguration();
    var cfg = new CountryBankConfiguration();
    g_FieldConfigurations["82"]={};
    g_FieldConfigurations['82']['Envoy'] = cfgEnvoy;
    g_Configurations['82'] = cfg;
    cfgEnvoy.showBankName = true;
    cfgEnvoy.showBranchAddress = true;
    cfgEnvoy.showPayee = true;
    cfgEnvoy.showIBAN = true;
    cfgEnvoy.showSWIFT = true;    

    cfg.maxLengthOfIBAN = 35;
    cfg.validationExpressionOfSWIFT = /^(([a-z]|[0-9]){8,11})$/i;
    cfg.exampleOfSWIFT = 'AGRIGFG1KOU';

    /* <%-- Gibraltar --%> */
    var cfgEnvoy = new CountryBankConfiguration();
    var cfgInPay = new CountryBankConfiguration();
    var cfg = new CountryBankConfiguration();

    g_FieldConfigurations["90"]={};
    g_FieldConfigurations['90']['Envoy'] = cfgEnvoy;
    cfgEnvoy.showBankName = true;
    cfgEnvoy.showBranchAddress = true;
    cfgEnvoy.showPayee = true;
    cfgEnvoy.showIBAN = true;
    cfgEnvoy.showSWIFT = true;
    
    g_FieldConfigurations['90']['InPay'] = cfgInPay;
    LoadDefaultFieldsConfig(cfgInPay, 'InPay'); //setting defaults
    cfgInPay.showBranchAddress = false;
    cfgInPay.showAccountNumber = false;
    cfgInPay.showIBAN = true;

    g_Configurations['90'] = cfg;
    cfg.maxLengthOfIBAN = 23;
    cfg.validationExpressionOfIBAN = /^(GI)([a-z]|[0-9]){21,21}$/i;
    cfg.exampleOfIBAN = 'GI75NWBK000000007099453';
    cfg.prefillOfIBAN = 'GI';
    cfg.validationExpressionOfSWIFT = /^(([a-z]|[0-9]){8,11})$/i;
    cfg.exampleOfSWIFT = 'BJSBGIGXXXX';

    /* <%-- Guadeloupe --%> */
    var cfgEnvoy = new CountryBankConfiguration();
    var cfgInPay = new CountryBankConfiguration();
    var cfg = new CountryBankConfiguration();

    g_FieldConfigurations["94"]={};
    g_FieldConfigurations['94']['Envoy'] = cfgEnvoy;
    cfgEnvoy.showBankName = true;
    cfgEnvoy.showBranchAddress = true;
    cfgEnvoy.showPayee = true;
    cfgEnvoy.showIBAN = true;
    cfgEnvoy.showSWIFT = true;
    
    g_FieldConfigurations['94']['InPay'] = cfgInPay;
    LoadDefaultFieldsConfig(cfgInPay, 'InPay'); //setting defaults
    cfgInPay.showBranchAddress = false;
    cfgInPay.showAccountNumber = false;
    cfgInPay.showIBAN = true;

    g_Configurations['94'] = cfg;
    cfg.maxLengthOfIBAN = 35;
    cfg.validationExpressionOfSWIFT = /^(([a-z]|[0-9]){8,11})$/i;
    cfg.exampleOfSWIFT = 'AGRIGPGXXXX';

    /* <%-- Hungary --%> */
    var cfgEnvoy = new CountryBankConfiguration();
    var cfgInPay = new CountryBankConfiguration();
    var cfg = new CountryBankConfiguration();

    g_FieldConfigurations["104"]={};
    g_FieldConfigurations['104']['Envoy'] = cfgEnvoy;
    cfgEnvoy.showBankName = true;
    cfgEnvoy.showBranchAddress = true;
    cfgEnvoy.showPayee = true;
    cfgEnvoy.showIBAN = true;
    cfgEnvoy.showSWIFT = true;

    g_FieldConfigurations['104']['InPay'] = cfgInPay;
    LoadDefaultFieldsConfig(cfgInPay, 'InPay'); //setting defaults
    cfgInPay.showPayeeAddress = false;
    cfgInPay.showBranchAddress = false;
    cfgInPay.showAccountNumber = false;
    cfgInPay.showIBAN = true;

    g_Configurations['104'] = cfg;
    cfg.maxLengthOfIBAN = 28;
    cfg.validationExpressionOfIBAN = /^(HU)\d{26,40}$/i;
    cfg.exampleOfIBAN = 'HU42117730161111101800000000';
    cfg.prefillOfIBAN = 'HU';
    cfg.validationExpressionOfSWIFT = /^(([a-z]|[0-9]){8,11})$/i;
    cfg.exampleOfSWIFT = 'AIFMHUH1XXX';
    
    /* <%-- Latvia --%> */
    var cfgEnvoy = new CountryBankConfiguration();
    var cfgInPay = new CountryBankConfiguration();
    var cfg = new CountryBankConfiguration();
    
    g_FieldConfigurations["122"]={};
    g_FieldConfigurations['122']['Envoy'] = cfgEnvoy;
    cfgEnvoy.showBankName = true;
    cfgEnvoy.showBranchAddress = true;
    cfgEnvoy.showPayee = true;
    cfgEnvoy.showIBAN = true;
    cfgEnvoy.showSWIFT = true;
    
    g_FieldConfigurations['122']['InPay'] = cfgInPay;
    LoadDefaultFieldsConfig(cfgInPay, 'InPay'); //setting defaults
    cfgInPay.showPayeeAddress = false;
    cfgInPay.showBranchAddress = false;
    cfgInPay.showAccountNumber = false;
    cfgInPay.showIBAN = true;

    g_Configurations['122'] = cfg;
    cfg.maxLengthOfIBAN = 21;
    cfg.validationExpressionOfIBAN = /^(LV)([a-z]|[0-9]){19,19}$/i;
    cfg.exampleOfIBAN = 'LV80BANK000043519500';
    cfg.prefillOfIBAN = 'LV';
    cfg.validationExpressionOfSWIFT = /^(([a-z]|[0-9]){8,11})$/i;
    cfg.exampleOfSWIFT = 'BATRLV2XXXX';

    /* <%-- Macedonia --%> */
    var cfgEnvoy = new CountryBankConfiguration();
    var cfgInPay = new CountryBankConfiguration();
    var cfg = new CountryBankConfiguration();

    g_FieldConfigurations["131"]={};
    g_FieldConfigurations['131']['Envoy'] = cfgEnvoy;
    cfgEnvoy.showBankName = true;
    cfgEnvoy.showBranchAddress = true;
    cfgEnvoy.showPayee = true;
    cfgEnvoy.showIBAN = true;
    cfgEnvoy.showSWIFT = true;
    
    g_FieldConfigurations['131']['InPay'] = cfgInPay;
    LoadDefaultFieldsConfig(cfgInPay, 'InPay'); //setting defaults
    cfgInPay.showBranchAddress = false;
    cfgInPay.showAccountNumber = false;
    cfgInPay.showIBAN = true;

    g_Configurations['131'] = cfg;
    cfg.maxLengthOfIBAN = 19;
    cfg.validationExpressionOfIBAN = /^(MK)\d{17,17}$/i;
    cfg.exampleOfIBAN = 'MK07250120000058984';
    cfg.prefillOfIBAN = 'MK';
    cfg.validationExpressionOfSWIFT = /^(([a-z]|[0-9]){8,11})$/i;
    cfg.exampleOfSWIFT = 'KOBSMK2XBTB';

    /* <%-- Martinique --%> */
    var cfgEnvoy = new CountryBankConfiguration();
    var cfgInPay = new CountryBankConfiguration();
    var cfg = new CountryBankConfiguration();

    g_FieldConfigurations["139"]={};
    g_FieldConfigurations['139']['Envoy'] = cfgEnvoy;
    cfgEnvoy.showBankName = true;
    cfgEnvoy.showBranchAddress = true;
    cfgEnvoy.showPayee = true;
    cfgEnvoy.showIBAN = true;
    cfgEnvoy.showSWIFT = true;
    
    g_FieldConfigurations['139']['InPay'] = cfgInPay;
    LoadDefaultFieldsConfig(cfgInPay, 'InPay'); //setting defaults
    cfgInPay.showBranchAddress = false;
    cfgInPay.showAccountNumber = false;
    cfgInPay.showIBAN = true;

    g_Configurations['139'] = cfg;
    cfg.maxLengthOfIBAN = 27;
    cfg.validationExpressionOfIBAN = /^(FR)\d{18,18}$/i;
    cfg.prefillOfIBAN = 'FR';
    cfg.exampleOfIBAN = 'FR142004101005050000';
    cfg.validationExpressionOfSWIFT = /^(([a-z]|[0-9]){8,11})$/i;
    cfg.exampleOfSWIFT = 'AGRIMQMXXXX';

    /* <%-- Portugal --%> */
    var cfgEnvoy = new CountryBankConfiguration();
    var cfgInPay = new CountryBankConfiguration();
    var cfg = new CountryBankConfiguration();

    g_FieldConfigurations["178"]={};
    g_FieldConfigurations['178']['Envoy'] = cfgEnvoy;
    cfgEnvoy.showBankName = true;
    cfgEnvoy.showBranchAddress = true;
    cfgEnvoy.showPayee = true;
    cfgEnvoy.showIBAN = true;
    cfgEnvoy.showSWIFT = true;
    
    g_FieldConfigurations['178']['InPay'] = cfgInPay;
    LoadDefaultFieldsConfig(cfgInPay, 'InPay'); //setting defaults
    cfgInPay.showPayeeAddress = false;

    g_Configurations['178'] = cfg;
    cfg.maxLengthOfIBAN = 25;
    cfg.validationExpressionOfIBAN = /^(PT)\d{23,23}$/i;
    cfg.exampleOfIBAN = 'PT50000201231234567890154';
    cfg.prefillOfIBAN = 'PT';
    cfg.validationExpressionOfSWIFT = /^(([a-z]|[0-9]){8,11})$/i;
    cfg.exampleOfSWIFT = 'BAPAPTPLXXX';

    /* <%-- Reunion --%> */
    var cfgEnvoy = new CountryBankConfiguration();
    var cfgInPay = new CountryBankConfiguration();
    var cfg = new CountryBankConfiguration();

    g_FieldConfigurations["181"]={};
    g_FieldConfigurations['181']['Envoy'] = cfgEnvoy;
    cfgEnvoy.showBankName = true;
    cfgEnvoy.showBranchAddress = true;
    cfgEnvoy.showPayee = true;
    cfgEnvoy.showIBAN = true;
    cfgEnvoy.showSWIFT = true;

    g_FieldConfigurations['181']['InPay'] = cfgInPay;
    LoadDefaultFieldsConfig(cfgInPay, 'InPay'); //setting defaults
    cfgInPay.showBranchAddress = false;
    cfgInPay.showAccountNumber = false;
    cfgInPay.showIBAN = true;

    g_Configurations['181'] = cfg;
    cfg.maxLengthOfIBAN = 27;
    cfg.validationExpressionOfIBAN = /^(FR)([a-z]|[0-9]){25,25}$/i;
    cfg.exampleOfIBAN = 'FR1420041010050500013M02606';
    cfg.prefillOfIBAN = 'FR';
    cfg.exampleOfSWIFT = 'BNPARERXPOR';

    /* <%-- Romania --%> */
    var cfgEnvoy = new CountryBankConfiguration();
    var cfgInPay = new CountryBankConfiguration();
    var cfg = new CountryBankConfiguration();

    g_FieldConfigurations["182"]={};
    g_FieldConfigurations['182']['Envoy'] = cfgEnvoy;
    cfgEnvoy.showBankName = true;
    cfgEnvoy.showBranchAddress = true;
    cfgEnvoy.showPayee = true;
    cfgEnvoy.showIBAN = true;
    cfgEnvoy.showSWIFT = true;
    
    g_FieldConfigurations['182']['InPay'] = cfgInPay;
    LoadDefaultFieldsConfig(cfgInPay, 'InPay'); //setting defaults
    cfgInPay.showPayeeAddress = false;
    cfgInPay.showBranchAddress = false;
    cfgInPay.showAccountNumber = false;
    cfgInPay.showIBAN = true;

    g_Configurations['182'] = cfg;
    cfg.maxLengthOfIBAN = 24;
    cfg.validationExpressionOfIBAN = /^(RO)([a-z]|[0-9]){22,22}$/i;
    cfg.exampleOfIBAN = 'RO49AAAA1B31007593840000';
    cfg.prefillOfIBAN = 'RO';
    cfg.validationExpressionOfSWIFT = /^(([a-z]|[0-9]){8,11})$/i;
    cfg.exampleOfSWIFT = 'BTRLRO22ABA';

    /* <%-- Serbia --%> */
    var cfgEnvoy = new CountryBankConfiguration();
    var cfgInPay = new CountryBankConfiguration();
    var cfg = new CountryBankConfiguration();

    g_FieldConfigurations["247"]={};
    g_FieldConfigurations['247']['Envoy'] = cfgEnvoy;
    cfgEnvoy.showBankName = true;
    cfgEnvoy.showBranchAddress = true;
    cfgEnvoy.showPayee = true;
    cfgEnvoy.showIBAN = true;
    cfgEnvoy.showSWIFT = true;
    
    g_FieldConfigurations['247']['InPay'] = cfgInPay;
    LoadDefaultFieldsConfig(cfgInPay, 'InPay'); //setting defaults
    cfgInPay.showBranchAddress = false;
    cfgInPay.showAccountNumber = false;
    cfgInPay.showIBAN = true;

    g_Configurations['247'] = cfg;
    cfg.maxLengthOfIBAN = 22;
    cfg.validationExpressionOfIBAN = /^(RS)(\d){20,20}$/i;
    cfg.exampleOfIBAN = 'RS35260005601001611379';
    cfg.prefillOfIBAN = 'RS';
    cfg.validationExpressionOfSWIFT = /^(([a-z]|[0-9]){8,11})$/i;
    cfg.exampleOfSWIFT = 'KOBBRSBGFCA';

    /* <%-- Slovakia --%> */
    var cfgEnvoy = new CountryBankConfiguration();
    var cfgInPay = new CountryBankConfiguration();
    var cfg = new CountryBankConfiguration();

    g_FieldConfigurations["196"]={};
    g_FieldConfigurations['196']['Envoy'] = cfgEnvoy;
    cfgEnvoy.showBankName = true;
    cfgEnvoy.showBranchAddress = true;
    cfgEnvoy.showPayee = true;
    cfgEnvoy.showIBAN = true;
    cfgEnvoy.showSWIFT = true;
    
    g_FieldConfigurations['196']['InPay'] = cfgInPay;
    LoadDefaultFieldsConfig(cfgInPay, 'InPay'); //setting defaults
    cfgInPay.showPayeeAddress = false;
    cfgInPay.showBranchAddress = false;
    cfgInPay.showAccountNumber = false;
    cfgInPay.showIBAN = true;

    g_Configurations['196'] = cfg;
    cfg.maxLengthOfIBAN = 24;
    cfg.validationExpressionOfIBAN = /^(SK)(\d){22,22}$/i;
    cfg.exampleOfIBAN = 'SK3112000000198742637541';
    cfg.prefillOfIBAN = 'SK';
    cfg.validationExpressionOfSWIFT = /^(([a-z]|[0-9]){8,11})$/i;
    cfg.exampleOfSWIFT = 'COBASKBXTBR';

    /* <%-- Slovenia --%> */
    var cfgEnvoy = new CountryBankConfiguration();
    var cfgInPay = new CountryBankConfiguration();
    var cfg = new CountryBankConfiguration();
    
    g_FieldConfigurations["197"]={};
    g_FieldConfigurations['197']['Envoy'] = cfgEnvoy;
    cfgEnvoy.showBankName = true;
    cfgEnvoy.showBranchAddress = true;
    cfgEnvoy.showPayee = true;
    cfgEnvoy.showIBAN = true;
    cfgEnvoy.showSWIFT = true;
    
    g_FieldConfigurations['197']['InPay'] = cfgInPay;
    LoadDefaultFieldsConfig(cfgInPay, 'InPay'); //setting defaults
    cfgInPay.showPayeeAddress = false;
    cfgInPay.showBranchAddress = false;
    cfgInPay.showAccountNumber = false;
    cfgInPay.showIBAN = true;

    g_Configurations['197'] = cfg;
    cfg.maxLengthOfIBAN = 19;
    cfg.validationExpressionOfIBAN = /^(SI)(\d){17,17}$/i;
    cfg.exampleOfIBAN = 'SI56191000000123438';
    cfg.prefillOfIBAN = 'SI';
    cfg.validationExpressionOfSWIFT = /^(([a-z]|[0-9]){8,11})$/i;
    cfg.exampleOfSWIFT = 'SABRSI2X';
    
    /* <%-- Tunisia  --%> */
    var cfgInPay = new CountryBankConfiguration();
    var cfg = new CountryBankConfiguration();

    g_FieldConfigurations["222"]={};
    g_FieldConfigurations['222']['InPay'] = cfgInPay;
    LoadDefaultFieldsConfig(cfgInPay, 'InPay'); //setting defaults
    cfgInPay.showBranchAddress = false;
    cfgInPay.showAccountNumber = false;
    cfgInPay.showIBAN = true;

    g_Configurations['222'] = cfg;
    cfg.maxLengthOfIBAN = 24;
    cfg.validationExpressionOfIBAN = /^(TN)\d{22,22}$/i;
    cfg.prefillOfIBAN = 'TN';
    cfg.exampleOfIBAN = 'TN5914207207100707129648';
    cfg.exampleOfSWIFT = 'BTBKTNTTVGM';
    
    /* <%-- Turkey --%> */
    var cfgInPay = new CountryBankConfiguration();
    var cfg = new CountryBankConfiguration();

    g_FieldConfigurations["77"]={};
    g_FieldConfigurations['77']['InPay'] = cfgInPay;
    LoadDefaultFieldsConfig(cfgInPay, 'InPay'); //setting defaults
    cfgInPay.showBranchAddress = false;
    cfgInPay.showAccountNumber = false;
    cfgInPay.showIBAN = true;

    g_Configurations['77'] = cfg;
    cfg.maxLengthOfIBAN = 26;
    cfg.validationExpressionOfIBAN = /^(TR)\d{24,24}$/i;
    cfg.prefillOfIBAN = 'TR';
    cfg.exampleOfIBAN = 'TR330006100519786457841326';
    cfg.exampleOfSWIFT = 'AKBKTRIS192';
    
    /* <%-- Bulgaria --%> */
    var cfgEnvoy = new CountryBankConfiguration();
    var cfgInPay = new CountryBankConfiguration();
    var cfg = new CountryBankConfiguration();

    g_FieldConfigurations["40"]={};
    g_FieldConfigurations['40']['Envoy'] = cfgEnvoy;
    cfgEnvoy.showBankName = true;
    cfgEnvoy.showBranchAddress = true;
    cfgEnvoy.showPayee = true;
    cfgEnvoy.showIBAN = true;
    cfgEnvoy.showSWIFT = true;

    g_FieldConfigurations['40']['InPay'] = cfgInPay;
    LoadDefaultFieldsConfig(cfgInPay, 'InPay'); //setting defaults
    cfgInPay.showPayeeAddress = false;
    cfgInPay.showBranchAddress = false;
    cfgInPay.showAccountNumber = false;
    cfgInPay.showIBAN = true;

    g_Configurations['40'] = cfg;
    cfg.maxLengthOfIBAN = 22;
    cfg.validationExpressionOfIBAN = /^(BG)([a-z]|[0-9]){20,20}$/i;
    cfg.exampleOfIBAN = 'BG80BNBG96611020345678';
    cfg.prefillOfIBAN = 'BG';
    cfg.validationExpressionOfSWIFT = /^(([a-z]|[0-9]){8,11})$/i;
    cfg.exampleOfSWIFT = 'INTFBGSF';

    /* <%-- Czech Republic --%> */
    var cfgEnvoy = new CountryBankConfiguration();
    var cfgInPay = new CountryBankConfiguration();
    var cfg = new CountryBankConfiguration();

    g_FieldConfigurations["63"]={};
    g_FieldConfigurations['63']['Envoy'] = cfgEnvoy;
    cfgEnvoy.showBankName = true;
    cfgEnvoy.showBranchAddress = true;
    cfgEnvoy.showPayee = true;
    cfgEnvoy.showIBAN = true;
    cfgEnvoy.showSWIFT = true;

    g_FieldConfigurations['63']['InPay'] = cfgInPay;
    LoadDefaultFieldsConfig(cfgInPay, 'InPay'); //setting defaults
    cfgInPay.showPayeeAddress = false;
    cfgInPay.showBranchAddress = false;
    cfgInPay.showAccountNumber = false;
    cfgInPay.showIBAN = true;

    g_Configurations['63'] = cfg;
    cfg.maxLengthOfIBAN = 24;
    cfg.validationExpressionOfIBAN = /^(CZ)\d{22,22}$/i;
    cfg.exampleOfIBAN = 'CZ6508000000192000145399';
    cfg.prefillOfIBAN = 'CZ';
    cfg.validationExpressionOfSWIFT = /^(([a-z]|[0-9]){8,11})$/i;
    cfg.exampleOfSWIFT = 'OBKLCZ2XTAB';

    /* <%-- Denmark --%> */
    var cfgEnvoy = new CountryBankConfiguration();
    var cfgInPay = new CountryBankConfiguration();
    var cfg = new CountryBankConfiguration();

    g_FieldConfigurations["64"]={};
    g_FieldConfigurations['64']['Envoy'] = cfgEnvoy;
    cfgEnvoy.showBankName = true;
    cfgEnvoy.showBranchAddress = true;
    cfgEnvoy.showPayee = true;
    cfgEnvoy.showIBAN = true;
    cfgEnvoy.showSWIFT = true;

    g_FieldConfigurations['64']['InPay'] = cfgInPay;
    LoadDefaultFieldsConfig(cfgInPay, 'InPay'); //setting defaults
    cfgInPay.showPayeeAddress = false;
    cfgInPay.showBranchAddress = false;
    cfgInPay.showAccountNumber = false;
    cfgInPay.showIBAN = true;

    g_Configurations['64'] = cfg;
    cfg.maxLengthOfIBAN = 18;
    cfg.validationExpressionOfIBAN = /^(DK)\d{16,16}$/i;
    cfg.exampleOfIBAN = 'DK5000400440116243';
    cfg.prefillOfIBAN = 'DK';
    cfg.validationExpressionOfSWIFT = /^(([a-z]|[0-9]){8,11})$/i;
    cfg.exampleOfSWIFT = 'DABADKKKHBK';

    /* <%-- Netherlands --%> */
    var cfgEnvoy = new CountryBankConfiguration();
    var cfgInPay = new CountryBankConfiguration();
    var cfg = new CountryBankConfiguration();

    g_FieldConfigurations["155"]={};
    g_FieldConfigurations['155']['Envoy'] = cfgEnvoy;
    cfgEnvoy.showBankName = true;
    cfgEnvoy.showBranchAddress = true;
    cfgEnvoy.showPayee = true;
    cfgEnvoy.showIBAN = true;
    cfgEnvoy.showSWIFT = true;

    g_FieldConfigurations['155']['InPay'] = cfgInPay;
    LoadDefaultFieldsConfig(cfgInPay, 'InPay'); //setting defaults
    cfgInPay.showPayeeAddress = false;
    cfgInPay.showBranchAddress = false;
    cfgInPay.showAccountNumber = false;
    cfgInPay.showIBAN = true;

    g_Configurations['155'] = cfg;
    cfg.maxLengthOfIBAN = 18;
    cfg.validationExpressionOfIBAN = /^(NL)([a-z]|[0-9]){16,16}$/i;
    cfg.exampleOfIBAN = 'NL39RABO0300065264';
    cfg.prefillOfIBAN = 'NL';
    cfg.validationExpressionOfSWIFT = /^(([a-z]|[0-9]){8,11})$/i;
    cfg.exampleOfSWIFT = 'ABNANL2AMEL';

    /* <%-- Sweden --%> */
    var cfgEnvoy = new CountryBankConfiguration();
    var cfgInPay = new CountryBankConfiguration();
    var cfgEnterCash = new CountryBankConfiguration();
    var cfg = new CountryBankConfiguration();

    g_FieldConfigurations["211"]={};
    g_FieldConfigurations['211']['Envoy'] = cfgEnvoy;
    cfgEnvoy.showBankName = true;
    cfgEnvoy.showBranchAddress = true;
    cfgEnvoy.showPayee = true;
    cfgEnvoy.showIBAN = true;
    cfgEnvoy.showSWIFT = true;
    
    g_FieldConfigurations['211']['InPay'] = cfgInPay;
    LoadDefaultFieldsConfig(cfgInPay, 'InPay'); //setting defaults
    cfgInPay.showPayeeAddress = false;
    cfgInPay.showBranchAddress = false;
    cfgInPay.showAccountNumber = false;
    cfgInPay.showIBAN = true;

    g_FieldConfigurations['211']['EnterCash'] = cfgEnterCash;
    LoadDefaultFieldsConfig(cfgEnterCash, 'EnterCash'); //setting defaults
    cfgEnterCash.showBankName = true;
    cfgEnterCash.showBankCode = true;
    cfgEnterCash.validationExpressionOfBankCode = /^\d{3,6}$/i;
    cfgEnterCash.maxLengthOfBankCode = 6;
    cfgEnterCash.showPayee = true;
    cfgEnterCash.maxLengthOfPayee = 32;
    cfgEnterCash.showAccountNumber = true;
    cfgEnterCash.maxLengthOfAccountNumber = 20;
    cfgEnterCash.validationExpressionOfAccountNumber = /^\d{3,20}$/i;

    g_Configurations['211'] = cfg;
    cfg.maxLengthOfIBAN = 24;
    cfg.validationExpressionOfIBAN = /^(SE)\d{22,22}$/i;
    cfg.exampleOfIBAN = 'SE3550000000054910000003';
    cfg.prefillOfIBAN = 'SE';
    cfg.validationExpressionOfSWIFT = /^(([a-z]|[0-9]){8,11})$/i;
    cfg.exampleOfSWIFT = 'OMBSSESSABR';

    /* <%-- France --%> */
    var cfgEnvoy = new CountryBankConfiguration();
    var cfgInPay = new CountryBankConfiguration();
    var cfg = new CountryBankConfiguration();

    g_FieldConfigurations["80"]={};
    g_FieldConfigurations['80']['Envoy'] = cfgEnvoy;
    cfgEnvoy.showBankName = true;
    cfgEnvoy.showBranchAddress = true;
    cfgEnvoy.showPayee = true;
    cfgEnvoy.showIBAN = true;
    cfgEnvoy.showSWIFT = true;
    
    g_FieldConfigurations['80']['InPay'] = cfgInPay;
    LoadDefaultFieldsConfig(cfgInPay, 'InPay'); //setting defaults
    cfgInPay.showPayeeAddress = false;
    cfgInPay.showBranchAddress = false;
    cfgInPay.showAccountNumber = false;
    cfgInPay.showIBAN = true;

    g_Configurations['80'] = cfg;
    cfg.maxLengthOfIBAN = 27;
    cfg.validationExpressionOfIBAN = /^(FR)([a-z]|[0-9]){25,25}$/i;
    cfg.exampleOfIBAN = 'FR1420041010050500013M02606';
    cfg.prefillOfIBAN = 'FR';
    cfg.validationExpressionOfSWIFT = /^(([a-z]|[0-9]){8,11})$/i;
    cfg.exampleOfSWIFT = 'BSCHFRPPBF1';

    /* <%-- Spain --%> */
    var cfgEnvoy = new CountryBankConfiguration();
    var cfgInPay = new CountryBankConfiguration();
    var cfg = new CountryBankConfiguration();

    g_FieldConfigurations["203"]={};
    g_FieldConfigurations['203']['Envoy'] = cfgEnvoy;
    cfgEnvoy.showBankName = true;
    cfgEnvoy.showBranchAddress = true;
    cfgEnvoy.showPayee = true;
    cfgEnvoy.showIBAN = true;
    cfgEnvoy.showSWIFT = true;
    
    g_FieldConfigurations['203']['InPay'] = cfgInPay;
    LoadDefaultFieldsConfig(cfgInPay, 'InPay'); //setting defaults
    cfgInPay.showPayeeAddress = false;

    g_Configurations['203'] = cfg;
    cfg.maxLengthOfIBAN = 24;
    cfg.validationExpressionOfIBAN = /^(ES)\d{22,22}$/i;
    cfg.exampleOfIBAN = 'ES8023100001180000012345';
    cfg.prefillOfIBAN = 'ES';
    cfg.validationExpressionOfSWIFT = /^(([a-z]|[0-9]){8,11})$/i;
    cfg.exampleOfSWIFT = 'AREBESMMCAN';

    //////////////////////////////////////////////////////////////////////////////////////////
    /* <%--- Cyprus ---
    * Bank Name bankName 50
    * Account Holding Branch branchAddress 50 General location is acceptable .i.e Madrid
    * Customer Name Payee 35
    * IBAN CY17002001280000001200527600
    * SWIFT 8/11
    -------------------%> */
    var cfgEnvoy = new CountryBankConfiguration();
    var cfgInPay = new CountryBankConfiguration();
    var cfg = new CountryBankConfiguration();

    g_FieldConfigurations["62"]={};
    g_FieldConfigurations['62']['Envoy'] = cfgEnvoy;
    cfgEnvoy.showBankName = true;
    cfgEnvoy.showBranchAddress = true;
    cfgEnvoy.showPayee = true;
    cfgEnvoy.showIBAN = true;
    cfgEnvoy.showSWIFT = true;
    
    g_FieldConfigurations['62']['InPay'] = cfgInPay;
    LoadDefaultFieldsConfig(cfgInPay, 'InPay'); //setting defaults
    cfgInPay.showPayeeAddress = false;
    cfgInPay.showBranchAddress = false;
    cfgInPay.showAccountNumber = false;
    cfgInPay.showIBAN = true;

    g_Configurations['62'] = cfg;
    cfg.maxLengthOfIBAN = 28;
    cfg.validationExpressionOfIBAN = /^(CY)\d{26,26}$/i;
    cfg.prefillOfIBAN = 'CY';
    cfg.exampleOfIBAN = 'CY17002001280000001200527600';
    cfg.validationExpressionOfSWIFT = /^(([a-z]|[0-9]){8,11})$/i;
    cfg.exampleOfSWIFT = 'LIKICY2N001';


    /* <%--- Greece ---    
    * Bank Name bankName 50
    * Account Holding Branch branchAddress 50 General location is acceptable .i.e Madrid
    * Customer Name Payee 35
    * IBAN GR1601101250000000012300695
    * SWIFT 8/11
    -------------------%> */
    var cfgEnvoy = new CountryBankConfiguration();
    var cfgInPay = new CountryBankConfiguration();
    var cfg = new CountryBankConfiguration();

    g_FieldConfigurations["91"]={};
    g_FieldConfigurations['91']['Envoy'] = cfgEnvoy;
    cfgEnvoy.showBankName = true;
    cfgEnvoy.showBranchAddress = true;
    cfgEnvoy.showPayee = true;
    cfgEnvoy.showIBAN = true;
    cfgEnvoy.showSWIFT = true;
    
    g_FieldConfigurations['91']['InPay'] = cfgInPay;
    LoadDefaultFieldsConfig(cfgInPay, 'InPay'); //setting defaults
    cfgInPay.showPayeeAddress = false;
    cfgInPay.showBranchAddress = false;
    cfgInPay.showAccountNumber = false;
    cfgInPay.showIBAN = true;

    g_Configurations['91'] = cfg;
    cfg.maxLengthOfIBAN = 27;
    cfg.validationExpressionOfIBAN = /^(GR)\d{25,25}$/i;
    cfg.exampleOfIBAN = 'GR1601101250000000012300695';
    cfg.prefillOfIBAN = 'GR';
    cfg.validationExpressionOfSWIFT = /^(([a-z]|[0-9]){8,11})$/i;
    cfg.exampleOfSWIFT = 'MIDLGRAATRS';


    /* <%--- Iceland ---
    * Bank Name bankName 50
    * Account Holding Branch branchAddress 50 General location is acceptable .i.e Madrid
    * Customer Name Payee 35
    * IBAN IS140159260076545510730339
    * SWIFT 8/11
    -------------------%> */
    var cfgEnvoy = new CountryBankConfiguration();
    var cfgInPay = new CountryBankConfiguration();
    var cfg = new CountryBankConfiguration();

    g_FieldConfigurations["105"]={};
    g_FieldConfigurations['105']['Envoy'] = cfgEnvoy;
    cfgEnvoy.showBankName = true;
    cfgEnvoy.showBranchAddress = true;
    cfgEnvoy.showPayee = true;
    cfgEnvoy.showIBAN = true;
    cfgEnvoy.showSWIFT = true;
    
    g_FieldConfigurations['105']['InPay'] = cfgInPay;
    LoadDefaultFieldsConfig(cfgInPay, 'InPay'); //setting defaults
    cfgInPay.showPayeeAddress = false;
    cfgInPay.showBranchAddress = false;
    cfgInPay.showAccountNumber = false;
    cfgInPay.showIBAN = true;

    g_Configurations['105'] = cfg;
    cfg.maxLengthOfIBAN = 26;
    cfg.validationExpressionOfIBAN = /^(IS)\d{24,24}$/i;
    cfg.exampleOfIBAN = 'IS140159260076545510730339';
    cfg.prefillOfIBAN = 'IS';
    cfg.validationExpressionOfSWIFT = /^(([a-z]|[0-9]){8,11})$/i;
    cfg.exampleOfSWIFT = 'BORGISRE';


    /* <%--- Luxembourg ---   
    * Bank Name bankName 50
    * Account Holding Branch branchAddress 50 General location is acceptable .i.e Madrid
    * Customer Name Payee 35
    * IBAN LU280019400644750000
    * SWIFT 8/11
    -------------------%> */
    var cfgEnvoy = new CountryBankConfiguration();
    var cfgInPay = new CountryBankConfiguration();
    var cfg = new CountryBankConfiguration();

    g_FieldConfigurations["129"]={};
    g_FieldConfigurations['129']['Envoy'] = cfgEnvoy;
    cfgEnvoy.showBankName = true;
    cfgEnvoy.showBranchAddress = true;
    cfgEnvoy.showPayee = true;
    cfgEnvoy.showIBAN = true;
    cfgEnvoy.showSWIFT = true;
    
    g_FieldConfigurations['129']['InPay'] = cfgInPay;
    LoadDefaultFieldsConfig(cfgInPay, 'InPay'); //setting defaults
    cfgInPay.showPayeeAddress = false;
    cfgInPay.showBranchAddress = false;
    cfgInPay.showAccountNumber = false;
    cfgInPay.showIBAN = true;

    g_Configurations['129'] = cfg;
    cfg.maxLengthOfIBAN = 20;
    cfg.validationExpressionOfIBAN = /^(LU)\d{18,18}$/i;
    cfg.exampleOfIBAN = 'LU280019400644750000';
    cfg.prefillOfIBAN = 'LU';
    cfg.validationExpressionOfSWIFT = /^(([a-z]|[0-9]){8,11})$/i;
    cfg.exampleOfSWIFT = 'SAFRLULL';


    /* <%--- Malta ---    
    * Bank Name bankName 50
    * Account Holding Branch branchAddress 50 General location is acceptable .i.e Madrid
    * Customer Name Payee 35
    * IBAN MT84 MALT 01100 0012345MTLCASTO01S
    * SWIFT 8/11
    -------------------%> */
    var cfgEnvoy = new CountryBankConfiguration();
    var cfgInPay = new CountryBankConfiguration();
    var cfg = new CountryBankConfiguration();

    g_FieldConfigurations["137"]={};
    g_FieldConfigurations['137']['Envoy'] = cfgEnvoy;
    cfgEnvoy.showBankName = true;
    cfgEnvoy.showBranchAddress = true;
    cfgEnvoy.showPayee = true;
    cfgEnvoy.showIBAN = true;
    cfgEnvoy.showSWIFT = true;
    
    g_FieldConfigurations['137']['InPay'] = cfgInPay;
    LoadDefaultFieldsConfig(cfgInPay, 'InPay'); //setting defaults
    cfgInPay.showPayeeAddress = false;
    cfgInPay.showBranchAddress = false;
    cfgInPay.showAccountNumber = false;
    cfgInPay.showIBAN = true;

    g_Configurations['137'] = cfg;
    cfg.maxLengthOfIBAN = 31;
    cfg.validationExpressionOfIBAN = /^(MT)([a-z]|[0-9]){29,29}$/i;
    cfg.exampleOfIBAN = 'MT84MALT011000012345MTLCASTO01S';
    cfg.prefillOfIBAN = 'MT';
    cfg.validationExpressionOfSWIFT = /^(([a-z]|[0-9]){8,11})$/i;
    cfg.exampleOfSWIFT = 'MALTMTMT';


    /* <%--- Australia ---    
    * Bank Name bankName 50
    * Account Holding Branch branchAddress 50
    * Customer Name Payee 35
    * BSB Code bankCode 6 Numeric-6 digits in length 
    * Account Number accountNumber 5/9 Between 5 & 9 digits in length
    -------------------%> */
    var cfgEnvoy = new CountryBankConfiguration();
    var cfg = new CountryBankConfiguration();
    g_FieldConfigurations["20"]={};
    g_FieldConfigurations['20']['Envoy'] = cfgEnvoy;
    g_Configurations['20'] = cfg;
    cfgEnvoy.showBankName = true;
    cfgEnvoy.showBankCode = true;
    cfgEnvoy.showBranchAddress = true;
    cfgEnvoy.showPayee = true;
    cfgEnvoy.showAccountNumber = true;

    cfg.maxLengthOfBankCode = 6;
    cfg.validationExpressionOfBankCode = /^(\d){6,6}$/i;
    cfg.maxLengthOfAccountNumber = 9;
    cfg.validationExpressionOfAccountNumber = /^(\d){5,9}$/i;


    /* <%--- Austria ---
    * Bank Name bankName 50
    * Account Holding Branch branchAddress 50
    * Customer Name Payee 35
    * Bank Code bankCode 5 Numeric-5 digits in length 
    * Account Number accountNumber 4/11 Numeric-between 4 and 11 digits in length
    -------------------%> */
    var cfgEnvoy = new CountryBankConfiguration();
    var cfgInPay = new CountryBankConfiguration();
    var cfg = new CountryBankConfiguration();

    g_FieldConfigurations["21"]={};
    g_FieldConfigurations['21']['Envoy'] = cfgEnvoy;
    cfgEnvoy.showBankName = true;
    cfgEnvoy.showBankCode = true;
    cfgEnvoy.showBranchAddress = true;
    cfgEnvoy.showPayee = true;
    cfgEnvoy.showIBAN = true;
    cfgEnvoy.showSWIFT = true;
    cfgEnvoy.showAccountNumber = true;
    
    g_FieldConfigurations['21']['InPay'] = cfgInPay;
    LoadDefaultFieldsConfig(cfgInPay, 'InPay'); //setting defaults
    cfgInPay.showPayeeAddress = false;
    cfgInPay.showBranchAddress = false;
    cfgInPay.showAccountNumber = false;
    cfgInPay.showIBAN = true;

    g_Configurations['21'] = cfg;
    cfg.maxLengthOfBankCode = 5;
    cfg.validationExpressionOfBankCode = /^(\d){5,5}$/i;
    cfg.maxLengthOfIBAN = 20;
    cfg.validationExpressionOfIBAN = /^(AT)\d{18,18}$/i;
    cfg.prefillOfIBAN = 'AT';
    cfg.exampleOfIBAN = 'AT611904300234573201';
    cfg.validationExpressionOfSWIFT = /^(([a-z]|[0-9]){8,11})$/i;
    cfg.exampleOfSWIFT = 'ASPKAT2LOBE';
    cfg.maxLengthOfAccountNumber = 11;
    cfg.validationExpressionOfAccountNumber = /^(\d){4,11}$/i;


    /* <%--- Belgium ---    
    * Bank Name bankName 50 
    * Account Holding Branch branchAddress
    * Customer Name Payee 35
    * Account Number accountNumber 12 12 digits all numeric-account number includes bank code and check digits
    -------------------%> */
    var cfgEnvoy = new CountryBankConfiguration();
    var cfgInPay = new CountryBankConfiguration();
    var cfg = new CountryBankConfiguration();

    g_FieldConfigurations["28"]={};
    g_FieldConfigurations['28']['Envoy'] = cfgEnvoy;
    cfgEnvoy.showBankName = true;
    cfgEnvoy.showBranchAddress = true;
    cfgEnvoy.showPayee = true;
    cfgEnvoy.showIBAN = true;
    cfgEnvoy.showSWIFT = true;
    cfgEnvoy.showAccountNumber = true;
    
    g_FieldConfigurations['28']['InPay'] = cfgInPay;
    LoadDefaultFieldsConfig(cfgInPay, 'InPay'); //setting defaults
    cfgInPay.showPayeeAddress = false;

    g_Configurations['28'] = cfg;
    cfg.maxLengthOfIBAN = 16;
    cfg.validationExpressionOfIBAN = /^(BE)\d{14,14}$/i;
    cfg.prefillOfIBAN = 'BE';
    cfg.exampleOfIBAN = 'BE68539007547034';
    cfg.validationExpressionOfSWIFT = /^(([a-z]|[0-9]){8,11})$/i;
    cfg.exampleOfSWIFT = 'DELEBE22NRA';
    cfg.maxLengthOfAccountNumber = 12;
    cfg.validationExpressionOfAccountNumber = /^(\d){12,12}$/i;


    /* <%--- Estonia ---
    * Bank Name bankName 50
    * Account Holding Branch branchAddress 50
    * Customer Name Payee 35
    * IBAN Iban 20 e.g. EE382200221020145685
    -------------------%> */
    var cfgEnvoy = new CountryBankConfiguration();
    var cfgInPay = new CountryBankConfiguration();
    var cfg = new CountryBankConfiguration();

    g_FieldConfigurations["74"]={};
    g_FieldConfigurations['74']['Envoy'] = cfgEnvoy;
    cfgEnvoy.showBankName = true;
    cfgEnvoy.showBranchAddress = true;
    cfgEnvoy.showPayee = true;
    cfgEnvoy.showIBAN = true;
    cfgEnvoy.showSWIFT = true;
    
    g_FieldConfigurations['74']['InPay'] = cfgInPay;
    LoadDefaultFieldsConfig(cfgInPay, 'InPay'); //setting defaults
    cfgInPay.showPayeeAddress = false;
    cfgInPay.showBranchAddress = false;
    cfgInPay.showAccountNumber = false;
    cfgInPay.showIBAN = true;

    g_Configurations['74'] = cfg;
    cfg.maxLengthOfIBAN = 20;
    cfg.validationExpressionOfIBAN = /^(EE)\d{18,18}$/i;
    cfg.prefillOfIBAN = 'EE';
    cfg.exampleOfIBAN = 'EE382200221020145685';
    cfg.validationExpressionOfSWIFT = /^(([a-z]|[0-9]){8,11})$/i;
    cfg.exampleOfSWIFT = 'EPBEEE2XCCB';


    /* <%--- Finland ---
    *** only 14 digits,  no FI code  in the beginning,
    
    * Bank Name bankName 50
    * Account Holding Branch branchAddress 50
    * Customer Name Payee 35
    * IBAN FI12112345600000785 18 Numeric displayed as: Branch code – 6 digits Account number, 8 digits
    -------------------%> */
    var cfgEnvoy = new CountryBankConfiguration();
    var cfgInPay = new CountryBankConfiguration();
    var cfgEnterCash = new CountryBankConfiguration();
    var cfg = new CountryBankConfiguration();

    g_FieldConfigurations["79"]={};
    g_FieldConfigurations['79']['Envoy'] = cfgEnvoy;
    cfgEnvoy.showBankName = true;
    cfgEnvoy.showBranchAddress = true;
    cfgEnvoy.showPayee = true;
    cfgEnvoy.showIBAN = true;
    cfgEnvoy.showSWIFT = true;
    
    g_FieldConfigurations['79']['InPay'] = cfgInPay;
    LoadDefaultFieldsConfig(cfgInPay, 'InPay'); //setting defaults
    cfgInPay.showPayeeAddress = false;
    cfgInPay.showBranchAddress = false;
    cfgInPay.showAccountNumber = false;
    cfgInPay.showIBAN = true;

    g_FieldConfigurations['79']['EnterCash'] = cfgEnterCash;
    LoadDefaultFieldsConfig(cfgEnterCash, 'EnterCash'); //setting defaults
    cfgEnterCash.showBankName = true;
    cfgEnterCash.showSWIFT = true;
    cfgEnterCash.maxLengthOfSWIFT = 11;
    cfgEnterCash.exampleOfSWIFT = 'ASPKFI2LOBE';
    cfgEnterCash.validationExpressionOfSWIFT = /^([a-zA-Z0-9]{4,4}(FI)[a-zA-Z0-9]{2,2}([a-zA-Z0-9]{3,3})?)$/i;
    cfgEnterCash.showPayee = true;
    cfgEnterCash.maxLengthOfPayee = 32;
    cfgEnterCash.showIBAN = true;
    cfgEnterCash.maxLengthOfIBAN = 18;
    cfgEnterCash.exampleOfIBAN = 'FI2112345600000785';
    cfgEnterCash.validationExpressionOfIBAN = /^(FI)\d{16,16}$/i;

    g_Configurations['79'] = cfg;
    cfg.maxLengthOfIBAN = 18;
    cfg.validationExpressionOfIBAN = /^(FI)\d{16,16}$/i;
    cfg.prefillOfIBAN = 'FI';
    cfg.exampleOfIBAN = 'FI2112345600000785';


    /* <%--- Germany ---    
    * Bank Name bankName 50
    * Account Holding Branch branchAddress 50
    * Customer Name Payee 35
    * IBAN Iban DE89370400440532013000
    * SWIFT Swift 8/11 Normal BIC/SWIFT format – numeric & alpha
    -------------------%> */
    var cfgEnvoy = new CountryBankConfiguration();
    var cfgInPay = new CountryBankConfiguration();
    var cfg = new CountryBankConfiguration();

    g_FieldConfigurations["88"]={};
    g_FieldConfigurations['88']['Envoy'] = cfgEnvoy;
    cfgEnvoy.showBankName = true;
    cfgEnvoy.showBranchAddress = true;
    cfgEnvoy.showPayee = true;
    cfgEnvoy.showIBAN = true;
    cfgEnvoy.showSWIFT = true;
    
    g_FieldConfigurations['88']['InPay'] = cfgInPay;
    LoadDefaultFieldsConfig(cfgInPay, 'InPay'); //setting defaults
    cfgInPay.showPayeeAddress = false;
    cfgInPay.showBranchAddress = false;
    cfgInPay.showAccountNumber = false;
    cfgInPay.showIBAN = true;

    g_Configurations['88'] = cfg;
    cfg.maxLengthOfIBAN = 22;
    cfg.validationExpressionOfIBAN = /^(DE)\d{20,20}$/i;
    cfg.prefillOfIBAN = 'DE';
    cfg.exampleOfIBAN = 'DE89370400440532013000';
    cfg.validationExpressionOfSWIFT = /^(([a-z]|[0-9]){8,11})$/i;
    cfg.exampleOfSWIFT = 'AARBDE5W860';


    /* <%--- Ireland ---
    * Bank Name BankName 50
    * Account Holding Branch branchAddress 50
    * Customer Name Payee 18
    * Sort Code bankCode 6 Numeric – must be 6 in total 
    * Account Number accountNumber 8 Numeric – must be 8 in total
    -------------------%> */
    var cfgEnvoy = new CountryBankConfiguration();
    var cfgInPay = new CountryBankConfiguration();
    var cfg = new CountryBankConfiguration();

    g_FieldConfigurations["110"]={};
    g_FieldConfigurations['110']['Envoy'] = cfgEnvoy;
    cfgEnvoy.showBankName = true;
    cfgEnvoy.showBankCode = true;
    cfgEnvoy.showBranchAddress = true;
    cfgEnvoy.showPayee = true;
    cfgEnvoy.showIBAN = true;
    cfgEnvoy.showSWIFT = true;
    cfgEnvoy.showAccountNumber = true;
    cfgEnvoy.onChangeOfAccountNumber = function (t) {
        var value = t.val();
        while (value.length < 8) value = '0' + value;
        t.val(value);
    };
    
    g_FieldConfigurations['110']['InPay'] = cfgInPay;
    LoadDefaultFieldsConfig(cfgInPay, 'InPay'); //setting defaults
    cfgInPay.showPayeeAddress = false;
    cfgInPay.showBranchAddress = false;
    cfgInPay.showAccountNumber = false;
    cfgInPay.showIBAN = true;

    g_Configurations['110'] = cfg;
    cfg.maxLengthOfBankCode = 6;
    cfg.validationExpressionOfBankCode = /^(\d){6,6}$/i;
    cfg.maxLengthOfIBAN = 22;
    cfg.validationExpressionOfIBAN = /^(IE)([a-z]|[0-9]){20,20}$/i;
    cfg.prefillOfIBAN = 'IE';
    cfg.exampleOfIBAN = 'IE29AIBK93115212345678';
    cfg.validationExpressionOfSWIFT = /^(([a-z]|[0-9]){8,11})$/i;
    cfg.exampleOfSWIFT = 'DXMAIE2D';
    cfg.maxLengthOfPayee = 18;
    cfg.maxLengthOfAccountNumber = 8;
    cfg.validationExpressionOfAccountNumber = /^(\d){8,8}$/i;
    

    /* <%--- Italy ---
    * Bank Name bankName 50
    * Account Holding Branch branchAddress 50
    * Customer Name Payee 35
    * IBAN Iban 27  IT60X0542811101000000123456
    * SWIFT Swift 8/11
    -------------------%> */
    var cfgEnvoy = new CountryBankConfiguration();
    var cfgInPay = new CountryBankConfiguration();
    var cfg = new CountryBankConfiguration();

    g_FieldConfigurations["112"]={};
    g_FieldConfigurations['112']['Envoy'] = cfgEnvoy;
    cfgEnvoy.showBankName = true;
    cfgEnvoy.showBranchAddress = true;
    cfgEnvoy.showPayee = true;
    cfgEnvoy.showIBAN = true;
    cfgEnvoy.showSWIFT = true;
    
    g_FieldConfigurations['112']['InPay'] = cfgInPay;
    LoadDefaultFieldsConfig(cfgInPay, 'InPay'); //setting defaults
    cfgInPay.showPayeeAddress = false;
    cfgInPay.showBranchAddress = false;
    cfgInPay.showAccountNumber = false;
    cfgInPay.showIBAN = true;

    g_Configurations['112'] = cfg;
    cfg.maxLengthOfIBAN = 27;
    cfg.prefillOfIBAN = 'IT';
    cfg.exampleOfIBAN = 'IT60X0542811101000000123456';
    cfg.validationExpressionOfIBAN = /^(IT)([0-9]|[a-z]){25,25}$/i;
    cfg.validationExpressionOfSWIFT = /^([0-9]|[a-z]){8,11}$/i;
    cfg.exampleOfSWIFT = 'ARNEITMMXXX';


    /* <%--- Lithuania ---
    * Bank Name bankName 30
    * Account Holding Branch branchAddress 50
    * Customer Name Payee 35
    * Swift Code Swift Code 8/11 Normal BIC/SWIFT format – numeric & alpha 
    * IBAN Iban 20 Eg: LT097044060005552604
    -------------------%> */
    var cfgEnvoy = new CountryBankConfiguration();
    var cfgInPay = new CountryBankConfiguration();
    var cfg = new CountryBankConfiguration();

    g_FieldConfigurations["128"]={};
    g_FieldConfigurations['128']['Envoy'] = cfgEnvoy;
    cfgEnvoy.showBankName = true;
    cfgEnvoy.showBranchAddress = true;
    cfgEnvoy.showPayee = true;
    cfgEnvoy.showIBAN = true;
    cfgEnvoy.showSWIFT = true;
    
    g_FieldConfigurations['128']['InPay'] = cfgInPay;
    LoadDefaultFieldsConfig(cfgInPay, 'InPay'); //setting defaults
    cfgInPay.showPayeeAddress = false;
    cfgInPay.showBranchAddress = false;
    cfgInPay.showAccountNumber = false;
    cfgInPay.showIBAN = true;

    g_Configurations['128'] = cfg;
    cfg.maxLengthOfBankName = 30;
    cfg.maxLengthOfIBAN = 20;
    cfg.prefillOfIBAN = 'LT';
    cfg.exampleOfIBAN = 'LT097044060005552604';
    cfg.validationExpressionOfIBAN = /^(LT)\d{18,18}$/i;
    cfg.validationExpressionOfSWIFT = /^(([a-z]|[0-9]){8,11})$/i;
    cfg.exampleOfSWIFT = 'LIABLT2X';


    /* <%--- New Zealand ---
    * Bank Name bankName 50
    * Account Holding Branch branchAddress 50
    * Customer Name Payee 35
    * Account Number accountNumber 14 including the four digit branch number, seven digit account and three digit suffix 
    * SWIFT Swift 8/11 Normal BIC/SWIFT format – numeric & alpha
    -------------------%> */
    var cfgEnvoy = new CountryBankConfiguration();
    var cfg = new CountryBankConfiguration();

    g_FieldConfigurations["158"]={};
    g_FieldConfigurations['158']['Envoy'] = cfgEnvoy;
    g_Configurations['158'] = cfg;
    cfgEnvoy.showBankName = true;
    cfgEnvoy.showBranchAddress = true;
    cfgEnvoy.showPayee = true;
    cfgEnvoy.showAccountNumber = true;
    cfgEnvoy.showSWIFT = true;

    cfg.maxLengthOfAccountNumber = 15;
    cfg.validationExpressionOfAccountNumber = /^(\d){14,15}$/i;
    cfg.validationExpressionOfSWIFT = /^(([a-z]|[0-9]){8,11})$/i;
    cfg.exampleOfSWIFT = 'BKNZNZ22100';


    /* <%--- Norway ---
    * Bank Name bankName 50
    * Account Holding Branch branchAddress 50
    * Customer Name Payee 35
    * IBAN NO9386011117947 Specific to country IBAN country specific refer to examples provided in table below. 
    * SWIFT Swift 8/11
    -------------------%> */
    var cfgEnvoy = new CountryBankConfiguration();
    var cfgInPay = new CountryBankConfiguration();
    var cfg = new CountryBankConfiguration();

    g_FieldConfigurations["166"]={};
    g_FieldConfigurations['166']['Envoy'] = cfgEnvoy;
    cfgEnvoy.showBankName = true;
    cfgEnvoy.showBranchAddress = true;
    cfgEnvoy.showPayee = true;
    cfgEnvoy.showIBAN = true;
    cfgEnvoy.showSWIFT = true;
    
    g_FieldConfigurations['166']['InPay'] = cfgInPay;
    LoadDefaultFieldsConfig(cfgInPay, 'InPay'); //setting defaults
    cfgInPay.showPayeeAddress = false;
    cfgInPay.showBranchAddress = false;
    cfgInPay.showAccountNumber = false;
    cfgInPay.showIBAN = true;

    g_Configurations['166'] = cfg;
    cfg.maxLengthOfIBAN = 15;
    cfg.prefillOfIBAN = 'NO';
    cfg.validationExpressionOfIBAN = /(NO)\d{13,13}/i;
    cfg.exampleOfIBAN = 'NO9386011117947';
    cfg.validationExpressionOfSWIFT = /^(([a-z]|[0-9]){8,11})$/i;
    cfg.exampleOfSWIFT = 'NOBANO22BNN';


    /* <%--- Poland ---   
    * Bank Name bankName 34
    * Account Holding Branch branchAddress 34
    * Customer Name Payee 32
    * Account Number accountNumber 26 Numeric only Includes: 2 digit check digit 8 digit branch code 16 digit account number
    -------------------%> */
    var cfgEnvoy = new CountryBankConfiguration();
    var cfgInPay = new CountryBankConfiguration();
    var cfg = new CountryBankConfiguration();

    g_FieldConfigurations["177"]={};
    g_FieldConfigurations['177']['Envoy'] = cfgEnvoy;
    cfgEnvoy.showBankName = true;
    cfgEnvoy.showBranchAddress = true;
    cfgEnvoy.showPayee = true;
    cfgEnvoy.showAccountNumber = false;
    cfgEnvoy.showBankCode = false;
    cfgEnvoy.showIBAN = true;
    cfgEnvoy.showSWIFT = true;
    cfgEnvoy.maxLengthOfIBAN = 28;
    
    g_FieldConfigurations['177']['InPay'] = cfgInPay;
    LoadDefaultFieldsConfig(cfgInPay, 'InPay'); //setting defaults
    cfgInPay.showPayeeAddress = false;
    cfgInPay.showBranchAddress = false;
    cfgInPay.showAccountNumber = false;
    cfgInPay.showIBAN = true;

    g_Configurations['177'] = cfg;
    cfg.maxLengthOfBankName = 34;
    cfg.maxLengthOfBranchAddress = 34;
    cfg.maxLengthOfPayee = 32;
    cfg.maxLengthOfAccountNumber = 26;
    cfg.validationExpressionOfAccountNumber = /^(\d){26,26}$/i;
    cfg.maxLengthOfIBAN = 28;
    cfg.prefillOfIBAN = 'PL';
    cfg.exampleOfIBAN = "PL27114020040000300201355387";
    cfg.validationExpressionOfIBAN = /(PL)\d{26,26}/i;


    /* <%--- United Kingdom, UK ---
    * Bank Name bankName 50
    * Account Holding Branch branchAddress 50
    * Customer Name Payee 35
    * Sort Code bankCode 6 Numeric, must be 8 digits 
    * Account Number accountNumber 10 Numeric, must be 8 digits
    -------------------%> */
    var cfgEnvoy = new CountryBankConfiguration();
    var cfgInPay = new CountryBankConfiguration();
    var cfg = new CountryBankConfiguration();

    g_FieldConfigurations["230"]={};
    g_FieldConfigurations['230']['Envoy'] = cfgEnvoy;
    cfgEnvoy.showBankName = true;
    cfgEnvoy.showBankCode = true;
    cfgEnvoy.showBranchAddress = true;
    cfgEnvoy.showPayee = true;
    cfgEnvoy.showAccountNumber = false;
    cfgEnvoy.onChangeOfAccountNumber = function (t) {
        var value = t.val();
        if( value.length == 6 )
            value = '00' + value;
        t.val(value);
    };
    cfgEnvoy.showIBAN = true;
    cfgEnvoy.showSWIFT = true;
    cfgEnvoy.maxLengthOfIBAN = 22;
    cfgEnvoy.exampleOfIBAN = "GB29NWBK60161331926819";
    cfgEnvoy.validationExpressionOfIBAN = /^(GB)\d{2,2}(([a-z]|[A-Z]){4,4})\d{14,14}$/i;
    
    g_FieldConfigurations['230']['InPay'] = cfgInPay;
    LoadDefaultFieldsConfig(cfgInPay, 'InPay'); //setting defaults
    cfgInPay.showPayeeAddress = false;
    cfgInPay.showBranchAddress = false;
    cfgInPay.showAccountNumber = false;
    cfgInPay.showIBAN = true;

    g_Configurations['230'] = cfg;
    cfg.maxLengthOfBankCode = 6;
    cfg.validationExpressionOfBankCode = /^(\d){6,6}$/i;
    cfg.maxLengthOfAccountNumber = 10;
    cfg.validationExpressionOfAccountNumber = /^(\d){8,10}$/i;
    cfg.maxLengthOfIBAN = 22;
    cfg.exampleOfIBAN = "GB33000610051978645784";
    cfg.prefillOfIBAN = 'GB';
    cfg.validationExpressionOfIBAN = /^(GB)\d{20,20}$/i;
    cfg.validationExpressionOfSWIFT = /^(([a-z]|[0-9]){8,11})$/i;
    

    /* <%--- Turkey ---   
    -------------------%> */
    var cfgBank = new CountryBankConfiguration();
    var cfg = new CountryBankConfiguration();

    g_FieldConfigurations["223"]={};
    g_FieldConfigurations['223']['Bank'] = cfgBank;
    g_Configurations['223'] = cfg;
    cfgBank.vendorID = "Bank";
    cfgBank.showBankName = true;
    cfgBank.showBankCode = true;
    cfgBank.showBranchAddress = true;
    cfgBank.showBranchCode = true;
    cfgBank.showPayee = true;
    cfgBank.showIBAN = true;
    cfgBank.showSWIFT = true;

    cfg.maxLengthOfBankName = 34;
    cfg.maxLengthOfBranchAddress = 34;
    cfg.maxLengthOfPayee = 32;
    cfg.maxLengthOfIBAN = 26;
    cfg.exampleOfIBAN = "TR330006100519786457841326";
    cfg.validationExpressionOfIBAN = /^(TR)(([a-z]|[0-9]){24,24})$/i;
    cfg.validationExpressionOfSWIFT = /^(([a-z]|[0-9]){8,11})$/i;
    cfg.exampleOfSWIFT = 'CITITRIXANK';
    cfg.currencyOptions = [ "EUR", "USD" ];


    /* <%--- Angola, AO---%> */
    var cfgEnvoy = new CountryBankConfiguration();

    g_FieldConfigurations["13"]={};
    g_FieldConfigurations['13']['Envoy'] = cfgEnvoy;
    cfgEnvoy.showBankName = true;
    cfgEnvoy.showBankCode = false;
    cfgEnvoy.showBranchAddress = false;
    cfgEnvoy.showPayee = true;
    cfgEnvoy.showAccountNumber = false;
    cfgEnvoy.showIBAN = true;
    cfgEnvoy.showSWIFT = true;
    cfgEnvoy.maxLengthOfIBAN = 25;
    cfgEnvoy.exampleOfIBAN = "AO06000600000100037131174";
    cfgEnvoy.validationExpressionOfIBAN = /^(AO)\d{23,23}$/i;


    /* <%--- Jordan, JO---%> */
    var cfgEnvoy = new CountryBankConfiguration();

    g_FieldConfigurations["115"]={};
    g_FieldConfigurations['115']['Envoy'] = cfgEnvoy;
    cfgEnvoy.showBankName = true;
    cfgEnvoy.showBankCode = false;
    cfgEnvoy.showBranchAddress = false;
    cfgEnvoy.showPayee = true;
    cfgEnvoy.showAccountNumber = false;
    cfgEnvoy.showIBAN = true;
    cfgEnvoy.showSWIFT = true;
    cfgEnvoy.maxLengthOfIBAN = 30;
    cfgEnvoy.exampleOfIBAN = "JO9425800010000000000131000302";
    cfgEnvoy.validationExpressionOfIBAN = /^(JO)\d{28,28}$/i;


    /* <%--- Qatar, QA---%> */
    var cfgEnvoy = new CountryBankConfiguration();

    g_FieldConfigurations["180"]={};
    g_FieldConfigurations['180']['Envoy'] = cfgEnvoy;
    cfgEnvoy.showBankName = true;
    cfgEnvoy.showBankCode = false;
    cfgEnvoy.showBranchAddress = false;
    cfgEnvoy.showPayee = true;
    cfgEnvoy.showAccountNumber = false;
    cfgEnvoy.showIBAN = true;
    cfgEnvoy.showSWIFT = true;
    cfgEnvoy.maxLengthOfIBAN = 29;
    cfgEnvoy.exampleOfIBAN = "QA582563000012345678901234567";
    cfgEnvoy.validationExpressionOfIBAN = /^(QA)\d{27,27}$/i;

    $(function () {
        new BankPayCard();
    });
</script>