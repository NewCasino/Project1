<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<script type="text/html" id="searchgame-template">
<#
    var data = arguments[0],g_detail=null,g_numb=0;
    var lth=data.length;
    for( var i=lth-1;i>=0;i--) {
    g_numb++;
    g_detail=data[i] || {};
 #>

<li class="GLItem Item_<#=g_numb #>" data-gameid="<#= g_detail.S #>">
        <# if( g_detail.I.length > 0 ) { #>
        <img class="GT" src="<#= g_detail.I.htmlEncode() #>" alt="<#= g_detail.G.htmlEncode() #>" />
        <# } #>
    <h3 class="GameTitle">
        <#= g_detail.G.htmlEncode() #>
    </h3>
</li>
<# } #>
</script>
<div class="multigamesearch_wraper">
    <div class="searchinput_ct">
        <input id="input_gamesearch" type="search" value="" placeholder="<%=this.GetMetadata(".search_label") %>" class="css_gamesearch" /><span class="search_icon">&nbsp;</span>
    </div>
    <div class="searchresultpanel"><ul id="searchresultlist" class="searchresultlist"></ul></div>
</div>
<script type="text/javascript">
// search games
    var _SearchGameManager=(function(){
        var targetSource = null,template_game=null,
            _Timer=null,_Timer_on=null;

        var init = function(p,t){
            if(typeof(p)==="undefined" || typeof(t)==="undefined")return;
            targetSource=p;
            template_game=t;

            $(".multigamesearch_wraper",targetSource).insertBefore($("#gameBarWidgetIframe",targetSource));
            $("#input_gamesearch",targetSource).keyup(function(){
                var searchText=$(this).val();
                if(_Timer!=null)
                    clearTimeout(_Timer);
                _Timer=setTimeout(function(){
                    GameDataManager.GameLoadByLocalStorage(function(dsource){
                        renderHtml(searchGames(searchText,dsource));
                    });
                },300);
            });
            bindEvent();
        }
        var bindEvent=function(){
            $(".multigamesearch_wraper",targetSource).mouseenter(function(){
                if(_Timer_on!=null)
                    clearTimeout(_Timer_on);
                _Timer_on=setTimeout(function(){
                    if($("#searchresultlist li").length>0){
                        switchTheOpenStatus(true);
                    }
                },500);
            }).mouseleave(function(){
                if(_Timer_on!=null)
                    clearTimeout(_Timer_on);
                _Timer_on=setTimeout(function(){
                    switchTheOpenStatus(false);
                },500);
            });
        }
        var switchTheOpenStatus=function(isOpen){
            if(isOpen)
                $(".multigamesearch_wraper",targetSource).addClass("open");
            else
                $(".multigamesearch_wraper",targetSource).removeClass("open");
        }
        var searchGames=function(t,dsource){
            var arrGames=[];
            if(!dsource)
                console.log(t+"="+"no data");
            for(var objg in dsource){
                objg=dsource[objg];
                if($.isArray(objg)){
                    var lth=objg.length;
                    for(var i=lth-1;i>=0;i--){
                        if(typeof(objg[i].G)!=="undefined" && objg[i].G.indexOf(t)>=0){
                            arrGames.push(objg[i]);
                        }
                    }
                }else{
                    console.log("the current object is not a array");
                }
            }
            return arrGames;
        }
        var renderHtml=function(d){
            if($.isArray(d)){
                if($(".multigamesearch_wraper.open",targetSource).length==0)
                    $(".multigamesearch_wraper",targetSource).addClass("open");
                $(".searchresultpanel #searchresultlist",targetSource).html(template_game.parseTemplate(d));

                $("#searchresultlist li",targetSource).click(function(){
                    _openCasinoGame($(this).data("gameid"), <%= Profile.IsAuthenticated ? "true" : "false"%>);
                });
            }
        }
        init($("#<%= this.ViewData["ContainerID"] %>"),$("#searchgame-template"));
    })();
</script>
