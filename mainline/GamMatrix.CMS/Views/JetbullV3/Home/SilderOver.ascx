<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>
 
    <div class="slidehandle sportsbook">
        <div class="name">
            <%=this.GetMetadata(".Sports_Name_Text") %></div>
        <div class="action">
            <a href="<%=this.GetMetadata(".Sports_Action_Url").SafeHtmlEncode()%>">
                <%=this.GetMetadata(".Sports_Action_Text").DefaultIfNullOrEmpty("Untitled").SafeHtmlEncode()%></a></div>
        <div class="slidepanel">
            <div class="title">
                <%=this.GetMetadata(".Sports_SlidePanel_Title_Text")%></div>
            <div class="content">
                <%=this.GetMetadata(".Sports_SlidePanel_Content_Html")%></div>
            <div class="button">
                <a href="<%=this.GetMetadata(".Sports_SlidePanel_Button_Url").SafeHtmlEncode()%>">
                    <%=this.GetMetadata(".Sports_SlidePanel_Button_Text").DefaultIfNullOrEmpty("Untitled").SafeHtmlEncode()%></a></div>
        </div>
    </div>
    <div class="slidehandle casino first">
        <div class="name">
            <%=this.GetMetadata(".Casino_Name_Text") %></div>
        <div class="action">
            <a href="<%=this.GetMetadata(".Casino_Action_Url").SafeHtmlEncode()%>">
                <%=this.GetMetadata(".Casino_Action_Text").DefaultIfNullOrEmpty("Untitled").SafeHtmlEncode()%></a></div>
        <div class="slidepanel"  >
            <div class="title">
                <%=this.GetMetadata(".Casino_SlidePanel_Title_Text")%></div>
            <div class="content">
                <%=this.GetMetadata(".Casino_SlidePanel_Content_Html")%></div>
            <div class="button">
                <a href="<%=this.GetMetadata(".Casino_SlidePanel_Button_Url").SafeHtmlEncode()%>">
                    <%=this.GetMetadata(".Casino_SlidePanel_Button_Text").DefaultIfNullOrEmpty("Untitled").SafeHtmlEncode()%></a></div>
        </div>
    </div>
    <div class="slidehandle poker">
        <div class="name">
            <%=this.GetMetadata(".Poker_Name_Text") %></div>
        <div class="action">
            <a href="<%=this.GetMetadata(".Poker_Action_Url").SafeHtmlEncode()%>">
                <%=this.GetMetadata(".Poker_Action_Text").DefaultIfNullOrEmpty("Untitled").SafeHtmlEncode()%></a></div>
        <div class="slidepanel" >
            <div class="title">
                <%=this.GetMetadata(".Poker_SlidePanel_Title_Text")%></div>
            <div class="content">
                <%=this.GetMetadata(".Poker_SlidePanel_Content_Html")%></div>
            <div class="button">
                <a href="<%=this.GetMetadata(".Poker_SlidePanel_Button_Url").SafeHtmlEncode()%>">
                    <%=this.GetMetadata(".Poker_SlidePanel_Button_Text").DefaultIfNullOrEmpty("Untitled").SafeHtmlEncode()%></a></div>
        </div>
    </div> 
<script>
function tabSlider(elmId) {
        //try{
        elMenuContainer = $("#"+elmId);
       // CreateElMenu();
        
        var initialTop;
        var sildeTop;
        var sildeHeight = 448;

        $.each($(".slidehandle"), function() {
            var $curpanel = $(".slidepanel", $(this));
            var $curhandle = $(this);
            initialTop = $curhandle.offset().top + $curhandle.height() -165;
            sildetop = $curhandle.offset().top + $curhandle.height() -165 - sildeHeight;
            $curpanel.css("top", initialTop);
            $curhandle.bind("mouseenter", function() {
                $curpanel.css("display", "block");
                $curpanel.animate({ height: sildeHeight, top: sildetop }, 200,"linear");
            });

            $curhandle.bind("mouseleave", function() {
                $curpanel.animate({ height: 0, top: initialTop  }, { duration: 200, complete: function() { $curpanel.css("display", "none"); } },"linear");
            });
        });
        //} catch (e) { }
    }
        
    $(function() {
    tabSlider("slidehandle");       
    });  
</script>