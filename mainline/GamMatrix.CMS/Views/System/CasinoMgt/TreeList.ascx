<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<CM.db.cmSite>" %>
<%@ Import Namespace="Casino" %>
<script type="text/html" id="category-template">
    <li class="category" id="<#=arguments[0].id#>">
        <span><#=arguments[0].name.htmlEncode()#></span>
        <div class="toolbar">
            <a class="move_up" href="javascript:void(0)" title="Move Up" onclick="onLnkMoveUpClick(event)"></a>
            <a class="move_down" href="javascript:void(0)" title="Move Down" onclick="onLnkMoveDownClick(event)"></a>
            <a class="edit" href="javascript:void(0)" title="Edit" onclick="onLnkEditClick(event)"></a>
            <a class="delete" href="javascript:void(0)" title="Remove" onclick="onLnkRemoveClick(event)"></a>
        </div>
        <ul></ul>
    </li>
</script>

<script type="text/html" id="group-template">
    <li class="grouped-games" id="<#=arguments[0].id#>">
        <span><#=arguments[0].name.htmlEncode()#></span>
        <div class="toolbar">
            <a class="edit" href="javascript:void(0)" title="Edit" onclick="onLnkEditClick(event)"></a>
            <a class="delete" href="javascript:void(0)" title="Remove" onclick="onLnkRemoveClick(event)"></a>
        </div>
        <ul></ul>
    </li>
</script>


<ul id="tree-list">
<%
    List<GameCategory> categories = GameManager.GetCategories(this.Model, false);
    foreach (GameCategory category in categories)
    {
    %>
    <li class="category" id="<%= category.ID.SafeHtmlEncode() %>">
        <span><%= category.GetName(this.Model).SafeHtmlEncode()%></span>
        <div class="toolbar">
            <a class="move_up" href="javascript:void(0)" title="Move Up" onclick="onLnkMoveUpClick(event)"></a>
            <a class="move_down" href="javascript:void(0)" title="Move Up" onclick="onLnkMoveDownClick(event)"></a>
            <a class="edit" href="javascript:void(0)" title="Edit" onclick="onLnkEditClick(event)"></a>
            <a class="delete" href="javascript:void(0)" title="Remove" onclick="onLnkRemoveClick(event)"></a>
        </div>
        <ul>
        <% 
        foreach (GameRef gameRef in category.GameRefs)
        { 
            if( gameRef.GameIDList.Length > 1 )
            {%>
                <li class="grouped-games" id="<%= gameRef.ID.SafeHtmlEncode() %>">
                    <span><%= gameRef.GetGroupName(this.Model).SafeHtmlEncode()%></span>
                    <div class="toolbar">
                        <a class="edit" href="javascript:void(0)" title="Edit" onclick="onLnkEditClick(event)"></a>
                        <a class="delete" href="javascript:void(0)" title="Remove" onclick="onLnkRemoveClick(event)"></a>
                    </div>
                    <ul>
             <%  
            }
            
            foreach( GameID gameID in gameRef.GameIDList)
            {
                if (gameID == null)
                    continue;

                var game = gameID.GetGame(this.Model);
                if (game == null)
                    continue;
                 %>
                    <li vendor="<%= gameID.VendorID %>" title="<%=gameID.ID.SafeHtmlEncode() %>" gameid="<%=gameID.ID.SafeHtmlEncode() %>" class="game <%= gameID.VendorID %>">
                        <span><%= gameID.VendorID %> - <%= game.Title.SafeHtmlEncode()%></span>
                        <div class="toolbar">
                            <a class="delete" href="javascript:void(0)" title="Remove" onclick="onLnkRemoveClick(event)"></a>
                        </div>
                    </li>
            <%
            }// foreach gameID
            if( gameRef.GameIDList.Length > 1 )
            {%>
                    </ul>
                </li>
            <%
            }
        }// foreach gameRef %>
        </ul>
    </li>
    <% } // foreach category%>
</ul>


<% using (Html.BeginRouteForm("CasinoMgt", new { @action = "SaveCategories",  @distinctName = this.Model.DistinctName.DefaultEncrypt() }, FormMethod.Post, new { @id="formSaveCategories", @target = "_self", @style="display:none" }))
   { %>
    <textarea id="txtJSONData" name="jsonData"></textarea>
<% } %>

<% using (Html.BeginRouteForm("CasinoMgt", new { @action = "EditMetadata", @distinctName = this.Model.DistinctName.DefaultEncrypt() }, FormMethod.Post, new { @id = "formEditMetadata", @target = "_blank", @style = "display:none" }))
   { %>
   <input type="hidden" name="distinctName" value="<%= this.Model.DistinctName.DefaultEncrypt() %>" />
   <input type="hidden" name="id" />
   <input type="hidden" name="name" />
<% } %>

<script language="javascript" type="text/javascript">
    function onLnkRemoveClick(evt) {
        evt = $.event.fix(evt);
        if (window.confirm('Are you sure to remove?') == true) {
            $($(evt.target).parents('li').get(0)).remove();
            syncList();
        }
    }

    function onLnkMoveUpClick(evt) {
        evt = $.event.fix(evt);
        var $prev = $(evt.target).parents('li.category').prev('li.category');
        if ($prev.length > 0) {
            $(evt.target).parents('li.category').detach().insertBefore($prev);
        }
    }
    function onLnkMoveDownClick(evt) {
        evt = $.event.fix(evt);
        var $next = $(evt.target).parents('li.category').next('li.category');
        if ($next.length > 0) {
            $(evt.target).parents('li.category').detach().insertAfter($next);
        }
    }
    function onLnkEditClick(evt) {
        evt = $.event.fix(evt);
        var $li = $($(evt.target).parents('li').get(0));
        $('#formEditMetadata :input[name="id"]').val($li.attr('id'));
        $('#formEditMetadata :input[name="name"]').val($('> span', $li).text());
        $('#formEditMetadata').submit();
    }

    function getGameRefsJson(category) {
        var gameRefs = $('> ul > li', category);
        var innerJson = '';
        for (var j = 0; j < gameRefs.length; j++) {
            var $gameRef = $(gameRefs[j]);
            if (j > 0)
                innerJson += ',';

            innerJson += '{';
            innerJson += '"ID":"' + $gameRef.attr('id').scriptEncode() + '",';
            innerJson += '"EnglishGroupName":"' + $('> span', $gameRef).text().scriptEncode() + '",';
            innerJson += '"GameIDList":[';
            if ($gameRef.hasClass('grouped-games')) {
                var games = $('> ul > li.game', $gameRef);
                for (var k = 0; k < games.length; k++) {
                    if (k > 0)
                        innerJson += ',';
                    innerJson += '{';
                    innerJson += '"VendorID":"' + $(games[k]).attr('vendor') + '",';
                    innerJson += '"ID":"' + $(games[k]).attr('gameid') + '"';
                    innerJson += '}';
                }
            }
            else if ($gameRef.hasClass('game')) {
                innerJson += '{"VendorID":"';
                innerJson += ($gameRef.attr('vendor') || '').scriptEncode();
                innerJson += '","ID":"';
                innerJson += ($gameRef.attr('gameid') || '').scriptEncode();
                innerJson += '"}';
            }

            innerJson += ']';
            innerJson += '}';
        }
        return innerJson;
    }

    function onBtnSaveClick() {
        var json = '[';

        var categories = $('#tree-list > li.category');
        for (var i = 0; i < categories.length; i++) {
            if (i > 0)
                json += ',';
            json += '{';
            {
                json += '"ID":"' + $(categories[i]).attr('id').scriptEncode() + '",';
                json += '"EnglishName":"' + $('> span', categories[i]).text().scriptEncode() + '",';
                json += '"GameRefs":[';
                json += getGameRefsJson($(categories[i]));
                json += ']';
            }
            json += '}';
        }

        json += ']';
        $('#txtJSONData').text(json).val(json);

        if (self.startLoad) self.startLoad();
        var options = {
            type: 'POST',
            dataType: 'json',
            success: function (json) {
                if (self.stopLoad) self.stopLoad();
                if( !json.success ) alert(json.error); 
            }
        };
        $('#formSaveCategories').ajaxForm(options);
        $('#formSaveCategories').submit();
    };

    setTimeout(function () {
        $('div.casino-categories-operations a.save').unbind('click').bind('click', onBtnSaveClick);
    }, 0);
</script>