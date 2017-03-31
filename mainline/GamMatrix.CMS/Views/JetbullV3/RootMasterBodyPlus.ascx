<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>

<script runat="server" type="text/C#">
    public int PromotionCount
    {
        get;
        set;
    }
</script>

<script type="text/javascript">
if (window.location.toString().indexOf('.gammatrix-dev.net') > 0)
    document.domain = document.domain;
else
    document.domain = '<%= SiteManager.Current.SessionCookieDomain.SafeJavascriptStringEncode() %>';

// <![CDATA[
    InputFields.onErrorPlacement = function (error, element) {
        var $pdiv = $(element).parents("div.inputfield");error.attr('elementId', $pdiv.attr('id'));if($('td.hint > *', $pdiv).length < 1 ){$('td.hint', $pdiv).html("<span class='NoticeText'>"+ $('td.hint', $pdiv).text() +" </span>");}
        error.insertAfter($('td.hint > *:last', $pdiv));
    }



    function Page_Style_Init() {
        <%
            PromotionCount = 0;
            ArrayList paths = new ArrayList();
            string[] categoryPaths = Metadata.GetChildrenPaths("/Metadata/Promotions");
            foreach (string categoryPath in categoryPaths)
            {
                paths.AddRange(Metadata.GetChildrenPaths(categoryPath));
            }

            foreach (string path in paths)
            {
                if ( this.GetMetadata(path + ".ShowOnTops_Bool").ToLower() == "true" || this.GetMetadata(path + ".ShowOnTops_Bool").ToLower() == "1")
                {
                    PromotionCount++;
                }
            }
         %>
        //$('.notification_icon').each(function() {
        //    $(this).parent().find('a.menu-item').append($(this).detach());
        //});
    }

    function GetPaymentLink() {
        $(".deposit-table .link").each(function () {
            var href = $(this).find("a").attr("href");
            $(this).parents("tr").click(function () {
                <% if (Profile.IsAuthenticated)
                { %>
                    window.location = href;
                <%} 
                else 
                { %>
                    $('iframe.CasinoHallDialog').remove();
                    $('<iframe style="border:0px;width:400px;height:300px;display:none" frameborder="0" scrolling="no" src="/Casino/Hall/Dialog?_=<%= DateTime.Now.Ticks %>" allowTransparency="true" class="CasinoHallDialog"></iframe>').appendTo(top.document.body);
                    var $iframe = $('iframe.CasinoHallDialog', top.document.body).eq(0);
                    $iframe.modalex($iframe.width(), $iframe.height(), true, top.document.body);
                    return false;
                <%} %>
            });
        });

        
    }

    $(document).ready(function () {
        $("head").append('<!--[if LT IE 9]><link href="//cdn.everymatrix.com/JetbullV2/ie.css" rel="stylesheet" type="text/css" /><![endif]-->');

        <% if (!Profile.IsAuthenticated)
        { %>
            $(".sidemenu .withdraw,.sidemenu .pendingwithdrawal,.sidemenu .transfer,.sidemenu .buddytransfer,.sidemenu .accountstatement,.sidemenu .changeemail,.sidemenu .changepwd,.sidemenu .changepwd,.sidemenu .mysportsaccount,,.sidemenu .availablebonus").parent("li").remove();
        <%} %>

        <% if (!Profile.IsInRole("Affiliate"))
        { %>
            $(".sidemenu .transfer").parent("li").remove();
        <% } %>

        $('#pnAccountStatement #filterType option[value=BuddyTransfer]').remove();
        $('#pnAccountStatement #filterType option[value=CakeNetworkWalletCreditDebit]').remove();

        GetPaymentLink();
        $(".withdraw-table .link").each(function () {
                var href = $(this).find("a").attr("href");
                $(this).parents("tr").click(function () {
                    <% if (Profile.IsAuthenticated)
                    { %>
                        window.location = href;
                    <%} 
                    else 
                    { %>
                        $('iframe.CasinoHallDialog').remove();
                        $('<iframe style="border:0px;width:400px;height:300px;display:none" frameborder="0" scrolling="no" src="/Casino/Hall/Dialog?_=<%= DateTime.Now.Ticks %>" allowTransparency="true" class="CasinoHallDialog"></iframe>').appendTo(top.document.body);
                        var $iframe = $('iframe.CasinoHallDialog', top.document.body).eq(0);
                        $iframe.modalex($iframe.width(), $iframe.height(), true, top.document.body);
                        return false;
                    <%} %>
                });
        });

        $(document).bind("_ON_PAYMENT_METHOD_LIST_LOAD_", GetPaymentLink);
        
        

        $('.foot_links a').each(function() {
            var href = $(this).attr('href');
            var reg = new RegExp(href);
            var currentUrl = document.location;
            if (reg.test(currentUrl)) {
                $(this).parent().addClass('ActiveItem');
            }
        });
         
        setInterval(function() { if ($(document).scrollTop() < 110) {$('#toplinks a.Home').css('display','none');} else {$('#toplinks a.Home').css('display','block');}},200);

        $(window).resize(function () {
            Page_Style_Init();
        });
        //alert('<%=Profile.IpCountryID + " " + Request.UserHostAddress %>');
        Page_Style_Init();
    });
// ]]>
</script>

<script>
  (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
  (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
  m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
  })(window,document,'script','//www.google-analytics.com/analytics.js','ga');

  ga('create', 'UA-5470473-6', 'auto');
  ga('send', 'pageview');

</script>
