<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<CM.db.cmSite>" %>

<div id="properties-links" class="casino-categories-operations">
    <ul>
        <li><a href="javascript:void(0)" target="_self" class="save">Save</a></li>
        <li>|</li>
        <li><a href="javascript:void(0)" target="_self" class="refresh">Refresh</a></li>
        <li>|</li>        
        <li><a href="javascript:void(0)" target="_self" class="clearcache">Reload Cache</a></li>
    </ul>
    
    <div id="casino_type_checkbox">
        Vendors:
	    <input type="checkbox" id="casino_netent1" value="NetEnt" name="avaliable_type" checked="checked" /><label for="casino_netent1">NetEnt</label>
        <%-- 
	    <input type="checkbox" id="casino_microgaming1" name="avaliable_type" value="Microgaming" checked="checked"/><label for="casino_microgaming1">Micro Gaming</label>
	    <input type="checkbox" id="casino_ctxm1" value="CTXM" name="avaliable_type" checked="checked"/><label for="casino_ctxm1">CTXM</label>
        <input type="checkbox" id="casino_igt1" value="IGT" name="avaliable_type" checked="checked"/><label for="casino_igt1">IGT</label>
        <input type="checkbox" id="casino_vig1" value="ViG" name="avaliable_type" checked="checked"/><label for="casino_vig1">ViG</label>
        --%>
    </div>    
</div>
<hr />
<div id="tree-wrapper">
    
</div>

<div id="content-wrapper">
<div class="title-bar" align="center" valign="middle">
    <select>
        <option value="NetEnt">NetEnt</option>
        <%-- 
        <option value="Microgaming">Microgaming</option>
        <option value="CTXM">CTXM</option>
        <option value="IGT">IGT</option>
        <option value="ViG">ViG</option>
        --%>
    </select>

    <input type="checkbox" id="btnHideAssignedGames" checked="checked" />
    <label for="btnHideAssignedGames"><u>Hide assigned games</u></label>
</div>

<ul class="list">
</ul>

</div>
<div style="clear:both"></div>

<script id="game-template" type="text/html">
<#
    var d=arguments[0];

    for(var i=0; i < d.length; i++)     
    {        
#>
    <li ondragstart="return false" class="game <#= d[i].VendorID.toLowerCase() #>" gameid="<#= d[i].GameID.htmlEncode() #>" title="<#= d[i].GameID.htmlEncode() #>" vendor="<#= d[i].VendorID #>">
        <span><#= d[i].VendorID #> - <#= d[i].Title #></span>
        <div class="toolbar">
            <a class="delete" href="javascript:void(0)" title="Remove" onclick="onLnkRemoveClick(event)"></a>
        </div>
    </li>
<#  }  #>
</script>


<ul id="context-menu">
    <li><a class="lnkCreateCategory" href="javascript:void(0)">Create Categotry</a></li>
    <li><a class="lnkCreateGroupedGames" href="javascript:void(0)">Create Grouped Games</a></li>
</ul>

<script type="text/javascript" language="javascript">
    function generateGUID() {
        var S4 = function () {
            return (((1 + Math.random()) * 0x10000) | 0).toString(16).substring(1);
        };
        return (S4() + S4() + "-" + S4() + "-" + S4() + "-" + S4() + "-" + S4() + S4() + S4());
    }


    function TabCategories() {
        this.isMoveStart = false;
        this.current = null;
        this.floating = null;
        this.onMouseDown = function (e) {
            if (e.data.isMoveStart || e.which != 1)
                return;
            if (e.target == 'javascript:void(0)')
                return;
            e.data.isMoveStart = true;
            e.data.current = $(this);
            $('#content-wrapper .list').css('overflow', 'hidden');

        };
        this.onMouseMoving = function (e) {
            if (!e.data.isMoveStart)
                return;

            if (e.data.floating == null) {
                e.data.floating = $('<ul class="list float-list"></ul>').appendTo(document.body);
                e.data.floating.append(e.data.current.clone(true, true));
                $('li.to-be-moved').removeClass('to-be-moved');
                e.data.current.addClass('to-be-moved');
            }
            e.data.floating.css('left', e.pageX - 30);
            e.data.floating.css('top', e.pageY - 10);

            $('li.place-holder').remove();

            var treeWrapper = $('#tree-wrapper');
            if (e.pageX > treeWrapper.offset().left &&
                e.pageY > treeWrapper.offset().top &&
                e.pageX < treeWrapper.width() + treeWrapper.offset().left) {

                var items = $('#tree-wrapper li.game');
                if (e.data.current.hasClass('grouped-games'))
                    items = $('#tree-wrapper li.category > ul > li');
                var found = false;
                var item = null;
                for (var i = 0; i < items.length; i++) {
                    item = $(items[i]);
                    if (item.offset().top <= e.pageY && e.pageY <= (item.offset().top + item.height())) {
                        found = true;
                        break;
                    }
                }

                if (!found) {
                    items = $('#tree-wrapper li.grouped-games');
                    for (var i = 0; i < items.length; i++) {
                        item = $(items[i]);
                        if (item.offset().top <= e.pageY && e.pageY <= (item.offset().top + item.height())) {
                            found = true;
                            break;
                        }
                    }
                }

                if (found) {
                    if (e.pageY - item.offset().top < item.height() / 2) {
                        $('<li class="place-holder"></li>').insertBefore(item);
                    }
                    else {
                        if (item.hasClass('grouped-games') && !e.data.current.hasClass('grouped-games') )
                            $('<li class="place-holder"></li>').appendTo($('> ul',item));
                        else
                            $('<li class="place-holder"></li>').insertAfter(item);                            
                    }
                }
                else {
                    items = $('#tree-wrapper li.category');
                    for (var i = 0; i < items.length; i++) {
                        item = $(items[i]);
                        if (item.offset().top <= e.pageY && e.pageY <= (item.offset().top + item.height())) {
                            found = true;
                            break;
                        }
                    }

                    if (found) {
                        if ((e.pageY - item.offset().top < item.height() / 2) &&
                            item.prev('li.category') != null) {
                            $('> ul', item.prev('li.category')).append($('<li class="place-holder"></li>'));
                        }
                        else {
                            $('> ul', item).append($('<li class="place-holder"></li>'));
                        }
                    } else {
                        $('#tree-wrapper > ul > li:last > ul').append($('<li class="place-holder"></li>'));
                    }
                }
            }
        };

        this.refresh = function () {
            var url = '<%= this.Url.RouteUrl( "CasinoMgt", new { @action="TreeList", @distinctName = this.Model.DistinctName.DefaultEncrypt() }).SafeJavascriptStringEncode() %>';
            var fun = (function (obj) {
                return function () {
                    syncList();
                    $('#tree-wrapper li.game,#tree-wrapper li.grouped-games').bind('mousedown', obj, obj.onMouseDown);
                };
            })(this);
            $('#tree-wrapper').html('<img src="/images/icon/loading.gif" />').load(url, fun);
        };
        this.onMouseUp = function (e) {
            $('#content-wrapper .list').css('overflow', 'auto');
            // <%-- handle moving --%>
            if (!e.data.isMoveStart)
                return;
            e.data.isMoveStart = false;
            if (e.data.floating != null) {
                if ($('li.place-holder').length > 0) {
                    if( $('#btnHideAssignedGames').is(':checked') )
                        $('li.to-be-moved').hide();
                    $('> li', e.data.floating).detach().insertAfter($('li.place-holder'));
                }
                e.data.floating.remove();
                e.data.floating = null;
            }
            e.data.current = null;
            $('li.place-holder').remove();
            $('li.to-be-moved').removeClass('to-be-moved');
        };


        this.init = function () {
            $("div.casino-categories-operations a.clearcache").bind('click', this, function (e) {
                e.preventDefault();
                var url = '<%= this.Url.RouteUrl("CasinoMgt", new { @action = "ClearCache", @distinctName = this.Model.DistinctName.DefaultEncrypt() }).SafeJavascriptStringEncode() %>';
                jQuery.getJSON(url, null, function (data) {
                    if (!data.success) { alert(data.error); return; }
                    alert('Cache has been reloaded!');
                });
            });

            // <%-- on casino vendor select change --%>
            $('div.title-bar select').bind('change', this, function (e) {
                var url = '<%= this.Url.RouteUrl( "CasinoMgt", new { @action="GetVendorGames", @distinctName = this.Model.DistinctName.DefaultEncrypt() }).SafeJavascriptStringEncode() %>?vendor=';
                url += $(this).val();
                $('#content-wrapper ul.list').html('');

                var fun = (function (o) {
                    return function () {
                        var json = arguments[0];
                        if (!json.success) {
                            alert(json.error);
                            return;
                        }
                        $('#content-wrapper ul.list').html($('#game-template').parseTemplate(json.data));
                        syncList();
                        $('#content-wrapper ul.list li').bind('mousedown', o, o.onMouseDown);
                    }
                })(e.data);

                jQuery.getJSON(url, null, fun);

            });

            $("div.casino-categories-operations a.refresh").bind('click', this, function (e) { e.preventDefault(); e.data.refresh(); });

            $(document.body).bind('mouseup', this, this.onMouseUp);
            $(document.body).bind('mousemove', this, this.onMouseMoving);
            $(window).scroll(this.onWindowScroll);
            $('div.title-bar select').trigger('change');

            this.refresh();

            $('#casino_type_checkbox :input').click(function () { syncList(); });

            // <%-- Context menu --%>
            $(document).bind("contextmenu", function (e) {
                return false;
            });

            $('#context-menu').hide();
            $(document.body).bind('mousedown', function (e) {
                if (e.pageX >= $('#context-menu').position().left &&
                    e.pageY >= $('#context-menu').position().top &&
                    e.pageX < $('#context-menu').position().left + $('#context-menu').width() &&
                    e.pageY < $('#context-menu').position().top + $('#context-menu').height()) {

                }
                else {
                    $('#context-menu').hide();
                }
            });
            $('#tree-wrapper').mouseup(function (e) {
                if (e.which == 3) {
                    $('#context-menu').css('left', e.pageX).css('top', e.pageY);
                    $('#context-menu').show().detach().appendTo(document.body);
                    var tar = $(e.target);
                    while (tar != null && tar.length > 0 && tar[0].nodeName.toLowerCase() != 'li') {
                        tar = tar.parent();
                    }
                    $('#tree-wrapper').data('insert-point', tar);
                }
            });
            $('#context-menu a.lnkCreateCategory').click(function (e) {
                e.preventDefault();
                $('#context-menu').hide();
                var name = window.prompt("Please enter the category name to be created", "");
                if (name == null || name == false || name.toString().length == 0)
                    return;

                var tar = $('#tree-wrapper').data('insert-point');
                while (tar != null && tar.length > 0) {
                    if (tar.hasClass('category') && tar[0].nodeName.toLowerCase() == 'li')
                        break;
                    tar = tar.parent();
                }

                if (tar != null && tar.length > 0)
                    $($('#category-template').parseTemplate({ name: name, id: generateGUID() })).insertAfter(tar);
                else
                    $($('#category-template').parseTemplate({ name: name, id: generateGUID() })).appendTo('#tree-list');
            });

            $('#context-menu a.lnkCreateGroupedGames').bind('click', this, function (e) {
                e.preventDefault();
                $('#context-menu').hide();

                var tar = $('#tree-wrapper').data('insert-point');
                while (tar != null && tar.parents('li.grouped-games').length > 0) {
                    tar = $(tar.parents('li.grouped-games').get(0));
                }
                if (tar != null && tar.length > 0) {
                    var name = window.prompt("Please enter the group name to be created", "");
                    if (name == null || name == false || name.toString().length == 0)
                        return;

                    if (tar.hasClass('category')) {
                        $($('#group-template').parseTemplate({ name: name, id: generateGUID() })).appendTo($('> ul', tar)).bind('mousedown', e.data, e.data.onMouseDown); ;
                    } else {
                        $($('#group-template').parseTemplate({ name: name, id: generateGUID() })).insertAfter(tar).bind('mousedown', e.data, e.data.onMouseDown); ;
                    }
                }

            });

            $('#btnHideAssignedGames').click(function (e) { syncList();  });
        };

        this.onWindowScroll = function () {
            $('#content-wrapper').css('margin-top', $(window).scrollTop());
        };

        this.init();
    };

    function syncList () {
        $('#content-wrapper li.game').show();
        var elems = $('#tree-wrapper li.game');
        if ($('#btnHideAssignedGames').is(':checked')) {
            for (var i = 0; i < elems.length; i++) {
                var cssSelector = '#content-wrapper li[vendor="'
                    + $(elems[i]).attr('vendor')
                    + '"][gameid="' + $(elems[i]).attr('gameid') + '"]';
                $(cssSelector).hide();
            }
        }

        $('#tree-wrapper li.game').hide();
        var types = $('#casino_type_checkbox :input');
        for (var i = 0; i < types.length; i++) {
            if ($(types[i]).is(':checked')) {
                var cssSelector = '#tree-wrapper li.game[vendor="' + $(types[i]).val() + '"]';
                $(cssSelector).show();
            }
        }
    };

</script>