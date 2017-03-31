<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<CM.db.cmSite>" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="CasinoEngine" %>
<div id="properties-links" class="casino-mgt-operations">
    <ul>
        <li><a href="javascript:void(0)" target="_self" class="refresh">Refresh</a></li>
    </ul>
    <div id="casino_type_radio">
        <%
            VendorID[] vendors = CasinoEngineClient.GetEnabledVendors(this.Model);
            foreach (VendorID vendor in vendors)
            { %>
            <input type="radio" id="casino_<%= vendor %>" value="<%= vendor %>" name="radio" />
            <label for="casino_<%= vendor %>"><%= vendor %></label>
        <%  } %>
	    
    </div>    
</div>
<hr />

<div id="game_list_wrapper">
</div>

<script type="text/javascript" language="javascript">
function TabGames() {
    this.loadGameList = function (vendor) {
        if (self.startLoad) self.startLoad();
        self._scrollTop = $(self).scrollTop();

        var url = '<%= this.Url.RouteUrl("CasinoGameMgt", new { @action = "GameList", @distinctName = this.Model.DistinctName.DefaultEncrypt() }).SafeJavascriptStringEncode() %>';
        url = url + '?vendor=' + encodeURIComponent(vendor);

        $('#game_list_wrapper').html('<img src="/images/icons/loading.gif" />');
        $('#game_list_wrapper').load(url, function () {
            if (self.stopLoad) self.stopLoad();
            $(self).scrollTop(self._scrollTop);
        });
    };
    this.refresh = function () {
        this.loadGameList(this.vendor);
    };
    this.init = function () {
        $("#casino_type_radio").buttonset();

        $("#casino_type_radio :radio").bind('click', this, function (e) {
            e.preventDefault();
            e.data.vendor = $(this).val();
            e.data.loadGameList($(this).val());
        });

        $("div.casino-mgt-operations a.refresh").bind('click', this, function (e) { e.preventDefault(); e.data.refresh(); });

        setTimeout(function () {
            $("#casino_type_radio :radio:first").click().attr('checked', true).button("refresh");
        }, 500);

    };

    this.init();
};

</script>