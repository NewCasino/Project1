<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>
<script type="text/javascript" src="/js/saloon/js/jquery.freshline.plugins.min.js"></script>
<script type="text/javascript" src="/js/saloon/js/jquery.freshline.saloon.min.js"></script>
<link rel="stylesheet" type="text/css" href="/js/saloon/css/settings.css" media="screen">

<script type="text/C#" runat="server">
    protected string SliderPath
    {
        get;
        set;
    }
    
    private int _width = 0;
    private int Width {
        get {
            if (this.ViewData["SlideWidth"] == null || !int.TryParse(this.ViewData["SlideWidth"].ToString(), out _width))
            {
                _width = 960;
            }
            return _width;
        }
    }
    
    private int _height = 0;
    private int Height
    {
        get
        {
            if (this.ViewData["SlideHeight"] == null || !int.TryParse(this.ViewData["SlideHeight"].ToString(), out _height))
            {
                _height = 394;
            }
            return _height;
        }
    }
    
    protected override void OnInit(EventArgs e)
    {
        if (ViewData["SliderPath"] != null && !string.IsNullOrEmpty(ViewData["SliderPath"].ToString()))
        {
            SliderPath = ViewData["SliderPath"].ToString();
        }
        base.OnInit(e);
    }
</script>
    

<div class="banner_rotator">
<ul style="visibility:hidden">
<%
    if (!string.IsNullOrEmpty(SliderPath))
    {
        string[] paths = Metadata.GetChildrenPaths(SliderPath);
        if (paths.Length > 0)
        {
            string name, url, urlTitle, target, image,
                wipeRightContentHtml, wipeRightStyle,
                wipeLeftContentHtml, wipeLeftStyle,
                wipeUpContentHtml, wipeUpStyle,
                wipeDownContentHtml, wipeDownStyle;
            
            foreach(string path in paths)
            {
                name = path.Substring(path.LastIndexOf("/") + 1).ToLowerInvariant();
                url = Metadata.Get(string.Format("{0}.Url", path)).HtmlEncodeSpecialCharactors().DefaultIfNullOrEmpty("#");
                target = Metadata.Get(string.Format("{0}.Target", path)).DefaultIfNullOrEmpty("_self").SafeHtmlEncode();
                urlTitle = Metadata.Get(string.Format("{0}.UrlTitle", path)).DefaultIfNullOrEmpty(string.Empty).SafeHtmlEncode();
                image = Metadata.Get(string.Format("{0}.Image", path)).HtmlEncodeSpecialCharactors().DefaultIfNullOrEmpty("#");

                wipeRightContentHtml = Metadata.Get(string.Format("{0}.WipeRightContentHtml", path)).HtmlEncodeSpecialCharactors();
                wipeRightStyle = Metadata.Get(string.Format("{0}.WipeRightStyle", path)).HtmlEncodeSpecialCharactors();
                wipeLeftContentHtml = Metadata.Get(string.Format("{0}.WipeLeftContentHtml", path)).HtmlEncodeSpecialCharactors();
                wipeLeftStyle = Metadata.Get(string.Format("{0}.WipeLeftStyle", path)).HtmlEncodeSpecialCharactors();
                wipeUpContentHtml = Metadata.Get(string.Format("{0}.WipeUpContentHtml", path)).HtmlEncodeSpecialCharactors();
                wipeUpStyle = Metadata.Get(string.Format("{0}.WipeUpStyle", path)).HtmlEncodeSpecialCharactors();
                wipeDownContentHtml = Metadata.Get(string.Format("{0}.WipeDownContentHtml", path)).HtmlEncodeSpecialCharactors();
                wipeDownStyle = Metadata.Get(string.Format("{0}.WipeDownStyle", path)).HtmlEncodeSpecialCharactors();
                %>
        <li><%= image%>
		<div class="creative_layer">            <%if (!string.IsNullOrEmpty(wipeRightContentHtml)) { %>
            <div class="wiperight" style="<%=wipeRightStyle%>"><%=wipeRightContentHtml %></div>
            <%} %>

            <%if (!string.IsNullOrEmpty(wipeLeftContentHtml))
              { %>
            <div class="wipeleft" style="<%=wipeLeftStyle%>"><%=wipeLeftContentHtml%></div>
            <%} %>

            <%if (!string.IsNullOrEmpty(wipeDownContentHtml))
              { %>
            <div class="wipedown" style="<%=wipeDownStyle%>"><%=wipeDownContentHtml%></div>
            <%} %>

            <%if (!string.IsNullOrEmpty(wipeUpContentHtml))
              { %>
            <div class="wipeup" style="<%=wipeUpStyle%>"><%=wipeUpContentHtml%></div>
            <%} %>            

		</div>
	</li>
                
                <%
            }
        }
    }

 %>
</ul>
</div>
<script type="text/javascript">


    $(document).ready(function () {
        //$.noConflict();

        $('.banner_rotator').saloon(
						{
						    width: <%=Width %>,
						    height: <%=Height %>,
						    speed: 1600,
						    delay: 5000,
						    direction: "vertical",
						    thumbs: "bottom",
						    grab: "on",
						    thumbsYOffset: 20,
						    thumbsXOffset: 4
						});
    });
</script>