<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>

<h2 class="LiveScoreTitle">
    <a class="LiveScoreLink" href="/canli-bahis" title="<%=this.GetMetadata(".SeeAllTitle")%>"><%=this.GetMetadata(".SeeAllLink")%>&nbsp;&#9658;</a>
</h2>

<%--=this.GetMetadata(".TheScript")--%>

<div id="NewScoreWidget" class="ScoreWidgetContainer">

<script type="text/javascript">
Function.prototype.brokenBind = Function.prototype.bind;
Function.prototype.bind = Function.prototype.originalBind;
var matchIdButton = false;
//var OMFECONFIG = { distUrl: 'http://omfe-components.everymatrix.local' };
 //var OMFECONFIG = { distUrl: '//cdn.everymatrix.com/omc/p' };
 var OMFECONFIG = { distUrl: '//cdn.everymatrix.com/omc/x' };
!function(O,M,F,E){var o=function(){ 
    OMFE.ComponentLoader.load('OMFEScoreWidgetCarousel', document.getElementById('NewScoreWidget'), { 
        endpoint: '//omfescoreapp.everymatrix.com/events',
        pollInterval: 1000,
        autoNext: 15000,
        enableStatistics: false,
        onChange: function(matchId) {
            if (!matchIdButton) {
                matchIdButton = document.createElement('a');
                matchIdButton.className = 'Button';
                matchIdButton.innerHTML = '<%=this.GetMetadata(".GoToMatch") %> &raquo;';
                document.getElementById('buttonContainer').appendChild(matchIdButton);
            } 
            matchIdButton.href = '/spor-bahisleri/?matchid=' + matchId;
        }
    });  
    //Function.prototype.bind = Function.prototype.brokenBind;
},r=window.OMFE||{},j=window.OMFECONFIG||{};return r.ComponentLoader&&(o()||1)||function(){var d=O.createElement("script"),c=O[M]("head").length&&O[M]("head")||O[M]("body"),i=!1,x=function(e){return e[E]&&e[E].removeChild(e)};j.distUrl=j.distUrl||"https://cdn.everymatrix.com/omc/x",d.type="text/javascript",d.src=j.distUrl+"/ComponentLoader.js?t="+Date.now(),d.onload=function(){i||(i=!0,o()),x(d)},void 0!==d.readyState&&(d.onreadystatechange=function(){window.OMFE&&(i||d.readyState&&"loaded"!==d.readyState&&"complete"!==d.readyState||(i=!0,o()),x(d))}),c[0][F](d)}()}(document,"getElementsByTagName","appendChild","parentNode");
</script>

</div>

<div id="buttonContainer" class="ScoreWidgetButton"></div>