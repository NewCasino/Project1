<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="System.Globalization" %>
<script language="C#" type="text/C#" runat="server">
    private TransType TransType
    {
        get
        {
            return (TransType)this.ViewData["TransType"];
        }
    }

    private string ID { get; set; }

    protected override void OnInit(EventArgs e)
    {
        this.ID = "_" + Guid.NewGuid().ToString("N").Truncate(5);
        base.OnInit(e);
    }
</script>



<div class="BonusContainer" id="<%= this.ID %>" >
    <ul class="BonusHeader">
        <li class="BonusOption"><a class="Active" href="javascript:void(0)"><%= this.GetMetadata(".No_Bonus").SafeHtmlEncode() %></a></li>
        <li class="BonusOption" data-assigned="BonusCode"><a href="javascript:void(0)"><%= this.GetMetadata(".Input_Bonus").SafeHtmlEncode()%></a></li>
        <li class="BonusOption" data-assigned="BonusSelector"><a href="javascript:void(0)"><%= this.GetMetadata(".Select_Bonus").SafeHtmlEncode()%></a></li>
    </ul> 
    <div class="BonusCode" style="display:none">        
        <%: Html.TextBox("bonusCode", string.Empty, new { maxlength = 20, @autocomplete="off", @class="textbox BonusCodeTextBox" })%>
        <% if (Settings.IsOMSeamlessWalletEnabled || Settings.IsBetConstructWalletEnabled) { %>
        <div class="BonusCodeVendorContainer">
            <ul class="BonusCode_Vendor">
                <li>
                <%: Html.RadioButton("bonusCodeVendor", VendorID.CasinoWallet.ToString(), false, new{
                    @id="rdBonusVendor_" + VendorID.CasinoWallet.ToString()
                }) %>
                <label for="rdBonusVendor_<%= VendorID.CasinoWallet.ToString()%>"><%= this.GetMetadata(".BonusCode_Vendor_CasinoWallet_Text").SafeHtmlEncode()%></label>
                </li>
                <% if (Settings.IsOMSeamlessWalletEnabled) { %>
                <li>
                <%: Html.RadioButton("bonusCodeVendor", VendorID.OddsMatrix.ToString(), false, new{
                    @id="rdBonusVendor_" + VendorID.OddsMatrix.ToString()
                }) %>
                <label for="rdBonusVendor_<%= VendorID.OddsMatrix.ToString()%>"><%= this.GetMetadata(".BonusCode_Vendor_OddsMatrix_Text").SafeHtmlEncode()%></label>
                </li>
                <% } %>
                <% if (Settings.IsBetConstructWalletEnabled) { %>
                <li>
                <%: Html.RadioButton("bonusCodeVendor", VendorID.BetConstruct.ToString(), false, new{
                    @id="rdBonusVendor_" + VendorID.BetConstruct.ToString()
                }) %>
                <label for="rdBonusVendor_<%= VendorID.BetConstruct.ToString()%>"><%= this.GetMetadata(".BonusCode_Vendor_BetConstruct_Text").SafeHtmlEncode()%></label>
                </li>
                <% } %>
            </ul>
            <label id="message_error_bonusCodeVendor" class="error" style="display:none;"><%= this.GetMetadata(".BonusCode_Error_Select_Vendor").SafeHtmlEncode()%></label>
        </div>
        <% } %>
        <div class="BonusCodeAdditionContainer">
            <%= this.GetMetadata(".Bonus_Code_Addition_Html").HtmlEncodeSpecialCharactors()%>
        </div>
    </div>
    <div class="BonusSelector" style="display:none">
        <ul class="BigBonusList">
        </ul>
        <input type="hidden" name="bonusVendor" id="bonusVendor" />
    </div>
    <span class="PokerBonusWarning" style="display:none">
    <%= this.GetMetadata(".Poker_Message_HTML").HtmlEncodeSpecialCharactors() %>
    </span>
</div>

<script type="text/html" id="bonus-casino-item-template">
<# 
    var bonuses = arguments[0];
    for( var i = 0; i < bonuses.length; i++) 
    { 
        var cssStyle = '';
        if( bonuses[i].backgroundImage != null && bonuses[i].backgroundImage.length > 0 ){
            cssStyle = "background-image:url('" + bonuses[i].backgroundImage.htmlEncode() + "');"
        }
        var bannerHTML = bonuses[i].bannerHTML;
        if( bannerHTML == null || bannerHTML.length == 0 ){
            bannerHTML = '<strong class="promotion-title">' + bonuses[i].name.htmlEncode() + '</strong><span class="promotion-text"><br /></span>';
        }
        var amounts = bonuses[i].predefinedList;
#>

    <li class="BigBonusItem" style="<#= cssStyle #>" data-code="<#= bonuses[i].code #>" data-vendor = "CasinoWallet" data-order="<#= bonuses[i].order #>" >
<label class="BigBonusLabel" for="bigBonus1">
<span class="BigBonusSignal">&nbsp;</span>
<span class="BigBonusText">
<#= bannerHTML #>
</span>
</label>

        <# 
        if( amounts.length > 0 ) 
        { 
            var range = 100.00 / (1.0 * (amounts.length - 1));
        #>
<div class="BigBonusSlider">
<ol class="BigBonusLevels Container">
             <#
                for( var j = 0; j < amounts.length; j++)
                {
                    var pos = (j * range).toString();
                    var right = (j * range) + (range / 2.0);
                #>
<li class="BigLevelItem" style="left:<#= pos #>%;" 
                    data-left="<#= pos #>" 
                    data-right="<#= right #>" 
                    data-depositamount="<#= amounts[j].depositAmount #>" 
                    data-depositcurrency="<#= amounts[j].depositCurrency #>" 
                    data-depositmoney="<#= amounts[j].depositMoney #>"
                    data-expectedbonus="<#= amounts[j].expectedBonus #>">
<a class="BigLevelText" href="javascript:void(0)"><#= amounts[j].depositMoney #></a>
</li>
             <# } #>

                
</ol>
<div class="BigBonusCanvas">
<div class="BigBonusController">
<a class="BigBonusKnob Button" href="javascript:void(0)">&nbsp;</a>
<span class="BigBonusDetail" style="display:none">&nbsp;</span>
</div>
</div>
</div>
        <# } #>

</li>

<# } #>
</script>

<script type="text/html" id="bonus-sports-item-template">
<# 
    var bonuses = arguments[0];
    var tcUrl = '/Sports/BonusTermsandConditions';
    for( var i = 0; i < bonuses.length; i++) 
    { 
        var cssStyle = '';
        if( bonuses[i].backgroundImage != null && bonuses[i].backgroundImage.length > 0 ){
            cssStyle = "background-image:url('" + bonuses[i].backgroundImage.htmlEncode() + "');"
        }
        var bannerHTML = bonuses[i].bannerHTML;
        if( bannerHTML == null || bannerHTML.length == 0 ){
            if(bonuses[i].tcUrl != null && bonuses[i].tcUrl != '')
                tcUrl = bonuses[i].tcUrl;            
            bannerHTML = '<strong class="promotion-title">' + bonuses[i].name.htmlEncode() + '</strong><span class="promotion-text"><br /><a href="' + tcUrl + '" target="_blank" title="<%=this.GetMetadata(".Link_TermsAndConditions_Text").SafeJavascriptStringEncode() %>"><%=this.GetMetadata(".Link_TermsAndConditions_Text").SafeJavascriptStringEncode() %></a></span>';
        }
#>

    <li class="BigBonusItem" style="<#= cssStyle #>" data-code="<#= bonuses[i].code #>" data-vendor = "OddsMatrix" data-order="<#= bonuses[i].order #>">
<label class="BigBonusLabel" for="bigBonus1">
<span class="BigBonusSignal">&nbsp;</span>
<span class="BigBonusText">
<#= bannerHTML #>
</span>
</label>
</li>

<# } #>
</script>


<script type="text/html" id="bonus-betconstruct-item-template">
<# 
    var bonuses = arguments[0];
    for( var i = 0; i < bonuses.length; i++) 
    { 
        var cssStyle = '';
        if( bonuses[i].backgroundImage != null && bonuses[i].backgroundImage.length > 0 ){
            cssStyle = "background-image:url('" + bonuses[i].backgroundImage.htmlEncode() + "');"
        }
        var bannerHTML = bonuses[i].bannerHTML;
        if( bannerHTML == null || bannerHTML.length == 0 ){
            bannerHTML = '<strong class="promotion-title">' + bonuses[i].name.htmlEncode() + '</strong><span class="promotion-text"></span>';
        }
#>

    <li class="BigBonusItem" style="<#= cssStyle #>" data-code="<#= bonuses[i].code #>" data-vendor = "BetConstruct" data-order="<#= bonuses[i].order #>">
<label class="BigBonusLabel" for="bigBonus1">
<span class="BigBonusSignal">&nbsp;</span>
<span class="BigBonusText">
<#= bannerHTML #>
</span>
</label>
</li>

<# } #>
</script>

<%--<ui:MinifiedJavascriptControl runat="server">--%>
<script type="text/javascript">
    var BonusValidator = function () {
        this.$c = $('#<%= this.ID %>');

        this.messager = $('#message_error_bonusCodeVendor', this.$c);

        this.validate = function () {
            <% if (Settings.IsOMSeamlessWalletEnabled || Settings.IsBetConstructWalletEnabled) { %>
            if ($('li[data-assigned="BonusCode"] a', this.$c).hasClass('Active')) {
                if ($('#bonusCode', this.$c).val().trim().length > 0) {
                    var _cur_bonusCodeVendor = $('input[name="bonusCodeVendor"]:checked', this.$c).val();
                    if (_cur_bonusCodeVendor == null)
                    {
                        this.messager.show();
                        return false;
                    }
                }
            }
            this.messager.hide();
            <% } %>
            return true;
        };
    };

    function validateBonusCodeVendor() {
        var bonusValidator = new BonusValidator();
        return bonusValidator.validate();
    }

    $(function () {
        var $c = $('#<%= this.ID %>');

        var _data = null;


        function setBonusCode(code) {
            $('input[name="bonusCode"]', $c).val(code);
        }

        function setBonusVendor(vendor) {
            $('input[name="bonusVendor"]', $c).val(vendor);
        }

        $('li.BonusOption', $c).click(function (e) {
            $('ul.BonusHeader a.Active', $c).removeClass('Active');
            $('a', $(this)).addClass('Active');

            $('div.BonusCode,div.BonusSelector', $c).hide();
            var cssCls = $(this).data('assigned');
            if (cssCls != null && cssCls.length > 0) {
                $('div.' + cssCls).fadeIn();
            }

            setBonusCode('');
            setBonusVendor('');
            if (cssCls == 'BonusSelector') {
                $('div.BonusSelector li.BigBonusItem:first', $c).click();
            }
        });

        <% if (Settings.IsOMSeamlessWalletEnabled || Settings.IsBetConstructWalletEnabled) { %>
        $('input[name="bonusCodeVendor"]', $c).removeAttr('checked').click(function (e) {
            setBonusVendor($(this).val());
        });
        $('input[name="bonusCode"]', $c).blur(function () {
            var bonusValidator = new BonusValidator();
            bonusValidator.validate();
        });        
        <% } %>

        function initControl(json) {
            // <%-- Verify the response --%>
            var isSelectorVisible = false;
            if (json != null && json.success) {
                if (json.accountID != _data.AccountID)
                    return;

                for (var b in json.bonuses) {
                    if (json.bonuses[b].length > 0) {
                        isSelectorVisible = true;
                        break;
                    }
                }
            }

            setBonusCode('');
            setBonusVendor('');
            $c.hide();

            if (!isSelectorVisible && !_data.IsBonusCodeInputEnabled)
                return;

            // <%-- Poker warning message --%>
            switch (_data.VendorID) {
                case 'CakeNetwork':
                case 'ENET':
                case 'MergeNetwork':
                    $('div.PokerBonusWarning', $c).show();
                    break;
                default:
                    $('div.PokerBonusWarning', $c).hide();
                    break;
            }

            // <%-- visibility --%>
            $('div.BonusCode,div.BonusSelector', $c).hide();
            var options = 1;
            if (_data.IsBonusCodeInputEnabled) {
                options++;
                $('li[data-assigned="BonusCode"]', $c).show();
            } else {
                $('li[data-assigned="BonusCode"]', $c).hide();
            }

            if (isSelectorVisible) {
                options++;
                $('li[data-assigned="BonusSelector"]', $c).show();
                initBonusSelector(json.bonuses);
            } else {
                $('li[data-assigned="BonusSelector"]', $c).hide();
            }

            $('ul.BonusHeader', $c).removeClass('BonusHeaderCols-2').removeClass('BonusHeaderCols-3').removeClass('BonusHeaderCols-1');
            $('ul.BonusHeader', $c).addClass('BonusHeaderCols-' + options);
            $c.fadeIn();
            //var abof = '<%=this.GetMetadata(".DefaultOption_Filter").SafeJavascriptStringEncode()%>';
            //var defaultBonusOptionFilter = abof.length > 0 ? abof : ':last';
            //$('li.BonusOption:visible' + defaultBonusOptionFilter, $c).click();
        }

        function sortNumber(a, b) {
            return a - b
        }

        function sortBonus() {
            var arrOrder = new Array();
            var arrEle = new Array();
            var fail = false;
            var $ul = $('ul.BigBonusList', $c);
            var $lis = $ul.find('> li');
            $lis.each(function (i, n) {
                var $n = $(n);
                var order, strOrder = $n.data('order');
                if (typeof (strOrder) === "undefined" || $.trim(strOrder)==="") {
                    fail = true;
                    return false;
                }
                order = parseInt(strOrder);
                arrOrder[i] = order;
                arrEle['o' + order] = $n;
            });
            if (fail) {
                return;
            }
            $lis.detach();
            if (arrOrder.length > 0) {
                arrOrder.sort(sortNumber);
                var html;
                for (var j = 0; j < arrOrder.length; j++) {
                    $ul.append(arrEle["o" + arrOrder[j]]);
                }
            }
        }

        function initBonusSelector(bonuses) {
            var $ul = $('ul.BigBonusList', $c);
            $ul.html('').hide();
            if (bonuses.CasinoWallet && bonuses.CasinoWallet != null)
                $ul.html($('#bonus-casino-item-template').parseTemplate(bonuses.CasinoWallet));

            if (bonuses.OddsMatrix && bonuses.OddsMatrix != null)
                $ul.append($('#bonus-sports-item-template').parseTemplate(bonuses.OddsMatrix));

            if (bonuses.BetConstruct && bonuses.BetConstruct != null)
                $ul.append($('#bonus-betconstruct-item-template').parseTemplate(bonuses.BetConstruct));

            sortBonus();
            $ul.show();

            $('> li.BigBonusItem', $ul).click(function (e) {
                var $this = $(this);
                $('> li.PickedBonus', $ul).removeClass('PickedBonus');
                setBonusCode($this.data('code'));
                setBonusVendor($this.data('vendor'));
                $this.addClass('PickedBonus');
                $('li.BigLevelItem:last a.BigLevelText', $this).trigger('click');
            });
            $('a.BigBonusKnob', $ul).each(function (i, el) {
                new BonusAmountKnob($(el));
            });

            $ul.attr('unselectable', 'on')
                 .css('user-select', 'none')
                 .on('selectstart', false);
        }

        function initSportsBonusSelector(bonuses) {
            alert(bonuses[0].amount);
        }

        $(document).bind('GAMING_ACCOUNT_SEL_CHANGED', function (e, data) {
            _data = data;
            $c.hide();

            if (data.IsBonusSelectorEnabled) {
                var url = '/_get_bonus_info.ashx?TransType=<%= this.TransType %>&AccountID=' + data.AccountID + '&VendorID=' + data.VendorID;
                $.getJSON(url, function (json) {
                    initControl(json);
                });
            }
            else if (data.IsBonusCodeInputEnabled) {
                initControl(null);
            }
        });


        function BonusAmountKnob($knob) {
            var _points = [];
            var _controller = $knob.parents('div.BigBonusController');
            var _canvas = $knob.parents('div.BigBonusCanvas');
            var _tip = $knob.siblings('span.BigBonusDetail');
            var _isMouseDown = false;
            var _pageX = 0;
            var _percent = 0;

            $('li.BigLevelItem[data-right]', $knob.parents('div.BigBonusSlider')).each(function (i, el) {
                _points.push({ right: parseFloat($(el).data('right'), 10), elem: $(el) });
                $('a.BigLevelText', el).click(function (e) {
                    applyNode($(this).parent());
                    e.stopPropagation();
                });

            });
            _points.sort(function (a, b) { return a.left - b.left });

            $knob.mousedown(function (e) {
                _isMouseDown = true;
                _tip.hide();
            });

            $(document.body).mousemove(function (e) {
                _pageX = e.pageX;
                onKnobMoved();
            });

            $(document.body).mouseup(function (e) {
                onKnobReleased();
            });
            $knob.parents('div.BigBonusItem').mouseleave(function (e) {
                onKnobReleased();
            });

            $(document.body).on('dragstart', function (e) {
                e.preventDefault();
            });

            function onKnobMoved() {
                if (!_isMouseDown)
                    return;
                var oX = _pageX - _canvas.offset().left;
                var width = _canvas.width();

                if (oX <= 0)
                    oX = 0;
                else if (oX > width)
                    oX = width;

                _percent = oX / (width * 1.0) * 100;
                _controller.css('left', _percent.toString(10) + '%');
            }

            function onKnobReleased() {
                if (!_isMouseDown)
                    return;
                _isMouseDown = false;
                var $n = null;
                for (var i = 0; i < _points.length; i++) {
                    if (_percent <= _points[i].right) {
                        $n = _points[i].elem;
                        break;
                    }
                }

                if ($n != null)
                    applyNode($n);
            }

            function applyNode($node) {
                if ($(".PickedBonus .BigBonusSlider:visible").length > 0) {
                    _controller.css('left', $node.data('left').toString(10) + '%');


                    var text = '<%= this.GetMetadata(".Bonus_Tip").SafeJavascriptStringEncode() %>';
                    text = text.replace(/(\{0\})/g, $node.data('depositmoney'));
                    text = text.replace(/(\{1\})/g, $node.data('expectedbonus'));
                    _tip.text(text).show();

                    $('#fldCurrencyAmount #ddlCurrency').val($node.data('depositcurrency'));
                    $('#fldCurrencyAmount #txtAmount').val($node.data('depositamount'));

                    if (typeof onAmountBlur !== 'undefined')
                        onAmountBlur();
                }
            }
        } // <%-- BonusAmountKnob --%>

    });
</script>

<%--</ui:MinifiedJavascriptControl>--%>