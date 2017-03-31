<%@ Page Title="Content Navigation" Language="C#" Inherits="CM.Web.ViewPageEx<dynamic>" %>

<%@ Import Namespace="CM.db" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <script language="javascript" type="text/javascript" src="<%= Url.Content("~/js/jquery/jquery-1.5.2.min.js") %>"></script>
    <script language="javascript" type="text/javascript" src="<%= Url.Content("~/js/jquery/jquery.tree/lib/jquery.cookie.js") %>"></script>
    <script language="javascript" type="text/javascript" src="<%= Url.Content("~/js/jquery/jquery.tree/jquery.tree.js") %>"></script>
    <script language="javascript" type="text/javascript" src="<%= Url.Content("~/js/jquery/jquery.tree/plugins/jquery.tree.cookie.js") %>"></script>
    <script language="javascript" type="text/javascript" src="<%= Url.Content("~/js/jquery/jquery.string.js") %>"></script>
    <link rel="stylesheet" type="text/css" href="<%= Url.Content("~/js/jquery/jquery.tree/themes/default/style.css") %>" />
    <link rel="stylesheet" type="text/css" href="<%= Url.Content( "~/App_Themes/AdminConsole/ContentMgt/Tree.css") %>" />
</head>


<body>
    <div id="toolbar" align="center">
        <%: Html.DropDownList("cmSite"
            , new SelectList(this.ViewData["Domains"] as IEnumerable, "DistinctName", "DisplayName")
            , new { id = "cmSite", value = Request["distinctName"] }
            ) %>
        <a class="icoRefresh" href="javascript:void(0)" target="_self">Refresh</a>
    </div>
    <div id="content-tree">
    </div>

    <ui:ExternalJavascriptControl runat="server">
        <script language="javascript" type="text/javascript">
            function ContentTreeNavigation() {
                self.ContentTreeNavigation = this;

                this.cache = new Image();
                this.cache.src = "/images/icon/loading.gif";

                this.onBtnRefreshClick = function () {
                    $('#cmSite').attr('disabled', true);
        <% if (string.IsNullOrWhiteSpace(Request.QueryString["privateMetadata"]))
           { %>
        var getTreeJsonAction = '<%= this.Url.RouteUrl("ContentMgt", new { @action="GetTreeJson"}).SafeJavascriptStringEncode() %>?distinctName=';
        <% }
           else %>
        <% { %>
        var getTreeJsonAction = '<%= this.Url.RouteUrl("ContentMgt", new { @action="GetMetadataTreeJson", @privateMetadata= Request.QueryString["privateMetadata"], @distinctName = Request["distinctName"] }).SafeJavascriptStringEncode() %>&';
        <% } %>
        $("#content-tree").empty().tree({
            data: {
                type: "json",
                opts: { method: "GET", url: (getTreeJsonAction + $('#cmSite').val()), cache: true, distinctName: $('#cmSite').val() }
            },
            ui: {
                dots: false,
                theme_name: "default"
            },
            types: {
                "default": {
                    clickable: true,
                    renameable: true,
                    deletable: true,
                    creatable: true,
                    draggable: false,
                    max_children: -1,
                    max_depth: -1,
                    valid_children: "all",

                    icon: {
                        image: false,
                        position: false
                    }
                }
            },
            rules: {
                multiple: false
            },
            callback: {
                ondata: function (data, tree) {
                    $('#cmSite').attr('disabled', false);
                    return self.ContentTreeNavigation.prepareData(data);
                }
            },
            plugins: {
                cookie: { prefix: "jstree_" }
            }
        });
    };

    this.prepareData = function (array) {
        if (array == null)
            return;
        if (array.success == false) {
            alert(array.error);
            return;
        }

        if (array instanceof Array) {
            for (var i = 0; i < array.length; i++) {
                var cssCls = "non-inherted";
                if (array[i].inherited == true) cssCls = "inherted";
                if (array[i].overrode == true) cssCls = "overrode";
                if (array[i].disabled == true) cssCls += " disabled";

                array[i].data.cssClass = cssCls;
                array[i].data.title = array[i].data.title.htmlEncode();
                switch (array[i].type) {
                    case "site": array[i].data.icon = "/images/icon/house.png"; break;
                    case "site-manager": array[i].data.icon = "/images/icon/application_home.png"; break;
                    case "site-route": array[i].data.icon = "/images/icon/page_link.gif"; break;
                    case "site-region": array[i].data.icon = "/images/icon/page_world.png"; break;
                    case "site-content": array[i].data.icon = "/images/icon/table_edit.png"; break;
                    case "payment-methods": array[i].data.icon = "/images/icon/creditcards.png"; break;
                    case "search-code": array[i].data.icon = "/images/icon/zoom.png"; break;
                    case "search-metadata": array[i].data.icon = "/images/icon/zoom.png"; break;
                    case "directory": array[i].data.icon = "/images/icon/folder.png"; break;
                    case "partialview": array[i].data.icon = "/images/icon/partialview.gif"; break;
                    case "view": array[i].data.icon = "/images/icon/view.gif"; break;
                    case "none": array[i].data.icon = "/images/icon/page_white.png"; break;
                    case "page": array[i].data.icon = "/images/icon/layout_sidebar.png"; break;
                    case "pagetemplate": array[i].data.icon = "/images/icon/pagetemplate.gif"; break;
                    case "metadata": array[i].data.icon = "/images/icon/icon_component.gif"; break;
                    case "casino": array[i].data.icon = "/images/icon/casino.png"; break;
                    case "staticcontent": array[i].data.icon = "/images/icon/icon_airmail.gif"; break;
                    case "htmlsnippet": array[i].data.icon = "/images/icon/html.png"; break;
                    case "terms-conditions": array[i].data.icon = "/images/icon/script.png"; break;

                    default: /*alert(array[i].type);*/ break;
                }
                delete array[i].type;

                array[i].data.attributes = {};
                if (array[i].data.id) {
                    array[i].attributes = {};
                    array[i].attributes.id = array[i].data.id;
                }
                array[i].data.attributes.href = "javascript:void(0)";
                array[i].data.attributes.target = "self";
                if (array[i].action != null)
                    array[i].data.attributes.onclick = "self.ContentTreeNavigation.onTreeClick('" + array[i].action.scriptEncode() + "', event)";
                this.prepareData(array[i].children);
            }
        }
        return array;
    }

    this.onTreeClick = function (action, e) {
        if (parent && parent.onNavTreeClicked)
            parent.onNavTreeClicked(action);
    };

    this.onResize = function () {
        $('#content-tree').height($(document.body).height() - $('#toolbar').height());
    };

    this.init = function () {
        this.onBtnRefreshClick();
        $('a.icoRefresh').bind('click', this, function (e) {
            localStorage.clear();
            e.data.onBtnRefreshClick();
        });

        $('#cmSite').bind('change', this, function (e) { e.data.onBtnRefreshClick(); });

        this.onResize();
        $(window).resize(this.onResize);

        <% if (!string.IsNullOrWhiteSpace(Request.QueryString["privateMetadata"]))
           { %>
        $('#cmSite').css('display', 'none');
        <% } %>
    };



    this.init();
}
$(document).ready(function () { new ContentTreeNavigation(); });
        </script>
    </ui:ExternalJavascriptControl>

</body>
</html>



