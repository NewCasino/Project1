<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>

<%=this.GetMetadata(".EGT_Css").HtmlEncodeSpecialCharactors() %>
<div class="EgtJackpotBar">
<div id="EgtJackpotBannersBox">
<div class="EgtJackpotTitle">
<%=this.GetMetadata(".EgtJackpotTitle").HtmlEncodeSpecialCharactors() %></div>
<div class="EgtBannerItem EgtBannerItem1">
<div class="EgtPopupBox">
<div class="EgtPopup">
<div class="EgtLargestWinner">
<div class="EgtLargestWinnerTitle">
<%=this.GetMetadata(".LargestWinnerTitle").SafeHtmlEncode() %></div>
<div class="EgtLargestWinnerDate"></div>
<div class="EgtLargestWinnerValues">
<span class="CurrencySymbol">
<%=this.GetMetadata(".CurrencySymbol").SafeHtmlEncode() %></span>
<span class="EgtLargestWinnerValue"></span>
</div>
</div>
<div class="EgtWinnersNumber">
<div class="EgtWinnerNumberTitle">
<%=this.GetMetadata(".WinnerNumberTitle").SafeHtmlEncode() %></div>
<div class="EgtWinnerNumberValue"></div>
</div>
<div class="EgtLastWinner">
<div class="EgtLastWinnerTitle">
<%=this.GetMetadata(".LastWinnerTitle").SafeHtmlEncode() %></div>
<div class="EgtLastWinnerDate"></div>
<div class="EgtLastWinnerName"></div>
<div class="EgtLastWinnerValues">
<span class="CurrencySymbol">
<%=this.GetMetadata(".CurrencySymbol").SafeHtmlEncode() %></span>
<span class="EgtLastWinnerValue"></span>
</div>
</div>
</div>
</div>
<div class="EgtBanner">
<div class="EgtCurrencyValue"></div>
<div class="EgtCurrencyName">
<%=this.GetMetadata(".CurrencyName").SafeHtmlEncode() %></div>
</div>
</div>
<div class="EgtBannerItem EgtBannerItem2">
<div class="EgtPopupBox">
<div class="EgtPopup">
<div class="EgtLargestWinner">
<div class="EgtLargestWinnerTitle">
<%=this.GetMetadata(".LargestWinnerTitle").SafeHtmlEncode() %></div>
<div class="EgtLargestWinnerDate"></div>
<div class="EgtLargestWinnerValues">
<span class="CurrencySymbol">
<%=this.GetMetadata(".CurrencySymbol").SafeHtmlEncode() %></span>
<span class="EgtLargestWinnerValue"></span>
</div>
</div>
<div class="EgtWinnersNumber">
<div class="EgtWinnerNumberTitle">
<%=this.GetMetadata(".WinnerNumberTitle").SafeHtmlEncode() %></div>
<div class="EgtWinnerNumberValue"></div>
</div>
<div class="EgtLastWinner">
<div class="EgtLastWinnerTitle">
<%=this.GetMetadata(".LastWinnerTitle").SafeHtmlEncode() %></div>
<div class="EgtLastWinnerDate"></div>
<div class="EgtLastWinnerName"></div>
<div class="EgtLastWinnerValues">
<span class="CurrencySymbol">
<%=this.GetMetadata(".CurrencySymbol").SafeHtmlEncode() %></span>
<span class="EgtLastWinnerValue"></span>
</div>
</div>
</div>
</div>
<div class="EgtBanner">
<div class="EgtCurrencyValue"></div>
<div class="EgtCurrencyName">EUR</div>
</div>
</div>
<div class="EgtBannerItem EgtBannerItem3">
<div class="EgtPopupBox">
<div class="EgtPopup">
<div class="EgtLargestWinner">
<div class="EgtLargestWinnerTitle">
<%=this.GetMetadata(".LargestWinnerTitle").SafeHtmlEncode() %></div>
<div class="EgtLargestWinnerDate"></div>
<div class="EgtLargestWinnerValues">
<span class="CurrencySymbol">
<%=this.GetMetadata(".CurrencySymbol").SafeHtmlEncode() %></span>
<span class="EgtLargestWinnerValue"></span>
</div>
</div>
<div class="EgtWinnersNumber">
<div class="EgtWinnerNumberTitle">
<%=this.GetMetadata(".WinnerNumberTitle").SafeHtmlEncode() %></div>
<div class="EgtWinnerNumberValue"></div>
</div>
<div class="EgtLastWinner">
<div class="EgtLastWinnerTitle">
<%=this.GetMetadata(".LastWinnerTitle").SafeHtmlEncode() %></div>
<div class="EgtLastWinnerDate"></div>
<div class="EgtLastWinnerName"></div>
<div class="EgtLastWinnerValues">
<span class="CurrencySymbol">
<%=this.GetMetadata(".CurrencySymbol").SafeHtmlEncode() %></span>
<span class="EgtLastWinnerValue"></span>
</div>
</div>
</div>
</div>
<div class="EgtBanner">
<div class="EgtCurrencyValue"></div>
<div class="EgtCurrencyName">EUR</div>
</div>
</div>
<div class="EgtBannerItem EgtBannerItem4">
<div class="EgtPopupBox">
<div class="EgtPopup">
<div class="EgtLargestWinner">
<div class="EgtLargestWinnerTitle">
<%=this.GetMetadata(".LargestWinnerTitle").SafeHtmlEncode() %></div>
<div class="EgtLargestWinnerDate"></div>
<div class="EgtLargestWinnerValues">
<span class="CurrencySymbol">
<%=this.GetMetadata(".CurrencySymbol").SafeHtmlEncode() %></span>
<span class="EgtLargestWinnerValue"></span>
</div>
</div>
<div class="EgtWinnersNumber">
<div class="EgtWinnerNumberTitle">
<%=this.GetMetadata(".WinnerNumberTitle").SafeHtmlEncode() %></div>
<div class="EgtWinnerNumberValue"></div>
</div>
<div class="EgtLastWinner">
<div class="EgtLastWinnerTitle">
<%=this.GetMetadata(".LastWinnerTitle").SafeHtmlEncode() %></div>
<div class="EgtLastWinnerDate"></div>
<div class="EgtLastWinnerName"></div>
<div class="EgtLastWinnerValues">
<span class="CurrencySymbol">
<%=this.GetMetadata(".CurrencySymbol").SafeHtmlEncode() %></span>
<span class="EgtLastWinnerValue"></span>
</div>
</div>
</div>
</div>
<div class="EgtBanner">
<div class="EgtCurrencyValue"></div>
<div class="EgtCurrencyName">EUR</div>
</div>
</div>
<script type="text/javascript">
    $(function () {
        $('#egt_css').appendTo('head');
        
        function addSeparator(data) {
            var arraystring = data.split("");
            var result = "";
            for (var i=0; i<arraystring.length; i++) {
                result += "<span class='separator'>" + arraystring[i] + "</span>";
            }
            return result;
        }

        function RollAnimation(amount, obj, count) {

        var oldvalue = 0;
        if (obj.text() != '') {
        oldvalue = parseFloat(obj.text());
        }

        if (count <= 0) {
        if (oldvalue != amount) obj.html(addSeparator(amount.toFixed(2)));
        return;
        }

        if (oldvalue < amount) {
            var increaseVaule = (amount - oldvalue) / count;
            setTimeout(function() {
            oldvalue = (oldvalue + increaseVaule);
            oldvalue = oldvalue < amount ? oldvalue : amount;
            obj.html(addSeparator(oldvalue.toFixed(2)));
            RollAnimation(amount, obj, count - 1);
            }, 50);
        } else {
            obj.html(addSeparator(amount.toFixed(2)));
       }
        }

        $('.EgtJackpotBar').click(function() {
        var gameid = "<%=this.GetMetadata(".GameID").SafeJavascriptStringEncode() %>";
              if (gameid != null && gameid != "") {
            _openCasinoGame( gameid, true);
              }
        })

        setInterval(function() {
        $('.EgtBannerItem').removeClass('HaveValue');
        $.getJSON("/Casino/EGTJackpotData.ashx",
            function (data) {
                var currency = data.currency;

                var currentLevelI = data.currentLevelI != null ? Number(data.currentLevelI / 100) : (isNaN($('.EgtBannerItem1 .EgtCurrencyValue').text()) ? Number($('.EgtBannerItem1 .EgtCurrencyValue').text()) : 0.00);
                var winsLevelI = data.winsLevelI;
                var largestWinLevelI = data.largestWinLevelI != null ? Number(data.largestWinLevelI / 100) : (isNaN($('.EgtBannerItem1 .EgtLargestWinnerValue').text()) ? Number($('.EgtBannerItem1 .EgtLargestWinnerValue').text()) : 0.00);
                var largestWinDateLevelI = data.largestWinDateLevelI;
                var largestWinUserLevelI = data.largestWinUserLevelI;
                var lastWinLevelI = data.lastWinLevelI != null ? Number(data.lastWinLevelI / 100) : (isNaN($('.EgtBannerItem1 .EgtLastWinnerValue').text()) ? Number($('.EgtBannerItem1 .EgtLastWinnerValue').text()) : 0.00);
                var lastWinDateLevelI = data.lastWinDateLevelI;
                var lastWinUserLevelI = data.lastWinUserLevelI;

                $('.EgtBannerItem1 .EgtCurrencyName').text(currency);
                RollAnimation(currentLevelI, $('.EgtBannerItem1 .EgtCurrencyValue'), 20);
                $('.EgtBannerItem1 .EgtLargestWinnerValue').text(largestWinLevelI);
                try {
                    var largestWinDateI = new Date(largestWinDateLevelI);
                    $('.EgtBannerItem1 .EgtLargestWinnerDate').text(largestWinDateI.getDate() + "/" + (largestWinDateI.getMonth() + 1) + "/" + largestWinDateI.getFullYear());
                } catch (e) {
                }
                //$('').text(largestWinUserLevelI);
                $('.EgtBannerItem1 .EgtWinnerNumberValue').text(winsLevelI);
                $('.EgtBannerItem1 .EgtLastWinnerValue').text(lastWinLevelI);
                try {
                    var lastWinDateI = new Date(lastWinDateLevelI);
                    $('.EgtBannerItem1 .EgtLastWinnerDate').text(lastWinDateI.getDate() + "/" + (lastWinDateI.getMonth() + 1) + "/" + lastWinDateI.getFullYear());
                } catch (e) {
                }
                $('.EgtBannerItem1 .EgtLastWinnerName').text(lastWinUserLevelI);
                if (largestWinLevelI > 0 || lastWinLevelI > 0 || winsLevelI > 0) {
                    $('.EgtBannerItem1').addClass('HaveValue');
                }

                var currentLevelII = data.currentLevelII != null ? Number(data.currentLevelII / 100) : (isNaN($('.EgtBannerItem2 .EgtCurrencyValue').text()) ? Number($('.EgtBannerItem2 .EgtCurrencyValue').text()) : 0.00);
                var winsLevelII = data.winsLevelII;
                var largestWinLevelII = data.largestWinLevelII != null ? Number(data.largestWinLevelII / 100) : (isNaN($('.EgtBannerItem2 .EgtLargestWinnerValue').text()) ? Number($('.EgtBannerItem2 .EgtLargestWinnerValue').text()) : 0.00);
                var largestWinDateLevelII = data.largestWinDateLevelII;
                var largestWinUserLevelII = data.largestWinUserLevelII;
                var lastWinLevelII = data.lastWinLevelII != null ? Number(data.lastWinLevelII / 100) : (isNaN($('.EgtBannerItem2 .EgtLastWinnerValue').text()) ? Number($('.EgtBannerItem2 .EgtLastWinnerValue').text()) : 0.00);
                var lastWinDateLevelII = data.lastWinDateLevelII;
                var lastWinUserLevelII = data.lastWinUserLevelII;

                $('.EgtBannerItem2 .EgtCurrencyName').text(currency);
                RollAnimation(currentLevelII, $('.EgtBannerItem2 .EgtCurrencyValue'), 20);
                $('.EgtBannerItem2 .EgtLargestWinnerValue').text(largestWinLevelII);
                try {
                    var largestWinDateII = new Date(largestWinDateLevelII);
                    $('.EgtBannerItem2 .EgtLargestWinnerDate').text(largestWinDateII.getDate() + "/" + (largestWinDateII.getMonth() + 1) + "/" + largestWinDateII.getFullYear());
                } catch (e) {
                }
                //$('').text(largestWinUserLevelII);
                $('.EgtBannerItem2 .EgtWinnerNumberValue').text(winsLevelII);
                $('.EgtBannerItem2 .EgtLastWinnerValue').text(lastWinLevelII);
                try {
                    var largestWinDateII = new Date(lastWinDateLevelII);
                    $('.EgtBannerItem2 .EgtLastWinnerDate').text(largestWinDateII.getDate() + "/" + (largestWinDateII.getMonth() + 1) + "/" + largestWinDateII.getFullYear());
                } catch (e) {
                }
                $('.EgtBannerItem2 .EgtLastWinnerName').text(lastWinUserLevelII);
                if (largestWinLevelII > 0 || lastWinLevelII > 0 || winsLevelII > 0) {
                    $('.EgtBannerItem2').addClass('HaveValue');
                }

                var currentLevelIII = data.currentLevelIII != null ? Number(data.currentLevelIII / 100) : (isNaN($('.EgtBannerItem3 .EgtCurrencyValue').text()) ? Number($('.EgtBannerItem3 .EgtCurrencyValue').text()) : 0.00);
                var winsLevelIII = data.winsLevelIII;
                var largestWinLevelIII = data.largestWinLevelIII != null ? Number(data.largestWinLevelIII / 100) : (isNaN($('.EgtBannerItem3 .EgtLargestWinnerValue').text()) ? Number($('.EgtBannerItem3 .EgtLargestWinnerValue').text()) : 0.00);
                var largestWinDateLevelIII = data.largestWinDateLevelIII;
                var largestWinUserLevelIII = data.largestWinUserLevelIII;
                var lastWinLevelIII = data.lastWinLevelIII != null ? Number(data.lastWinLevelIII / 100) : (isNaN($('.EgtBannerItem3 .EgtLastWinnerValue').text()) ? Number($('.EgtBannerItem3 .EgtLastWinnerValue').text()) : 0.00);
                var lastWinDateLevelIII = data.lastWinDateLevelIII;
                var lastWinUserLevelIII = data.lastWinUserLevelIII;

                $('.EgtBannerItem3 .EgtCurrencyName').text(currency);
                RollAnimation(currentLevelIII, $('.EgtBannerItem3 .EgtCurrencyValue'), 20);
                $('.EgtBannerItem3 .EgtLargestWinnerValue').text(largestWinLevelIII);
                try {
                    var largestWinDateIII = new Date(largestWinDateLevelIII);
                    $('.EgtBannerItem3 .EgtLargestWinnerDate').text(largestWinDateIII.getDate() + "/" + (largestWinDateIII.getMonth() + 1) + "/" + largestWinDateIII.getFullYear());
                } catch (e) {
                }
                //$('').text(largestWinUserLevelIII);
                $('.EgtBannerItem3 .EgtWinnerNumberValue').text(winsLevelIII);
                $('.EgtBannerItem3 .EgtLastWinnerValue').text(lastWinLevelIII);
                try {
                    var largestWinDateIII = new Date(lastWinDateLevelIII);
                    $('.EgtBannerItem3 .EgtLastWinnerDate').text(largestWinDateIII.getDate() + "/" + (largestWinDateIII.getMonth() + 1) + "/" + largestWinDateIII.getFullYear());
                } catch (e) {
                }
                $('.EgtBannerItem3 .EgtLastWinnerName').text(lastWinUserLevelIII);
                if (largestWinLevelIII > 0 || lastWinLevelIII > 0 || winsLevelIII > 0) {
                    $('.EgtBannerItem3').addClass('HaveValue');
                }

                var currentLevelIV = data.currentLevelIV != null ? Number(data.currentLevelIV / 100) : (isNaN($('.EgtBannerItem4 .EgtCurrencyValue').text()) ? Number($('.EgtBannerItem4 .EgtCurrencyValue').text()) : 0.00);
                var winsLevelIV = data.winsLevelIV;
                var largestWinLevelIV = data.largestWinLevelIV != null ? Number(data.largestWinLevelIV / 100) : (isNaN($('.EgtBannerItem4 .EgtLargestWinnerValue').text()) ? Number($('.EgtBannerItem4 .EgtLargestWinnerValue').text()) : 0.00);
                var largestWinDateLevelIV = data.largestWinDateLevelIV;
                var largestWinUserLevelIV = data.largestWinUserLevelIV;
                var lastWinLevelIV = data.lastWinLevelIV != null ? Number(data.lastWinLevelIV / 100) : (isNaN($('.EgtBannerItem4 .EgtLastWinnerValue').text()) ? Number($('.EgtBannerItem4 .EgtLastWinnerValue').text()) : 0.00);
                var lastWinDateLevelIV = data.lastWinDateLevelIV;
                var lastWinUserLevelIV = data.lastWinUserLevelIV;

                $('.EgtBannerItem4 .EgtCurrencyName').text(currency);
                RollAnimation(currentLevelIV, $('.EgtBannerItem4 .EgtCurrencyValue'), 20);
                $('.EgtBannerItem4 .EgtLargestWinnerValue').text(largestWinLevelIV);
                try {
                    var largestWinDateIV = new Date(largestWinDateLevelIV);
                    $('.EgtBannerItem4 .EgtLargestWinnerDate').text(largestWinDateIV.getDate() + "/" + (largestWinDateIV.getMonth() + 1) + "/" + largestWinDateIV.getFullYear());
                } catch (e) {
                }
                //$('').text(largestWinUserLevelIV);
                $('.EgtBannerItem4 .EgtWinnerNumberValue').text(winsLevelIV);
                $('.EgtBannerItem4 .EgtLastWinnerValue').text(lastWinLevelIV);
                try {
                    var largestWinDateIV = new Date(lastWinDateLevelIV);
                    $('.EgtBannerItem4 .EgtLastWinnerDate').text(largestWinDateIV.getDate() + "/" + (largestWinDateIV.getMonth() + 1) + "/" + largestWinDateIV.getFullYear());
                } catch (e) {
                }
                $('.EgtBannerItem4 .EgtLastWinnerName').text(lastWinUserLevelIV);
                if (largestWinLevelIV > 0 || lastWinLevelIV > 0 || winsLevelIV > 0) {
                    $('.EgtBannerItem4').addClass('HaveValue');
                }
            })
        }, 60000);
    })
</script>
</div>
</div>