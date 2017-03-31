<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<script type="text/C#" runat="server">
    private string MetaPath { get; set; } 
    protected override void OnInit(EventArgs e) {
        this.MetaPath = this.ViewData["MetaPath"] as string;
        base.OnInit(e);
    }
</script>

<div class="TopContent">
    <div class="TopContentWrapper">
        <div class="topContentMain">
            <a class="Button closeTopContent" href="javascript:void(0)" title="<%= this.GetMetadata(".CloseTitle") %>"><%= this.GetMetadata(".Close") %></a>
            <ul class="topContentList">
                <% 
                    string[] table1paths = Metadata.GetChildrenPaths(MetaPath);
                    string HtmlV;
                    for (int i = 0; i < table1paths.Length; i++) {
                        HtmlV = Metadata.Get(string.Format("{0}.Html", table1paths[i])).DefaultIfNullOrEmpty(" ");
                %>
                    <li class="topContent_item">
                        <div class="topContent_Container"><%=HtmlV %></div>
                    </li>
                <% } %>
            </ul>
        </div>
    </div>
</div>

<script type="text/javascript">
    function getCookieValue(objname) {
        var arrstr = document.cookie.split("; ");
        for(var i = 0;i < arrstr.length;i ++){
            var temp = arrstr[i].split("=");
            if(temp[0] == objname) return unescape(temp[1]);
        }
    }
    function setCookieValue(name,value) {
        var exp = new Date(); 
        exp.setTime(exp.getTime() + 24*60*60*1000*2);
        document.cookie = name +"="+value+";path=/;expires=" + exp.toGMTString();
    }
    $(function() {
        if(getCookieValue("hide_topContent_new") == "1"){
            $('html').addClass('NoVideo');
            $(".topContentMain").hide();
        } else {
            $('html').addClass('Video');
            $(".topContentMain").show();
        }
        $(".closeTopContent").click(function () {
            setCookieValue("hide_topContent_new", "1");  
            $(".topContentMain").hide();
            $('html').removeClass('Video').addClass('NoVideo');
        });
    });
</script>