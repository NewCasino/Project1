<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<CM.db.cmSite>" %>

<div id="files-links" class="site-mgr-links">
    <ul>
        <li>
            <a href="<%= this.Url.RouteUrl( "HistoryViewer", new {  
                        @action = "Dialog",
                        @distinctName = this.Model.DistinctName.DefaultEncrypt(),
                        @relativePath = "/.config/site_files.setting".DefaultEncrypt(),
                        @searchPattner = "",
                        } ).SafeHtmlEncode()  %>"
                target="_blank" class="history">Change history...</a>
        </li>
    </ul>
</div>
<hr class="seperator" />
<div class="ui-widget">
    <div style="margin-top: 20px; padding: 0pt 0.7em;" class="ui-state-highlight ui-corner-all">
        <p>
            <span style="float: left; margin-right: 0.3em;" class="ui-icon ui-icon-info"></span>
            You can upload the following files here.
        <ul>
            <li><strong>favicon.ico</strong> : <em>Icon to be presented in the address bar of web browser.</em></li>
            <li><strong>favicon-32.png</strong> : <em>32px X 32px PNG image.</em></li>
            <li><strong>favicon-48.png</strong> : <em>48px X 48px PNG image.</em></li>
            <li><strong>favicon-180.png</strong> : <em>180 X 180 PNG image.</em></li>
            <li><strong>apple-touch-icon.png</strong> : <em>57px X 57px PNG image. Thumbnail of WebClip Bookmarks on iOS(iPhone/iPad).</em></li>
            <li><strong>apple-touch-icon-57x57-precomposed.png</strong> : <em>57px X 57px PNG image.</em></li>
            <li><strong>apple-touch-icon-72x72-precomposed.png</strong> : <em>72px X 72px PNG image.</em></li>
            <li><strong>apple-touch-icon-76x76-precomposed.png</strong> : <em>76px X 76px PNG image.</em></li>
            <li><strong>apple-touch-icon-114x114-precomposed.png</strong> : <em>114px X 114px PNG image.</em></li>
            <li><strong>apple-touch-icon-120x120-precomposed.png</strong> : <em>120px X 120px PNG image.</em></li>
            <li><strong>apple-touch-icon-152x152-precomposed.png</strong> : <em>152px X 152px PNG image.</em></li>
            <!--setup image-->
            <li><strong>Default.png</strong> : <em>320px X 460px PNG image. Mobile Cover Image</em></li>
            <li><strong>Default-landscape.png</strong> : <em>1024px X 748px PNG image.</em></li>
            <li><strong>Default-portrait.png</strong> : <em>768px X 1004px PNG image.</em></li>
            <li><strong>Default@2x.png</strong> : <em>640 X 960 PNG image.</em></li>
            <li><strong>Default-568@2x.png</strong> : <em>640 X 1096 PNG image.</em></li>
            <li><strong>Default-iphone6@2x.png</strong> : <em>750 X 1294 PNG image.</em></li>
            <li><strong>Default-iphone6-Landscape@2x.png</strong> : <em>1334 X 710 PNG image.</em></li>
            <li><strong>Default-iphone6plus@2x.png</strong> : <em>1242 X 2148 PNG image.</em></li>
            <li><strong>Default-iphone6plus-Landscape@2x.png</strong> : <em>2208 X 1182 PNG image.</em></li>
            <li><strong>Default-ipad@2x.png</strong> : <em>1536x2008 PNG image.</em></li>
            <li><strong>Default-ipad-Landscape@2x.png</strong> : <em>2048x1496 PNG image.</em></li>

            <li><strong>robots.txt</strong> : <em>Plain text file put on the site to tell search robots which pages you would like them not to visit.</em></li>
            <li><strong>urllist.txt</strong> : <em>Plain text sitemap, some search engine like Yahoo analyse this file.</em></li>
            <li><strong>sitemap.txt</strong> : <em>Plain text sitemap.</em></li>
            <li><strong>sitemap.xml</strong> : <em>Xml file to inform search engines about URLs on a website that are available for crawling.</em></li>
            <li><strong>sitemap.xml.gz</strong> : <em>Compressed sitemap.xml, which are supported by all major search engines. </em></li>
            <li><strong>sitemap.html</strong> : <em>Html based sitemap</em></li>
            <li><strong>sitemap_images.xml</strong> : <em>Sitemap for images</em></li>
            <li><strong>sitemap_video.xml</strong> : <em>Sitemap for videos</em></li>
            <li><strong>sitemap_news.xml</strong> : <em>Sitemap for news</em></li>
            <li><strong>ror.xml</strong> : <em>ROR promotes the concept of structured feeds enabling search engines to complement text search with structured information to better understand meaning.</em></li>
            <li><strong>LiveSearchSiteAuth.xml</strong> : <em>For Bing Search WebMaster.</em></li>
            <li><strong>google????????????????.html</strong> : <em>For Google Search WebMaster. (i.e. google738829e6d51e861c.html)</em></li>
            <li><strong>yandex_????????????????.txt</strong> : <em>For Yandex Search WebMaster. (i.e. yandex_7267636dcf88fed1.txt)</em></li>
        </ul>
        </p>
    </div>
</div>
<br />
<div id="uploader"></div>



<% using (Html.BeginRouteForm("SiteManager"
       , new { @action = "PrepareUpload", @distinctName = this.Model.DistinctName.DefaultEncrypt() }
       , FormMethod.Post
       , new { @id = "formPrepareUpload" }))
   { %>
<input type="hidden" name="filename" />
<input type="hidden" name="size" />
<input type="hidden" name="path" />
<% } %>

<ui:ExternalJavascriptControl runat="server" AutoDisableInPostbackRequest="true">
    <script language="javascript" type="text/javascript">
        function TabFiles(viewEditor) {
    <%-- the method is called from flash to prepare the uploading --%>
    this.prepareUpload = function (filename, size) {
        if (self.startLoad) self.startLoad();

        $('#formPrepareUpload :input[name="filename"]').val(filename);
        $('#formPrepareUpload :input[name="size"]').val(size);
        $('#formPrepareUpload :input[name="path"]').val(this.currentPath);

        var options = {
            type: 'POST',
            dataType: 'json',
            success: function (data) {
                if (self.stopLoad) self.stopLoad();
                if (!data.success) { alert(data.error); return; }

                <%-- invoke the flash method to start upload --%>
                try {
                    document.getElementById('ctlFileUploader').startUpload(data.key);
                }
                catch (e) { alert(e); }
            }
        };
        $('#formPrepareUpload').ajaxForm(options);
        $('#formPrepareUpload').submit();
    };

    this.init = function () {
        var image = new Image();
        try {
            image.src = '<%= this.Url.RouteUrl( "SiteManager", new { @action = "PartialUpload" }).SafeJavascriptStringEncode() %>';
        }
        catch (e) { }
        var flashvars = {
            cmSession: '<%= Profile.AsCustomProfile().SessionID.SafeJavascriptStringEncode() %>',
            PartialUploadUrl: image.src
        };
        var params = {
            menu: "false",
            wmode: "transparent",
            allowScriptAccess: "always",
            allowNetworking: "all"
        };
        var attributes = {
            id: "ctlFileUploader",
            name: "ctlFileUploader"
        };

        swfobject.embedSWF("/images/FileUploader.swf", "uploader", "100%", "70", "10.0.0", "/images/expressInstall.swf", flashvars, params, attributes);

        self.prepareUpload = this.prepareUpload;

        $('#files-links a.history').click(function (e) {
            var wnd = window.open($(this).attr('href'), null, "width=1000,height=700,toolbar=no,location=no,directories=0,status=yes,menubar=no,copyhistory=no");
            if (wnd) e.preventDefault();
        });
    };

    this.init();
}
    </script>
</ui:ExternalJavascriptControl>
