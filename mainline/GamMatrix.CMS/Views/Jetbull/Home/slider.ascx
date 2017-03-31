<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>
<%@ Import Namespace="System.Text" %>
<%@ Import Namespace="CM.Content" %>
<script type="text/C#" runat="server">
    protected string SliderPath
    {
        get;
        set;
    }    
    protected override void OnInit(EventArgs e)
    {
        if (ViewData["SliderPath"] != null && !string.IsNullOrEmpty(ViewData["SliderPath"].ToString()))
        {
            SliderPath = ViewData["SliderPath"].ToString();
        }
        base.OnInit(e);
    }
    protected string GetBackgountStyle(string strImage)
    {
        if (!string.IsNullOrEmpty(strImage))
        {
            strImage = ContentHelper.ParseFirstImageSrc(strImage).DefaultIfNullOrEmpty(strImage);
            if (!string.IsNullOrEmpty(strImage))
            {
                return string.Format(@" style="" background-image:url('{0}')""", strImage);
            }
        }
        
        return string.Empty;
    }
</script>
<%
    StringBuilder sbController = new StringBuilder();
    StringBuilder sbSlider = new StringBuilder();
    string controllerPrevTitle = string.Empty, controllerNextTitle = string.Empty;

    int slideCount = 0;
    
   if (!string.IsNullOrEmpty(SliderPath))
  {
      controllerPrevTitle = this.GetMetadata(SliderPath + ".Controller_Prev_Title").SafeHtmlEncode();
      controllerNextTitle = this.GetMetadata(SliderPath + ".Controller_Next_Title").SafeHtmlEncode();
       
      string[] paths = Metadata.GetChildrenPaths(SliderPath);
      slideCount = paths.Length;
       
      sbController.Append(@"<div class=""slider-numbers""><ul>");
      
      string controllerTitle , title, intro, image, button_url, button_title, button_target, button_content;
      
      string slideHtml =string.Empty, slideHtmlFirst = string.Empty, slideHtmlLast = string.Empty;
      
      for (int i = 0; i < paths.Length; i++)
      {
          controllerTitle = this.GetMetadata(paths[i]+".ControllerTitle").DefaultIfNullOrEmpty(string.Empty).SafeHtmlEncode();
          
          title = this.GetMetadata(paths[i]+".Title").SafeHtmlEncode();
          intro = this.GetMetadata(paths[i]+".Intro").HtmlEncodeSpecialCharactors();
          image = this.GetMetadata(paths[i]+".Image").HtmlEncodeSpecialCharactors();
          
          button_url = this.GetMetadata(paths[i]+".Button_Url").SafeHtmlEncode();
          button_title = this.GetMetadata(paths[i]+".Button_Title").SafeHtmlEncode();
          button_target = this.GetMetadata(paths[i]+".Button_Target").SafeHtmlEncode();
          button_content = this.GetMetadata(paths[i]+".Button_Content").HtmlEncodeSpecialCharactors();

          button_target = string.IsNullOrEmpty(button_target) ? string.Empty : string.Format(@" target=""{0}""", button_target);

          sbController.AppendLine(string.Format(@"<li> <a href=""#slide{0}"" data-slide=""{0}"" title=""{1}"" class=""badge slidenr{0}{2}"">{0}</a></li>", i + 1, controllerTitle, i == 0 ? " activeslide" : string.Empty));

          slideHtml = string.Format(@"<div class=""slide slide{6}{7}{8}""{9}>
                            <div class=""content-slide"">
                                <h3>{0}</h3>
                                <p>{1}</p>
                                <a href=""{2}"" class=""bigbutton"" title=""{3}"" {4}><span class=""button_Right""><span class=""button_Left""><span class=""button_Center""><span class=""GoldButtonText"">{5}</span></span></span></span></a>
                            </div>
                        </div>", title, intro, button_url, button_title, button_target, button_content, i + 1, i == 0 ? " active" : string.Empty, i == paths.Length - 1 ? " last" : string.Empty, GetBackgountStyle(image));          

          sbSlider.AppendLine(slideHtml);

          if (i == 0)
          {
              slideHtmlFirst = string.Format(@"<div class=""slide slide{6}""{7}>
                            <div class=""content-slide"">
                                <h3>{0}</h3>
                                <p>{1}</p>
                                <a href=""{2}"" class=""bigbutton"" title=""{3}"" {4}><span class=""button_Right""><span class=""button_Left""><span class=""button_Center""><span class=""GoldButtonText"">{5}</span></span></span></span></a>
                            </div>
                        </div>", title, intro, button_url, button_title, button_target, button_content, i + 1, GetBackgountStyle(image));
          }
          else if (i == paths.Length - 1)
          {
              slideHtmlLast = string.Format(@"<div class=""slide slide{6}""{7}>
                            <div class=""content-slide"">
                                <h3>{0}</h3>
                                <p>{1}</p>
                                <a href=""{2}"" class=""bigbutton"" title=""{3}"" {4}><span class=""button_Right""><span class=""button_Left""><span class=""button_Center""><span class=""GoldButtonText"">{5}</span></span></span></span></a>
                            </div>
                        </div>", title, intro, button_url, button_title, button_target, button_content, i + 1, GetBackgountStyle(image));
          }
      }
      sbController.Append("</ul></div>");

      sbSlider.Insert(0, slideHtmlLast);
      sbSlider.AppendLine(slideHtmlFirst);
  } %>
<%=sbController.ToString()%>
<div  class="slider-container"> <%=sbSlider.ToString()%> </div>
<div class="carousel-nav">
  <div class="align"> <a class="carousel-control left" href="#myCarousel" data-slide="prev" title="<%=controllerPrevTitle %>">‹</a> </div>
  <div class="align"> <a class="carousel-control right" href="#myCarousel" data-slide="next" title="<%=controllerNextTitle %>">›</a> </div>
</div>
<ui:MinifiedJavascriptControl runat="server" Enabled="true" AppendToPageEnd="true">
<script type="text/javascript">
    var Slider = {};
    Slider.NumberClick = function () {
        var _this = $(this);
        _this.blur();
        Slider.currentIndex = _this.data("slide") || _this.attr('data-slide');
        Slider.SwitchSlide();        
        return false;
    };
    Slider.ControllerClick = function () {
        var _this = $(this);
        _this.blur();
        var direction = _this.data("slide") || _this.attr('data-slide');

        if (direction == 'prev') {
            Slider.currentIndex = Slider.currentIndex - 1;
            if (Slider.currentIndex < 1)
                Slider.currentIndex = Slider.count;
        }
        else {
            Slider.currentIndex = Slider.currentIndex + 1;
            if (Slider.currentIndex > Slider.count)
                Slider.currentIndex = 1;
        }
        Slider.SwitchSlide();
        return false;
    };
    Slider.SwitchSlide = function () {
        Slider.slideContainer.animate({ "left": 0 - Slider.slideWidth * Slider.currentIndex  + this.adjustWidth }, "fast","linear");
        Slider.numberContainer.find("a").removeClass("activeslide");
        Slider.numberContainer.find("a.slidenr" + Slider.currentIndex).addClass("activeslide");
        Slider.slideContainer.find("div.slide").removeClass("active");
        if(Slider.count == Slider.currentIndex)
        {
            Slider.slideContainer.find("div.slide" + Slider.currentIndex).eq(1).addClass("active");   
        }
        else
        {
            Slider.slideContainer.find("div.slide" + Slider.currentIndex).eq(0).addClass("active");        
        }
    };
    Slider.Init = function () {
        this.count = $("#slider").find(".slider-numbers").Length;
        this.numberContainer = $("#slider").find(".slider-numbers");
        this.slideContainer = $("#slider").find(".slider-container");
        $("#slider").find(".slide").width($("#slider").width());
        this.slideWrapper = this.slideContainer.parent();
        this.slideWidth = this.slideContainer.find("div.slide").width();
        this.adjustWidth =0;      
        this.currentIndex = 1;
        this.numberContainer.find("a").unbind("click");
        this.numberContainer.find("a").bind("click", this.NumberClick);
    }; 
    Slider.GoNext = function(){
        var i = this.currentIndex ++ ; 
        var num = $(".slider-numbers li").length;
        if (this.currentIndex > num)  i=0;
        $("#slider a.badge").eq(i).click();  
    };
    function PreventClick(evt) {
        evt.preventDefault();
        return false;
    }
    $(window).resize(function(){
      Slider.Init();
      $("#slider a.badge").eq(0).click();
    });
    $(document).ready(function () {
        Slider.Init();
        setInterval(function(){
          Slider.GoNext();
        },8000);
    });
</script>
</ui:MinifiedJavascriptControl>