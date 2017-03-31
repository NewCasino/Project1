<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>

<div class="Slider LiveCasinoSlider" >
    <ul data-slide="Default" class="SliderContainer LiveCasinoSliderContainer" >
        <li id="LCSlide-Default" data-bg="" data-state="active" class="SliderItem LiveCasinoSlide LCSlide-Default Active">
            <div class="SliderContent">
                <h3 class="LCSlideTitle SlideTitle">
                    <span class="SlideWelcome">Welcome to Artemisbet</span>
                    <span class="hidable SlideDefaultTitle hidden"></span>
                    <span class="CategorySlideTitle">Live Casino</span>
                </h3>
                <span class="CasinoCoin LeftCoin">&nbsp;</span>
                <span class="CasinoCoin RightCoin">&nbsp;</span>
            </div>
        </li>
        <li id="LCSlide-ROULETTE" data-bg="" data-state="hidden" class="SliderItem LiveCasinoSlide LCSlide-Roulette">
            <div class="SliderContent">
                <h3 class="LCSlideTitle SlideTitle">
                    <span class="SlideWelcome">Welcome to</span>
                    <span class="CategorySlideTitle">Roulette</span>
                </h3>
            </div>
        </li>
        <li id="LCSlide-BLACKJACK" data-bg="" data-state="hidden" class="SliderItem LiveCasinoSlide LCSlide-Blackjack">
            <div class="SliderContent">
                <h3 class="LCSlideTitle SlideTitle">
                    <span class="SlideWelcome">Welcome to</span>
                    <span class="CategorySlideTitle">Black jack</span>
                </h3>
            </div>
        </li>
        <li id="LCSlide-BACCARAT" data-bg="" data-state="hidden" class="SliderItem LiveCasinoSlide LCSlide-Baccarat">
            <div class="SliderContent">
                <h3 class="LCSlideTitle SlideTitle">
                    <span class="SlideWelcome">Welcome to</span>
                    <span class="CategorySlideTitle">Baccarat</span>
                </h3>
            </div>
        </li>
        <li id="LCSlide-HOLDEM" data-bg="" data-state="hidden" class="SliderItem LiveCasinoSlide LCSlide-Holdem">
            <div class="SliderContent">
                <h3 class="LCSlideTitle SlideTitle">
                    <span class="SlideWelcome">Welcome to</span>
                    <span class="CategorySlideTitle">Casino <br>Hold'em</span>
                </h3>
                <span class="CasinoCoin LeftCoin2">&nbsp;</span>
                <span class="CasinoCoin RightCard">&nbsp;</span>
            </div>
        </li>
    </ul>
</div>

<script>
    $(function () {
        var Sliders = $(".SliderContainer .SliderItem");
        var SliderNum = Sliders.length;
        var CurrentSliderNum = 1 ; 
        var refreshSlider =  function(){
            Sliders.slideUp("slow", function () {
                Sliders.removeClass("Active").hide();
                Sliders.eq(CurrentSliderNum).slideDown().addClass("Active");
            });
            setTimeout(function(){
                CurrentSliderNum ++ ;
               if(SliderNum == CurrentSliderNum )   CurrentSliderNum = 0;
                refreshSlider();
            },10000);
        };
        setTimeout(function () {
            refreshSlider();
        },10000);
    });
</script>