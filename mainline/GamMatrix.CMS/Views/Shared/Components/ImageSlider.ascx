<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>
<%@ Import Namespace="System.Globalization" %>
<script runat="server" type="text/C#">
    private string _MetadataPath = "";
    public string MetadataPath
    {
        get { return _MetadataPath; }
        set { _MetadataPath = value; }
    }

    private bool _ShowIconButton = false;
    public bool ShowIconButton
    {
        get { return _ShowIconButton; }
        set { _ShowIconButton = value; }
    }
    
    private bool _BackGroundModel = false;
    protected bool BackGroundModel
    {
        get { return _BackGroundModel; }
        set { _BackGroundModel = value; }
    }
    
    private string SliderDelays { get; set; }


    protected override void OnInit(EventArgs e)
    {
        if (ViewData["MetadataPath"] != null && !string.IsNullOrEmpty(ViewData["MetadataPath"].ToString()))
        {
            MetadataPath = ViewData["MetadataPath"].ToString();
        }
        if (ViewData["ShowIconButton"] != null && !string.IsNullOrEmpty(ViewData["ShowIconButton"].ToString()))
        {
            bool.TryParse(ViewData["ShowIconButton"].ToString(), out _ShowIconButton);
        }
        if (ViewData["BackGroundModel"] != null && !string.IsNullOrEmpty(ViewData["BackGroundModel"].ToString()))
        {
            bool.TryParse(ViewData["BackGroundModel"].ToString(), out _BackGroundModel);
        }
        base.OnInit(e);
    }
</script>
<style type="text/css">
        #slideshow div{ display:none; position:absolute;z-index:3;filter:alpha(opacity=0);opacity:0.0;}
        #slideshow div.current{z-index:5;}
        #slideshow div.prev{z-index:4;}
</style>

<div class="imageslider-wrapper">
    <div id="imageslide-holder">
     <%
         StringBuilder sbSliderDelays = new StringBuilder();
         sbSliderDelays.Append("[");
         string[] paths = Metadata.GetChildrenPaths(MetadataPath);

         string image, link, title, target, delay, backgroundStyle;         
         for (int i = 0; i < paths.Length; i++)
         {
             image = Metadata.Get(string.Format("{0}.Image", paths[i])).DefaultIfNullOrEmpty("");
             link = Metadata.Get(string.Format("{0}.Link", paths[i])).DefaultIfNullOrEmpty("#");
             title = Metadata.Get(string.Format("{0}.Title", paths[i])).DefaultIfNullOrEmpty("").SafeJavascriptStringEncode();
             target = Metadata.Get(string.Format("{0}.Target", paths[i])).DefaultIfNullOrEmpty("_self");
             delay = Metadata.Get(string.Format("{0}.Delay", paths[i])).DefaultIfNullOrEmpty("2000");
             sbSliderDelays.Append("{");
             sbSliderDelays.AppendFormat(CultureInfo.InvariantCulture, "image:'{0}', link:'{1}', title:'{2}', target:'{3}', delay:{4}", image, link, title, target, delay);
             sbSliderDelays.Append(i==(paths.Length-1)?"}":"},");

             backgroundStyle = string.Empty;
             if (BackGroundModel)
             {
                 backgroundStyle = string.Format(@" style=""background-image:url({0});""", ContentHelper.ParseFirstImageSrc(image).DefaultIfNullOrEmpty(image));
                 image = "";
             }
            %>
            <div id="slidepanel<%=i %>" >
            <%=string.Format(@"<a title=""{0}"" href=""{1}"" target=""{3}""{4}>{2}</a>", title, link, image, target, backgroundStyle)%>
            </div>
            <%
         }
         sbSliderDelays.Append("]");
         
     %>
    </div>
</div>
    <script type="text/javascript">   
    
    var slideShowIconButton = <%=ShowIconButton.ToString().ToLowerInvariant() %>;
    var slideFiller = <%=sbSliderDelays.ToString() %>;//[{ image: "/images/1.jpg", delay: "2500", link: "1" }, { image: "/images/2.jpg", delay: "2500", link: "2" }, { image: "/images/3.jpg", delay: "2500", link: "3" }, { image: "/images/4.jpg", delay: "2500", link: "4"}];
    
    var slideContainer, slideControl;
    var s_f_count;
    var s_f_currentIndex, s_f_nextIndex;
    var s_current, s_next, s_c_surrent, s_c_next;
    var s_callIndex;
    var s_timer;

    function elSlider(s_id) {  
        try{
        slideContainer = $("#" + s_id + "");
        slideContainer.after('<div class="slideimgloading"><%=this.GetMetadata(".Filed_Load").SafeHtmlEncode() %></div>');    
        
        buildSlider();
        preloadImg();  
        }catch(e){}                
    }
    
    function startSlider()
    {      
        try{          
        if (!s_f_currentIndex) { s_f_currentIndex = s_f_count - 1; s_f_nextIndex = 0; }  
        slideProcess();
        }catch(e){}    
    }

    function buildSlider()
    {
        s_f_count = slideFiller.length;
        slideContainer.after('<div class="sc_wrapper"><div class="sc_container"><ul id="slidecontrols" style="display:none"></ul></div></div>');
        slideControl = $("#slidecontrols");
                
        $.each(slideFiller, function(e_i, e_n) {
            var s_css = e_i == 0 ? ' class="first current"' : e_i==slideFiller.length-1?' class="last"':'';
            
            slideControl.append('<li' + s_css + '><a href="javascript:void(0);" onclick="slideCut(' + e_i + ')">' + (slideShowIconButton?'&nbsp;':(e_i + 1)) + '</a></li>');
        });                
        
        $(".current",slideContainer).css("opacity", "1.0");
    }

    function slideCut(s_index) {
        try{
        clearTimeout(s_timer);
        s_f_nextIndex = s_index;
        slideProcess();
        }catch(e){}    
    }

    function slideProcess() {
        try{
        clearTimeout(s_timer);
        callSwicth();
        s_f_nextIndex = s_f_nextIndex + 1 < s_f_count ? s_f_nextIndex + 1 : 0;
        s_timer = setTimeout(slideProcess, slideFiller[s_f_currentIndex].delay < 2000 ? 2000 : slideFiller[s_f_currentIndex].delay);
        }catch(e){}    
    }

    function callSwicth() {
        try{
        slideSwicth();
        s_f_currentIndex = s_f_nextIndex;
        }catch(e){}    
    }

    function slideSwicth() {
        try{
        s_current = slideContainer.find("div:nth-child(" + (s_f_currentIndex + 1) + ")");
        s_c_surrent = slideControl.find("li:nth-child(" + (s_f_currentIndex + 1) + ")");
        if (s_current.length == 0) s_current = slideContainer.find("div:last");
        if (s_c_surrent.length == 0) s_c_surrent = slideControl.find("li:last");

        s_next = slideContainer.find("div:nth-child(" + (s_f_nextIndex + 1) + ")");
        s_c_next = slideControl.find("li:nth-child(" + (s_f_nextIndex + 1) + ")");
        s_current.addClass('prev');
        s_next.css({ opacity: 0.0 }).addClass("current").animate({ opacity: 1.0 }, 1000,"linear", function() { s_current.removeClass("current prev"); });

        s_c_surrent.removeClass("current");
        s_c_next.addClass("current");
        }catch(e){}    
    }


    var checknum=0;
    function preloadImg(){     
        try{
            checknum++;
            var loaded = true;
            if(s_timer) clearTimeout(s_timer);

            $.each(slideContainer.find("img"),function(i,n){
                if(!n.complete)
                {
                s_timer = setTimeout(preloadImg,1000); 
                loaded = false;
                return false;
                }
            });
            if(loaded || checknum==5 )
            {
            if(s_timer) clearTimeout(s_timer);
            slideContainer.find("div").show();
            slideControl.show();
            $(".slideimgloading").remove();
            startSlider();
            }
        }catch(e){}    
   }
   
    $(function() {  
        try{      
        elSlider('imageslide-holder');   
        }catch(e){}         
    });  
</script>
