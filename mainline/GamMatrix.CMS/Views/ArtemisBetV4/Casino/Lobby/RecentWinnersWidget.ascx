<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<%@ Import Namespace="CasinoEngine" %>
<%@ Import Namespace="Finance" %>

<script language="C#" type="text/C#" runat="server">
    public bool ShowCapitalName {
        get {
            if (this.ViewData["ShowCapitalName"] != null) {
                return (bool)this.ViewData["ShowCapitalName"];
            } else {
                return false;
            }
        }
    }

    public bool NeedConvert {
        get {
            if (this.ViewData["needConvert"] != null) {
                return (bool)this.ViewData["needConvert"];
            } else {
                return false;
            }
        }
    }
    
    private int _RollingCount = -1;
    public int RollingCount
    {
        get {
            if (_RollingCount == -1)
            {
                if (this.ViewData["RollingCount"]!=null)
                    int.TryParse(this.ViewData["RollingCount"].ToString(), out _RollingCount);
                if (_RollingCount < 1)
                    _RollingCount = 1;
            }            

            return _RollingCount;
        }
    }

    private string GetJquerySelectorForRolling()
    { 
        StringBuilder sb = new StringBuilder("li:first");
        if (RollingCount > 1)
        {
            for (int i = 1; i < RollingCount; i++)
            {
                sb.AppendFormat(", li:nth-child({0})",i+1);
            }
        }
        return sb.ToString();
    }
</script>

<script type="text/html" id="recent-winner-template">
<# var item=arguments[0]; #>
<li class="Winner Container" data-WinTimeTicks="<#= item.WinTimeTicks #>">
    <span class="WinnerThumbnail">
        <# if( item.Url.length > 0 ){ #>
            <a href="<#= item.Url.htmlEncode() #>" class="WinGame" title="<#= item.GameName.htmlEncode() #>" data-gameid="<#= item.GameID.htmlEncode() #>"><img src="<#= item.ThumbnailUrl#>" width="120" height=="80" alt="<#= item.CountryName.htmlEncode() #>" title="<#= item.CountryName.htmlEncode() #>" /></a>
        <# }else{ #>
            <img src="<#= item.ThumbnailUrl#>" width="120" height=="80" alt="<#= item.CountryName.htmlEncode() #>" />
        <# } #>
    </span>
    <span class="WinnerInfo">
        <# if(item.WinTimeTicks % 2 == 0 ) {
            #><span class="WinnerName"><#= item.DisplayName.htmlEncode() #></span> <span><%=this.GetMetadata(".JustWon").SafeHtmlEncode() %></span> <span class="WinAmmount Cash"><#= item.FormattedAmount.htmlEncode() #></span>  <span><%=this.GetMetadata(".On").SafeHtmlEncode() %></span>
            <# if( item.Url.length > 0 ){
                #><a href="<#= item.Url.htmlEncode() #>" class="WinGame" title="<#= item.GameName.htmlEncode() #>" data-gameid="<#= item.GameID.htmlEncode() #>"><#= item.GameName.htmlEncode() #></a><#
            } else {
                #><span class="WinGame"><#= item.GameName.htmlEncode() #></span><#
            } #> &ndash; <span><%=this.GetMetadata(".GoodTimes").SafeHtmlEncode() %>!</span><#
        } else {
            #><span class="WinnerName"><#= item.DisplayName.htmlEncode() #></span> <span><%=this.GetMetadata(".KnowWon").SafeHtmlEncode() %></span> <span class="WinAmmount Cash"><#= item.FormattedAmount.htmlEncode() #></span> <span><%=this.GetMetadata(".On").SafeHtmlEncode() %></span> 
            <# if( item.Url.length > 0 ){
                #><a href="<#= item.Url.htmlEncode() #>" class="WinGame" title="<#= item.GameName.htmlEncode() #>" data-gameid="<#= item.GameID.htmlEncode() #>"><#= item.GameName.htmlEncode() #></a><#
            } else {
                #><span class="WinGame"><#= item.GameName.htmlEncode() #></span><#
            }#> &ndash; <span><%=this.GetMetadata(".Awesome").SafeHtmlEncode() %>!</span><#
        } #>
    </span>
</li>
</script>

<% string wrapperID = Guid.NewGuid().ToString("N"); %>

<div id="<%= wrapperID %>" class="Box Winners WinnersNow">
    <h2 class="BoxTitle WinnersTitle">
        <span class="TitleIcon">&sect;</span>
        <strong class="TitleText"><%= this.GetMetadata(".Title").SafeHtmlEncode() %></strong>
    </h2>
    <div class="WinnersContainer Canvas">
        <ol class="WinnersList Container"></ol>
    </div>
</div>

<script type="text/javascript">
    $(function () {        
        var _rolling_loop_index=0;
        var winnersAnimationTimer = null;
        function startAnimation() {            
            if(_rolling_loop_index == 1800) return;
            var temp = ++_rolling_loop_index;
            if(winnersAnimationTimer)
                window.clearTimeout(winnersAnimationTimer);
            var $container = $('ol.WinnersList', $('#<%= wrapperID %>'));
            var $li = $('<%= GetJquerySelectorForRolling() %>', $container);
            $li.animate({ 'marginTop': -1 * $li.eq(0).outerHeight() }
                , {
                    duration: 500,
                    easing: 'linear',
                    complete: function () {
                        $li.css('marginTop', 0).detach().appendTo($container);
                        if(temp==_rolling_loop_index)
                        {
                            temp-=1;
                            innersAnimationTimer = setTimeout(startAnimation, 2000);
                        }
                    }
                });
        }

        var maxCount = 50;
        var maxTime = 0;
        function loadData() {

            var url = '<%= this.Url.RouteUrl( "CasinoLobby", new { @action = "GetRecentWinners", @currency = this.ViewData["Currency"] as string, @showCapitalName = ShowCapitalName,@needConvert = NeedConvert }).SafeJavascriptStringEncode() %>';
            $.getJSON(url, function (json) {
                json = {"success":true,"winners":[{"ThumbnailUrl":"//cdn.everymatrix.com/_casino/A/A0B45DF94EDC0C6327EFC8F02CFDFB46.jpg","WinTimeTicks":200748509,"ElapsedSeconds":152,"DisplayName":"z. y.","FormattedAmount":"TRY 100.00","GameName":"1 Hand Deuces Wild","GameID":"7323","Url":"/Casino/Game/Index/7323","CountryFlagName":"tr","CountryName":"Turkey","OriginalCurrency":"TRY"},{"ThumbnailUrl":"//cdn.everymatrix.com/_casino/6/68EA3351D70B7FF3BFEDF69FC59E2A43.jpg","WinTimeTicks":200748354,"ElapsedSeconds":307,"DisplayName":"M. T.","FormattedAmount":"£ 4.12","GameName":"Jack and the Beanstalk","GameID":"7232","Url":"/Casino/Game/Index/7232","CountryFlagName":"gb","CountryName":"United Kingdom","OriginalCurrency":"GBP"},{"ThumbnailUrl":"//cdn.everymatrix.com/_casino/0/0649DAE62BC8FA633D42AE53C1552334.jpg","WinTimeTicks":200746120,"ElapsedSeconds":2541,"DisplayName":"M. D.","FormattedAmount":"zł 62.50","GameName":"Go Bananas","GameID":"8985","Url":"/Casino/Game/Index/8985","CountryFlagName":"pl","CountryName":"Poland","OriginalCurrency":"PLN"},{"ThumbnailUrl":"//cdn.everymatrix.com/_casino/4/485FB205560AD12B59B9C58A46808799.jpg","WinTimeTicks":200746060,"ElapsedSeconds":2601,"DisplayName":"S. W.","FormattedAmount":"€ 10.00","GameName":"Fantasini: Master of Mystery™","GameID":"9897","Url":"/Casino/Game/Index/9897","CountryFlagName":"pl","CountryName":"Poland","OriginalCurrency":"EUR"},{"ThumbnailUrl":"//cdn.everymatrix.com/_casino/3/3A7CEC1EB39C7E327CFB3E562938EC56.jpg","WinTimeTicks":200742049,"ElapsedSeconds":6612,"DisplayName":"h. g.","FormattedAmount":"TRY 21.56","GameName":"Elements: The Awakening","GameID":"8155","Url":"/Casino/Game/Index/8155","CountryFlagName":"tr","CountryName":"Turkey","OriginalCurrency":"TRY"},{"ThumbnailUrl":"//cdn.everymatrix.com/_casino/C/C44B6A5E8F2F94408CAA96D10C1ADEDC.jpg","WinTimeTicks":200740069,"ElapsedSeconds":8592,"DisplayName":"D. P.","FormattedAmount":"€ 5.72","GameName":"Devil\u0027s Delight™","GameID":"7401","Url":"/Casino/Game/Index/7401","CountryFlagName":"pl","CountryName":"Poland","OriginalCurrency":"EUR"},{"ThumbnailUrl":"//cdn.everymatrix.com/_casino/D/D18E7A2CD38AFD777B74F6C160B770C5.jpg","WinTimeTicks":200739805,"ElapsedSeconds":8856,"DisplayName":"O. D.","FormattedAmount":"TRY 21.30","GameName":"Jack Hammer 2","GameID":"7372","Url":"/Casino/Game/Index/7372","CountryFlagName":"tr","CountryName":"Turkey","OriginalCurrency":"TRY"},{"ThumbnailUrl":"//cdn.everymatrix.com/_casino/D/D9CBA046BFC7A3EC03B41A4E01E99977.jpg","WinTimeTicks":200739735,"ElapsedSeconds":8926,"DisplayName":"S. P.","FormattedAmount":"US$ 12.00","GameName":"Jack Hammer™","GameID":"7233","Url":"/Casino/Game/Index/7233","CountryFlagName":"au","CountryName":"Australia","OriginalCurrency":"USD"},{"ThumbnailUrl":"//cdn.everymatrix.com/_casino/B/B7A3EB2D301498EAF6237B8F4212A8BC.jpg","WinTimeTicks":200738070,"ElapsedSeconds":10591,"DisplayName":"v. k.","FormattedAmount":"€ 5.10","GameName":"Golden Ticket","GameID":"9057","Url":"/Casino/Game/Index/9057","CountryFlagName":"tr","CountryName":"Turkey","OriginalCurrency":"EUR"},{"ThumbnailUrl":"//cdn.everymatrix.com/_casino/6/67C2F77A5AB3DB82E826AA50D78A618C.jpg","WinTimeTicks":200736126,"ElapsedSeconds":12535,"DisplayName":"L. R.","FormattedAmount":"€ 16.28","GameName":"Victorious™","GameID":"7272","Url":"/Casino/Game/Index/7272","CountryFlagName":"dk","CountryName":"Denmark","OriginalCurrency":"EUR"},{"ThumbnailUrl":"//cdn.everymatrix.com/_casino/A/AE7659D98264C947DB267BE944932198.jpg","WinTimeTicks":200723736,"ElapsedSeconds":24925,"DisplayName":"N. D.","FormattedAmount":"SEK 200.00","GameName":"Spellcast","GameID":"7258","Url":"/Casino/Game/Index/7258","CountryFlagName":"se","CountryName":"Sweden","OriginalCurrency":"SEK"},{"ThumbnailUrl":"//cdn.everymatrix.com/_casino/3/3256845B2E7AFE180503D893F0BF37C4.jpg","WinTimeTicks":200718340,"ElapsedSeconds":30321,"DisplayName":"T. O.","FormattedAmount":"€ 9.60","GameName":"Wild Chase","GameID":"9942","Url":"/Casino/Game/Index/9942","CountryFlagName":"fi","CountryName":"Finland","OriginalCurrency":"EUR"},{"ThumbnailUrl":"//cdn.everymatrix.com/_casino/C/C9B1E480E150E4C6BC5F27F59378DE96.jpg","WinTimeTicks":200714347,"ElapsedSeconds":34314,"DisplayName":"L. B.","FormattedAmount":"US$ 8.00","GameName":"Aloha Party","GameID":"9952","Url":"/Casino/Game/Index/9952","CountryFlagName":"bm","CountryName":"Bermuda","OriginalCurrency":"USD"},{"ThumbnailUrl":"//cdn.everymatrix.com/_casino/F/FD9011272233BA152836FE88B06FDEBF.jpg","WinTimeTicks":200710570,"ElapsedSeconds":38091,"DisplayName":"a. g.","FormattedAmount":"TRY 24.20","GameName":"Dead or Alive™","GameID":"7204","Url":"/Casino/Game/Index/7204","CountryFlagName":"tr","CountryName":"Turkey","OriginalCurrency":"TRY"},{"ThumbnailUrl":"//cdn.everymatrix.com/_casino/8/84DF7377DB24D5E93EC5C0D648AD6572.jpg","WinTimeTicks":200707981,"ElapsedSeconds":40680,"DisplayName":"P. W.","FormattedAmount":"zł 28.00","GameName":"Starburst™","GameID":"7262","Url":"/Casino/Game/Index/7262","CountryFlagName":"pl","CountryName":"Poland","OriginalCurrency":"PLN"},{"ThumbnailUrl":"//cdn.everymatrix.com/_casino/3/31AC8B1EFF2BE96FD3515E4B22B1B68A.jpg","WinTimeTicks":200704259,"ElapsedSeconds":44402,"DisplayName":"S. B.","FormattedAmount":"€ 7.50","GameName":"Arctic Fortune","GameID":"7782","Url":"/Casino/Game/Index/7782","CountryFlagName":"no","CountryName":"Norway","OriginalCurrency":"EUR"},{"ThumbnailUrl":"//cdn.everymatrix.com/_casino/6/68EA3351D70B7FF3BFEDF69FC59E2A43.jpg","WinTimeTicks":200702589,"ElapsedSeconds":46072,"DisplayName":"M. E.","FormattedAmount":"TRY 20.15","GameName":"Jack and the Beanstalk","GameID":"7232","Url":"/Casino/Game/Index/7232","CountryFlagName":"tr","CountryName":"Turkey","OriginalCurrency":"TRY"},{"ThumbnailUrl":"//cdn.everymatrix.com/_casino/2/235E2FA51262C15FBCFA237EFC6DC3F8.jpg","WinTimeTicks":200700651,"ElapsedSeconds":48010,"DisplayName":"E. D.","FormattedAmount":"£ 15.10","GameName":"Jimi Hendrix Online Slot™","GameID":"9951","Url":"/Casino/Game/Index/9951","CountryFlagName":"gb","CountryName":"United Kingdom","OriginalCurrency":"GBP"},{"ThumbnailUrl":"//cdn.everymatrix.com/_casino/8/84DF7377DB24D5E93EC5C0D648AD6572.jpg","WinTimeTicks":200696530,"ElapsedSeconds":52131,"DisplayName":"M. E.","FormattedAmount":"TRY 19.00","GameName":"Starburst™","GameID":"7262","Url":"/Casino/Game/Index/7262","CountryFlagName":"tr","CountryName":"Turkey","OriginalCurrency":"TRY"},{"ThumbnailUrl":"//cdn.everymatrix.com/_casino/8/84DF7377DB24D5E93EC5C0D648AD6572.jpg","WinTimeTicks":200696110,"ElapsedSeconds":52551,"DisplayName":"M. C.","FormattedAmount":"€ 10.28","GameName":"Starburst™","GameID":"7262","Url":"/Casino/Game/Index/7262","CountryFlagName":"de","CountryName":"Germany","OriginalCurrency":"EUR"},{"ThumbnailUrl":"//cdn.everymatrix.com/_casino/9/90D3D9A0F6BF016873932D64653EA4EA.jpg","WinTimeTicks":200695032,"ElapsedSeconds":53629,"DisplayName":"A. S.","FormattedAmount":"£ 4.00","GameName":"What on Earth","GameID":"7185","Url":"/Casino/Game/Index/7185","CountryFlagName":"gb","CountryName":"United Kingdom","OriginalCurrency":"GBP"},{"ThumbnailUrl":"//cdn.everymatrix.com/_casino/7/712247DB9181EF2754F22551C4635E7A.jpg","WinTimeTicks":200693651,"ElapsedSeconds":55010,"DisplayName":"J. D.","FormattedAmount":"US$ 7.60","GameName":"Diamond Dogs","GameID":"7207","Url":"/Casino/Game/Index/7207","CountryFlagName":"cl","CountryName":"Chile","OriginalCurrency":"USD"},{"ThumbnailUrl":"//cdn.everymatrix.com/_casino/6/61F69709919BEA640F6342C4654FD419.jpg","WinTimeTicks":200685455,"ElapsedSeconds":63206,"DisplayName":"Ł. M.","FormattedAmount":"zł 90.00","GameName":"Glow","GameID":"9874","Url":"/Casino/Game/Index/9874","CountryFlagName":"pl","CountryName":"Poland","OriginalCurrency":"PLN"},{"ThumbnailUrl":"//cdn.everymatrix.com/_casino/8/85ED6F5071C53D7501ECFB46C6D5EF52.jpg","WinTimeTicks":200685299,"ElapsedSeconds":63362,"DisplayName":"e. ç.","FormattedAmount":"TRY 20.00","GameName":"Triple Wins Star Ticket","GameID":"7297","Url":"/Casino/Game/Index/7297","CountryFlagName":"tr","CountryName":"Turkey","OriginalCurrency":"TRY"},{"ThumbnailUrl":"//cdn.everymatrix.com/_casino/8/84DF7377DB24D5E93EC5C0D648AD6572.jpg","WinTimeTicks":200684019,"ElapsedSeconds":64642,"DisplayName":"P. K.","FormattedAmount":"€ 7.98","GameName":"Starburst™","GameID":"7262","Url":"/Casino/Game/Index/7262","CountryFlagName":"pl","CountryName":"Poland","OriginalCurrency":"EUR"},{"ThumbnailUrl":"//cdn.everymatrix.com/_casino/B/BC5A6743E4C36FFCB45CC75C265BBBC8.jpg","WinTimeTicks":200682545,"ElapsedSeconds":66116,"DisplayName":"M. K.","FormattedAmount":"TRY 24.00","GameName":"Thunderstruck II","GameID":"7183","Url":"/Casino/Game/Index/7183","CountryFlagName":"tr","CountryName":"Turkey","OriginalCurrency":"TRY"},{"ThumbnailUrl":"//cdn.everymatrix.com/_casino/F/FD9011272233BA152836FE88B06FDEBF.jpg","WinTimeTicks":200680672,"ElapsedSeconds":67989,"DisplayName":"P. K.","FormattedAmount":"€ 5.00","GameName":"Dead or Alive™","GameID":"7204","Url":"/Casino/Game/Index/7204","CountryFlagName":"pl","CountryName":"Poland","OriginalCurrency":"EUR"},{"ThumbnailUrl":"//cdn.everymatrix.com/_casino/C/C749F3681F41EB17ED948987D3F63BE3.jpg","WinTimeTicks":200680460,"ElapsedSeconds":68201,"DisplayName":"J. K.","FormattedAmount":"€ 15.21","GameName":"Mythic Maiden™","GameID":"7241","Url":"/Casino/Game/Index/7241","CountryFlagName":"fi","CountryName":"Finland","OriginalCurrency":"EUR"},{"ThumbnailUrl":"//cdn.everymatrix.com/_casino/B/BFAB47E5676632C465CA479365E1AB4C.jpg","WinTimeTicks":200680048,"ElapsedSeconds":68613,"DisplayName":"J. O.","FormattedAmount":"£ 7.65","GameName":"Blood Suckers","GameID":"7052","Url":"/Casino/Game/Index/7052","CountryFlagName":"pl","CountryName":"Poland","OriginalCurrency":"GBP"},{"ThumbnailUrl":"//cdn.everymatrix.com/_casino/2/26EEDBE1B0ACBEB264351829D755D401.jpg","WinTimeTicks":200679660,"ElapsedSeconds":69001,"DisplayName":"ü. ı.","FormattedAmount":"TRY 42.21","GameName":"Cloud Quest","GameID":"9911","Url":"/Casino/Game/Index/9911","CountryFlagName":"tr","CountryName":"Turkey","OriginalCurrency":"TRY"},{"ThumbnailUrl":"//cdn.everymatrix.com/_casino/C/CA5B2A19DD18DE3A5B304B0C8A163D90.jpg","WinTimeTicks":200676437,"ElapsedSeconds":72224,"DisplayName":"A. S.","FormattedAmount":"TRY 19.60","GameName":"Reel Steal","GameID":"7247","Url":"/Casino/Game/Index/7247","CountryFlagName":"tr","CountryName":"Turkey","OriginalCurrency":"TRY"},{"ThumbnailUrl":"//cdn.everymatrix.com/_casino/7/7CF8265A59879D4984B980CBFA38011A.jpg","WinTimeTicks":200674018,"ElapsedSeconds":74643,"DisplayName":"V. H.","FormattedAmount":"€ 6.08","GameName":"JEWEL BLAST","GameID":"9611","Url":"/Casino/Game/Index/9611","CountryFlagName":"fi","CountryName":"Finland","OriginalCurrency":"EUR"},{"ThumbnailUrl":"//cdn.everymatrix.com/_casino/5/5EB32075E70E2F0222A43EAD05650174.jpg","WinTimeTicks":200670601,"ElapsedSeconds":78060,"DisplayName":"T. H.","FormattedAmount":"€ 5.25","GameName":"Jungle Games™","GameID":"7235","Url":"/Casino/Game/Index/7235","CountryFlagName":"fi","CountryName":"Finland","OriginalCurrency":"EUR"},{"ThumbnailUrl":"//cdn.everymatrix.com/_casino/3/3A7CEC1EB39C7E327CFB3E562938EC56.jpg","WinTimeTicks":200669999,"ElapsedSeconds":78662,"DisplayName":"S. S.","FormattedAmount":"TRY 20.37","GameName":"Elements: The Awakening","GameID":"8155","Url":"/Casino/Game/Index/8155","CountryFlagName":"tr","CountryName":"Turkey","OriginalCurrency":"TRY"},{"ThumbnailUrl":"//cdn.everymatrix.com/_casino/7/7D50812F167C976B46271F720E84A212.jpg","WinTimeTicks":200667335,"ElapsedSeconds":81326,"DisplayName":"A. T.","FormattedAmount":"TRY 40.00","GameName":"1 Hand Jacks or Better","GameID":"7322","Url":"/Casino/Game/Index/7322","CountryFlagName":"tr","CountryName":"Turkey","OriginalCurrency":"TRY"},{"ThumbnailUrl":"//cdn.everymatrix.com/_casino/9/9FFE0FB1D41E6FBD5784603C1B6C7375.jpg","WinTimeTicks":200665464,"ElapsedSeconds":83197,"DisplayName":"Ö. K.","FormattedAmount":"TRY 80.00","GameName":"Bikini Party","GameID":"9888","Url":"/Casino/Game/Index/9888","CountryFlagName":"tr","CountryName":"Turkey","OriginalCurrency":"TRY"},{"ThumbnailUrl":"//cdn.everymatrix.com/_casino/B/BFAB47E5676632C465CA479365E1AB4C.jpg","WinTimeTicks":200664851,"ElapsedSeconds":83810,"DisplayName":"R. L.","FormattedAmount":"SEK 73.00","GameName":"Blood Suckers","GameID":"7052","Url":"/Casino/Game/Index/7052","CountryFlagName":"se","CountryName":"Sweden","OriginalCurrency":"SEK"},{"ThumbnailUrl":"//cdn.everymatrix.com/_casino/2/2D02A0FE599D400E468D4ED0FA2C3558.jpg","WinTimeTicks":200661599,"ElapsedSeconds":87062,"DisplayName":"M. P.","FormattedAmount":"€ 8.26","GameName":"Steam Tower","GameID":"9223","Url":"/Casino/Game/Index/9223","CountryFlagName":"se","CountryName":"Sweden","OriginalCurrency":"EUR"},{"ThumbnailUrl":"//cdn.everymatrix.com/_casino/F/FD9011272233BA152836FE88B06FDEBF.jpg","WinTimeTicks":200624141,"ElapsedSeconds":124520,"DisplayName":"k. e.","FormattedAmount":"TRY 20.76","GameName":"Dead or Alive™","GameID":"7204","Url":"/Casino/Game/Index/7204","CountryFlagName":"tr","CountryName":"Turkey","OriginalCurrency":"TRY"},{"ThumbnailUrl":"//cdn.everymatrix.com/_casino/C/C397A3B92B4BD57DD27FC043574431A6.jpg","WinTimeTicks":200617974,"ElapsedSeconds":130687,"DisplayName":"I. R.","FormattedAmount":"€ 12.70","GameName":"Twin Spin","GameID":"8537","Url":"/Casino/Game/Index/8537","CountryFlagName":"ru","CountryName":"Russian Federation","OriginalCurrency":"EUR"},{"ThumbnailUrl":"//cdn.everymatrix.com/_casino/B/B6D06B248112B81FADA053AE23EC5016.jpg","WinTimeTicks":200617269,"ElapsedSeconds":131392,"DisplayName":"M. W.","FormattedAmount":"US$ 9.25","GameName":"Energoonz","GameID":"8547","Url":"/Casino/Game/Index/8547","CountryFlagName":"pl","CountryName":"Poland","OriginalCurrency":"USD"},{"ThumbnailUrl":"//cdn.everymatrix.com/_casino/2/2909DEDFADFCA4BC871CE4E286BE26DF.jpg","WinTimeTicks":200612609,"ElapsedSeconds":136052,"DisplayName":"B. S.","FormattedAmount":"€ 5.46","GameName":"Subtopia","GameID":"7260","Url":"/Casino/Game/Index/7260","CountryFlagName":"pl","CountryName":"Poland","OriginalCurrency":"EUR"},{"ThumbnailUrl":"//cdn.everymatrix.com/_casino/F/FD9011272233BA152836FE88B06FDEBF.jpg","WinTimeTicks":200612219,"ElapsedSeconds":136442,"DisplayName":"K. K.","FormattedAmount":"€ 5.00","GameName":"Dead or Alive™","GameID":"7204","Url":"/Casino/Game/Index/7204","CountryFlagName":"at","CountryName":"Austria","OriginalCurrency":"EUR"},{"ThumbnailUrl":"//cdn.everymatrix.com/_casino/5/5616D9B3058403EF65F82393B63D39FE.jpg","WinTimeTicks":200611945,"ElapsedSeconds":136716,"DisplayName":"C. Ç.","FormattedAmount":"TRY 400.00","GameName":"Single Deck Blackjack ","GameID":"7806","Url":"/Casino/Game/Index/7806","CountryFlagName":"tr","CountryName":"Turkey","OriginalCurrency":"TRY"},{"ThumbnailUrl":"//cdn.everymatrix.com/_casino/9/91F2E50936A681DD8533C588949B70C4.jpg","WinTimeTicks":200611693,"ElapsedSeconds":136968,"DisplayName":"Ç. A.","FormattedAmount":"TRY 88.20","GameName":"Reel Rush","GameID":"8452","Url":"/Casino/Game/Index/8452","CountryFlagName":"tr","CountryName":"Turkey","OriginalCurrency":"TRY"},{"ThumbnailUrl":"//cdn.everymatrix.com/_casino/2/23A0EF92C2C5EDF066E0491139BAC6FA.jpg","WinTimeTicks":200610569,"ElapsedSeconds":138092,"DisplayName":"J. E.","FormattedAmount":"SEK 51.40","GameName":"Gonzo\u0027s Quest™","GameID":"7226","Url":"/Casino/Game/Index/7226","CountryFlagName":"se","CountryName":"Sweden","OriginalCurrency":"SEK"},{"ThumbnailUrl":"//cdn.everymatrix.com/_casino/A/AF62D28C638A6E1BD96BFA20B798803D.jpg","WinTimeTicks":200609068,"ElapsedSeconds":139593,"DisplayName":"ü. a.","FormattedAmount":"TRY 50.00","GameName":"High Society","GameID":"8666","Url":"/Casino/Game/Index/8666","CountryFlagName":"tr","CountryName":"Turkey","OriginalCurrency":"TRY"},{"ThumbnailUrl":"//cdn.everymatrix.com/_casino/3/3B54F3408D08C687EFF2F4B254B0D8EA.jpg","WinTimeTicks":200608036,"ElapsedSeconds":140625,"DisplayName":"E. K.","FormattedAmount":"€ 6.45","GameName":"Blue Heart","GameID":"9103","Url":"/Casino/Game/Index/9103","CountryFlagName":"nl","CountryName":"Netherlands","OriginalCurrency":"EUR"},{"ThumbnailUrl":"//cdn.everymatrix.com/_casino/8/83B5CBCAA2B79915D575EB38175CB2FC.jpg","WinTimeTicks":200606534,"ElapsedSeconds":142127,"DisplayName":"F. Y.","FormattedAmount":"TRY 25.00","GameName":"American Roulette","GameID":"8685","Url":"/Casino/Game/Index/8685","CountryFlagName":"tr","CountryName":"Turkey","OriginalCurrency":"TRY"},{"ThumbnailUrl":"//cdn.everymatrix.com/_casino/2/23A0EF92C2C5EDF066E0491139BAC6FA.jpg","WinTimeTicks":200606030,"ElapsedSeconds":142631,"DisplayName":"A. M.","FormattedAmount":"US$ 13.33","GameName":"Gonzo\u0027s Quest™","GameID":"7226","Url":"/Casino/Game/Index/7226","CountryFlagName":"pl","CountryName":"Poland","OriginalCurrency":"USD"},{"ThumbnailUrl":"//cdn.everymatrix.com/_casino/3/37E111DD27CF69D7147ACE18965182E5.jpg","WinTimeTicks":200605686,"ElapsedSeconds":142975,"DisplayName":"A. G.","FormattedAmount":"TRY 37.50","GameName":"Wild Blood","GameID":"8263","Url":"/Casino/Game/Index/8263","CountryFlagName":"tr","CountryName":"Turkey","OriginalCurrency":"TRY"},{"ThumbnailUrl":"//cdn.everymatrix.com/_casino/2/235E2FA51262C15FBCFA237EFC6DC3F8.jpg","WinTimeTicks":200605098,"ElapsedSeconds":143563,"DisplayName":"R. M.","FormattedAmount":"€ 6.16","GameName":"Jimi Hendrix Online Slot™","GameID":"9951","Url":"/Casino/Game/Index/9951","CountryFlagName":"de","CountryName":"Germany","OriginalCurrency":"EUR"}]};
                if (!json.success) {
                    alert(json.error);
                }

                var container = $('ol.WinnersList', $('#<%= wrapperID %>'));
                var max = 0;
                
                for (var i = 0; i < json.winners.length; i++) {
                    if (json.winners[i].WinTimeTicks > maxTime)
                        $($('#recent-winner-template').parseTemplate(json.winners[i])).appendTo(container);
                    
                    var liWinners = container.find('li.Winner')
                    if(liWinners.length > maxCount)
                    {
                        liWinners.sort(function(a,b){
                            return $(a).attr('data-WinTimeTicks') < $(b).attr('data-WinTimeTicks');
                        });
                        
                        for(var j = maxCount; j<liWinners.length;j++)
                        {
                            liWinners.eq(j).remove();   
                        }                       
                    }

                    max = Math.max(max, json.winners[i].WinTimeTicks);
                }

                if (maxTime == 0 && container.find("li").length><%=RollingCount %>)
                    startAnimation();

                if (max > maxTime)
                    maxTime = max;
                
                bindEvent();

                setTimeout(loadData, 100000);
            });
        }
        loadData();

        function bindEvent() {
            $('#<%= wrapperID%>').find('a.WinGame').click(function (e) {
                try {
                    var playToWin  = <%= (Profile.IsAuthenticated).ToString().ToLowerInvariant() %>;
                    var gameID = $(this).data('gameID') || $(this).attr('data-gameID');
                    if(gameID.length>0)
                        __loadGame(gameID, playToWin);
                    e.preventDefault();
                }
                catch (e) {alert(e);
                }
            });
        }
    });
</script>