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
        error.attr('elementId', $(element).parents("div.inputfield").attr('id'));
        error.insertAfter($('td.controls > *:last', $(element).parents("div.inputfield")));
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
//        $('.notification_icon').each(function() {
//            $(this).parent().find('a.menu-item').append($(this).detach());
//        });
//        var promotionCount = "<%=PromotionCount %>";
//        var promotion = $(".menu-promotions");
//        if (promotion != null && promotion.offset() != null) {
//            if (promotionCount > 0) {
//                $(".notification_icon").text(promotionCount);
//                $(".notification_icon").css("position", "absolute");
//                $(".notification_icon").css("right", -10);
//                $(".notification_icon").css("top", -12);
//                $(".notification_icon").css("display","block");
//            } else {
//                $(".notification_icon").css("display","none");
//            }
//            
//        }
//        $(".menu-bingo .notification_icon").text("beta");
    }

    $(document).ready(function () {

        <% if (!Profile.IsAuthenticated)
        { %>
            $(".sidemenu .withdraw,.sidemenu .pendingwithdrawal,.sidemenu .transfer,.sidemenu .buddytransfer,.sidemenu .accountstatement,.sidemenu .changeemail,.sidemenu .changepwd,.sidemenu .changepwd,.sidemenu .mysportsaccount,,.sidemenu .availablebonus").parent("li").remove();
        <%} %>

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
