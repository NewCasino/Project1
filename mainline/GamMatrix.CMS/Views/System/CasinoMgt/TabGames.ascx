<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<CM.db.cmSite>" %>

<div id="properties-links" class="casino-mgt-operations">
    <ul>
        <li><a href="javascript:void(0)" target="_self" class="refresh">Refresh</a></li>
        <li>|</li>
        <li><a href="javascript:void(0)" target="_self" class="clearcache">Reload Cache</a></li>
    </ul>
    <div id="casino_type_radio">
	    <input type="radio" id="casino_netent" value="NetEnt" name="radio" checked="checked" /><label for="casino_netent">NetEnt</label>
        <%-- 
	    <input type="radio" id="casino_microgaming" name="radio" value="Microgaming" /><label for="casino_microgaming">Micro Gaming</label>
	    <input type="radio" id="casino_ctxm" value="CTXM" name="radio" /><label for="casino_ctxm">CTXM</label>
        <input type="radio" id="casino_igt" value="IGT" name="radio" /><label for="casino_igt">IGT</label>
        <input type="radio" id="casino_vig" value="ViG" name="radio" /><label for="casino_vig">ViG</label>
        --%>
    </div>    
</div>
<hr />

<div id="operation_wrapper">
</div>

<div id="game_list_wrapper">
</div>

<script type="text/javascript" language="javascript">
function TabGames() {
    this.loadGameList = function (vendor) {
        if (self.startLoad) self.startLoad();
        self._scrollTop = $(self).scrollTop();

        var url = '<%= this.Url.RouteUrl("CasinoMgt", new { @action = "GameList", @distinctName = this.Model.DistinctName.DefaultEncrypt() }).SafeJavascriptStringEncode() %>';
        url = url + '?vendor=' + encodeURIComponent(vendor);

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

            var url = '<%= this.Url.RouteUrl("CasinoMgt", new { @action = "VendorOperation", @distinctName = this.Model.DistinctName.DefaultEncrypt() }).SafeJavascriptStringEncode() %>';
            url = url + '?vendor=' + encodeURIComponent(e.data.vendor);
            $('#operation_wrapper').html('').load(url);
        });

        $("div.casino-mgt-operations a.refresh").bind('click', this, function (e) { e.preventDefault(); e.data.refresh(); });

        $("div.casino-mgt-operations a.clearcache").bind('click', this, function (e) {
            e.preventDefault();
            var url = '<%= this.Url.RouteUrl("CasinoMgt", new { @action = "ClearCache", @distinctName = this.Model.DistinctName.DefaultEncrypt() }).SafeJavascriptStringEncode() %>';
            jQuery.getJSON(url, null, function (data) {
                if (!data.success) { alert(data.error); return; }
                alert('Cache has been reloaded!');
            });
        });

        setTimeout(function () {
            $("#casino_type_radio :radio[value='NetEnt']").click().button("refresh");
        }, 500);

    };

    this.init();
};
</script>